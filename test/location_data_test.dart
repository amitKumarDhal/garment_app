import 'package:flutter_test/flutter_test.dart';
import 'package:yoobbel/controllers/floor_management/marketing_upload_controller.dart';
import 'package:yoobbel/utils/constants/app_constants.dart';
import 'package:get/get.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() async {
    await TestHelper.setup();
  });

  tearDownAll(() {
    TestHelper.tearDown();
  });

  group('Odisha & Location Data Tests', () {
    test('Canonical Odisha dataset contains all 30 districts', () {
      expect(AppConstants.odishaDistricts.length, 30);
      expect(AppConstants.odishaDistricts.toSet().length, 30);

      final expectedDistricts = [
        'Angul', 'Balangir', 'Balasore', 'Bargarh', 'Bhadrak', 'Boudh',
        'Cuttack', 'Deogarh', 'Dhenkanal', 'Gajapati', 'Ganjam', 'Jagatsinghpur',
        'Jajpur', 'Jharsuguda', 'Kalahandi', 'Kandhamal', 'Kendrapara', 'Kendujhar',
        'Khordha', 'Koraput', 'Malkangiri', 'Mayurbhanj', 'Nabarangpur', 'Nayagarh',
        'Nuapada', 'Puri', 'Rayagada', 'Sambalpur', 'Subarnapur', 'Sundargarh'
      ];

      for (final district in expectedDistricts) {
        expect(AppConstants.odishaDistricts.contains(district), isTrue,
            reason: '$district must be present in Odisha district list');
      }
    });

    test('Indian states list contains Odisha and major states', () {
      expect(AppConstants.indianStates.contains('Odisha'), isTrue);
      expect(AppConstants.indianStates.length, greaterThanOrEqualTo(28));
    });

    test('MarketingUploadController loads all 30 Odisha districts when Odisha is selected', () {
      Get.reset();
      final controller = Get.put(MarketingUploadController());

      expect(controller.selectedState.value, 'Odisha');
      expect(controller.availableDistricts.length, 30);
      expect(controller.availableDistricts.contains('Cuttack'), isTrue);
      expect(controller.availableDistricts.contains('Khordha'), isTrue);
      expect(controller.availableDistricts.contains('Puri'), isTrue);
    });

    test('Changing state clears previous district selection and loads new district list', () {
      Get.reset();
      final controller = Get.put(MarketingUploadController());

      controller.onStateChanged('Odisha');
      controller.selectedDistrict.value = 'Khordha';
      expect(controller.selectedDistrict.value, 'Khordha');

      // Switch to Maharashtra
      controller.onStateChanged('Maharashtra');
      expect(controller.selectedDistrict.value, isNull);
      expect(controller.availableDistricts.contains('Pune'), isTrue);
      expect(controller.availableDistricts.contains('Khordha'), isFalse);
    });
  });
}
