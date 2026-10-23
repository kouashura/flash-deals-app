import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  /// Génère et ouvre la facture PDF d'une commande
  static Future<void> generateInvoice({
    required String orderId,
    required DateTime createdAt,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required int deliveryFee,
    required double total,
    String? deliveryZone,
    String? timeSlot,
  }) async {
    final doc = pw.Document();

    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm', 'fr');

    final shortId = orderId.length > 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // ═══ HEADER ═══
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'FLASH DEALS',
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Abidjan, Côte d\'Ivoire',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'contact@flashdeals.ci',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    '+225 07 00 00 00 00',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.orange100,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'FACTURE',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange900,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'N° $shortId',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    dateFormat.format(createdAt),
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 20),

          // ═══ CLIENT ═══
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CLIENT',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  customerName,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text('📞 $customerPhone',
                    style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 2),
                pw.Text(
                  '📍 $customerAddress',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                if (deliveryZone != null && deliveryZone.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '🗺️ Zone : $deliveryZone',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
                if (timeSlot != null && timeSlot.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '⏰ Créneau : $timeSlot',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ═══ TABLEAU ARTICLES ═══
          pw.Text(
            'ARTICLES COMMANDÉS',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColors.grey300,
              width: 0.5,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.orange800,
                ),
                children: [
                  _headerCell('Article'),
                  _headerCell('Qté'),
                  _headerCell('Prix unit.'),
                  _headerCell('Total'),
                ],
              ),
              ...items.map((item) {
                return pw.TableRow(
                  children: [
                    _cell(item['name'] as String? ?? 'Article'),
                    _cell('${item['quantity'] ?? 0}'),
                    _cell('${item['price'] ?? 0} F'),
                    _cell('${item['total'] ?? 0} F'),
                  ],
                );
              }),
            ],
          ),

          pw.SizedBox(height: 20),

          // ═══ TOTAUX ═══
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 220,
              child: pw.Column(
                children: [
                  _totalRow('Sous-total',
                      '${subtotal.toStringAsFixed(0)} F'),
                  pw.SizedBox(height: 4),
                  _totalRow('Livraison', '$deliveryFee F'),
                  pw.SizedBox(height: 6),
                  pw.Divider(color: PdfColors.grey400),
                  pw.SizedBox(height: 6),
                  _totalRow(
                    'TOTAL À PAYER',
                    '${total.toStringAsFixed(0)} F',
                    bold: true,
                    color: PdfColors.orange800,
                  ),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 30),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),

          // ═══ PIED DE PAGE ═══
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'Merci pour votre commande !',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Flash Deals Abidjan • www.flashdeals.ci',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => doc.save(),
      name: 'Facture_$shortId.pdf',
    );
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _cell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  static pw.Widget _totalRow(
    String label,
    String value, {
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: bold ? 12 : 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: bold ? 13 : 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}
