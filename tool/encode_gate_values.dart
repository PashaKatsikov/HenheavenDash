// ignore_for_file: avoid_print

import 'dart:typed_data';

/// Keep this salt byte-for-byte identical to `_pantrySalt` in
/// lib/gate/core/glaze_codec.dart. Change it there AND here together, then
/// re-run this tool and paste the printed arrays into DashGateConfig.
const List<int> _pantrySalt = <int>[
  0x48, 0x76, 0x6E, 0x44, 0x61, 0x73, 0x68, 0x5F,
  0x32, 0x36, 0x21, 0x67, 0x6C, 0x7A,
];

Uint8List _pantryStream(int length) {
  var hash = 0x811C9DC5;
  for (final byte in _pantrySalt) {
    hash = (hash ^ (byte & 0xff)) & 0xffffffff;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  var state = hash == 0 ? 0x9E3779B9 : hash;
  final out = Uint8List(length);
  for (var index = 0; index < length; index++) {
    state = (state * 1664525 + 1013904223) & 0xffffffff;
    out[index] = (state >> 23) & 0xff;
  }
  return out;
}

List<int> mask(String value) {
  final bytes = Uint8List.fromList(value.codeUnits);
  final key = _pantryStream(bytes.length);
  return List<int>.generate(
    bytes.length,
    (index) => (((bytes[index] + ((index * 31) & 0xff)) & 0xff) ^ key[index]) & 0xff,
  );
}

String unmask(List<int> encoded) {
  final key = _pantryStream(encoded.length);
  return String.fromCharCodes(
    List<int>.generate(encoded.length, (index) {
      final mixed = (encoded[index] ^ key[index]) & 0xff;
      return (mixed - ((index * 31) & 0xff)) & 0xff;
    }),
  );
}

void main() {
  const values = <String, String>{
    'endpoint': 'https://henhavendash.com/config.php',
    'privacy': 'https://henhavendash.com/privacy-policy.html',
    'support': 'https://henhavendash.com/support.html',
    'gcd': 'https://gcdsdk.appsflyer.com/install_data/v5.0/',
    'webkit': '605.1.15',
    'safari': '18.5',
    'safariTail': '604.1',
    'appsFlyerKey': 'w3L6z4WTmGuFtNSMjtetpS',
    'firebaseProject': '890446547222',
    'oneLinkHost': 'https://henheavendash.onelink.me/LA0c/r9fas0zc',
  };

  for (final entry in values.entries) {
    final encoded = mask(entry.value);
    print('${entry.key}: <int>[${encoded.join(', ')}]');
    if (unmask(encoded) != entry.value) {
      throw StateError('Round-trip failed for ${entry.key}');
    }
  }
  print('VERIFY: all values round-tripped');
}
