import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../config/routes.dart';
import '../../../data/models/fee_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/student_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  final bool isStandalone;

  const CartScreen({super.key, this.isStandalone = false});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = false;
  int? _currentPayId;
  int? _currentCarId;
  List<FeeModel>? _currentPaymentItems;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: Column(
          children: [
            // Header with white SafeArea and subtle shadow
            Container(
              color: AppColors.headerBg(context),
              child: SafeArea(
                bottom: false,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.headerBg(context),
                    boxShadow: AppColors.cardShadow(context),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildHeader(context, ref, cartState),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
              child: cartState.isEmpty
                  ? _buildEmptyState(context)
                  : _buildCartContent(context, ref, cartState),
            ),
            // Bottom payment bar
            if (cartState.isNotEmpty)
              _buildBottomBar(context, ref, cartState),
          ],
        ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, CartState cartState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button - Dark theme
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(Routes.home);
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.iconButtonBg(context),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Title
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Payment Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryC(context),
                ),
              ),
              if (cartState.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '${cartState.items.length} item${cartState.items.length > 1 ? 's' : ''} selected',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondaryC(context),
                  ),
                ),
              ],
            ],
          ),

          // Clear All Button or Placeholder
          if (cartState.isNotEmpty)
            GestureDetector(
              onTap: () => _showClearCartDialog(context, ref),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cart?'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.filterBg(context),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/Cart.svg',
                width: 48,
                height: 48,
                colorFilter: ColorFilter.mode(
                  AppColors.textHintC(context),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your Cart is Empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryC(context),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Select fees from the pending section to add them to your cart',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryC(context),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => context.go(Routes.home),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_rounded, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Go to Home',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, WidgetRef ref, CartState cartState) {
    // Group fees by category type
    final Map<String, List<FeeModel>> feesByCategory = {};

    for (final fee in cartState.items) {
      String category;
      if (_isBusFee(fee.demfeetype)) {
        category = 'Bus Fees';
      } else if (_isTuitionFee(fee.demfeetype)) {
        category = 'Tuition Fees';
      } else if (_isHostelFee(fee.demfeetype)) {
        category = 'Hostel Fees';
      } else {
        category = '${fee.demfeeterm} (${fee.demfeeyear})';
      }
      feesByCategory.putIfAbsent(category, () => []);
      feesByCategory[category]!.add(fee);
    }

    // Sort categories: Term fees first, then Tuition, Hostel, Bus
    final sortedCategories = feesByCategory.keys.toList()
      ..sort((a, b) {
        // Define category order: regular terms first, then special categories
        int getCategoryOrder(String cat) {
          if (cat == 'Tuition Fees') return 100;
          if (cat == 'Hostel Fees') return 101;
          if (cat == 'Bus Fees') return 102;
          return 0; // Term fees first
        }
        final orderA = getCategoryOrder(a);
        final orderB = getCategoryOrder(b);
        if (orderA != orderB) return orderA.compareTo(orderB);
        return a.compareTo(b);
      });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Fee Category Cards
        ...sortedCategories.map((category) {
          final fees = feesByCategory[category]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCategoryCard(context, ref, category, fees),
          );
        }),

        SizedBox(height: 70 + MediaQuery.of(context).padding.bottom + 20), // Space for bottom bar
      ],
    );
  }

  bool _isBusFee(String feeType) {
    final lowerType = feeType.toLowerCase();
    return lowerType.contains('bus') || lowerType.contains('transport') || lowerType.contains('van');
  }

  bool _isTuitionFee(String feeType) {
    final lowerType = feeType.toLowerCase();
    return lowerType.contains('tuition');
  }

  bool _isHostelFee(String feeType) {
    final lowerType = feeType.toLowerCase();
    return lowerType.contains('hostel');
  }

  Map<String, dynamic> _getCategoryStyle(String category) {
    if (category == 'Bus Fees') {
      return {
        'color': const Color(0xFFF59E0B),
        'icon': Icons.directions_bus,
        'showMonth': true,
      };
    } else if (category == 'Tuition Fees') {
      return {
        'color': const Color(0xFF8B5CF6),
        'icon': Icons.menu_book_rounded,
        'showMonth': true,
      };
    } else if (category == 'Hostel Fees') {
      return {
        'color': const Color(0xFF3B82F6),
        'icon': Icons.hotel_rounded,
        'showMonth': true,
      };
    } else {
      return {
        'color': AppColors.success,
        'icon': Icons.school_rounded,
        'showMonth': false,
      };
    }
  }

  Widget _buildCategoryCard(BuildContext context, WidgetRef ref, String category, List<FeeModel> fees) {
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final categoryStyle = _getCategoryStyle(category);
    final isBus = category.toLowerCase().contains('bus') || category.toLowerCase().contains('transport');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Column(
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: categoryStyle['color'] as Color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isBus)
                        SvgPicture.asset(
                          'assets/school Icons/van.svg',
                          width: 14,
                          height: 14,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        )
                      else
                        SvgPicture.asset(
                          'assets/school Icons/school.svg',
                          width: 14,
                          height: 14,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Items count
                Text(
                  '${fees.length} item${fees.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryC(context),
                  ),
                ),
                const SizedBox(width: 12),
                // Remove Button
                GestureDetector(
                  onTap: () => _showRemoveGroupDialog(context, ref, category, fees),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: AppColors.borderC(context)),

          // Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Particular',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryC(context),
                    ),
                  ),
                ),
                Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
              ],
            ),
          ),

          Container(height: 1, color: AppColors.borderC(context)),

          // Fee Items
          ...fees.map((fee) => _buildFeeItem(fee, categoryStyle['showMonth'] as bool)),

          // Total Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.filterBg(context),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
                Text(
                  '₹ ${NumberFormat('#,##,###').format(totalAmount.toInt())}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveGroupDialog(BuildContext context, WidgetRef ref, String category, List<FeeModel> fees) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Group?'),
        content: Text('Remove all ${fees.length} item${fees.length > 1 ? 's' : ''} from $category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              for (final fee in fees) {
                ref.read(cartProvider.notifier).removeFee(fee.id);
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$category removed'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeItem(FeeModel fee, bool showMonth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderC(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fee.feeTypeName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimaryC(context),
                    height: 1.4,
                  ),
                ),
                if (showMonth) ...[
                  const SizedBox(height: 2),
                  Text(
                    _extractMonthFromDate(fee),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHintC(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '₹ ${NumberFormat('#,##,###').format(fee.balancedue.toInt())}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryC(context),
            ),
          ),
        ],
      ),
    );
  }

  String _extractMonthFromDate(FeeModel fee) {
    final date = fee.duedate ?? fee.createdat;
    return DateFormat('MMMM yyyy').format(date);
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, CartState cartState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryC(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹ ${NumberFormat('#,##,###').format(cartState.totalAmount.toInt())}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _handleProceedToPayment(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primary600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pay Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleProceedToPayment(BuildContext context, WidgetRef ref) async {
    if (_isProcessing) return;

    final cartState = ref.read(cartProvider);
    final student = ref.read(selectedStudentProvider);
    if (cartState.isEmpty || student == null) return;

    setState(() => _isProcessing = true);

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      // Step 1: Save cart to database
      final carId = await saveCartToDatabase(
        ref: ref,
        items: cartState.items,
        studentId: student.stuId,
      );

      if (carId == null) {
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save cart: ${lastCartSaveError ?? "Unknown error"}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      // Step 2: Initiate payment
      final payId = await initiatePayment(
        ref: ref,
        carId: carId,
        cartItems: cartState.items,
        cartTotal: cartState.totalAmount,
      );

      if (payId == null) {
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to initiate payment: ${lastPaymentError ?? "Unknown error"}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      // Step 3: Create Razorpay order via Edge Function
      final amountInPaise = (cartState.totalAmount * 100).toInt();

      final orderId = await createRazorpayOrder(
        ref: ref,
        payId: payId,
        amountInPaise: amountInPaise,
        receipt: 'PAY-$payId',
      );

      if (orderId == null) {
        // Roll back payment since we can't proceed without an order
        await handlePaymentFailure(ref: ref, payId: payId, carId: carId);
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create payment order: ${lastOrderCreationError ?? "Unknown error"}. Please try again.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      // Store payment info for callbacks
      _currentPayId = payId;
      _currentCarId = carId;
      _currentPaymentItems = List.from(cartState.items);

      // Dismiss loading
      if (context.mounted) Navigator.pop(context);

      // Step 4: Open Razorpay checkout with order_id
      _razorpay.open({
        'key': 'rzp_test_RQsgJgVFwM7kov',
        'amount': amountInPaise,
        'currency': 'INR',
        'name': 'TBS School',
        'description': 'School Fees Payment',
        'order_id': orderId,
        'prefill': {
          'name': student.stuname,
          'contact': student.stumobile,
          'email': student.stuemail ?? '',
        },
        'theme': {
          'color': '#1A73E8',
        },
        'notes': {
          'pay_id': payId.toString(),
          'car_id': carId.toString(),
          'student_id': student.stuId.toString(),
        },
      });
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('Payment Success: ${response.paymentId}');

    final payId = _currentPayId;
    final carId = _currentCarId;
    final items = _currentPaymentItems;

    if (payId == null || carId == null || items == null) return;

    // Show processing dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Processing payment...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final success = await handlePaymentSuccess(
      ref: ref,
      payId: payId,
      carId: carId,
      paymethod: 'razorpay',
      payreference: response.paymentId ?? '',
      items: items,
    );

    // Dismiss processing dialog
    if (mounted) Navigator.pop(context);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go(Routes.paymentHistory);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment received but processing failed. Please contact support.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    _currentPayId = null;
    _currentCarId = null;
    _currentPaymentItems = null;
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    debugPrint('Payment Error: ${response.code} - ${response.message}');

    final payId = _currentPayId;
    final carId = _currentCarId;

    if (payId != null && carId != null) {
      await handlePaymentFailure(ref: ref, payId: payId, carId: carId);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message ?? "Cancelled by user"}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    _currentPayId = null;
    _currentCarId = null;
    _currentPaymentItems = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Redirecting to ${response.walletName}...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
