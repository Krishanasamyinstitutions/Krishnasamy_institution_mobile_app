import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/fee_model.dart';
import 'auth_provider.dart';
import 'student_provider.dart';

/// Fetch fees for currently selected student from Supabase 'feedemand' table
final feesProvider = FutureProvider<List<FeeModel>>((ref) async {
  final student = ref.watch(selectedStudentProvider);
  final client = ref.watch(supabaseClientProvider);

  if (student == null) {
    debugPrint('Fees Provider: No student selected');
    return [];
  }

  debugPrint('Fees Provider: Fetching fees for stu_id=${student.stuId}');

  try {
    // Try fetching feedemand with joined feetype and feegroup data
    // Falls back to basic query if FK relationships aren't set up yet
    dynamic response;
    try {
      response = await client
          .from('feedemand')
          .select('*, feetype(*, feegroup(*))')
          .eq('stu_id', student.stuId)
          .eq('activestatus', 1)
          .order('createdat', ascending: false);
    } catch (e) {
      // Fallback to basic query without joins
      debugPrint('Fees Provider: Join failed, using basic query: $e');
      response = await client
          .from('feedemand')
          .select('*')
          .eq('stu_id', student.stuId)
          .eq('activestatus', 1)
          .order('createdat', ascending: false);
    }

    debugPrint('Fees Provider: Found ${(response as List).length} fee records');

    return (response as List<dynamic>)
        .map((e) => FeeModel.fromJson(e))
        .toList();
  } catch (e) {
    debugPrint('Fees Provider: Error fetching fees: $e');
    return [];
  }
});

/// Fetch fees by student ID
final feesByStudentIdProvider = FutureProvider.family<List<FeeModel>, int>((ref, stuId) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    dynamic response;
    try {
      response = await client
          .from('feedemand')
          .select('*, feetype(*, feegroup(*))')
          .eq('stu_id', stuId)
          .eq('activestatus', 1)
          .order('createdat', ascending: false);
    } catch (e) {
      response = await client
          .from('feedemand')
          .select('*')
          .eq('stu_id', stuId)
          .eq('activestatus', 1)
          .order('createdat', ascending: false);
    }

    return (response as List<dynamic>)
        .map((e) => FeeModel.fromJson(e))
        .toList();
  } catch (e) {
    debugPrint('Error fetching fees by student ID: $e');
    return [];
  }
});

/// Fetch pending (unpaid) fees for selected student (excludes zero balance)
final pendingFeesProvider = Provider<List<FeeModel>>((ref) {
  final feesAsync = ref.watch(feesProvider);
  return feesAsync.maybeWhen(
    data: (fees) => fees
        .where((f) => f.paidstatus == 'U' && f.balancedue > 0)
        .toList(),
    orElse: () => [],
  );
});

/// Fetch paid fees for selected student
final paidFeesProvider = Provider<List<FeeModel>>((ref) {
  final feesAsync = ref.watch(feesProvider);
  return feesAsync.maybeWhen(
    data: (fees) => fees
        .where((f) => f.paidstatus == 'P')
        .toList(),
    orElse: () => [],
  );
});

/// Calculate fee summary for selected student
final feeSummaryProvider = FutureProvider<FeeSummary>((ref) async {
  final fees = await ref.watch(feesProvider.future);

  double totalDue = 0;
  double totalPaid = 0;
  double totalPending = 0;
  int pendingCount = 0;
  int overdueCount = 0;
  DateTime? nearestDueDate;

  for (final fee in fees) {
    totalDue += fee.feeamount - fee.conamount;
    totalPaid += fee.paidamount;
    totalPending += fee.balancedue;

    if (fee.paidstatus == 'U') {
      pendingCount++;

      // Find the nearest due date from unpaid fees
      if (fee.duedate != null) {
        if (nearestDueDate == null || fee.duedate!.isBefore(nearestDueDate)) {
          nearestDueDate = fee.duedate;
        }
      }

      // Check if overdue
      if (fee.duedate != null && fee.duedate!.isBefore(DateTime.now())) {
        overdueCount++;
      }
    }
  }

  return FeeSummary(
    totalDue: totalDue,
    totalPaid: totalPaid,
    totalPending: totalPending,
    pendingCount: pendingCount,
    overdueCount: overdueCount,
    nextDueDate: nearestDueDate,
  );
});

/// Fetch a single fee demand by ID
final feeByIdProvider = FutureProvider.family<FeeModel?, int>((ref, demId) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    dynamic response;
    try {
      response = await client
          .from('feedemand')
          .select('*, feetype(*, feegroup(*))')
          .eq('dem_id', demId)
          .maybeSingle();
    } catch (e) {
      response = await client
          .from('feedemand')
          .select('*')
          .eq('dem_id', demId)
          .maybeSingle();
    }

    if (response != null) {
      return FeeModel.fromJson(response);
    }
    return null;
  } catch (e) {
    debugPrint('Error fetching fee by ID: $e');
    return null;
  }
});

/// Fetch fees by year
final feesByYearProvider = FutureProvider.family<List<FeeModel>, int>((ref, yrId) async {
  final student = ref.watch(selectedStudentProvider);
  final client = ref.watch(supabaseClientProvider);

  if (student == null) return [];

  try {
    dynamic response;
    try {
      response = await client
          .from('feedemand')
          .select('*, feetype(*, feegroup(*))')
          .eq('stu_id', student.stuId)
          .eq('yr_id', yrId)
          .eq('activestatus', 1)
          .order('createdat', ascending: false);
    } catch (e) {
      response = await client
          .from('feedemand')
          .select('*')
          .eq('stu_id', student.stuId)
          .eq('yr_id', yrId)
          .eq('activestatus', 1)
          .order('createdat', ascending: false);
    }

    return (response as List<dynamic>)
        .map((e) => FeeModel.fromJson(e))
        .toList();
  } catch (e) {
    debugPrint('Error fetching fees by year: $e');
    return [];
  }
});

/// Fetch all fee groups for the selected year
final feeGroupsProvider = FutureProvider<List<FeeGroupModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    final response = await client
        .from('feegroup')
        .select('*')
        .eq('activestatus', 1)
        .order('fgdesc');

    return (response as List<dynamic>)
        .map((e) => FeeGroupModel.fromJson(e))
        .toList();
  } catch (e) {
    debugPrint('Error fetching fee groups: $e');
    return [];
  }
});

/// Fetch all fee types with their fee groups
final feeTypesProvider = FutureProvider<List<FeeTypeModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    dynamic response;
    try {
      response = await client
          .from('feetype')
          .select('*, feegroup(*)')
          .eq('activestatus', 1)
          .order('feedesc');
    } catch (e) {
      response = await client
          .from('feetype')
          .select('*')
          .eq('activestatus', 1)
          .order('feedesc');
    }

    return (response as List<dynamic>)
        .map((e) => FeeTypeModel.fromJson(e))
        .toList();
  } catch (e) {
    debugPrint('Error fetching fee types: $e');
    return [];
  }
});

/// Get fees grouped by fee group (for categorized display)
final feesByGroupProvider = Provider<Map<String, List<FeeModel>>>((ref) {
  final feesAsync = ref.watch(feesProvider);
  return feesAsync.maybeWhen(
    data: (fees) {
      final Map<String, List<FeeModel>> grouped = {};
      for (final fee in fees) {
        // Use fee group name from joined data, or fallback to demfeetype
        final groupName = fee.feeGroupName.isNotEmpty
            ? fee.feeGroupName
            : _categorizeByFeeType(fee.demfeetype);
        grouped.putIfAbsent(groupName, () => []).add(fee);
      }
      return grouped;
    },
    orElse: () => {},
  );
});

/// Helper to categorize fees by type name (fallback when no fee_id)
String _categorizeByFeeType(String feeType) {
  final lower = feeType.toLowerCase();
  if (lower.contains('transport') || lower.contains('bus') || lower.contains('van')) {
    return 'Transport Fees';
  }
  return 'Tuition Fees';
}

/// Provider to fetch feegroup data first
/// Returns List of fgdesc values from feegroup table
final feeGroupListProvider = FutureProvider<List<String>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final student = ref.watch(selectedStudentProvider);

  if (student == null) return [];

  try {
    final response = await client
        .from('feegroup')
        .select('fgdesc')
        .eq('ins_id', student.insId)
        .eq('activestatus', 1);

    final groups = (response as List).map((e) => e['fgdesc'] as String).toList();
    debugPrint('Fee Groups fetched: $groups');
    return groups;
  } catch (e) {
    debugPrint('Error fetching fee groups: $e');
    return [];
  }
});

/// Provider to fetch feetype -> feegroup mapping
/// Returns Map<fee_id, fgdesc> for grouping feedemand by feegroup
final feeTypeToGroupMappingProvider = FutureProvider<Map<int, String>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final student = ref.watch(selectedStudentProvider);

  if (student == null) return {};

  try {
    // First, fetch feegroups (this should work - no RLS issues)
    final feeGroupsResponse = await client
        .from('feegroup')
        .select('fg_id, fgdesc')
        .eq('ins_id', student.insId)
        .eq('activestatus', 1);

    // Create fg_id -> fgdesc mapping
    final Map<int, String> fgIdToDesc = {};
    for (final fg in feeGroupsResponse as List) {
      fgIdToDesc[fg['fg_id'] as int] = fg['fgdesc'] as String;
    }
    debugPrint('Fee Groups loaded: $fgIdToDesc');

    // Try to fetch feetypes (may fail due to RLS)
    try {
      final feeTypesResponse = await client
          .from('feetype')
          .select('fee_id, fg_id')
          .eq('activestatus', 1);

      // Create fee_id -> fgdesc mapping
      final Map<int, String> feeIdToGroupName = {};
      for (final ft in feeTypesResponse as List) {
        final feeId = ft['fee_id'] as int;
        final fgId = ft['fg_id'] as int;
        if (fgIdToDesc.containsKey(fgId)) {
          feeIdToGroupName[feeId] = fgIdToDesc[fgId]!;
        }
      }

      debugPrint('Fee Mapping: Created mapping for ${feeIdToGroupName.length} fee types');
      return feeIdToGroupName;
    } catch (e) {
      debugPrint('Feetype fetch failed (RLS?): $e');
      // Return empty map - will use keyword matching fallback
      return {};
    }
  } catch (e) {
    debugPrint('Error fetching fee type mapping: $e');
    return {};
  }
});

/// Get pending fees grouped by feegroup.fgdesc with totals
/// Returns Map<fgdesc, total_balance> for display in home screen
final pendingFeesByGroupProvider = Provider<Map<String, double>>((ref) {
  final pendingFees = ref.watch(pendingFeesProvider);
  final mappingAsync = ref.watch(feeTypeToGroupMappingProvider);
  final feeGroupsAsync = ref.watch(feeGroupListProvider);

  final mapping = mappingAsync.valueOrNull ?? {};
  final feeGroups = feeGroupsAsync.valueOrNull ?? [];
  final Map<String, double> grouped = {};

  for (final fee in pendingFees) {
    String groupName;

    // Try to get group name from mapping using fee_id
    if (fee.feeId != null && mapping.containsKey(fee.feeId)) {
      groupName = mapping[fee.feeId]!;
    } else if (fee.feeGroupName.isNotEmpty) {
      // Use joined data if available
      groupName = fee.feeGroupName;
    } else {
      // Smart fallback: match demfeetype against actual feegroup.fgdesc values
      groupName = _matchFeeTypeToGroup(fee.demfeetype, feeGroups);
    }

    grouped[groupName] = (grouped[groupName] ?? 0) + fee.balancedue;
  }

  debugPrint('Pending Fees by Group: $grouped');
  return grouped;
});

/// Match fee type name to a feegroup.fgdesc using keyword matching
String _matchFeeTypeToGroup(String demfeetype, List<String> feeGroups) {
  final lower = demfeetype.toLowerCase();

  // Try to find a matching feegroup based on keywords
  for (final group in feeGroups) {
    final groupLower = group.toLowerCase();

    // Check for transport/van/bus related fees
    if ((lower.contains('van') || lower.contains('bus') || lower.contains('transport')) &&
        (groupLower.contains('van') || groupLower.contains('bus') || groupLower.contains('transport'))) {
      return group;
    }

    // Check for school/tuition/term related fees
    if ((lower.contains('school') || lower.contains('tuition') || lower.contains('term') ||
         lower.contains('fee') || lower.contains('eca')) &&
        (groupLower.contains('school') || groupLower.contains('tuition') || groupLower.contains('fee'))) {
      return group;
    }
  }

  // If no match found, use first feegroup as default or fallback to categorization
  if (feeGroups.isNotEmpty) {
    // Default: non-transport fees go to first group (usually school fees)
    if (lower.contains('van') || lower.contains('bus') || lower.contains('transport')) {
      // Look for any transport-related group
      for (final group in feeGroups) {
        if (group.toLowerCase().contains('van') ||
            group.toLowerCase().contains('bus') ||
            group.toLowerCase().contains('transport')) {
          return group;
        }
      }
      return feeGroups.last; // Assume last group might be transport
    }
    return feeGroups.first; // Default to first group for other fees
  }

  return _categorizeByFeeType(demfeetype);
}
