/// Supabase configuration
class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase project URL
  static const String url = 'YOUR_SUPABASE_URL';

  /// Supabase anonymous key
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';

  /// Supabase service role key (for server-side operations only)
  /// Never expose this in client-side code
  static const String serviceRoleKey = '';
}
