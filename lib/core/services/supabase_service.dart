import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase service with schema-based multi-tenancy support.
///
/// Tables in the PUBLIC schema (shared across institutions):
///   institution, institutionyear, year, country, state, city, currency, paymentgateway
///
/// Tables in INSTITUTION-SPECIFIC schemas (e.g. kcet20262027):
///   students, parents, parentdetail, feedemand, feetype, feegroup,
///   payment, paymentdetails, shoppingcart, shoppingcartdetails,
///   notification, concessioncategory, classfeedemand
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Current institution schema name (e.g. 'kcet20262027')
  static String? _currentSchema;
  static String? get currentSchema => _currentSchema;

  /// Current institution ID (set alongside schema)
  static int? _currentInsId;
  static int? get currentInsId => _currentInsId;

  /// Set the schema after login / institution selection
  static void setSchema(String? schema) {
    _currentSchema = schema;
    debugPrint('SupabaseService schema set to: $schema');
  }

  /// Query from institution-specific schema table.
  /// Falls back to public if no schema is set, but logs a loud warning so
  /// schema-not-set bugs surface during development instead of silently
  /// reading/writing the wrong schema.
  static SupabaseQueryBuilder fromSchema(String table) {
    if (_currentSchema != null && _currentSchema!.isNotEmpty) {
      return client.schema(_currentSchema!).from(table);
    }
    debugPrint(
      '⚠️  fromSchema("$table") called with NO schema set — falling back to public. '
      'This usually means a query ran before login/student selection completed.',
    );
    return client.from(table);
  }

  /// Build schema name from institution short name and year label.
  /// e.g. ('kcet', '2026-2027') -> 'kcet20262027'
  static String buildSchemaName(String shortName, String yearLabel) {
    return '${shortName.toLowerCase()}${yearLabel.replaceAll('-', '')}';
  }

  /// Fetch the active academic year label for an institution.
  /// Tries `institutionyear` first, then `year`, then defaults to current year.
  static Future<String?> fetchActiveYearLabel(int insId) async {
    // 1. Try institutionyear table (primary source)
    try {
      final result = await client
          .from('institutionyear')
          .select('yrlabel')
          .eq('ins_id', insId)
          .eq('activestatus', 1)
          .order('iyr_id', ascending: false)
          .limit(1)
          .maybeSingle();

      if (result != null && result['yrlabel'] != null) {
        return result['yrlabel'] as String;
      }
    } catch (e) {
      debugPrint('institutionyear query failed: $e');
    }

    // 2. Fallback to year table
    try {
      final result = await client
          .from('year')
          .select('yrlabel')
          .eq('ins_id', insId)
          .eq('activestatus', 1)
          .order('yr_id', ascending: false)
          .limit(1)
          .maybeSingle();

      if (result != null && result['yrlabel'] != null) {
        return result['yrlabel'] as String;
      }
    } catch (_) {}

    // 3. Default to current academic year
    final now = DateTime.now();
    return '${now.year}-${now.year + 1}';
  }

  /// Determine and set the schema for a given institution ID.
  /// Returns the schema name on success, null on failure.
  static Future<String?> determineAndSetSchema(int insId) async {
    try {
      // Fetch institution short name
      final insRow = await client
          .from('institution')
          .select('inshortname')
          .eq('ins_id', insId)
          .maybeSingle();

      if (insRow == null || insRow['inshortname'] == null) {
        debugPrint('No institution found for ins_id=$insId');
        return null;
      }

      // Fetch active academic year (always returns a value with fallback)
      final yearLabel = await fetchActiveYearLabel(insId);
      if (yearLabel == null) {
        debugPrint('No year label for ins_id=$insId');
        return null;
      }

      final shortName = insRow['inshortname'] as String;
      final schema = buildSchemaName(shortName, yearLabel);
      _currentInsId = insId;
      setSchema(schema);
      return schema;
    } catch (e) {
      debugPrint('Error determining schema: $e');
      return null;
    }
  }

  /// Find ALL institutions where a parent exists (by mobile number).
  /// Returns list of (insId, schema, hasPassword) records.
  /// Active schema is set to the FIRST match that has a password already configured
  /// (falls back to first match overall if none have passwords yet).
  static Future<List<({int insId, String schema, bool hasPassword})>> findParentInstitutions(String mobile) async {
    final matches = <({int insId, String schema, bool hasPassword})>[];

    try {
      // 1. Get all active institutions with their short names
      final institutions = await client
          .from('institution')
          .select('ins_id, inshortname')
          .eq('activestatus', 1);

      if ((institutions as List).isEmpty) return matches;

      // 2. For each institution, build schema and search parents table
      for (final inst in institutions) {
        final insId = inst['ins_id'] as int;
        final shortName = inst['inshortname'] as String?;
        if (shortName == null || shortName.isEmpty) continue;

        final yearLabel = await fetchActiveYearLabel(insId);
        if (yearLabel == null) continue;

        final schema = buildSchemaName(shortName, yearLabel);

        try {
          final result = await client.schema(schema)
              .from('parents')
              .select('par_id, parpassword')
              .eq('payinchargemob', mobile)
              .eq('activestatus', 1)
              .limit(1)
              .maybeSingle();

          if (result != null) {
            final pwd = result['parpassword']?.toString();
            final hasPassword = pwd != null && pwd.isNotEmpty;
            debugPrint('Found parent in schema: $schema (ins_id=$insId, hasPassword=$hasPassword)');
            matches.add((insId: insId, schema: schema, hasPassword: hasPassword));
          }
        } on PostgrestException catch (e) {
          // PGRST106 = schema not exposed in PostgREST. Happens when an
          // institution row exists but its schema isn't in db-schemas.
          // e.code holds the HTTP status ('406'), so match on message.
          if (!e.message.contains('PGRST106')) {
            debugPrint('Schema $schema search failed: $e');
          }
        } catch (e) {
          debugPrint('Schema $schema search failed: $e');
        }
      }

      // Prefer a schema where the password is already set (for login).
      // Fall back to first match if none have passwords (sign-up flow).
      if (matches.isNotEmpty) {
        final authMatch = matches.firstWhere(
          (m) => m.hasPassword,
          orElse: () => matches.first,
        );
        _currentInsId = authMatch.insId;
        setSchema(authMatch.schema);
      }
    } catch (e) {
      debugPrint('Error finding parent institutions: $e');
    }

    return matches;
  }

  /// Convenience wrapper — returns first match for backward compat.
  static Future<({int? insId, String? schema})> findParentInstitution(String mobile) async {
    final matches = await findParentInstitutions(mobile);
    if (matches.isEmpty) return (insId: null, schema: null);
    return (insId: matches.first.insId, schema: matches.first.schema);
  }

  /// Cached list of schemas where the current parent exists.
  /// Populated during login, used by studentsByParentProvider.
  static List<({int insId, String schema, bool hasPassword})> _parentSchemas = [];
  static List<({int insId, String schema, bool hasPassword})> get parentSchemas => _parentSchemas;

  static void setParentSchemas(List<({int insId, String schema, bool hasPassword})> schemas) {
    _parentSchemas = schemas;
  }

  /// Clear the current schema (on logout)
  static void clearSchema() {
    _currentSchema = null;
    _currentInsId = null;
    _parentSchemas = [];
    debugPrint('SupabaseService schema cleared');
  }
}
