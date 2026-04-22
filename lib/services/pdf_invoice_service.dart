import 'package:flutter/services.dart'; // ✅ Required to load the logo image
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/order_model.dart';

class PdfInvoiceService {

  // ===========================================================================
  // 1. GENERATE INVOICE (From existing Order Model)
  // ===========================================================================
  static Future<void> generateAndPrintInvoice(OrderModel order) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

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
                    pw.Text("YOOBBEL", style: pw.TextStyle(font: boldFont, fontSize: 32, color: const PdfColor.fromInt(0xFF1A237E))),
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
              rowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFAFAFA)),
            ),
            pw.SizedBox(height: 20),

            // --- FINANCIAL SUMMARY WITH PAYMENT HISTORY ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
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
                      if (order.balanceDue <= 0) ...[
                        pw.SizedBox(height: 30),
                        pw.Transform.rotate(
                          angle: 0.2,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.green800, width: 3),
                              borderRadius: pw.BorderRadius.circular(8),
                            ),
                            child: pw.Text("FULLY PAID", style: pw.TextStyle(font: boldFont, fontSize: 24, color: PdfColors.green800, letterSpacing: 4)),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                pw.SizedBox(width: 40),
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

            pw.Spacer(),
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

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${order.manualOrderNo ?? order.id}.pdf',
    );
  }

  // ===========================================================================
  // 2. GENERATE QUOTATION (Red & White Theme with Exact Logo)
  // ===========================================================================
  static Future<void> generateQuotationPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // Load Fonts
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    // ✅ Define the Brand Red Color
    final PdfColor brandRed = const PdfColor.fromInt(0xFFC62828);

    // ✅ Load the Logo from assets
    pw.MemoryImage? logoImage;
    try {
      final ByteData bytes = await rootBundle.load('assets/images/Yoobbel.png');
      logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      print("Warning: Could not load Yoobbel.png from assets. Make sure it's added to pubspec.yaml.");
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // --- 1. HEADER ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo Area (Uses the image, falls back to text if missing)
                  if (logoImage != null)
                    pw.Image(logoImage, width: 140)
                  else
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 40, height: 40,
                          decoration: pw.BoxDecoration(color: brandRed, borderRadius: pw.BorderRadius.circular(8)),
                          alignment: pw.Alignment.center,
                          child: pw.Text("y", style: pw.TextStyle(font: boldFont, color: PdfColors.white, fontSize: 24)),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text("yoobbel", style: pw.TextStyle(font: boldFont, fontSize: 26, color: PdfColors.grey800, letterSpacing: -1)),
                      ],
                    ),

                  // Company Info
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("QUOTATION", style: pw.TextStyle(font: boldFont, fontSize: 24, color: brandRed, letterSpacing: 2)),
                      pw.SizedBox(height: 8),
                      pw.Text("Yoobbel Technologies Pvt Ltd.", style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.grey900)),
                      pw.Text("2nd Floor, Plot No 204 Aditya Nagar,", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                      pw.Text("Sundarpada, Botanda, Odisha", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                      pw.Text("751002 Bhubaneswar", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                      pw.Text("India", style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Divider(color: brandRed, thickness: 1.5), // Red Accent Line
              pw.SizedBox(height: 10),

              // --- 2. TAX INFO ---
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("GSTIN : 21AABCY4324K1ZH", style: pw.TextStyle(font: boldFont, fontSize: 10)),
                    pw.Text("IEC : AABCY4324K", style: pw.TextStyle(font: boldFont, fontSize: 10)),
                    pw.Text("PAN : AABCY4324K", style: pw.TextStyle(font: boldFont, fontSize: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text("E-mail : admin@yoobbel.com", style: pw.TextStyle(font: boldFont, fontSize: 10, color: brandRed)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // --- 3. BILL TO & QUOTE META ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("BILL TO", style: pw.TextStyle(font: boldFont, fontSize: 12, color: brandRed)),
                      pw.SizedBox(height: 4),
                      pw.Text(data['clientName'] ?? "", style: pw.TextStyle(font: boldFont, fontSize: 11)),
                      if ((data['clientAddress'] ?? "").toString().isNotEmpty)
                        pw.Text(data['clientAddress'], style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey800)),
                      if ((data['clientGst'] ?? "").toString().isNotEmpty)
                        pw.Text("GST: ${data['clientGst']}", style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey800)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("Quotation No: ", style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700)),
                          pw.Text(data['quotationNo'] ?? "", style: pw.TextStyle(font: boldFont, fontSize: 11)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("Issue Date: ", style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700)),
                          pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now()), style: pw.TextStyle(font: boldFont, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // --- 4. ITEM TABLE (Red Header) ---
              pw.TableHelper.fromTextArray(
                headers: ['DESCRIPTION', 'QTY', 'UNIT PRICE', 'GST', 'AMOUNT'],
                data: (data['items'] as List<dynamic>).map((item) {
                  double qty = double.tryParse(item['quantity'].toString()) ?? 0;
                  double price = double.tryParse(item['price'].toString()) ?? 0;
                  double gstPercent = double.tryParse(item['gstPercent'].toString()) ?? 0;

                  double amountWithoutGst = qty * price;
                  double gstAmount = amountWithoutGst * (gstPercent / 100);
                  double totalAmount = amountWithoutGst + gstAmount;

                  return [
                    item['name'] ?? '',
                    qty.toStringAsFixed(0),
                    currency.format(price),
                    currency.format(gstAmount),
                    currency.format(totalAmount),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.white),
                cellStyle: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.black),
                headerDecoration: pw.BoxDecoration(color: brandRed), // Red Header Background
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
                cellPadding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                rowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFAFAFA)),
              ),
              pw.SizedBox(height: 20),

              // --- 5. BOTTOM SECTION ---
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Bank Details
                  pw.Expanded(
                    flex: 5,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: pw.BorderRadius.circular(6),
                          color: const PdfColor.fromInt(0xFFF5F5F5)
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Bank Details:", style: pw.TextStyle(font: boldFont, fontSize: 10, color: brandRed)),
                          pw.SizedBox(height: 6),
                          pw.Text("Account name- Yoobbel Technologies Private Limited", style: pw.TextStyle(font: font, fontSize: 10)),
                          pw.Text("Bank Name- Yes Bank", style: pw.TextStyle(font: font, fontSize: 10)),
                          pw.Text("Account no- 106663300002414", style: pw.TextStyle(font: font, fontSize: 10)),
                          pw.Text("IFSC code- YESB0001066", style: pw.TextStyle(font: font, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 20),

                  // Totals
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      children: [
                        _buildSummaryRow("SUB TOTAL", currency.format(data['subTotal'] ?? 0), font),
                        _buildSummaryRow("TOTAL GST", currency.format(data['totalGst'] ?? 0), font),
                        _buildSummaryRow("SHIPPING", currency.format(data['shipping'] ?? 0), font),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: brandRed, width: 2), // Thick Red Border for Total
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: _buildSummaryRow("TOTAL", currency.format(data['grandTotal'] ?? 0), boldFont, color: brandRed),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Signature Placeholder
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Text("Authorized Signatory", style: pw.TextStyle(font: font, fontSize: 12, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${data['quotationNo']}.pdf',
    );
  }

  // ===========================================================================
  // COMMON HELPER
  // ===========================================================================
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