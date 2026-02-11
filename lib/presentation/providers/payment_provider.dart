import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/fee_model.dart';
import '../../data/models/payment_model.dart';
import 'student_provider.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';
import 'notification_provider.dart';

/// Fetch payments from Supabase 'payment' table
/// Note: The payment table stores payment records linked to shopping carts
final paymentsProvider = FutureProvider<List<PaymentModel>>((ref) async {
  final student = ref.watch(selectedStudentProvider);
  final client = ref.watch(supabaseClientProvider);

  if (student == null) return [];

  try {
    // Get payments for the selected student
    final response = await client
        .from('payment')
        .select('*')
        .eq('stu_id', student.stuId)
        .eq('activestatus', 1)
        .neq('paystatus', 'I')
        .order('createdat', ascending: false);

    return (response as List<dynamic>)
        .map((e) => PaymentModel.fromJson(e))
        .toList();
  } catch (e) {
    debugPrint('Error fetching payments: $e');
    return [];
  }
});

/// Fetch payments by institution ID
final paymentsByInstitutionProvider = FutureProvider.family<List<PaymentModel>, int>((ref, insId) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    final response = await client
        .from('payment')
        .select('*')
        .eq('ins_id', insId)
        .eq('activestatus', 1)
        .order('createdat', ascending: false);

    return (response as List<dynamic>)
        .map((e) => PaymentModel.fromJson(e))
        .toList();
  } catch (e) {
    debugPrint('Error fetching payments by institution: $e');
    return [];
  }
});

/// Fetch a single payment by ID
final paymentByIdProvider = FutureProvider.family<PaymentModel?, int>((ref, payId) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    final response = await client
        .from('payment')
        .select('*')
        .eq('pay_id', payId)
        .maybeSingle();

    if (response != null) {
      return PaymentModel.fromJson(response);
    }
    return null;
  } catch (e) {
    debugPrint('Error fetching payment by ID: $e');
    return null;
  }
});

/// Recent payments (last 5)
final recentPaymentsProvider = Provider<List<PaymentModel>>((ref) {
  final paymentsAsync = ref.watch(paymentsProvider);
  return paymentsAsync.maybeWhen(
    data: (payments) => payments.take(5).toList(),
    orElse: () => [],
  );
});

/// Successful payments only
final successfulPaymentsProvider = Provider<List<PaymentModel>>((ref) {
  final paymentsAsync = ref.watch(paymentsProvider);
  return paymentsAsync.maybeWhen(
    data: (payments) => payments
        .where((p) => p.paystatus == 'C')
        .toList(),
    orElse: () => [],
  );
});

/// Shopping cart provider
final shoppingCartProvider = FutureProvider.family<ShoppingCartModel?, int>((ref, carId) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    final response = await client
        .from('shoppingcart')
        .select('*')
        .eq('car_id', carId)
        .maybeSingle();

    if (response != null) {
      return ShoppingCartModel.fromJson(response);
    }
    return null;
  } catch (e) {
    debugPrint('Error fetching shopping cart: $e');
    return null;
  }
});

/// Shopping cart details provider
final shoppingCartDetailsProvider = FutureProvider.family<List<ShoppingCartDetailModel>, int>((ref, carId) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    final response = await client
        .from('shoppingcartdetails')
        .select('*')
        .eq('car_id', carId)
        .eq('activestatus', 1);

    return (response as List<dynamic>)
        .map((e) => ShoppingCartDetailModel.fromJson(e))
        .toList();
  } catch (e) {
    debugPrint('Error fetching shopping cart details: $e');
    return [];
  }
});

/// Deletes the active cart from database for a student
Future<bool> clearCartFromDatabase({
  required WidgetRef ref,
  required int studentId,
}) async {
  final client = ref.read(supabaseClientProvider);

  try {
    // Find active cart for this student
    final existingCart = await client
        .from('shoppingcart')
        .select('car_id')
        .eq('stu_id', studentId)
        .eq('carinitiated', 'N')
        .eq('activestatus', 1)
        .maybeSingle();

    if (existingCart != null) {
      final carId = existingCart['car_id'] as int;

      // Delete cart details first (foreign key constraint)
      await client.from('shoppingcartdetails').delete().eq('car_id', carId);

      // Delete the cart
      await client.from('shoppingcart').delete().eq('car_id', carId);

      debugPrint('Cart cleared from DB: car_id=$carId');

      // Check if table is empty and reset sequence
      final remainingCarts = await client
          .from('shoppingcart')
          .select('car_id')
          .limit(1);

      if ((remainingCarts as List).isEmpty) {
        // Reset sequences when tables are empty
        await client.rpc('reset_cart_sequences');
        debugPrint('Cart sequences reset to 1');
      }
    }
    return true;
  } catch (e) {
    debugPrint('Error clearing cart from database: $e');
    return false;
  }
}

/// Saves the in-memory cart to Supabase shoppingcart + shoppingcartdetails tables.
/// Returns the created car_id on success, or null on failure.
/// Error message from the last saveCartToDatabase call
String? lastCartSaveError;

Future<int?> saveCartToDatabase({
  required WidgetRef ref,
  required List<FeeModel> items,
  required int studentId,
}) async {
  lastCartSaveError = null;
  final client = ref.read(supabaseClientProvider);
  final student = ref.read(selectedStudentProvider);
  final parent = ref.read(currentParentProvider);
  if (student == null || items.isEmpty) return null;

  // Use yr_id/yrlabel from the first fee item
  final firstFee = items.first;
  final totalAmount = items.fold<double>(0, (sum, f) => sum + f.balancedue);

  try {
    // Check if student already has active (non-finalized) carts
    // Note: Only check stu_id and activestatus - carinitiated 'N' means not initiated
    final existingCarts = await client
        .from('shoppingcart')
        .select('car_id, carinitiated')
        .eq('stu_id', student.stuId)
        .eq('activestatus', 1)
        .order('car_id', ascending: false);

    // Separate non-initiated carts from stale initiated carts
    final activeCarts = <Map<String, dynamic>>[];
    final staleCarts = <Map<String, dynamic>>[];
    for (final c in (existingCarts as List)) {
      if (c['carinitiated']?.toString().trim() == 'N') {
        activeCarts.add(c);
      } else if (c['carinitiated']?.toString().trim() == 'I') {
        staleCarts.add(c);
      }
    }

    debugPrint('Found ${existingCarts.length} carts, ${activeCarts.length} active, ${staleCarts.length} stale for student ${student.stuId}');

    // Clean up stale initiated carts (from failed/abandoned payments)
    for (final stale in staleCarts) {
      final staleCarId = stale['car_id'] as int;
      await client.from('shoppingcartdetails').delete().eq('car_id', staleCarId);
      await client.from('shoppingcart').delete().eq('car_id', staleCarId);
      debugPrint('Deleted stale initiated cart: $staleCarId');
    }

    int carId;

    if (activeCarts.isNotEmpty) {
      // Use the most recent cart
      carId = activeCarts.first['car_id'] as int;

      // Delete any other duplicate carts for this student
      for (int i = 1; i < activeCarts.length; i++) {
        final oldCarId = activeCarts[i]['car_id'] as int;
        await client.from('shoppingcartdetails').delete().eq('car_id', oldCarId);
        await client.from('shoppingcart').delete().eq('car_id', oldCarId);
        debugPrint('Deleted duplicate cart: $oldCarId');
      }

      // Update cart header with new total, date, and createdby
      await client.from('shoppingcart').update({
        'yr_id': firstFee.yrId,
        'yrlabel': firstFee.demfeeyear,
        'transdate': DateTime.now().toIso8601String().split('T')[0],
        'transtotalamount': totalAmount,
        'createdby': parent?.payincharge ?? student.stuname,
      }).eq('car_id', carId);

      // Delete old cart details
      await client
          .from('shoppingcartdetails')
          .delete()
          .eq('car_id', carId);
    } else {
      // Create new cart
      final cartResponse = await client.from('shoppingcart').insert({
        'yr_id': firstFee.yrId,
        'yrlabel': firstFee.demfeeyear,
        'ins_id': student.insId,
        'stu_id': student.stuId,
        'transtype': 'FEE',
        'transdate': DateTime.now().toIso8601String().split('T')[0],
        'transcurrency': 'INR',
        'transtotalamount': totalAmount,
        'carinitiated': 'N',
        'createdby': parent?.payincharge ?? student.stuname,
      }).select('car_id').single();

      carId = cartResponse['car_id'] as int;
    }

    // Insert cart details
    final detailRows = items.map((fee) => {
      'car_id': carId,
      'yr_id': fee.yrId,
      'yrlabel': fee.demfeeyear,
      'ins_id': fee.insId,
      'dem_id': fee.demId,
      'transcurrency': 'INR',
      'transtotalamount': fee.balancedue,
    }).toList();

    await client.from('shoppingcartdetails').insert(detailRows);

    debugPrint('Cart saved to DB: car_id=$carId, ${items.length} detail rows');
    return carId;
  } catch (e, stackTrace) {
    lastCartSaveError = e.toString();
    debugPrint('Error saving cart to database: $e');
    debugPrint('Stack trace: $stackTrace');
    return null;
  }
}

/// Step 3: Initiate payment - creates payment + paymentdetails records.
/// Accepts cart data directly to avoid redundant DB fetches.
/// Returns pay_id on success, null on failure.
String? lastPaymentError;

Future<int?> initiatePayment({
  required WidgetRef ref,
  required int carId,
  required List<FeeModel> cartItems,
  required double cartTotal,
}) async {
  lastPaymentError = null;
  final client = ref.read(supabaseClientProvider);
  final student = ref.read(selectedStudentProvider);
  final parent = ref.read(currentParentProvider);
  if (student == null || cartItems.isEmpty) return null;

  try {
    var items = cartItems;
    var totalAmount = cartTotal;

    // 1. Validate: check actual balancedue from DB to prevent double payment
    final demIds = items.map((f) => f.demId).toList();
    final freshDemands = await client
        .from('feedemand')
        .select('dem_id, balancedue, paidstatus')
        .inFilter('dem_id', demIds);

    // Filter out already-paid fees (balancedue <= 0 or paidstatus = 'P')
    final paidDemIds = <int>{};
    for (final d in (freshDemands as List)) {
      final bal = (d['balancedue'] as num?)?.toDouble() ?? 0;
      if (bal <= 0 || d['paidstatus'] == 'P') {
        paidDemIds.add(d['dem_id'] as int);
      }
    }

    if (paidDemIds.isNotEmpty) {
      // Remove already-paid items
      items = items.where((f) => !paidDemIds.contains(f.demId)).toList();
      totalAmount = items.fold(0.0, (sum, f) => sum + f.balancedue);

      if (items.isEmpty) {
        lastPaymentError = 'All fees have already been paid';
        return null;
      }

      // Also update in-memory cart to remove paid items
      for (final demId in paidDemIds) {
        ref.read(cartProvider.notifier).removeFee(demId.toString());
      }

      debugPrint('Removed ${paidDemIds.length} already-paid fees from payment');
    }

    // 2. Fetch sequence to generate payment number
    final sequence = await client
        .from('sequence')
        .select('seq_id, sequid, seqwidth, seqcurno')
        .limit(1)
        .single();

    final seqId = sequence['seq_id'] as int;
    final sequid = sequence['sequid'] as String; // e.g. "FC25/00001"
    final seqWidth = sequence['seqwidth'] as int; // e.g. 5
    final seqCurNo = (sequence['seqcurno'] as num).toInt();
    final newSeqNo = seqCurNo + 1;

    // Extract prefix from sequid (everything before the numeric part)
    final prefix = sequid.replaceAll(RegExp(r'\d+$'), ''); // "FC25/"
    final payNumber = '$prefix${newSeqNo.toString().padLeft(seqWidth, '0')}';

    // 3. Create payment record with paynumber (paystatus = 'I' for Initiated)
    final payResponse = await client.from('payment').insert({
      'ins_id': student.insId,
      'inscode': student.inscode,
      'stu_id': student.stuId,
      'yr_id': items.first.yrId,
      'yrlabel': items.first.demfeeyear,
      'transtotalamount': totalAmount,
      'transcurrency': 'INR',
      'paydate': DateTime.now().toIso8601String(),
      'paystatus': 'I',
      'paynumber': payNumber,
      'createdby': parent?.payincharge ?? student.stuname,
    }).select('pay_id').single();

    final payId = payResponse['pay_id'] as int;

    // 3. Insert paymentdetails + update shoppingcart + increment sequence in parallel
    final payDetailRows = items.map((fee) => {
      'pay_id': payId,
      'dem_id': fee.demId,
      'yr_id': fee.yrId,
      'yrlabel': fee.demfeeyear,
      'ins_id': fee.insId,
      'transcurrency': 'INR',
      'transtotalamount': fee.balancedue,
    }).toList();

    await Future.wait([
      client.from('paymentdetails').insert(payDetailRows),
      client.from('shoppingcart').update({
        'carinitiated': 'I',
      }).eq('car_id', carId),
      client.from('sequence').update({
        'seqcurno': newSeqNo,
      }).eq('seq_id', seqId),
    ]);

    debugPrint('Payment initiated: pay_id=$payId, paynumber=$payNumber, ${items.length} detail rows');
    return payId;
  } catch (e, stackTrace) {
    lastPaymentError = e.toString();
    debugPrint('Error initiating payment: $e');
    debugPrint('Stack trace: $stackTrace');
    return null;
  }
}

/// Step 4: Handle payment gateway response.
/// On success: update payment status, update feedemand, delete cart, clear memory.
Future<bool> handlePaymentSuccess({
  required WidgetRef ref,
  required int payId,
  required int carId,
  required String paymethod,
  required String payreference,
  required List<FeeModel> items,
}) async {
  final client = ref.read(supabaseClientProvider);

  try {
    // 1. Update payment status + fetch feedemand in parallel
    final paymentUpdateFuture = client.from('payment').update({
      'paystatus': 'C',
      'paymethod': paymethod,
      'payreference': payreference,
      'paydate': DateTime.now().toIso8601String(),
    }).eq('pay_id', payId).select('paynumber').single();

    final demandsFuture = client
        .from('feedemand')
        .select('dem_id, paidamount, feeamount, conamount')
        .inFilter('dem_id', items.map((f) => f.demId).toList())
        .eq('activestatus', 1);

    final results = await Future.wait<dynamic>([
      paymentUpdateFuture,
      demandsFuture,
    ]);

    final demands = results[1] as List<dynamic>;

    // 2. Update feedemand + find all student carts in parallel
    final List<Future> feedemandOps = [];
    final studentId = items.first.stuId;

    final paidMap = <int, double>{};
    for (final fee in items) {
      paidMap[fee.demId] = fee.balancedue;
    }

    for (final demand in demands) {
      final demId = demand['dem_id'] as int;
      final paidAmount = paidMap[demId] ?? 0;
      final currentPaid = (demand['paidamount'] as num?)?.toDouble() ?? 0;
      final feeAmount = (demand['feeamount'] as num?)?.toDouble() ?? 0;
      final conAmount = (demand['conamount'] as num?)?.toDouble() ?? 0;
      final newPaid = currentPaid + paidAmount;
      final newBalance = feeAmount - conAmount - newPaid;

      feedemandOps.add(client.from('feedemand').update({
        'paidamount': newPaid,
        'balancedue': newBalance <= 0 ? 0 : newBalance,
        'paidstatus': newBalance <= 0 ? 'P' : 'U',
        'pay_id': payId,
      }).eq('dem_id', demId));
    }

    // Fetch all cart IDs for this student in parallel with feedemand updates
    final allCartsFuture = client
        .from('shoppingcart')
        .select('car_id')
        .eq('stu_id', studentId);

    await Future.wait([...feedemandOps, allCartsFuture]);

    // 3. Bulk delete ALL carts for this student (current + stale)
    final allCarIds = ((await allCartsFuture) as List)
        .map((c) => c['car_id'] as int)
        .toList();

    if (allCarIds.isNotEmpty) {
      await client.from('shoppingcartdetails').delete().inFilter('car_id', allCarIds);
      await client.from('shoppingcart').delete().inFilter('car_id', allCarIds);
      debugPrint('Deleted ${allCarIds.length} cart(s) for student $studentId');
    }

    // 4. Clear in-memory cart & refresh payment history
    ref.read(cartProvider.notifier).clearCart();
    ref.invalidate(paymentsProvider);

    // 5. Refresh notifications (payment will appear from DB)
    ref.invalidate(notificationsProvider);

    debugPrint('Payment success: pay_id=$payId, feedemand updated, carts cleaned');
    return true;
  } catch (e, stackTrace) {
    debugPrint('Error handling payment success: $e');
    debugPrint('Stack trace: $stackTrace');
    // Still try to delete the cart even if feedemand updates failed
    try {
      await client.from('shoppingcartdetails').delete().eq('car_id', carId);
      await client.from('shoppingcart').delete().eq('car_id', carId);
      ref.read(cartProvider.notifier).clearCart();
      debugPrint('Cart deleted in error recovery');
    } catch (_) {}
    return false;
  }
}

/// Handle payment failure
Future<bool> handlePaymentFailure({
  required WidgetRef ref,
  required int payId,
  required int carId,
}) async {
  final client = ref.read(supabaseClientProvider);

  try {
    // Update payment status to 'F' (Failed) and reset cart in parallel
    final payUpdateFuture = client.from('payment').update({
      'paystatus': 'F',
    }).eq('pay_id', payId).select('paynumber').single();

    final cartResetFuture = client.from('shoppingcart').update({
      'carinitiated': 'N',
    }).eq('car_id', carId);

    await Future.wait<dynamic>([payUpdateFuture, cartResetFuture]);

    await payUpdateFuture;

    ref.invalidate(paymentsProvider);
    ref.invalidate(notificationsProvider);

    debugPrint('Payment failed: pay_id=$payId, cart car_id=$carId reset');
    return true;
  } catch (e) {
    debugPrint('Error handling payment failure: $e');
    return false;
  }
}

/// Restores the in-memory cart from database on app restart.
/// Watches selectedStudentProvider - auto-triggers when student changes.
/// Uses the `get_active_cart_fees` RPC for a single DB round trip.
/// Falls back to 3 sequential queries if the RPC is not available.
final cartRestorerProvider = FutureProvider.autoDispose<void>((ref) async {
  final student = ref.watch(selectedStudentProvider);
  if (student == null) return;

  final client = ref.watch(supabaseClientProvider);
  final currentCart = ref.read(cartProvider);

  // If cart already has items for THIS student, skip loading
  if (currentCart.isNotEmpty && currentCart.studentId == student.stuId) {
    return;
  }

  // Clear cart (either empty or belongs to different student)
  if (currentCart.isNotEmpty) {
    ref.read(cartProvider.notifier).clearCart();
  }

  try {
    // Try single-query RPC first (requires running db_sync/setup_cart_rpc.sql)
    final fees = await client.rpc('get_active_cart_fees', params: {
      'p_stu_id': student.stuId,
    });

    final feeModels = (fees as List)
        .map((f) => FeeModel.fromJson(f as Map<String, dynamic>))
        .toList();

    if (feeModels.isNotEmpty) {
      ref.read(cartProvider.notifier).restoreCart(feeModels, student.stuId);
      debugPrint('Cart restored via RPC: ${feeModels.length} items for student ${student.stuId}');
    }
  } catch (rpcError) {
    // Fallback: 3 sequential queries (RPC not deployed yet)
    debugPrint('RPC fallback: $rpcError');
    try {
      final cart = await client
          .from('shoppingcart')
          .select('car_id')
          .eq('stu_id', student.stuId)
          .eq('carinitiated', 'N')
          .eq('activestatus', 1)
          .maybeSingle();

      if (cart == null) return;

      final carId = cart['car_id'] as int;

      // Get dem_ids from cart details
      final details = await client
          .from('shoppingcartdetails')
          .select('dem_id')
          .eq('car_id', carId)
          .eq('activestatus', 1);

      final demIds = (details as List)
          .map((d) => d['dem_id'] is int ? d['dem_id'] as int : int.parse(d['dem_id'].toString()))
          .toList();

      if (demIds.isEmpty) return;

      // Fetch full feedemand records for these dem_ids
      final fees = await client
          .from('feedemand')
          .select('*')
          .inFilter('dem_id', demIds)
          .eq('activestatus', 1);

      final feeModels = (fees as List)
          .map((f) => FeeModel.fromJson(f))
          .toList();

      if (feeModels.isNotEmpty) {
        ref.read(cartProvider.notifier).restoreCart(feeModels, student.stuId);
        debugPrint('Cart restored from DB: ${feeModels.length} items for student ${student.stuId}');
      }
    } catch (e) {
      debugPrint('Error restoring cart from database: $e');
    }
  }
});
