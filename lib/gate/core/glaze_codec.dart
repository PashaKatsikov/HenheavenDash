import 'dart:typed_data';

/// Position-keyed XOR cipher over an FNV-1a-seeded LCG keystream.
///
/// The salt below MUST stay unique to this app (it is the only project-level
/// secret that seeds every encoded credential). Change it and re-run
/// `dart run tool/encode_gate_values.dart` to regenerate the byte arrays in
/// [DashGateConfig].
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

/// Reverses [maskGlaze]: `plain[i] = ((enc[i] ^ key[i]) - i*31) & 0xff`.
String unmaskGlaze(List<int> encoded) {
  if (encoded.isEmpty) return '';
  final key = _pantryStream(encoded.length);
  final plain = Uint8List(encoded.length);
  for (var index = 0; index < encoded.length; index++) {
    final mixed = (encoded[index] ^ key[index]) & 0xff;
    plain[index] = (mixed - ((index * 31) & 0xff)) & 0xff;
  }
  return String.fromCharCodes(plain);
}
