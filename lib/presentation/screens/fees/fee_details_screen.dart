import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/fee_model.dart';
import '../../providers/fee_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';

class FeeDetailsScreen extends ConsumerWidget {
  final String feeId;

  const FeeDetailsScreen({super.key, required this.feeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(feesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Fee Details'),
      ),
      body: feesAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (fees) {
          final fee = fees.firstWhere(
            (f) => f.id == feeId,
            orElse: () => throw Exception('Fee not found'),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: AppSizes.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeeHeader(fee),
                const SizedBox(height: AppSizes.s4),
                _buildFeeDetails(fee),
                const SizedBox(height: AppSizes.s4),
                _buildPaymentBreakdown(fee),
                if (fee.status != FeeStatus.paid) ...[
                  const SizedBox(height: AppSizes.s6),
                  AppButton(
                    text: 'Pay Now - ${Formatters.currency(fee.balanceAmount)}',
                    onPressed: () {
                      // TODO: Implement payment
                    },
                    isFullWidth: true,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeeHeader(FeeModel fee) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s4),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(AppSizes.roundedXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _getStatusColor(fee.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.roundedLg),
            ),
            child: Icon(
              _getStatusIcon(fee.status),
              color: _getStatusColor(fee.status),
              size: 28,
            ),
          ),
          const SizedBox(width: AppSizes.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fee.feeTypeName,
                  style: const TextStyle(
                    fontSize: AppSizes.textLg,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.s1),
                Text(
                  fee.term,
                  style: const TextStyle(
                    fontSize: AppSizes.textSm,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(fee.status),
        ],
      ),
    );
  }

  Widget _buildFeeDetails(FeeModel fee) {
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
            'Fee Details',
            style: TextStyle(
              fontSize: AppSizes.textBase,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          _buildDetailRow('Due Date', Formatters.date(fee.dueDate)),
          _buildDetailRow('Base Amount', Formatters.currency(fee.amount)),
          if (fee.discountAmount > 0)
            _buildDetailRow('Discount', '- ${Formatters.currency(fee.discountAmount)}', valueColor: AppColors.success),
          if (fee.lateFee > 0)
            _buildDetailRow('Late Fee', '+ ${Formatters.currency(fee.lateFee)}', valueColor: AppColors.error),
          const Divider(height: AppSizes.s6),
          _buildDetailRow('Total Amount', Formatters.currency(fee.totalAmount), isBold: true),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown(FeeModel fee) {
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
            'Payment Summary',
            style: TextStyle(
              fontSize: AppSizes.textBase,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          _buildDetailRow('Amount Paid', Formatters.currency(fee.paidAmount), valueColor: AppColors.success),
          _buildDetailRow('Balance Due', Formatters.currency(fee.balanceAmount), valueColor: fee.balanceAmount > 0 ? AppColors.error : AppColors.success),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.textSm,
              color: AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.textSm,
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(FeeStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s3,
        vertical: AppSizes.s1,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.roundedFull),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          fontSize: AppSizes.textXs,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  Color _getStatusColor(FeeStatus status) {
    switch (status) {
      case FeeStatus.paid:
        return AppColors.success;
      case FeeStatus.pending:
        return AppColors.warning;
      case FeeStatus.overdue:
        return AppColors.error;
      case FeeStatus.partial:
        return AppColors.info;
    }
  }

  IconData _getStatusIcon(FeeStatus status) {
    switch (status) {
      case FeeStatus.paid:
        return Icons.check_circle_rounded;
      case FeeStatus.pending:
        return Icons.schedule_rounded;
      case FeeStatus.overdue:
        return Icons.warning_rounded;
      case FeeStatus.partial:
        return Icons.timelapse_rounded;
    }
  }

  String _getStatusText(FeeStatus status) {
    switch (status) {
      case FeeStatus.paid:
        return 'Paid';
      case FeeStatus.pending:
        return 'Pending';
      case FeeStatus.overdue:
        return 'Overdue';
      case FeeStatus.partial:
        return 'Partial';
    }
  }
}
