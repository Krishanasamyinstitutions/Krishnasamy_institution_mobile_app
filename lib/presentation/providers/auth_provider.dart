import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/parent_model.dart';
import '../../core/services/sms_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Custom auth state for parent-based authentication
class ParentAuthState {
  final ParentModel? parent;
  final bool isAuthenticated;

  ParentAuthState({
    this.parent,
    this.isAuthenticated = false,
  });

  ParentAuthState copyWith({
    ParentModel? parent,
    bool? isAuthenticated,
  }) {
    return ParentAuthState(
      parent: parent ?? this.parent,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

/// Provider for parent authentication state
final parentAuthStateProvider =
    StateNotifierProvider<ParentAuthNotifier, AsyncValue<ParentAuthState>>(
        (ref) {
  return ParentAuthNotifier(ref.watch(supabaseClientProvider));
});

/// Legacy auth state provider - kept for compatibility
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

/// Current logged-in parent provider
final currentParentProvider = Provider<ParentModel?>((ref) {
  final authState = ref.watch(parentAuthStateProvider);
  return authState.valueOrNull?.parent;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser;
});

class ParentAuthNotifier extends StateNotifier<AsyncValue<ParentAuthState>> {
  final SupabaseClient _client;
  static const String _parentIdKey = 'logged_in_parent_id';

  ParentAuthNotifier(this._client)
      : super(AsyncValue.data(ParentAuthState())) {
    _loadSavedSession();
  }

  /// Load saved parent session from SharedPreferences
  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedParentId = prefs.getInt(_parentIdKey);

      if (savedParentId != null) {
        // Fetch parent from database
        final response = await _client
            .from('parents')
            .select()
            .eq('par_id', savedParentId)
            .eq('activestatus', 1)
            .maybeSingle();

        if (response != null) {
          final parent = ParentModel.fromJson(response);
          state = AsyncValue.data(ParentAuthState(
            parent: parent,
            isAuthenticated: true,
          ));
        }
      }
    } catch (e) {
      // Silently fail - user will just need to login again
    }
  }

  /// Save parent session to SharedPreferences
  Future<void> _saveSession(int parentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_parentIdKey, parentId);
  }

  /// Clear saved session
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_parentIdKey);
  }

  /// Sign in using parent table - checks payinchargemob and parpassword
  Future<ParentModel> signIn({
    required String mobile,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Clean mobile number - remove any non-digit characters
      final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');

      // Query parents table for matching payinchargemob
      final response = await _client
          .from('parents')
          .select()
          .eq('payinchargemob', cleanMobile)
          .eq('activestatus', 1)
          .maybeSingle();

      if (response == null) {
        throw Exception('Mobile number not registered');
      }

      final parent = ParentModel.fromJson(response);

      // Check if account creation is complete (password is set)
      if (parent.parpassword == null || parent.parpassword!.isEmpty) {
        throw Exception(
            'Account setup incomplete. Please create your account first.');
      }

      // Verify password using pgcrypto's verify_password function
      final verifyResult = await _client.rpc('verify_password', params: {
        'plain_password': password,
        'hashed_password': parent.parpassword,
      });

      // Debug: Print exact result
      print('DEBUG: verifyResult = $verifyResult');
      print('DEBUG: verifyResult type = ${verifyResult.runtimeType}');
      print('DEBUG: password = $password');
      print('DEBUG: hashed = ${parent.parpassword}');

      // RPC can return bool, String, or other formats - handle all cases
      final isValid = verifyResult == true ||
                      verifyResult == 'true' ||
                      verifyResult == 't' ||
                      verifyResult.toString() == 'true';

      print('DEBUG: isValid = $isValid');

      if (!isValid) {
        throw Exception('Invalid password');
      }

      // Save session
      await _saveSession(parent.parId);

      state = AsyncValue.data(ParentAuthState(
        parent: parent,
        isAuthenticated: true,
      ));

      return parent;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Sign out - clear parent session
  Future<void> signOut() async {
    await _clearSession();
    state = AsyncValue.data(ParentAuthState());
  }

  /// Check if parent is authenticated
  bool get isAuthenticated => state.valueOrNull?.isAuthenticated ?? false;

  /// Get current parent
  ParentModel? get currentParent => state.valueOrNull?.parent;
}

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseClient _client;
  final Ref _ref;

  AuthNotifier(this._client, this._ref) : super(const AsyncValue.data(null));

  /// Validate if mobile number exists in parents table
  /// Returns the parent if found, throws exception if not found
  Future<ParentModel> validateMobileNumber(String mobile) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');

    print('Auth: Validating mobile number: $cleanMobile');

    // Convert to int for numeric column comparison
    final mobileNumber = int.tryParse(cleanMobile);
    if (mobileNumber == null) {
      throw Exception('Invalid mobile number format');
    }

    final response = await _client
        .from('parents')
        .select()
        .eq('payinchargemob', mobileNumber)
        .maybeSingle();

    if (response == null) {
      throw Exception('Mobile number not registered. Contact school admin.');
    }

    final parent = ParentModel.fromJson(response);

    // Check if account is active
    if (parent.activestatus != 1) {
      if (parent.activestatus == 2) {
        throw Exception('Account suspended. Contact school admin.');
      } else if (parent.activestatus == 9) {
        throw Exception('Account terminated. Contact school admin.');
      }
      throw Exception('Account inactive. Contact school admin.');
    }

    // Check if already has password (account already created)
    if (parent.parpassword != null && parent.parpassword!.isNotEmpty) {
      throw Exception('Account already exists. Please sign in instead.');
    }

    return parent;
  }

  Future<void> requestOtp({
    required String mobile,
    String countryCode = '+91',
  }) async {
    state = const AsyncValue.loading();
    try {
      final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');

      // Step 1: Validate mobile exists in parents table
      final parent = await validateMobileNumber(cleanMobile);

      // Step 2: Generate secure 6-digit OTP
      final otp = _generateSecureOtp();

      // Step 3: Store OTP in parent record (parmobotp field)
      await _client.from('parents').update({
        'parmobotp': int.parse(otp),
        'parotpstatus': 0, // Reset to pending
      }).eq('par_id', parent.parId);

      // Step 4: Send OTP via Twilio SMS
      final smsSent = await SmsService.sendOtp(
        phoneNumber: cleanMobile,
        otp: otp,
        countryCode: countryCode,
      );

      if (!smsSent) {
        throw Exception('Failed to send OTP. Please try again.');
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> verifyOtp({required String mobile, required String otp}) async {
    state = const AsyncValue.loading();
    try {
      final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');

      // Query parent record with matching mobile and OTP
      final response = await _client
          .from('parents')
          .select()
          .eq('payinchargemob', cleanMobile)
          .eq('parmobotp', int.parse(otp))
          .eq('parotpstatus', 0) // Not yet verified
          .eq('activestatus', 1)
          .maybeSingle();

      if (response == null) {
        throw Exception('Invalid or expired OTP');
      }

      // Mark OTP as verified in parent record
      await _client
          .from('parents')
          .update({'parotpstatus': 1})
          .eq('par_id', response['par_id']);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Complete account creation by setting password
  /// This UPDATES the existing parent record, does NOT create new
  Future<void> completeAccountCreation({
    required String mobile,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');

      // Verify OTP was verified for this mobile
      final response = await _client
          .from('parents')
          .select()
          .eq('payinchargemob', cleanMobile)
          .eq('parotpstatus', 1) // Must be verified
          .eq('activestatus', 1)
          .maybeSingle();

      if (response == null) {
        throw Exception('Please verify OTP first');
      }

      final parent = ParentModel.fromJson(response);

      // Update parent record with password
      await _client.from('parents').update({
        'parpassword': password,
        // Clear OTP after successful password set
        'parmobotp': null,
      }).eq('par_id', parent.parId);

      // Auto-login after account creation
      await _ref.read(parentAuthStateProvider.notifier).signIn(
            mobile: cleanMobile,
            password: password,
          );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Sign in using parent table authentication
  Future<void> signIn({
    required String mobile,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Use parent table authentication
      await _ref.read(parentAuthStateProvider.notifier).signIn(
            mobile: mobile,
            password: password,
          );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _ref.read(parentAuthStateProvider.notifier).signOut();
    await _client.auth.signOut();
  }

/// Reset password for existing parent
  Future<void> resetPassword({
    required String mobile,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Clean mobile number
      final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');

      // Update password in parents table
      final response = await _client
          .from('parents')
          .update({'parpassword': newPassword})
          .eq('payinchargemob', cleanMobile)
          .eq('activestatus', 1)
          .select()
          .maybeSingle();

      if (response == null) {
        throw Exception('Mobile number not found');
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Generate cryptographically secure 6-digit OTP
  String _generateSecureOtp() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(supabaseClientProvider), ref);
});
