import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/payment_model.dart';
import '../../providers/payment_provider.dart';
import '../../providers/student_provider.dart';

class TransactionDetailsScreen extends ConsumerWidget {
  final String paymentId;

  const TransactionDetailsScreen({super.key, required this.paymentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentAsync = ref.watch(paymentByIdProvider(int.tryParse(paymentId) ?? 0));
    final selectedStudent = ref.watch(selectedStudentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: paymentAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (payment) {
            // Use mock data if payment is null (for preview)
            final displayPayment = payment ?? PaymentModel(
              payId: 9826,
              insId: 1,
              inscode: 'INS001',
              paydate: DateTime(2025, 7, 10, 18, 0),
              paystatus: 'C',
              paymethod: 'VISA**** 9918',
              createdat: DateTime(2025, 7, 10, 18, 0),
            );
            const mockAmount = 15000.0;
            const mockFeeName = 'Tuition Fee - Term 1';

            final isPaid = displayPayment.status == PaymentStatus.success;

            return Column(
              children: [
                const SizedBox(height: 8),
                // Header
                _buildHeader(context),
                const SizedBox(height: 12),
                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Transaction Card
                        _buildTransactionCard(
                          context,
                          displayPayment,
                          selectedStudent?.name ?? 'Robert',
                          selectedStudent?.className ?? '10-B',
                          mockAmount,
                          mockFeeName,
                          isPaid,
                        ),
                        const SizedBox(height: 24),
                        // Action Buttons
                        _buildActionButtons(context, isPaid),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF1F2933),
                ),
              ),
            ),
          ),

          // Title
          const Text(
            'Transaction Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2933),
            ),
          ),

          // Notification Button
          GestureDetector(
            onTap: () => context.go(Routes.notifications),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/notification.svg',
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF1F2933),
                      BlendMode.srcIn,
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
            // White Details Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  // Amount Section
                  const Text(
                    'Amount Paid',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
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
                    color: const Color(0xFFC6DDFF),
                  ),
                  const SizedBox(height: 16),
                  // Transaction Details
                  _buildDetailRow('Transaction ID', '#TRA-${payment.id}'),
                  const SizedBox(height: 16),
                  _buildDetailRowWithDot(
                    'Date & Time',
                    _formatDate(payment.paidAt ?? payment.createdAt),
                    _formatTime(payment.paidAt ?? payment.createdAt),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Payment Method', payment.paymentMethod),
                  const SizedBox(height: 16),
                  _buildDetailRow('Fee Type', feeName),
                  const SizedBox(height: 16),
                  _buildDetailRow('Student', studentName),
                  const SizedBox(height: 16),
                  _buildDetailRow('Class', className),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF6B7280),
            height: 1.43,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFF1F2933),
            height: 1.47,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRowWithDot(String label, String date, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF6B7280),
            height: 1.43,
          ),
        ),
        Row(
          children: [
            Text(
              '$date ',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1F2933),
                height: 1.47,
              ),
            ),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF1F2933),
                shape: BoxShape.circle,
              ),
            ),
            Text(
              ' $time',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1F2933),
                height: 1.47,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isPaid) {
    return Row(
      children: [
        // Primary Button (Download for success, Retry for failed)
        Expanded(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isPaid ? 'Download - Coming Soon' : 'Retry - Coming Soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
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
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share - Coming Soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6B7280), width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.share,
                    size: 24,
                    color: Color(0xFF6B7280),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Share',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
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
