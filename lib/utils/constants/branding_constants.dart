/// Centralized single source of truth for Zobbra branding, company information,
/// and bank account details across Invoices, Quotations, and PDF generators.
class ZobbraBranding {
  // --- Known Official Zobbra Brand Details ---
  static const String brandName = "Zobbra";
  static const String appName = "Zobbra Production";
  static const String tagline = "Premium Manufacturing & Logistics";
  static const String logoAssetPath = "assets/images/zobbra.jpeg";

  // --- Contact & Location ---
  static const String supportEmail = "support@zobbra.com";
  static const String website = "https://zobbra.com";
  static const String city = "Bhubaneswar";
  static const String state = "Odisha";
  static const String country = "India";
  static const String fullLocation = "Bhubaneswar, Odisha, India";

  // --- Legal Company Registration Details (Centralized for User Confirmation) ---
  // If specific legal corporate name or GST credentials are updated, modify here.
  static const String legalCompanyName = "Zobbra Manufacturing Pvt. Ltd.";
  static const String addressLine1 = "Plot No 204, Aditya Nagar, Sundarpada";
  static const String addressLine2 = "Botanda, Bhubaneswar, Odisha";
  static const String pinCode = "751002";
  static const String gstin = "21AABCY4324K1ZH";
  static const String iec = "AABCY4324K";
  static const String pan = "AABCY4324K";

  // --- Bank Account Details (Centralized for User Confirmation) ---
  static const String bankAccountName = "Zobbra Manufacturing Pvt. Ltd.";
  static const String bankName = "Yes Bank";
  static const String bankAccountNumber = "106663300002414";
  static const String bankIfscCode = "YESB0001066";
}
