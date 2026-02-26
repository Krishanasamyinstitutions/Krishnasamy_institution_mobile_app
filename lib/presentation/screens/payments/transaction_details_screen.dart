import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/receipt_pdf_generator.dart';
import '../../../data/models/fee_model.dart';
import '../../../data/models/payment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/student_provider.dart';
import '../../../core/utils/extensions.dart';
import '../../widgets/common/breadcrumb_bar.dart';
import '../../widgets/common/desktop_detail_scaffold.dart';

class TransactionDetailsScreen extends ConsumerWidget {
  final String paymentId;
  final bool isNested;

  const TransactionDetailsScreen({super.key, required this.paymentId, this.isNested = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentAsync = ref.watch(paymentByIdProvider(int.tryParse(paymentId) ?? 0));
    final selectedStudent = ref.watch(selectedStudentProvider);

    return DesktopDetailScaffold(
      isNested: isNested,
      header: Column(
        children: [
          const SizedBox(height: 8),
          _buildHeader(context, ref),
          const SizedBox(height: 12),
        ],
      ),
      toolbar: BreadcrumbBar(
        parentLabel: 'Payment History',
        parentRoute: Routes.paymentHistory,
        currentLabel: 'Transaction Details',
      ),
      body: paymentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (payment) {
          if (payment == null) {
            return const Center(child: Text('Payment not found'));
          }

          final isPaid = payment.status == PaymentStatus.success;

          return SingleChildScrollView(
            padding: context.isDesktop ? const EdgeInsets.all(24) : const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Transaction Card
                _buildTransactionCard(
                  context,
                  payment,
                  selectedStudent?.name ?? '',
                  selectedStudent?.className ?? '',
                  selectedStudent?.admissionNumber ?? '',
                  payment.transtotalamount,
                  payment.yrlabel ?? 'Fee Payment',
                  isPaid,
                ),
                const SizedBox(height: 24),
                // Action Buttons
                _buildActionButtons(context, ref, payment, isPaid),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final notificationCount = ref.watch(notificationCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(Routes.paymentHistory);
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
          Text(
            'Transaction Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryC(context),
            ),
          ),

          // Notification Icon - Dark theme with badge
          GestureDetector(
            onTap: () => context.go(Routes.notifications),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.iconButtonBg(context),
                shape: BoxShape.circle,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/notification.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  if (notificationCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.iconButtonBg(context), width: 2),
                        ),
                        child: Text(
                          notificationCount > 9 ? '9+' : '$notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
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

  Widget _buildTransactionCard(
    BuildContext context,
    PaymentModel payment,
    String studentName,
    String className,
    String admissionNumber,
    double amount,
    String feeName,
    bool isPaid,
  ) {
    final headerColor = isPaid ? const Color(0xFF2DBE60) : const Color(0xFFDC2626);
    final amountColor = isPaid ? const Color(0xFF2DBE60) : const Color(0xFFDC2626);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Header (Green for success, Red for failed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: headerColor,
              child: Column(
                children: [
                  // Icon (Checkmark for success, X for failed)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF1F6FD), width: 1),
                    ),
                    child: Center(
                      child: isPaid
                          ? CustomPaint(
                              size: const Size(36, 36),
                              painter: _CheckmarkPainter(),
                            )
                          : CustomPaint(
                              size: const Size(36, 36),
                              painter: _CrossPainter(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Payment Status Text
                  Text(
                    isPaid ? 'Payment  Successful' : 'Payment  Failed',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.27,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Transaction Status Text
                  Text(
                    isPaid ? 'Transaction Completed' : 'Transaction In-completed',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            // Details Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.cardBg(context),
              child: Column(
                children: [
                  // Amount Section
                  Text(
                    isPaid ? 'Amount Paid' : 'Amount',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondaryC(context),
                      height: 1.47,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '₹ ${_formatAmount(amount)}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: amountColor,
                      height: 1.38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Divider
                  Container(
                    height: 1,
                    color: AppColors.borderC(context),
                  ),
                  const SizedBox(height: 16),
                  // Transaction Details
                  _buildDetailRow(context, 'Receipt No', payment.paymentNumber),
                  const SizedBox(height: 16),
                  _buildDetailRow(context, 'Student', studentName),
                  const SizedBox(height: 16),
                  _buildDetailRow(context, 'Class', className),
                  const SizedBox(height: 16),
                  _buildDetailRow(context, 'Admission No', admissionNumber),
                  if (payment.payreference != null) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(context, 'Transaction ID', payment.payreference!),
                  ],
                  const SizedBox(height: 16),
                  _buildDetailRow(context, 'Payment Method', payment.paymentMethod),
                  const SizedBox(height: 16),
                  _buildDetailRowWithDot(
                    context,
                    'Date & Time',
                    _formatDate(payment.paidAt ?? payment.createdAt),
                    _formatTime(payment.paidAt ?? payment.createdAt),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryC(context),
            height: 1.43,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimaryC(context),
            height: 1.47,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRowWithDot(BuildContext context, String label, String date, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryC(context),
            height: 1.43,
          ),
        ),
        Row(
          children: [
            Text(
              '$date ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimaryC(context),
                height: 1.47,
              ),
            ),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textPrimaryC(context),
                shape: BoxShape.circle,
              ),
            ),
            Text(
              ' $time',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimaryC(context),
                height: 1.47,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, PaymentModel payment, bool isPaid) {
    return Row(
      children: [
        // Primary Button (Download for success, Retry for failed)
        Expanded(
          child: GestureDetector(
            onTap: () async {
              if (isPaid) {
                await _handleDownloadOrShare(context, ref, payment, isShare: false);
              } else {
                await _handleRetryPayment(context, ref, payment);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF007DFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPaid ? Icons.download_rounded : Icons.refresh,
                    size: 24,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isPaid ? 'Download' : 'Retry',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Share Button
        Expanded(
          child: GestureDetector(
            onTap: () async {
              await _handleDownloadOrShare(context, ref, payment, isShare: true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textSecondaryC(context), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.share,
                    size: 24,
                    color: AppColors.textSecondaryC(context),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Share',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryC(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleDownloadOrShare(BuildContext context, WidgetRef ref, PaymentModel payment, {required bool isShare}) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating receipt...'),
            ],
          ),
        ),
      ),
    );

    try {
      final student = ref.read(selectedStudentProvider);
      final institutionAsync = ref.read(selectedStudentWithInstitutionProvider);
      final institution = institutionAsync.valueOrNull;

      if (student == null) {
        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
        return;
      }

      final pdf = await generateReceiptPdf(
        payment: payment,
        student: student,
        institution: institution,
      );

      final bytes = await pdf.save();

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

      if (isShare) {
        // Save PDF to temp file and share via share_plus
        final safeFilename = payment.paymentNumber.replaceAll('/', '_');
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$safeFilename.pdf');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Payment Receipt - ${payment.paymentNumber}',
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: '${payment.paymentNumber}.pdf',
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleRetryPayment(BuildContext context, WidgetRef ref, PaymentModel payment) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final client = ref.read(supabaseClientProvider);

      // 1. Get dem_ids from paymentdetails for this payment
      final payDetails = await client
          .from('paymentdetails')
          .select('dem_id')
          .eq('pay_id', payment.payId);

      final demIds = (payDetails as List)
          .map((d) => d['dem_id'] is int ? d['dem_id'] as int : int.parse(d['dem_id'].toString()))
          .toList();

      if (demIds.isEmpty) {
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No fee details found for this payment'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // 2. Fetch fresh feedemand records to check current status
      final fees = await client
          .from('feedemand')
          .select('*')
          .inFilter('dem_id', demIds)
          .eq('activestatus', 1);

      final feeModels = (fees as List)
          .map((f) => FeeModel.fromJson(f))
          .toList();

      // 3. Filter to only unpaid fees (balancedue > 0 and paidstatus != 'P')
      final unpaidFees = feeModels
          .where((f) => f.balancedue > 0 && f.paidstatus != 'P')
          .toList();

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

      if (unpaidFees.isEmpty) {
        // All fees already paid
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.check_circle, color: Color(0xFF2DBE60), size: 48),
            title: const Text('Already Paid'),
            content: const Text('All fees from this payment have already been paid.'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // Add unpaid fees to cart and navigate
        final cartNotifier = ref.read(cartProvider.notifier);
        cartNotifier.clearCart();
        cartNotifier.addFees(unpaidFees);

        if (context.mounted) {
          context.go(Routes.cart);
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatAmount(double amount) {
    if (amount == 0) return '0';
    final parts = amount.toStringAsFixed(0).split('');
    final result = <String>[];
    for (int i = 0; i < parts.length; i++) {
      if (i > 0) {
        final posFromEnd = parts.length - i;
        if (posFromEnd == 3 || (posFromEnd > 3 && (posFromEnd - 3) % 2 == 0)) {
          result.add(',');
        }
      }
      result.add(parts[i]);
    }
    return result.join('');
  }

  String _formatDate(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'pm' : 'am';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

/// Custom painter for checkmark icon (success)
class _CheckmarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();

    // Draw checkmark shape
    path.moveTo(size.width * 0.15, size.height * 0.5);
    path.lineTo(size.width * 0.4, size.height * 0.75);
    path.lineTo(size.width * 0.85, size.height * 0.25);
    path.lineTo(size.width * 0.75, size.height * 0.15);
    path.lineTo(size.width * 0.4, size.height * 0.55);
    path.lineTo(size.width * 0.25, size.height * 0.4);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for X icon (failed)
class _CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Draw X shape
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.25),
      Offset(size.width * 0.75, size.height * 0.75),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.75, size.height * 0.25),
      Offset(size.width * 0.25, size.height * 0.75),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
