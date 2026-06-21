import 'dart:ui' show PlatformDispatcher;

import 'package:openfoodfacts/openfoodfacts.dart';

/// Maps the device locale’s ISO region to Open Food Facts’ `cc` parameter.
///
/// OFF search without `cc` ranks by global popularity, which surfaces a lot of
/// EU-packaged products (e.g. Lidl DE) even for English queries.
OpenFoodFactsCountry resolveOffDeviceCountry() {
  final raw = PlatformDispatcher.instance.locale.countryCode;
  if (raw == null || raw.isEmpty) {
    return OpenFoodFactsCountry.USA;
  }
  final parsed = OpenFoodFactsCountry.fromOffTag(raw);
  return parsed ?? OpenFoodFactsCountry.USA;
}
