import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/fee_model.dart';

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

/// Cart state notifier for managing fee selections
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

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
  }

  /// Add multiple fees to cart
  void addFees(List<FeeModel> fees) {
    for (final fee in fees) {
      addFee(fee);
    }
  }

  /// Remove single fee from cart
  void removeFee(String feeId) {
    state = state.copyWith(
      items: state.items.where((f) => f.id != feeId).toList(),
    );
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
  void restoreCart(List<FeeModel> items, int studentId) {
    if (items.isEmpty) return;
    state = CartState(items: items, studentId: studentId);
  }

  /// Clear all items from cart
  void clearCart() {
    state = const CartState();
  }

  /// Check if fee is in cart
  bool isInCart(String feeId) => state.containsFee(feeId);
}

/// Cart provider - session-only (in-memory)
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
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
