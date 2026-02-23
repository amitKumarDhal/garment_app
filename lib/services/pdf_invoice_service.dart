import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../data/models/order_model.dart';

class PdfInvoiceService {
  static Future<void> generateAndPrintInvoice(OrderModel order) async {
    final pdf = pw.Document();

    // Use a font that supports the Rupee (₹) symbol
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Calculate totals
    double calculatedSubtotal = 0;
    double calculatedTax = 0;

    for (var prod in order.products) {
      double price = double.tryParse(prod['price']?.toString() ?? '0') ?? 0.0;
      int qty = int.tryParse(prod['qty']?.toString() ?? '0') ?? 0;
      double gst = double.tryParse(prod['gstPercentage']?.toString() ?? '0') ?? 0.0;

      double base = price * qty;
      calculatedSubtotal += base;
      calculatedTax += base * (gst / 100);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // --- HEADER ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("YOOBBEL", style: pw.TextStyle(font: boldFont, fontSize: 28, color: PdfColors.deepPurple)),
                    pw.SizedBox(height: 4),
                    pw.Text("Premium Manufacturing & Logistics", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                    pw.Text("Bhubaneswar, Odisha", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("INVOICE", style: pw.TextStyle(font: boldFont, fontSize: 24, color: PdfColors.black)),
                    pw.SizedBox(height: 4),
                    pw.Text("Order #: ${order.manualOrderNo ?? 'N/A'}", style: pw.TextStyle(font: boldFont, fontSize: 12)),
                    pw.Text("Date: ${DateFormat('MMM dd, yyyy').format(order.orderDate)}", style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 20),

            // --- CLIENT INFO ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("BILLED TO:", style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.grey600)),
                    pw.SizedBox(height: 4),
                    pw.Text(order.clientName, style: pw.TextStyle(font: boldFont, fontSize: 14)),
                    pw.Text(order.organization ?? "", style: pw.TextStyle(font: font, fontSize: 11)),
                    pw.Text(order.clientPhone ?? "", style: pw.TextStyle(font: font, fontSize: 11)),
                    pw.Text(order.clientAddress ?? "", style: pw.TextStyle(font: font, fontSize: 11)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("SALES ASSOCIATE:", style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.grey600)),
                    pw.SizedBox(height: 4),
                    pw.Text(order.marketingPersonName, style: pw.TextStyle(font: boldFont, fontSize: 12)),
                    pw.SizedBox(height: 10),
                    pw.Text("DELIVERY DEADLINE:", style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.grey600)),
                    pw.SizedBox(height: 4),
                    pw.Text(DateFormat('MMM dd, yyyy').format(order.deliveryDate), style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.red800)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // --- ITEMIZED TABLE ---
            pw.TableHelper.fromTextArray(
              headers: ['Item Description', 'SKU', 'Qty', 'Unit Price', 'Total'],
              data: order.products.map((item) {
                double iPrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                int iQty = int.tryParse(item['qty']?.toString() ?? '0') ?? 0;
                double iTotal = iPrice * iQty;
                return [
                  item['productName'] ?? "Unknown",
                  item['productCode'] ?? "-",
                  iQty.toString(),
                  currency.format(iPrice),
                  currency.format(iTotal),
                ];
              }).toList(),
              border: null,
              headerStyle: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple),
              cellStyle: pw.TextStyle(font: font, fontSize: 10),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
              cellPadding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
            ),
            pw.SizedBox(height: 20),

            // --- FINANCIAL SUMMARY ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 200,
                  child: pw.Column(
                    children: [
                      _buildSummaryRow("Subtotal", currency.format(calculatedSubtotal), font),
                      _buildSummaryRow("Tax (GST)", "+ ${currency.format(calculatedTax)}", font),
                      _buildSummaryRow("Shipping", "+ ${currency.format(order.shippingCharge)}", font),
                      pw.Divider(color: PdfColors.grey300),
                      _buildSummaryRow("Grand Total", currency.format(order.totalAmount), boldFont, size: 14),
                      _buildSummaryRow("Advance Paid", "- ${currency.format(order.advanceAmount)}", font, color: PdfColors.green700),
                      pw.Divider(color: PdfColors.grey300),
                      _buildSummaryRow("Balance Due", currency.format(order.balanceDue), boldFont, size: 14, color: PdfColors.red800),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 40),

            // --- FOOTER ---
            pw.Center(
              child: pw.Text(
                "Thank you for doing business with Yoobbel!",
                style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
              ),
            ),
          ];
        },
      ),
    );

    // This triggers the native Print/Share screen!
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${order.manualOrderNo ?? order.id}.pdf',
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, pw.Font font, {double size = 10, PdfColor color = PdfColors.black}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: size, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: size, color: color)),
        ],
      ),
    );
  }
}