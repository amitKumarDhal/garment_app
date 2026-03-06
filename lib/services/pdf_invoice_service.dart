import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/order_model.dart';

class PdfInvoiceService {
  static Future<void> generateAndPrintInvoice(OrderModel order) async {
    final pdf = pw.Document();

    // Use a font that supports the Rupee (₹) symbol
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

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
                    pw.Text("YOOBBEL", style: pw.TextStyle(font: boldFont, fontSize: 32, color: const PdfColor.fromInt(0xFF1A237E))), // Deep Indigo
                    pw.SizedBox(height: 4),
                    pw.Text("Premium Manufacturing & Logistics", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                    pw.Text("Bhubaneswar, Odisha", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                    pw.Text("Contact: support@yoobbel.com", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("INVOICE", style: pw.TextStyle(font: boldFont, fontSize: 26, color: PdfColors.black, letterSpacing: 2)),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFE8EAF6),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text("Order #: ${order.manualOrderNo ?? 'N/A'}", style: pw.TextStyle(font: boldFont, fontSize: 12, color: const PdfColor.fromInt(0xFF1A237E))),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text("Date: ${DateFormat('MMM dd, yyyy').format(order.orderDate)}", style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey300, thickness: 1.5),
            pw.SizedBox(height: 20),

            // --- CLIENT INFO ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("BILLED TO:", style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.grey600)),
                    pw.SizedBox(height: 6),
                    pw.Text(order.clientName, style: pw.TextStyle(font: boldFont, fontSize: 14)),
                    if (order.organization != null && order.organization!.isNotEmpty)
                      pw.Text(order.organization!, style: pw.TextStyle(font: font, fontSize: 11)),
                    if (order.clientPhone != null && order.clientPhone!.isNotEmpty)
                      pw.Text(order.clientPhone!, style: pw.TextStyle(font: font, fontSize: 11)),
                    if (order.clientAddress != null && order.clientAddress!.isNotEmpty)
                      pw.Container(
                        width: 200,
                        child: pw.Text(order.clientAddress!, style: pw.TextStyle(font: font, fontSize: 11)),
                      ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("SALES ASSOCIATE:", style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.grey600)),
                    pw.SizedBox(height: 4),
                    pw.Text(order.marketingPersonName, style: pw.TextStyle(font: boldFont, fontSize: 12)),
                    pw.SizedBox(height: 15),
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

                // Construct a detailed description including sizes if they exist
                String desc = item['productName'] ?? "Unknown";
                if (item['sizeDescription'] != null && item['sizeDescription'].toString().isNotEmpty) {
                  desc += "\nSizes: ${item['sizeDescription']}";
                }

                return [
                  desc,
                  item['productCode'] ?? "-",
                  iQty.toString(),
                  currency.format(iPrice),
                  currency.format(iTotal),
                ];
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
              headerStyle: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1A237E)),
              cellStyle: pw.TextStyle(font: font, fontSize: 10),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
              cellPadding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              // Alternating row colors
              rowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFAFAFA)),
            ),
            pw.SizedBox(height: 20),

            // --- FINANCIAL SUMMARY WITH PAYMENT HISTORY ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left Side: Notes / Payment Terms
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Notes:", style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.grey600)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                          order.productDetails?.isNotEmpty == true ? order.productDetails! : "No additional notes provided.",
                          style: pw.TextStyle(font: font, fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey800)
                      ),

                      // 🌟 WATERMARK STAMP IF FULLY PAID 🌟
                      if (order.balanceDue <= 0) ...[
                        pw.SizedBox(height: 30),
                        pw.Transform.rotate(
                          angle: 0.2, // Slight tilt
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.green800, width: 3),
                              borderRadius: pw.BorderRadius.circular(8),
                            ),
                            child: pw.Text(
                                "FULLY PAID",
                                style: pw.TextStyle(font: boldFont, fontSize: 24, color: PdfColors.green800, letterSpacing: 4)
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                pw.SizedBox(width: 40),

                // Right Side: Math
                pw.Container(
                  width: 220,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _buildSummaryRow("Subtotal", currency.format(calculatedSubtotal), font),
                      _buildSummaryRow("Tax (GST)", "+ ${currency.format(calculatedTax)}", font),
                      if (order.shippingCharge > 0)
                        _buildSummaryRow("Shipping", "+ ${currency.format(order.shippingCharge)}", font),

                      pw.SizedBox(height: 4),
                      pw.Divider(color: PdfColors.grey300),
                      pw.SizedBox(height: 4),

                      _buildSummaryRow("Grand Total", currency.format(order.totalAmount), boldFont, size: 14),

                      pw.SizedBox(height: 10),

                      // ✅ DYNAMIC PAYMENT HISTORY LOOP ON INVOICE
                      if (order.paymentHistory.isNotEmpty) ...[
                        pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text("Payment Record:", style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.grey600)),
                        ),
                        pw.SizedBox(height: 4),
                        ...order.paymentHistory.map((payment) {
                          double amount = double.tryParse(payment['amount']?.toString() ?? '0') ?? 0.0;
                          String dateStr = "";
                          if (payment['date'] != null) {
                            DateTime dt = (payment['date'] as Timestamp).toDate();
                            dateStr = DateFormat('dd MMM').format(dt);
                          }
                          return _buildSummaryRow("Paid on $dateStr", "- ${currency.format(amount)}", font, color: PdfColors.red800, size: 9);
                        }),
                      ] else if (order.advanceAmount > 0) ...[
                        _buildSummaryRow("Advance Paid", "- ${currency.format(order.advanceAmount)}", font, color: PdfColors.red800),
                      ],

                      pw.SizedBox(height: 4),
                      pw.Divider(color: PdfColors.grey800, thickness: 1.5),
                      pw.SizedBox(height: 4),

                      _buildSummaryRow(
                          order.balanceDue <= 0 ? "Amount Due" : "Balance Due",
                          currency.format(order.balanceDue),
                          boldFont,
                          size: 16,
                          color: order.balanceDue <= 0 ? PdfColors.green800 : PdfColors.red800
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- PUSH FOOTER TO BOTTOM ---
            pw.Spacer(),

            // --- FOOTER & T&C ---
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Terms & Conditions:", style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.grey800)),
                      pw.SizedBox(height: 2),
                      pw.Text("1. Payment is due as per the agreed schedule.", style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
                      pw.Text("2. Goods once sold cannot be returned without prior approval.", style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Text(
                    "Thank you for doing business with Yoobbel!",
                    style: pw.TextStyle(font: boldFont, fontSize: 10, color: const PdfColor.fromInt(0xFF1A237E), fontStyle: pw.FontStyle.italic),
                  ),
                ]
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

  // HELPER TO KEEP ROWS CLEAN
  static pw.Widget _buildSummaryRow(String label, String value, pw.Font font, {double size = 10, PdfColor color = PdfColors.black}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
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