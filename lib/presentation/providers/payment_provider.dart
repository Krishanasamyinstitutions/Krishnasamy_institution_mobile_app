import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/fee_model.dart';
import '../../data/models/payment_model.dart';
import 'student_provider.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';
import 'fee_provider.dart';
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

    // 0. Clean up any stale 'I' (initiated but never completed) payments for this student
    final stalePays = await client
        .from('payment')
        .select('pay_id')
        .eq('stu_id', student.stuId)
        .eq('paystatus', 'I');

    if ((stalePays as List).isNotEmpty) {
      final stalePayIds = stalePays.map((p) => p['pay_id'] as int).toList();
      await client.from('paymentdetails').delete().inFilter('pay_id', stalePayIds);
      await client.from('payment').delete().inFilter('pay_id', stalePayIds);
      debugPrint('Cleaned up ${stalePayIds.length} stale initiated payment(s)');
    }

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

    // 2. Check if these fees are already being paid on another device
    try {
      final lockedFees = await client.rpc('check_fees_locked', params: {
        'p_dem_ids': items.map((f) => f.demId).toList(),
      });
      if ((lockedFees as List).isNotEmpty) {
        lastPaymentError = 'These fees are already being processed on another device. Please wait.';
        return null;
      }
    } catch (e) {
      // RPC not deployed yet - skip check (non-critical safety feature)
      debugPrint('check_fees_locked RPC not available: $e');
    }

    // 3. Generate payment number atomically (prevents duplicate paynumber on concurrent devices)
    String payNumber;
    try {
      final rpcResult = await client.rpc('generate_payment_number');
      payNumber = rpcResult as String;
    } catch (e) {
      // Fallback: non-atomic sequence generation (if RPC not deployed yet)
      debugPrint('generate_payment_number RPC not available, using fallback: $e');
      final sequence = await client
          .from('sequence')
          .select('seq_id, sequid, seqwidth, seqcurno')
          .limit(1)
          .single();

      final sequid = sequence['sequid'] as String;
      final seqWidth = sequence['seqwidth'] as int;
      final seqCurNo = (sequence['seqcurno'] as num).toInt();
      final newSeqNo = seqCurNo + 1;
      final prefix = sequid.replaceAll(RegExp(r'\d+$'), '');
      payNumber = '$prefix${newSeqNo.toString().padLeft(seqWidth, '0')}';

      await client.from('sequence').update({
        'seqcurno': newSeqNo,
      }).eq('seq_id', sequence['seq_id'] as int);
    }

    // 4. Create payment record with paynumber (paystatus = 'I' for Initiated)
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

    // 5. Insert paymentdetails + update shoppingcart in parallel
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

/// Step 3: Create Razorpay order via Supabase Edge Function.
/// Returns the order_id string on success, null on failure.
String? lastOrderCreationError;

Future<String?> createRazorpayOrder({
  required WidgetRef ref,
  required int payId,
  required int amountInPaise,
  required String receipt,
  String currency = 'INR',
}) async {
  lastOrderCreationError = null;
  final client = ref.read(supabaseClientProvider);

  try {
    final response = await client.functions.invoke(
      'create-razorpay-order',
      body: {
        'amount': amountInPaise,
        'currency': currency,
        'pay_id': payId,
        'receipt': receipt,
      },
    );

    if (response.status != 200) {
      lastOrderCreationError =
          'Edge function returned status ${response.status}';
      debugPrint('Razorpay order creation failed: ${response.data}');
      return null;
    }

    final data = response.data as Map<String, dynamic>;
    final orderId = data['order_id'] as String?;

    if (orderId == null || orderId.isEmpty) {
      lastOrderCreationError = 'No order_id in response';
      debugPrint('Razorpay order response missing order_id: $data');
      return null;
    }

    debugPrint('Razorpay order created: $orderId for pay_id=$payId');
    return orderId;
  } catch (e, stackTrace) {
    lastOrderCreationError = e.toString();
    debugPrint('Error creating Razorpay order: $e');
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
        .select('dem_id, paidamount, feeamount, conamount, balancedue')
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
      final currentBalance = (demand['balancedue'] as num?)?.toDouble() ?? 0;
      final newPaid = currentPaid + paidAmount;
      final newBalance = currentBalance - paidAmount;

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

    // 4. Clear in-memory cart & refresh all related providers
    ref.read(cartProvider.notifier).clearCart();
    ref.invalidate(feesProvider);
    ref.invalidate(paymentsProvider);
    ref.invalidate(paidFeesByPaymentProvider);
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

/// Handle payment failure — marks payment as 'F' (failed) and resets the cart
Future<bool> handlePaymentFailure({
  required WidgetRef ref,
  required int payId,
  required int carId,
  String? payReference,
  String? errorReason,
}) async {
  final client = ref.read(supabaseClientProvider);

  try {
    // Build update map - always set paymethod since payment was attempted via Razorpay
    final paymentUpdate = <String, dynamic>{
      'paystatus': 'F',
      'paymethod': 'razorpay',
      'paydate': DateTime.now().toIso8601String(),
    };
    if (payReference != null) {
      paymentUpdate['payreference'] = payReference;
    }

    // Mark payment as failed and reset cart in parallel
    await Future.wait([
      client.from('payment').update(paymentUpdate).eq('pay_id', payId),
      client.from('shoppingcart').update({
        'carinitiated': 'N',
      }).eq('car_id', carId),
    ]);

    ref.invalidate(paymentsProvider);
    ref.invalidate(notificationsProvider);

    debugPrint('Payment failed: pay_id=$payId marked as F, cart car_id=$carId reset');
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

  // First, recover any abandoned 'I' (initiated) carts from failed/interrupted payments
  try {
    final abandonedCarts = await client
        .from('shoppingcart')
        .select('car_id')
        .eq('stu_id', student.stuId)
        .eq('carinitiated', 'I')
        .eq('activestatus', 1);

    if ((abandonedCarts as List).isNotEmpty) {
      final abandonedCarIds = abandonedCarts.map((c) => c['car_id'] as int).toList();
      // Reset abandoned carts back to 'N' so RPC/fallback can find them
      await client.from('shoppingcart').update({
        'carinitiated': 'N',
      }).inFilter('car_id', abandonedCarIds);

      // Delete orphaned 'I' payments (never completed, no need to show in history)
      final stalePays = await client
          .from('payment')
          .select('pay_id')
          .eq('stu_id', student.stuId)
          .eq('paystatus', 'I');

      if ((stalePays as List).isNotEmpty) {
        final stalePayIds = stalePays.map((p) => p['pay_id'] as int).toList();
        await client.from('paymentdetails').delete().inFilter('pay_id', stalePayIds);
        await client.from('payment').delete().inFilter('pay_id', stalePayIds);
        debugPrint('Deleted ${stalePayIds.length} orphaned initiated payment(s)');
      }

      debugPrint('Reset ${abandonedCarIds.length} abandoned cart(s) from I to N');
    }

  } catch (e) {
    debugPrint('Error resetting abandoned carts: $e');
  }

  try {
    // Try single-query RPC first (requires running db_sync/setup_cart_rpc.sql)
    final fees = await client.rpc('get_active_cart_fees', params: {
      'p_stu_id': student.stuId,
    });

    final allFees = (fees as List)
        .map((f) => FeeModel.fromJson(f as Map<String, dynamic>))
        .toList();

    // Filter out already-paid fees (balancedue <= 0 or paidstatus = 'P')
    final unpaidFees = allFees.where((f) => f.balancedue > 0 && f.paidstatus != 'P').toList();
    final paidFees = allFees.where((f) => f.balancedue <= 0 || f.paidstatus == 'P').toList();

    // Clean up paid fee rows from DB
    if (unpaidFees.isEmpty && allFees.isNotEmpty) {
      await _cleanupPaidCart(client, student.stuId);
      debugPrint('All cart fees already paid — cart cleaned up');
    } else if (paidFees.isNotEmpty) {
      await _cleanupPaidCartItems(client, student.stuId, paidFees, unpaidFees);
    }

    ref.read(cartProvider.notifier).restoreCart(unpaidFees, student.stuId);
    if (unpaidFees.isNotEmpty) {
      debugPrint('Cart restored via RPC: ${unpaidFees.length} unpaid items for student ${student.stuId}');
    }
  } catch (rpcError) {
    // Fallback: 3 sequential queries (RPC not deployed yet)
    debugPrint('RPC fallback: $rpcError');
    try {
      // Abandoned 'I' carts were already reset to 'N' above, so just look for 'N'
      final cart = await client
          .from('shoppingcart')
          .select('car_id')
          .eq('stu_id', student.stuId)
          .eq('carinitiated', 'N')
          .eq('activestatus', 1)
          .maybeSingle();

      if (cart == null) {
        ref.read(cartProvider.notifier).restoreCart([], student.stuId);
        return;
      }

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

      if (demIds.isEmpty) {
        ref.read(cartProvider.notifier).restoreCart([], student.stuId);
        return;
      }

      // Fetch full feedemand records for these dem_ids
      final fees = await client
          .from('feedemand')
          .select('*')
          .inFilter('dem_id', demIds)
          .eq('activestatus', 1);

      final allFees = (fees as List)
          .map((f) => FeeModel.fromJson(f))
          .toList();

      // Filter out already-paid fees
      final unpaidFees = allFees.where((f) => f.balancedue > 0 && f.paidstatus != 'P').toList();
      final paidFees = allFees.where((f) => f.balancedue <= 0 || f.paidstatus == 'P').toList();

      // Clean up paid fee rows from DB
      if (unpaidFees.isEmpty && allFees.isNotEmpty) {
        await _cleanupPaidCart(client, student.stuId);
        debugPrint('All cart fees already paid — cart cleaned up (fallback)');
      } else if (paidFees.isNotEmpty) {
        await _cleanupPaidCartItems(client, student.stuId, paidFees, unpaidFees);
      }

      ref.read(cartProvider.notifier).restoreCart(unpaidFees, student.stuId);
      if (unpaidFees.isNotEmpty) {
        debugPrint('Cart restored from DB: ${unpaidFees.length} unpaid items for student ${student.stuId}');
      }
    } catch (e) {
      debugPrint('Error restoring cart from database: $e');
      ref.read(cartProvider.notifier).restoreCart([], student.stuId);
    }
  }
});

/// A completed payment with its fee details
class PaidPaymentGroup {
  final PaymentModel payment;
  final List<FeeModel> fees;

  PaidPaymentGroup({required this.payment, required this.fees});
}

/// Paid fee groups sourced from payment + paymentdetails + feedemand tables.
/// More reliable than filtering feedemand by paidstatus (which can be stale).
final paidFeesByPaymentProvider = FutureProvider<Map<int, PaidPaymentGroup>>((ref) async {
  final student = ref.watch(selectedStudentProvider);
  final client = ref.watch(supabaseClientProvider);

  if (student == null) return {};

  try {
    // 1. Get all completed payments
    final payments = await client
        .from('payment')
        .select('*')
        .eq('stu_id', student.stuId)
        .eq('paystatus', 'C')
        .eq('activestatus', 1)
        .order('createdat', ascending: false);

    if ((payments as List).isEmpty) return {};

    final paymentModels = payments.map((p) => PaymentModel.fromJson(p)).toList();
    final payIds = paymentModels.map((p) => p.payId).toList();

    // 2. Get all payment details for these payments
    final details = await client
        .from('paymentdetails')
        .select('*')
        .inFilter('pay_id', payIds)
        .eq('activestatus', 1);

    final detailModels = (details as List)
        .map((d) => PaymentDetailModel.fromJson(d))
        .toList();

    // Group details by pay_id
    final detailsByPayId = <int, List<PaymentDetailModel>>{};
    for (final detail in detailModels) {
      detailsByPayId.putIfAbsent(detail.payId, () => []).add(detail);
    }

    // 3. Get all feedemand records for the dem_ids (for fee names/terms)
    final allDemIds = detailModels.map((d) => d.demId).toSet().toList();
    if (allDemIds.isEmpty) {
      final result = <int, PaidPaymentGroup>{};
      for (final payment in paymentModels) {
        result[payment.payId] = PaidPaymentGroup(payment: payment, fees: []);
      }
      return result;
    }

    List<FeeModel> feeModels;
    try {
      final fees = await client
          .from('feedemand')
          .select('*, feetype(*, feegroup(*))')
          .inFilter('dem_id', allDemIds);
      feeModels = (fees as List).map((f) => FeeModel.fromJson(f)).toList();
    } catch (e) {
      final fees = await client
          .from('feedemand')
          .select('*')
          .inFilter('dem_id', allDemIds);
      feeModels = (fees as List).map((f) => FeeModel.fromJson(f)).toList();
    }

    // Map dem_id -> FeeModel
    final feeMap = <int, FeeModel>{};
    for (final fee in feeModels) {
      feeMap[fee.demId] = fee;
    }

    // 4. Build result: each payment with its fee details
    final result = <int, PaidPaymentGroup>{};
    for (final payment in paymentModels) {
      final payDetails = detailsByPayId[payment.payId] ?? [];
      final fees = payDetails
          .where((d) => feeMap.containsKey(d.demId))
          .map((d) {
            final fee = feeMap[d.demId]!;
            // Use the amount from paymentdetails (actual paid amount for this payment)
            return fee.copyWith(paidamount: d.transtotalamount);
          })
          .toList();

      result[payment.payId] = PaidPaymentGroup(payment: payment, fees: fees);
    }

    return result;
  } catch (e) {
    debugPrint('Error fetching paid fee groups: $e');
    return {};
  }
});

/// Helper: Remove individual paid fee rows from shoppingcartdetails (partial payment scenario)
/// Updates the cart total to reflect only unpaid fees remaining.
Future<void> _cleanupPaidCartItems(dynamic client, int stuId, List<FeeModel> paidFees, List<FeeModel> unpaidFees) async {
  try {
    final carts = await client
        .from('shoppingcart')
        .select('car_id')
        .eq('stu_id', stuId)
        .eq('activestatus', 1);

    if ((carts as List).isEmpty) return;

    final carIds = carts.map((c) => c['car_id'] as int).toList();
    final paidDemIds = paidFees.map((f) => f.demId).toList();

    // Delete paid fee rows from shoppingcartdetails
    await client
        .from('shoppingcartdetails')
        .delete()
        .inFilter('car_id', carIds)
        .inFilter('dem_id', paidDemIds);

    // Update cart header total to reflect only unpaid fees
    final newTotal = unpaidFees.fold<double>(0, (sum, f) => sum + f.balancedue);
    await client
        .from('shoppingcart')
        .update({'transtotalamount': newTotal})
        .inFilter('car_id', carIds);

    debugPrint('Removed ${paidFees.length} paid fee(s) from cart details, updated total to $newTotal');
  } catch (e) {
    debugPrint('Error cleaning up paid cart items: $e');
  }
}

/// Helper: Delete stale shopping cart for a student whose fees are all paid
Future<void> _cleanupPaidCart(dynamic client, int stuId) async {
  try {
    final carts = await client
        .from('shoppingcart')
        .select('car_id')
        .eq('stu_id', stuId)
        .eq('activestatus', 1);

    if ((carts as List).isNotEmpty) {
      final carIds = carts.map((c) => c['car_id'] as int).toList();
      await client.from('shoppingcartdetails').delete().inFilter('car_id', carIds);
      await client.from('shoppingcart').delete().inFilter('car_id', carIds);
      debugPrint('Deleted ${carIds.length} stale cart(s) for student $stuId (all fees paid)');
    }
  } catch (e) {
    debugPrint('Error cleaning up paid cart: $e');
  }
}
