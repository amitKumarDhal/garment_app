class InventoryConstants {

  // ✅ MASTER COLOR LIST (24 Colors from PDF Palette)
  static const List<Map<String, dynamic>> allColors = [

    // --- 🔹 REGULAR COLORS (Top 5 - Highlighted in UI) ---
    {'name': 'White', 'hex': 0xFFFFFFFF, 'isRegular': true},
    {'name': 'Black', 'hex': 0xFF000000, 'isRegular': true},
    {'name': 'Navy blue', 'hex': 0xFF000080, 'isRegular': true},
    {'name': 'Royal blue', 'hex': 0xFF4169E1, 'isRegular': true},
    {'name': 'Light grey', 'hex': 0xFFD3D3D3, 'isRegular': true}, // Using Light Grey as the standard Grey

    // --- 🔸 EXTENDED COLORS (Remaining 19) ---
    {'name': 'Off white', 'hex': 0xFFFAF9F6, 'isRegular': false},
    {'name': 'Beige', 'hex': 0xFFF5F5DC, 'isRegular': false},
    {'name': 'Dark grey', 'hex': 0xFFA9A9A9, 'isRegular': false},
    {'name': 'Sky blue', 'hex': 0xFF87CEEB, 'isRegular': false},
    {'name': 'Ocean blue', 'hex': 0xFF0077BE, 'isRegular': false},
    {'name': 'Neon green', 'hex': 0xFF39FF14, 'isRegular': false},
    {'name': 'Green', 'hex': 0xFF008000, 'isRegular': false},
    {'name': 'Bottle green', 'hex': 0xFF006A4E, 'isRegular': false},
    {'name': 'Lemon yellow', 'hex': 0xFFFFF44F, 'isRegular': false},
    {'name': 'Yellow', 'hex': 0xFFFFFF00, 'isRegular': false},
    {'name': 'Mustard yellow', 'hex': 0xFFFFDB58, 'isRegular': false},
    {'name': 'Orange', 'hex': 0xFFFFA500, 'isRegular': false},
    {'name': 'Red', 'hex': 0xFFFF0000, 'isRegular': false},
    {'name': 'Maroon', 'hex': 0xFF800000, 'isRegular': false},
    {'name': 'Pink', 'hex': 0xFFFFC0CB, 'isRegular': false},
    {'name': 'Light pink', 'hex': 0xFFFFB6C1, 'isRegular': false},
    {'name': 'Brown', 'hex': 0xFFA52A2A, 'isRegular': false},
    {'name': 'Purple', 'hex': 0xFF800080, 'isRegular': false},
    {'name': 'Lavender', 'hex': 0xFFE6E6FA, 'isRegular': false},
  ];

  // ✅ MASTER PRODUCT LIST
  static const List<String> products = [
    'Dotknit (160 gsm)',
    'Nokia (120 gsm)',
    'Spun matty (220 gsm)',
    'Pc matty (240 gsm)',
    'Polyester collar',
    'Acrylic collar',
    'Others'
  ];

  // ✅ MASTER COLLAR & RIB STYLES
  static const List<String> collarStyles = [
    'Solid color',
    'Single Line',
    'Dual line',
    '3+ lines'
  ];

  // ✅ HELPER: Get Hex by Color Name (Useful for the Summary Screen)
  static int getHexForColor(String colorName) {
    try {
      final match = allColors.firstWhere(
            (c) => c['name'].toString().toLowerCase() == colorName.toLowerCase(),
      );
      return match['hex'];
    } catch (e) {
      return 0xFF808080; // Default to grey if somehow not found
    }
  }
}