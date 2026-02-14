import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/fee_model.dart';
import 'auth_provider.dart';
import 'student_provider.dart';

/// Cart state model containing selected fees for payment
class CartState {
  final List<FeeModel> items;
  final int studentId;

  const CartState({
    this.items = const [],
    this.studentId = 0,
  });

  CartState copyWith({
    List<FeeModel>? items,
    int? studentId,
  }) {
    return CartState(
      items: items ?? this.items,
      studentId: studentId ?? this.studentId,
    );
  }

  // Computed properties
  int get itemCount => items.length;
  double get totalAmount => items.fold(0.0, (sum, fee) => sum + fee.balanceAmount);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  bool containsFee(String feeId) => items.any((f) => f.id == feeId);
  Set<String> get feeIds => items.map((f) => f.id).toSet();
}

/// Cart state notifier for managing fee selections with real-time Supabase sync
class CartNotifier extends StateNotifier<CartState> {
  final Ref _ref;
  Timer? _syncTimer;
  bool _skipSync = false;

  CartNotifier(this._ref) : super(const CartState());

  /// Add single fee to cart
  void addFee(FeeModel fee) {
    if (state.containsFee(fee.id)) return;

    // Clear cart if switching students
    if (state.isNotEmpty && state.studentId != fee.stuId) {
      state = CartState(items: [fee], studentId: fee.stuId);
    } else {
      state = state.copyWith(
        items: [...state.items, fee],
        studentId: fee.stuId,
      );
    }
    _scheduleSyncToDatabase();
  }

  /// Add multiple fees to cart
  void addFees(List<FeeModel> fees) {
    _skipSync = true;
    for (int i = 0; i < fees.length - 1; i++) {
      addFee(fees[i]);
    }
    _skipSync = false;
    if (fees.isNotEmpty) {
      addFee(fees.last);
    }
  }

  /// Remove single fee from cart
  void removeFee(String feeId) {
    state = state.copyWith(
      items: state.items.where((f) => f.id != feeId).toList(),
    );
    _scheduleSyncToDatabase();
  }

  /// Toggle fee in cart (add if not present, remove if present)
  void toggleFee(FeeModel fee) {
    if (state.containsFee(fee.id)) {
      removeFee(fee.id);
    } else {
      addFee(fee);
    }
  }

  /// Restore cart from database (on app restart or student switch)
  /// Also handles clearing when items is empty (no DB sync triggered)
  void restoreCart(List<FeeModel> items, int studentId) {
    _syncTimer?.cancel();
    _skipSync = true;
    state = items.isEmpty
        ? const CartState()
        : CartState(items: items, studentId: studentId);
    _skipSync = false;
  }

  /// Clear all items from cart and delete from database (user explicitly clears)
  void clearCart() {
    _syncTimer?.cancel();
    state = const CartState();
    _syncToDatabase();
  }

  /// Clear in-memory cart only (used for student switch, does NOT delete from DB)
  void clearCartLocal() {
    _syncTimer?.cancel();
    state = const CartState();
  }

  /// Check if fee is in cart
  bool isInCart(String feeId) => state.containsFee(feeId);

  /// Schedule a debounced sync to Supabase (500ms delay)
  void _scheduleSyncToDatabase() {
    if (_skipSync) return;
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(milliseconds: 500), () {
      _syncToDatabase();
    });
  }

  /// Sync current cart state to Supabase shoppingcart + shoppingcartdetails
  Future<void> _syncToDatabase() async {
    final student = _ref.read(selectedStudentProvider);
    if (student == null) return;

    final client = _ref.read(supabaseClientProvider);
    final parent = _ref.read(currentParentProvider);

    try {
      // Find existing active (non-initiated) cart for this student
      final existingCart = await client
          .from('shoppingcart')
          .select('car_id')
          .eq('stu_id', student.stuId)
          .eq('carinitiated', 'N')
          .eq('activestatus', 1)
          .maybeSingle();

      // If cart is empty, delete existing cart from database
      if (state.isEmpty) {
        if (existingCart != null) {
          final carId = existingCart['car_id'] as int;
          await client.from('shoppingcartdetails').delete().eq('car_id', carId);
          await client.from('shoppingcart').delete().eq('car_id', carId);
          debugPrint('Cart deleted from DB: car_id=$carId');
        }
        return;
      }

      final items = state.items;
      final firstFee = items.first;
      final totalAmount = items.fold<double>(0, (sum, f) => sum + f.balancedue);

      int carId;

      if (existingCart != null) {
        carId = existingCart['car_id'] as int;

        // Update cart header
        await client.from('shoppingcart').update({
          'yr_id': firstFee.yrId,
          'yrlabel': firstFee.demfeeyear,
          'transdate': DateTime.now().toIso8601String().split('T')[0],
          'transtotalamount': totalAmount,
          'createdby': parent?.payincharge ?? student.stuname,
        }).eq('car_id', carId);

        // Delete old cart details
        await client.from('shoppingcartdetails').delete().eq('car_id', carId);
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

      // Insert new detail rows
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

      debugPrint('Cart synced to DB: car_id=$carId, ${items.length} items, total=$totalAmount');
    } catch (e) {
      debugPrint('Cart sync error: $e');
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

/// Cart provider with real-time Supabase sync
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});

/// Convenience provider for cart item count
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).itemCount;
});

/// Convenience provider for cart total amount
final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).totalAmount;
});

/// Convenience provider for checking if cart is empty
final cartIsEmptyProvider = Provider<bool>((ref) {
  return ref.watch(cartProvider).isEmpty;
});
