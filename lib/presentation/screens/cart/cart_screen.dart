import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/razorpay_checkout.dart' as razorpay_web;
import '../../../config/routes.dart';
import '../../../data/models/fee_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/student_provider.dart';
import '../../../core/utils/extensions.dart';
import '../../widgets/common/breadcrumb_bar.dart';
import '../../widgets/common/desktop_detail_scaffold.dart';

class CartScreen extends ConsumerStatefulWidget {
  final bool isStandalone;

  const CartScreen({super.key, this.isStandalone = false});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  Razorpay? _razorpay;
  bool _isProcessing = false;
  /// Local loading overlay — replaces showDialog so it auto-clears when widget disposes.
  bool _isPaymentLoading = false;
  String? _loadingMessage; // null = just spinner, non-null = spinner + text
  int? _currentPayId;
  int? _currentCarId;
  String? _currentOrderId;
  List<FeeModel>? _currentPaymentItems;
  /// Captured before opening Razorpay so callbacks can clean up even after widget disposal.
  SupabaseClient? _capturedClient;

  @override
  void initState() {
    super.initState();
    // razorpay_flutter only works on mobile (Android/iOS), not on web
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    final scaffold = DesktopDetailScaffold(
      isNested: true,
      header: Column(
        children: [
          const SizedBox(height: 16),
          _buildHeader(context, ref, cartState),
          const SizedBox(height: 16),
        ],
      ),
      toolbar: Row(
        children: [
          const Expanded(child: BreadcrumbBar(currentLabel: 'Payment Summary')),
          if (cartState.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => _showClearCartDialog(context, ref),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
            ),
        ],
      ),
      body: cartState.isEmpty
          ? _buildEmptyState(context)
          : _buildCartContent(context, ref, cartState),
      bottomBar: cartState.isNotEmpty
          ? _buildBottomBar(context, ref, cartState)
          : null,
    );

    // Local loading overlay — lives inside this widget so it auto-clears on dispose,
    // preventing the orphaned global-dialog spinner bug when navigating away.
    if (!_isPaymentLoading) return scaffold;

    return Stack(
      children: [
        scaffold,
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: _loadingMessage != null ? Colors.white : AppColors.primary,
                  ),
                  if (_loadingMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _loadingMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
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
        title: const Text('Clear Queue?'),
        content: const Text('Are you sure you want to remove all items from your queue?'),
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
              child: Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.textHintC(context)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your Queue is Empty',
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
              'Select fees from the pending section to add them to your queue',
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
      } else if (_isExamFee(fee)) {
        category = 'Exam Fees';
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
          if (cat == 'Exam Fees') return 102;
          if (cat == 'Bus Fees') return 103;
          return 0; // Term fees first
        }
        final orderA = getCategoryOrder(a);
        final orderB = getCategoryOrder(b);
        if (orderA != orderB) return orderA.compareTo(orderB);
        return a.compareTo(b);
      });

    return ListView(
      padding: context.isDesktop ? const EdgeInsets.all(24) : const EdgeInsets.all(16),
      children: [
        // Fee Category Cards (sequential: can only remove last term first, backward order)
        ...sortedCategories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final fees = feesByCategory[category]!;
          // Check if this category can be removed (no later categories in cart)
          // Only enforce sequential removal for term categories (order < 100)
          int getCatOrder(String cat) {
            if (cat == 'Tuition Fees') return 100;
            if (cat == 'Hostel Fees') return 101;
            if (cat == 'Exam Fees') return 102;
            if (cat == 'Bus Fees') return 103;
            return 0; // Term fees
          }
          final isTermCategory = getCatOrder(category) == 0;
          // For term categories: can only remove if no later term categories exist
          final noLaterTerms = !sortedCategories.skip(index + 1).any((c) => getCatOrder(c) == 0);
          final canRemove = !isTermCategory || noLaterTerms;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCategoryCard(context, ref, category, fees, canRemove: canRemove),
          );
        }),

        const SizedBox(height: 24), // Space for bottom bar
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

  bool _isExamFee(FeeModel fee) {
    final lowerType = fee.demfeetype.toLowerCase();
    final lowerGroup = fee.feeGroupName.toLowerCase();
    return lowerType.contains('exam') || lowerGroup.contains('exam');
  }

  Map<String, dynamic> _getCategoryStyle(String category) {
    if (category == 'Bus Fees') {
      return {
        'color': const Color(0xFFF59E0B),
        'svgPath': 'assets/school Icons/van.svg',
        'showMonth': true,
      };
    } else if (category == 'Tuition Fees') {
      return {
        'color': const Color(0xFF8B5CF6),
        'svgPath': 'assets/school Icons/school.svg',
        'showMonth': true,
      };
    } else if (category == 'Hostel Fees') {
      return {
        'color': const Color(0xFF3B82F6),
        'svgPath': 'assets/school Icons/school.svg',
        'showMonth': true,
      };
    } else if (category == 'Exam Fees') {
      return {
        'color': const Color(0xFF06B6D4),
        'svgPath': 'assets/school Icons/exam.svg',
        'showMonth': false,
      };
    } else {
      return {
        'color': AppColors.success,
        'svgPath': 'assets/school Icons/school.svg',
        'showMonth': false,
      };
    }
  }

  Widget _buildCategoryCard(BuildContext context, WidgetRef ref, String category, List<FeeModel> fees, {bool canRemove = true}) {
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final categoryStyle = _getCategoryStyle(category);
    final svgPath = categoryStyle['svgPath'] as String;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderC(context)),
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
                      SvgPicture.asset(
                        svgPath,
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
                  onTap: canRemove ? () => _showRemoveGroupDialog(context, ref, category, fees) : null,
                  child: Opacity(
                    opacity: canRemove ? 1.0 : 0.3,
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
    final bottomContent = Padding(
      padding: const EdgeInsets.all(20),
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
            onTap: () => _handleProceedToPayment(),
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
    );

    // On desktop, DesktopDetailScaffold wraps in a card — return just the inner content
    if (context.isDesktop) return bottomContent;

    // On mobile, keep existing decoration
    return Container(
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
        child: bottomContent,
      ),
    );
  }

  Future<void> _handleProceedToPayment() async {
    if (_isProcessing) return;

    final cartState = ref.read(cartProvider);
    final student = ref.read(selectedStudentProvider);
    if (cartState.isEmpty || student == null) return;

    setState(() {
      _isProcessing = true;
      _isPaymentLoading = true;  // Show local overlay (auto-clears if widget disposes)
    });

    try {
      // Step 1: Save cart to database
      debugPrint('PAYMENT STEP 1: Saving cart to database...');
      final carId = await saveCartToDatabase(
        ref: ref,
        items: cartState.items,
        studentId: student.stuId,
      );

      if (carId == null) {
        debugPrint('PAYMENT STEP 1 FAILED: carId is null. Error: $lastCartSaveError');
        if (mounted) setState(() => _isPaymentLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save cart: ${lastCartSaveError ?? "Unknown error"}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
      debugPrint('PAYMENT STEP 1 OK: carId=$carId');

      // Step 2: Initiate payment
      debugPrint('PAYMENT STEP 2: Initiating payment...');
      final payId = await initiatePayment(
        ref: ref,
        carId: carId,
        cartItems: cartState.items,
        cartTotal: cartState.totalAmount,
      );

      if (payId == null) {
        debugPrint('PAYMENT STEP 2 FAILED: payId is null. Error: $lastPaymentError');
        if (mounted) setState(() => _isPaymentLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to initiate payment: ${lastPaymentError ?? "Unknown error"}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
      debugPrint('PAYMENT STEP 2 OK: payId=$payId');

      // Step 3: Create Razorpay order via Edge Function
      final amountInPaise = (cartState.totalAmount * 100).toInt();
      debugPrint('PAYMENT STEP 3: Creating Razorpay order (amount=$amountInPaise paise)...');

      final orderId = await createRazorpayOrder(
        ref: ref,
        payId: payId,
        amountInPaise: amountInPaise,
        receipt: 'PAY-$payId',
      );

      if (orderId == null) {
        debugPrint('PAYMENT STEP 3 FAILED: orderId is null. Error: $lastOrderCreationError');
        // Roll back payment since we can't proceed without an order
        await handlePaymentFailure(ref: ref, payId: payId, carId: carId);
        if (mounted) setState(() => _isPaymentLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create payment order: ${lastOrderCreationError ?? "Unknown error"}. Please try again.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
      debugPrint('PAYMENT STEP 3 OK: orderId=$orderId');

      // Store payment info for callbacks (captured before Razorpay opens
      // so cleanup can happen even if the widget is disposed when callback fires)
      _currentPayId = payId;
      _currentCarId = carId;
      _currentOrderId = orderId;
      _currentPaymentItems = List.from(cartState.items);
      _capturedClient = ref.read(supabaseClientProvider);

      // Hide loading overlay before opening Razorpay
      if (mounted) setState(() => _isPaymentLoading = false);

      // Step 4: Open Razorpay checkout with order_id
      debugPrint('PAYMENT STEP 4: Opening Razorpay checkout (kIsWeb=$kIsWeb)...');
      final checkoutOptions = {
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
      };

      if (kIsWeb) {
        // Use JavaScript SDK directly on web
        razorpay_web.openRazorpayWebCheckout(
          options: checkoutOptions,
          onSuccess: (paymentId) {
            debugPrint('Razorpay Web Payment Success: $paymentId');
            _handleWebPaymentSuccess(paymentId);
          },
          onError: (code, description) {
            debugPrint('Razorpay Web Payment Error: $code - $description');
            _handleWebPaymentError(code, description);
          },
        );
      } else {
        // Use razorpay_flutter on mobile
        _razorpay!.open(checkoutOptions);
      }
      debugPrint('PAYMENT STEP 4: Razorpay checkout opened successfully');
    } catch (e, stackTrace) {
      debugPrint('PAYMENT ERROR: $e');
      debugPrint('PAYMENT STACK: $stackTrace');
      if (mounted) {
        setState(() => _isPaymentLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Handles web Razorpay payment success (called from JS interop callback)
  void _handleWebPaymentSuccess(String paymentId) async {
    _handlePaymentSuccessCore(paymentId);
  }

  /// Handles web Razorpay payment error (called from JS interop callback)
  void _handleWebPaymentError(int code, String description) async {
    debugPrint('Web Payment Error: $code - $description');

    final payId = _currentPayId;
    final carId = _currentCarId;
    final client = _capturedClient;

    // Clear state immediately to prevent duplicate handling
    _currentPayId = null;
    _currentCarId = null;
    _currentOrderId = null;
    _currentPaymentItems = null;
    _capturedClient = null;

    if (payId != null && carId != null) {
      if (mounted) {
        // Widget is still alive — use ref-based cleanup (refreshes providers too)
        try {
          await handlePaymentFailure(
            ref: ref,
            payId: payId,
            carId: carId,
            errorReason: description,
          );
        } catch (e) {
          debugPrint('Error in handlePaymentFailure: $e');
        }
      } else if (client != null) {
        // Widget disposed (user navigated away) — use captured client directly
        debugPrint('Widget disposed, cleaning up payment directly via captured client');
        try {
          await Future.wait([
            client.from('payment').update({
              'paystatus': 'F',
              'paymethod': 'razorpay',
              'paydate': DateTime.now().toIso8601String(),
            }).eq('pay_id', payId),
            client.from('shoppingcart').update({
              'carinitiated': 'N',
            }).eq('car_id', carId),
          ]);
          debugPrint('Direct cleanup done: pay_id=$payId marked F, car_id=$carId reset to N');
        } catch (e) {
          debugPrint('Error in direct payment cleanup: $e');
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $description'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Core payment success logic shared by mobile (razorpay_flutter) and web (JS interop)
  void _handlePaymentSuccessCore(String paymentId) async {
    debugPrint('Payment Success: $paymentId');

    final payId = _currentPayId;
    final carId = _currentCarId;
    final items = _currentPaymentItems;

    if (payId == null || carId == null || items == null) return;

    // Immediately clear to prevent duplicate callback execution
    _currentPayId = null;
    _currentCarId = null;
    _currentOrderId = null;
    _currentPaymentItems = null;

    // Show processing overlay (local widget — auto-clears if cart screen disposes)
    if (mounted) {
      setState(() {
        _isPaymentLoading = true;
        _loadingMessage = 'Processing payment...';
      });
    }

    bool success = false;
    if (mounted) {
      try {
        success = await handlePaymentSuccess(
          ref: ref,
          payId: payId,
          carId: carId,
          paymethod: 'razorpay',
          payreference: paymentId,
          items: items,
        );
      } catch (e) {
        debugPrint('Error in handlePaymentSuccess (widget may be disposed): $e');
      }
    }

    // Hide processing overlay
    if (mounted) setState(() => _isPaymentLoading = false);

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
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _handlePaymentSuccessCore(response.paymentId ?? '');
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    debugPrint('Payment Error: ${response.code} - ${response.message}');

    // Extract payment_id from Razorpay error response
    String? razorpayPaymentId = response.error?['id']?.toString();
    String? errorReason = response.error?['error_description']?.toString()
        ?? response.error?['description']?.toString();
    debugPrint('Razorpay error map: ${response.error}');

    // If SDK didn't provide payment_id, fetch it from Razorpay API via order_id
    final orderId = _currentOrderId;
    if (razorpayPaymentId == null && orderId != null) {
      debugPrint('Payment ID not in error response, fetching from Razorpay API for order: $orderId');
      razorpayPaymentId = await _fetchPaymentIdFromOrder(orderId);
    }
    debugPrint('Final paymentId: $razorpayPaymentId, errorReason: $errorReason');

    final payId = _currentPayId;
    final carId = _currentCarId;

    if (payId != null && carId != null) {
      await handlePaymentFailure(
        ref: ref,
        payId: payId,
        carId: carId,
        payReference: razorpayPaymentId,
        errorReason: errorReason,
      );
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
    _currentOrderId = null;
    _currentPaymentItems = null;
  }

  /// Fetches the Razorpay payment ID by order_id via Edge Function
  Future<String?> _fetchPaymentIdFromOrder(String orderId) async {
    try {
      final client = ref.read(supabaseClientProvider);
      final response = await client.functions.invoke(
        'get-razorpay-payment',
        body: {'order_id': orderId},
      );

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        final paymentId = data['payment_id'] as String?;
        debugPrint('Fetched payment ID from Razorpay API: $paymentId');
        return paymentId;
      }
      debugPrint('Edge function returned status ${response.status}');
      return null;
    } catch (e) {
      debugPrint('Error fetching payment ID from Razorpay: $e');
      return null;
    }
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
