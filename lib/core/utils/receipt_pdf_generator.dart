import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/student_model.dart';
import '../../data/models/institution_model.dart';

Future<pw.Document> generateReceiptPdf({
  required PaymentModel payment,
  required StudentModel student,
  InstitutionModel? institution,
}) async {
  final pdf = pw.Document();
  final isPaid = payment.paystatus == 'C';
  final dateStr = payment.paydate != null
      ? DateFormat('dd MMM yyyy, hh:mm a').format(payment.paydate!)
      : DateFormat('dd MMM yyyy, hh:mm a').format(payment.createdat);
  final amountStr = NumberFormat('#,##,###.00', 'en_IN').format(payment.transtotalamount);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header - School Info
            _buildHeader(institution),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 2, color: PdfColors.grey800),
            pw.SizedBox(height: 16),

            // Title
            pw.Center(
              child: pw.Text(
                'PAYMENT RECEIPT',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: isPaid ? PdfColors.green100 : PdfColors.red100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  isPaid ? 'COMPLETED' : 'FAILED',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: isPaid ? PdfColors.green900 : PdfColors.red900,
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Payment & Student Info - Two Column
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Payment Info
                pw.Expanded(
                  child: _buildInfoBox('Payment Details', [
                    _infoRow('Receipt No', payment.paymentNumber),
                    _infoRow('Date', dateStr),
                    _infoRow('Method', payment.paymethod ?? '-'),
                    if (payment.payreference != null)
                      _infoRow('Transaction ID', payment.payreference!),
                  ]),
                ),
                pw.SizedBox(width: 16),
                // Student Info
                pw.Expanded(
                  child: _buildInfoBox('Student Details', [
                    _infoRow('Name', student.stuname),
                    _infoRow('Class', student.stuclass),
                    _infoRow('Adm No', student.stuadmno),
                    _infoRow('Year', payment.yrlabel ?? '-'),
                  ]),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Amount Box
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: isPaid ? PdfColors.green50 : PdfColors.red50,
                border: pw.Border.all(
                  color: isPaid ? PdfColors.green300 : PdfColors.red300,
                ),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'Total Amount',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    '₹ $amountStr',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: isPaid ? PdfColors.green800 : PdfColors.red800,
                    ),
                  ),
                ],
              ),
            ),

            pw.Spacer(),

            // Footer
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'This is a computer-generated receipt and does not require a signature.',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf;
}

pw.Widget _buildHeader(InstitutionModel? institution) {
  final schoolName = institution?.insname ?? 'School';
  final addressParts = <String>[
    if (institution?.insaddress1 != null) institution!.insaddress1!,
    if (institution?.insaddress2 != null) institution!.insaddress2!,
    if (institution?.cityName != null) institution!.cityName!,
    if (institution?.inspincode != null) institution!.inspincode!,
  ];
  final address = addressParts.isNotEmpty ? addressParts.join(', ') : '';

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Text(
        schoolName.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey900,
        ),
        textAlign: pw.TextAlign.center,
      ),
      if (address.isNotEmpty) ...[
        pw.SizedBox(height: 4),
        pw.Text(
          address,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          textAlign: pw.TextAlign.center,
        ),
      ],
      if (institution?.insmobno != null || institution?.insmail != null) ...[
        pw.SizedBox(height: 2),
        pw.Text(
          [
            if (institution?.insmobno != null) 'Phone: ${institution!.insmobno}',
            if (institution?.insmail != null) 'Email: ${institution!.insmail}',
          ].join('  |  '),
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    ],
  );
}

pw.Widget _buildInfoBox(String title, List<pw.Widget> rows) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 8),
        ...rows,
      ],
    ),
  );
}

pw.Widget _infoRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 90,
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
