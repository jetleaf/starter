/// ID and time utilities. Centralised so the entire codebase agrees on
/// time source (UTC) and id shape — no stray `DateTime.now()` calls.
library;

import 'dart:math';

import 'package:jetleaf/jetleaf.dart';

class Ids {
  Ids._();

  static final Random _random = Random.secure();
  static const String _alphabet = '0123456789abcdefghijklmnopqrstuvwxyz';

  static String randomId([int length = 16]) {
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(_alphabet[_random.nextInt(_alphabet.length)]);
    }
    return buffer.toString();
  }

  /// Prefixed, sortable-ish id: `<prefix>_<epochMillis><random>`.
  static String prefixed(String prefix) =>
      '${prefix}_${DateTime.now().toUtc().millisecondsSinceEpoch.toRadixString(36)}${randomId(6)}';
}

@Component()
class SocialClock {
  const SocialClock();

  DateTime now() => DateTime.now().toUtc();
}
