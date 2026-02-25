import 'package:equatable/equatable.dart';

/// Represents a country with its dial code and phone number mask.
class Country extends Equatable {
  const Country({
    required this.name,
    required this.flag,
    required this.dialCode,
    required this.mask,
    required this.isoCode,
  });
  final String name;
  final String flag;
  final String dialCode;
  final String mask;
  final String isoCode;

  /// A list of commonly used countries.
  /// In a production app, this could be fetched from a service or expanded.
  static const List<Country> all = [
    Country(
      name: 'Turkey',
      flag: '🇹🇷',
      dialCode: '+90',
      mask: '000-000-00-00',
      isoCode: 'TR',
    ),
    Country(
      name: 'United States',
      flag: '🇺🇸',
      dialCode: '+1',
      mask: '(000) 000-0000',
      isoCode: 'US',
    ),
    Country(
      name: 'United Kingdom',
      flag: '🇬🇧',
      dialCode: '+44',
      mask: '0000 000000',
      isoCode: 'GB',
    ),
    Country(
      name: 'Germany',
      flag: '🇩🇪',
      dialCode: '+49',
      mask: '0000 0000000',
      isoCode: 'DE',
    ),
    Country(
      name: 'France',
      flag: '🇫🇷',
      dialCode: '+33',
      mask: '0 00 00 00 00',
      isoCode: 'FR',
    ),
  ];

  @override
  List<Object?> get props => [isoCode];
}
