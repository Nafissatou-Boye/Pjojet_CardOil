// lib/utils/countries.dart
class Country {
  final String code;
  final String name;
  final String flag;
  final String dialCode;

  const Country({
    required this.code,
    required this.name,
    required this.flag,
    required this.dialCode,
  });
}

class Countries {
  static const List<Country> westAfrica = [
    Country(code: 'SN', name: 'Sénégal', flag: '🇸🇳', dialCode: '+221'),
    Country(code: 'GM', name: 'Gambie', flag: '🇬🇲', dialCode: '+220'),
    Country(code: 'MR', name: 'Mauritanie', flag: '🇲🇷', dialCode: '+222'),
    Country(code: 'ML', name: 'Mali', flag: '🇲🇱', dialCode: '+223'),
    Country(code: 'CI', name: 'Côte d\'Ivoire', flag: '🇨🇮', dialCode: '+225'),
    Country(code: 'BF', name: 'Burkina Faso', flag: '🇧🇫', dialCode: '+226'),
    Country(code: 'NE', name: 'Niger', flag: '🇳🇪', dialCode: '+227'),
    Country(code: 'TG', name: 'Togo', flag: '🇹🇬', dialCode: '+228'),
    Country(code: 'BJ', name: 'Bénin', flag: '🇧🇯', dialCode: '+229'),
    Country(code: 'GN', name: 'Guinée', flag: '🇬🇳', dialCode: '+224'),
    Country(code: 'GW', name: 'Guinée-Bissau', flag: '🇬🇼', dialCode: '+245'),
    Country(code: 'SL', name: 'Sierra Leone', flag: '🇸🇱', dialCode: '+232'),
    Country(code: 'LR', name: 'Liberia', flag: '🇱🇷', dialCode: '+231'),
    Country(code: 'GH', name: 'Ghana', flag: '🇬🇭', dialCode: '+233'),
    Country(code: 'NG', name: 'Nigeria', flag: '🇳🇬', dialCode: '+234'),
    Country(code: 'CV', name: 'Cap-Vert', flag: '🇨🇻', dialCode: '+238'),
  ];
}