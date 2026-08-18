import 'package:flutter_test/flutter_test.dart';
import 'package:yoobbel/utils/constants/branding_constants.dart';

void main() {
  group('Zobbra PDF Branding & B&W Styling Tests', () {
    test('ZobbraBranding constants contain no old Yoobbel company text', () {
      expect(ZobbraBranding.brandName.toLowerCase(), 'zobbra');
      expect(ZobbraBranding.legalCompanyName.toLowerCase(), contains('zobbra'));
      expect(ZobbraBranding.legalCompanyName.toLowerCase(), isNot(contains('yoobbel')));
      expect(ZobbraBranding.supportEmail.toLowerCase(), contains('zobbra.com'));
      expect(ZobbraBranding.supportEmail.toLowerCase(), isNot(contains('yoobbel.com')));
      expect(ZobbraBranding.website.toLowerCase(), contains('zobbra.com'));
      expect(ZobbraBranding.bankAccountName.toLowerCase(), contains('zobbra'));
      expect(ZobbraBranding.bankAccountName.toLowerCase(), isNot(contains('yoobbel')));
    });

    test('ZobbraBranding includes all required business fields', () {
      expect(ZobbraBranding.brandName, isNotEmpty);
      expect(ZobbraBranding.legalCompanyName, isNotEmpty);
      expect(ZobbraBranding.addressLine1, isNotEmpty);
      expect(ZobbraBranding.pinCode, isNotEmpty);
      expect(ZobbraBranding.gstin, isNotEmpty);
      expect(ZobbraBranding.iec, isNotEmpty);
      expect(ZobbraBranding.pan, isNotEmpty);
      expect(ZobbraBranding.bankName, isNotEmpty);
      expect(ZobbraBranding.bankAccountNumber, isNotEmpty);
      expect(ZobbraBranding.bankIfscCode, isNotEmpty);
    });
  });
}
