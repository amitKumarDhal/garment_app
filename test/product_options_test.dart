import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoobbel/utils/constants/app_constants.dart';

void main() {
  group('Product Color & Material Options Exact Lists Tests', () {
    test('Color options list matches EXACT 10 specified values', () {
      const expectedColors = [
        'Black',
        'White',
        'Navy Blue',
        'Royal Blue',
        'Grey',
        'Maroon',
        'Red',
        'Sky',
        'Bottle Green',
        'Other',
      ];

      expect(AppConstants.colorOptions, expectedColors);
      expect(AppConstants.colorOptions.length, 10);
    });

    test('Color helper maps standard colors correctly', () {
      expect(AppConstants.getColor('Black'), const Color(0xFF000000));
      expect(AppConstants.getColor('White'), const Color(0xFFFFFFFF));
      expect(AppConstants.getColor('Navy Blue'), const Color(0xFF000080));
      expect(AppConstants.getColor('Royal Blue'), const Color(0xFF4169E1));
      expect(AppConstants.getColor('Grey'), const Color(0xFF808080));
      expect(AppConstants.getColor('Maroon'), const Color(0xFF800000));
      expect(AppConstants.getColor('Red'), const Color(0xFFFF0000));
      expect(AppConstants.getColor('Sky'), const Color(0xFF87CEEB));
      expect(AppConstants.getColor('Bottle Green'), const Color(0xFF006A4E));
      expect(AppConstants.getColor('Other'), Colors.transparent);
    });

    test('Material / Fabric options list matches EXACT 11 specified values', () {
      const expectedMaterials = [
        'Spun Matty',
        'PC Matty',
        'US Polo',
        'Techno Matty',
        'Drifit',
        'Dot knit',
        'Serena',
        'Red Tag',
        'Oversized',
        'Promotional',
        'Others',
      ];

      expect(AppConstants.materialOptions, expectedMaterials);
      expect(AppConstants.materialOptions.length, 11);
    });
  });
}
