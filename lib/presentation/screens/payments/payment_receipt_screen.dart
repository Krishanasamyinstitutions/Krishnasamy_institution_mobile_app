import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/payment_model.dart';
import '../../providers/payment_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';

class PaymentReceiptScreen extends ConsumerWidget {
  final String paymentId;

  const PaymentReceiptScreen({super.key, required this.paymentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentAsync = ref.watch(paymentByIdProvider(int.tryParse(paymentId) ?? 0));
    final selectedStudent = ref.watch(selectedStudentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Payment Receipt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              // TODO: Implement share
            },
          ),
        ],
      ),
      body: paymentAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (payment) {
          if (payment == null) {
            return const Center(child: Text('Payment not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: AppSizes.s4),
            child: Column(
              children: [
                _buildReceiptCard(payment, selectedStudent?.name ?? ''),
                const SizedBox(height: AppSizes.s4),
                _buildPaymentDetails(payment),
                const SizedBox(height: AppSizes.s6),
                AppButton(
                  text: 'Download Receipt',
                  onPressed: () {
                    // TODO: Implement download
                  },
                  icon: Icons.download_rounded,
                  isFullWidth: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceiptCard(PaymentModel payment, String studentName) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s6),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(AppSizes.roundedXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _getStatusColor(payment.status).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(payment.status),
              size: 32,
              color: _getStatusColor(payment.status),
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          Text(
            payment.status == PaymentStatus.success ? 'Payment Successful' : 'Payment ${payment.status.name}',
            style: TextStyle(
              fontSize: AppSizes.textLg,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(payment.status),
            ),
          ),
          const SizedBox(height: AppSizes.s2),
          Text(
            Formatters.currency(payment.amount),
            style: const TextStyle(
              fontSize: AppSizes.text3xl,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s4,
              vertical: AppSizes.s2,
            ),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(AppSizes.roundedFull),
            ),
            child: Text(
              payment.paymentNumber,
              style: const TextStyle(
                fontSize: AppSizes.textSm,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          const Divider(),
          const SizedBox(height: AppSizes.s4),
          _buildInfoRow('Student', studentName),
          _buildInfoRow('Date', payment.paidAt != null ? Formatters.dateTime(payment.paidAt!) : '-'),
          _buildInfoRow('Method', payment.paymentMethod ?? '-'),
          if (payment.transactionId != null)
            _buildInfoRow('Transaction ID', payment.transactionId!),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(PaymentModel payment) {
    if (payment.details.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSizes.s4),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(AppSizes.roundedXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fee Breakdown',
            style: TextStyle(
              fontSize: AppSizes.textBase,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          ...payment.details.map((detail) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.s2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  detail.feeName ?? 'Fee',
                  style: const TextStyle(
                    fontSize: AppSizes.textSm,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  Formatters.currency(detail.amount),
                  style: const TextStyle(
                    fontSize: AppSizes.textSm,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          )),
          const Divider(height: AppSizes.s6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: AppSizes.textBase,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                Formatters.currency(payment.amount),
                style: const TextStyle(
                  fontSize: AppSizes.textBase,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: AppSizes.textSm,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppSizes.textSm,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.success:
        return AppColors.success;
      case PaymentStatus.pending:
        return AppColors.warning;
      case PaymentStatus.failed:
        return AppColors.error;
      case PaymentStatus.refunded:
        return AppColors.info;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.success:
        return Icons.check_circle_rounded;
      case PaymentStatus.pending:
        return Icons.schedule_rounded;
      case PaymentStatus.failed:
        return Icons.cancel_rounded;
      case PaymentStatus.refunded:
        return Icons.replay_rounded;
    }
  }
}
