import 'package:flutter/material.dart';

class AppConstants {
  // ===========================================================================
  // 1. ORDER STATUSES & FILTERS
  // ===========================================================================
  static const List<String> orderStatuses = [
    'Pending',
    'Approved',
    'Production',
    'Dispatched',
    'Delivered',
  ];

  static const List<String> orderFilterOptions = [
    'All',
    'Pending',
    'Approved',
    'Production',
    'Dispatched',
    'Delivered',
  ];

  // ===========================================================================
  // 2. PRODUCT COLOR OPTIONS (EXACT 10 VALUES)
  // ===========================================================================
  static const List<String> colorOptions = [
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

  static const Map<String, Color> colorHexMap = {
    'Black': Color(0xFF000000),
    'White': Color(0xFFFFFFFF),
    'Navy Blue': Color(0xFF000080),
    'Royal Blue': Color(0xFF4169E1),
    'Grey': Color(0xFF808080),
    'Maroon': Color(0xFF800000),
    'Red': Color(0xFFFF0000),
    'Sky': Color(0xFF87CEEB),
    'Bottle Green': Color(0xFF006A4E),
    'Other': Colors.transparent,
  };

  static Color getColor(String colorName) {
    if (colorHexMap.containsKey(colorName)) {
      return colorHexMap[colorName]!;
    }
    // Backward compatibility normalization
    final lower = colorName.toLowerCase().trim();
    if (lower == 'navy' || lower == 'navy blue') return const Color(0xFF000080);
    if (lower == 'royal blue') return const Color(0xFF4169E1);
    if (lower == 'sky' || lower == 'sky blue') return const Color(0xFF87CEEB);
    if (lower == 'bottle green') return const Color(0xFF006A4E);
    if (lower == 'light grey' || lower == 'dark grey' || lower == 'grey') return const Color(0xFF808080);
    if (lower == 'maroon') return const Color(0xFF800000);
    if (lower == 'red') return const Color(0xFFFF0000);
    if (lower == 'white') return Colors.white;
    if (lower == 'black') return Colors.black;
    return Colors.transparent;
  }

  // ===========================================================================
  // 3. PRODUCT MATERIAL / FABRIC OPTIONS (EXACT 11 VALUES)
  // ===========================================================================
  static const List<String> materialOptions = [
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

  // ===========================================================================
  // 4. NECK TYPES & PRODUCT TYPES
  // ===========================================================================
  static const List<String> neckTypes = [
    'Round Neck',
    'Polo',
    'V-Neck',
    'Hoodie',
    'High Neck',
    'Collar',
  ];

  static const List<String> productTypes = [
    'T-Shirt',
    'Polo',
    'Hoodie',
    'Sweatshirt',
    'Tracksuit',
    'Jacket',
    'Jersey',
    'Other',
  ];

  // ===========================================================================
  // 5. ODISHA DISTRICTS (ALL 30 CANONICAL DISTRICTS)
  // ===========================================================================
  static const List<String> odishaDistricts = [
    'Angul',
    'Balangir',
    'Balasore',
    'Bargarh',
    'Bhadrak',
    'Boudh',
    'Cuttack',
    'Deogarh',
    'Dhenkanal',
    'Gajapati',
    'Ganjam',
    'Jagatsinghpur',
    'Jajpur',
    'Jharsuguda',
    'Kalahandi',
    'Kandhamal',
    'Kendrapara',
    'Kendujhar',
    'Khordha',
    'Koraput',
    'Malkangiri',
    'Mayurbhanj',
    'Nabarangpur',
    'Nayagarh',
    'Nuapada',
    'Puri',
    'Rayagada',
    'Sambalpur',
    'Subarnapur',
    'Sundargarh',
  ];

  // ===========================================================================
  // 6. INDIAN STATES & UNION TERRITORIES
  // ===========================================================================
  static const List<String> indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  // ===========================================================================
  // 7. STATE TO DISTRICTS MAPPING
  // ===========================================================================
  static const Map<String, List<String>> stateDistricts = {
    'Odisha': odishaDistricts,
    'Maharashtra': [
      'Ahmednagar', 'Akola', 'Amravati', 'Aurangabad', 'Beed', 'Bhandara', 'Buldhana',
      'Chandrapur', 'Dhule', 'Gadchiroli', 'Gondia', 'Hingoli', 'Jalgaon', 'Jalna',
      'Kolhapur', 'Latur', 'Mumbai City', 'Mumbai Suburban', 'Nagpur', 'Nanded',
      'Nandurbar', 'Nashik', 'Osmanabad', 'Palghar', 'Parbhani', 'Pune', 'Raigad',
      'Ratnagiri', 'Sangli', 'Satara', 'Sindhudurg', 'Solapur', 'Thane', 'Wardha',
      'Washim', 'Yavatmal'
    ],
    'Delhi': [
      'Central Delhi', 'East Delhi', 'New Delhi', 'North Delhi', 'North East Delhi',
      'North West Delhi', 'Shahdara', 'South Delhi', 'South East Delhi', 'South West Delhi',
      'West Delhi'
    ],
    'Gujarat': [
      'Ahmedabad', 'Amreli', 'Anand', 'Aravalli', 'Banaskantha', 'Bharuch', 'Bhavnagar',
      'Botad', 'Chhota Udaipur', 'Dahod', 'Dang', 'Devbhoomi Dwarka', 'Gandhinagar',
      'Gir Somnath', 'Jamnagar', 'Junagadh', 'Kheda', 'Kutch', 'Mahisagar', 'Mehsana',
      'Morbi', 'Narmada', 'Navsari', 'Panchmahal', 'Patan', 'Porbandar', 'Rajkot',
      'Sabarkantha', 'Surat', 'Surendranagar', 'Tapi', 'Vadodara', 'Valsad'
    ],
    'Karnataka': [
      'Bagalkot', 'Ballari', 'Belagavi', 'Bengaluru Rural', 'Bengaluru Urban', 'Bidar',
      'Chamarajanagar', 'Chikkaballapur', 'Chikkamagaluru', 'Chitradurga', 'Dakshina Kannada',
      'Davanagere', 'Dharwad', 'Gadag', 'Hassan', 'Haveri', 'Kalaburagi', 'Kodagu',
      'Kolar', 'Koppal', 'Mandya', 'Mysuru', 'Raichur', 'Ramanagara', 'Shivamogga',
      'Tumakuru', 'Udupi', 'Uttara Kannada', 'Vijayapura', 'Yadgir'
    ],
    'Tamil Nadu': [
      'Ariyalur', 'Chengalpattu', 'Chennai', 'Coimbatore', 'Cuddalore', 'Dharmapuri',
      'Dindigul', 'Erode', 'Kallakurichi', 'Kanchipuram', 'Kanyakumari', 'Karur',
      'Krishnagiri', 'Madurai', 'Mayiladuthurai', 'Nagapattinam', 'Namakkal', 'Nilgiris',
      'Perambalur', 'Pudukkottai', 'Ramanathapuram', 'Ranipet', 'Salem', 'Sivaganga',
      'Tenkasi', 'Thanjavur', 'Theni', 'Thoothukudi', 'Tiruchirappalli', 'Tirunelveli',
      'Tirupathur', 'Tiruppur', 'Tiruvallur', 'Tiruvannamalai', 'Tiruvarur', 'Vellore',
      'Viluppuram', 'Virudhunagar'
    ],
    'West Bengal': [
      'Alipurduar', 'Bankura', 'Birbhum', 'Cooch Behar', 'Dakshin Dinajpur', 'Darjeeling',
      'Hooghly', 'Howrah', 'Jalpaiguri', 'Jhargram', 'Kalimpong', 'Kolkata', 'Malda',
      'Murshidabad', 'Nadia', 'North 24 Parganas', 'Paschim Bardhaman', 'Paschim Medinipur',
      'Purba Bardhaman', 'Purba Medinipur', 'Purulia', 'South 24 Parganas', 'Uttar Dinajpur'
    ],
  };

  static List<String> getDistrictsForState(String? stateName) {
    if (stateName == null || stateName.isEmpty) return [];
    if (stateDistricts.containsKey(stateName)) {
      return stateDistricts[stateName]!;
    }
    return [];
  }
}
