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
    final response = await client
        .from('feedemand')
        .select('*')
        .eq('stu_id', student.stuId)
        .eq('activestatus', 1)
        .order('createdat', ascending: false);

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
    final response = await client
        .from('feedemand')
        .select('*')
        .eq('stu_id', stuId)
        .eq('activestatus', 1)
        .order('createdat', ascending: false);

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
    final response = await client
        .from('feedemand')
        .select('*')
        .eq('dem_id', demId)
        .maybeSingle();

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
    final response = await client
        .from('feedemand')
        .select('*')
        .eq('stu_id', student.stuId)
        .eq('yr_id', yrId)
        .eq('activestatus', 1)
        .order('createdat', ascending: false);

    return (response as List<dynamic>)
        .map((e) => FeeModel.fromJson(e))
        .toList();
  } catch (e) {
    debugPrint('Error fetching fees by year: $e');
    return [];
  }
});
