import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/student_model.dart';
import '../../data/models/institution_model.dart';

// Brand palette
const _kPrimary = PdfColor(0.18, 0.49, 0.20); // #2E7D32
const _kPrimaryLight = PdfColor(0.91, 0.96, 0.91); // #E8F5E9
const _kPrimaryMid = PdfColor(0.51, 0.78, 0.52); // #81C784
const _kErrorDark = PdfColor(0.73, 0.11, 0.11); // #BA1A1A
const _kErrorLight = PdfColor(1.0, 0.93, 0.93); // #FFEDED
const _kErrorMid = PdfColor(0.94, 0.60, 0.60); // #EF9999

Future<pw.Document> generateReceiptPdf({
  required PaymentModel payment,
  required StudentModel student,
  InstitutionModel? institution,
}) async {
  final pdf = pw.Document();
  final isPaid = payment.paystatus == 'C';

  final primaryColor = isPaid ? _kPrimary : _kErrorDark;
  final bgColor = isPaid ? _kPrimaryLight : _kErrorLight;
  final borderColor = isPaid ? _kPrimaryMid : _kErrorMid;

  final dateStr = payment.paydate != null
      ? DateFormat('dd MMM yyyy, hh:mm a').format(payment.paydate!)
      : DateFormat('dd MMM yyyy, hh:mm a').format(payment.createdat);
  final amountStr =
      NumberFormat('#,##,###.00', 'en_IN').format(payment.transtotalamount);

  final addressParts = <String>[
    if (institution?.insaddress1 != null) institution!.insaddress1!,
    if (institution?.insaddress2 != null) institution!.insaddress2!,
    if (institution?.cityName != null) institution!.cityName!,
    if (institution?.inspincode != null) institution!.inspincode!,
  ];
  final contactParts = <String>[
    if (institution?.insmobno != null) 'Ph: ${institution!.insmobno}',
    if (institution?.insmail != null) institution!.insmail!,
  ];

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── Green header banner ────────────────────────────────────
            pw.Container(
              color: isPaid ? _kPrimary : _kErrorDark,
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 40, vertical: 22),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    (institution?.insname ?? 'School').toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 1.2,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  if (addressParts.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      addressParts.join(', '),
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.white),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                  if (contactParts.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      contactParts.join('   |   '),
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.white),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            // ── Title strip ───────────────────────────────────────────
            pw.Container(
              color: bgColor,
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 40, vertical: 12),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'PAYMENT RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      isPaid ? 'COMPLETED' : 'FAILED',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────────────
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(40, 24, 40, 24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // Receipt No + Date chips
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _metaChip(
                              'Receipt No', payment.paymentNumber, primaryColor),
                        ),
                        pw.SizedBox(width: 16),
                        pw.Expanded(
                          child: _metaChip('Date', dateStr, primaryColor),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),

                    // Info cards
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: _infoCard(
                            title: 'Payment Details',
                            titleColor: primaryColor,
                            rows: [
                              ('Method',
                                  _capitalize(payment.paymethod ?? '-')),
                              if (payment.payreference != null &&
                                  payment.payreference!.isNotEmpty)
                                ('Transaction ID', payment.payreference!),
                              ('Currency', payment.transcurrency),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 16),
                        pw.Expanded(
                          child: _infoCard(
                            title: 'Student Details',
                            titleColor: primaryColor,
                            rows: [
                              ('Name', student.stuname),
                              ('Class', student.stuclass),
                              ('Adm No', student.stuadmno),
                              ('Academic Year', payment.yrlabel ?? '-'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 24),

                    // Amount box
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 22, horizontal: 20),
                      decoration: pw.BoxDecoration(
                        color: bgColor,
                        border: pw.Border.all(
                            color: borderColor, width: 1.5),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Total Amount Paid',
                            style: const pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            'Rs. $amountStr',
                            style: pw.TextStyle(
                              fontSize: 30,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            payment.transcurrency,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.Spacer(),
                  ],
                ),
              ),
            ),

            // ── Footer ────────────────────────────────────────────────
            pw.Container(
              color: PdfColors.grey100,
              padding: const pw.EdgeInsets.fromLTRB(40, 10, 40, 14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Divider(
                      color: PdfColors.grey300, thickness: 0.5),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        institution?.inscode != null
                            ? 'Code: ${institution!.inscode}'
                            : '',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey500),
                      ),
                      pw.Text(
                        'This is a computer-generated receipt. No signature required.',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey500),
                      ),
                      pw.Text(
                        'Generated: ${DateFormat("dd MMM yyyy").format(DateTime.now())}',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf;
}

// ── Helpers ─────────────────────────────────────────────────────────────

pw.Widget _metaChip(String label, String value, PdfColor accent) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey50,
      border: pw.Border.all(color: PdfColors.grey200),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$label  ',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _infoCard({
  required String title,
  required PdfColor titleColor,
  required List<(String, String)> rows,
}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey200),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Card header
        pw.Container(
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: pw.BoxDecoration(
            color: titleColor,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(5),
              topRight: pw.Radius.circular(5),
            ),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        // Card rows
        pw.Padding(
          padding: const pw.EdgeInsets.all(12),
          child: pw.Column(
            children: rows
                .map((r) => _infoRow(r.$1, r.$2))
                .toList(),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _infoRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 88,
          child: pw.Text(
            label,
            style:
                const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}
