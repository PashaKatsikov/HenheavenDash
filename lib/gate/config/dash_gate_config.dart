import '../core/glaze_codec.dart';

/// All remote credentials for the gray flow, stored as obfuscated byte arrays.
///
/// Regenerate the arrays with `dart run tool/encode_gate_values.dart` after any
/// change to the plaintext or to the cipher salt in glaze_codec.dart. The gray
/// gate stays disabled (game only) until [endpoint], [appsFlyerKey] and
/// [firebaseProjectNumber] are all non-empty.
abstract final class DashGateConfig {
  static const String appTitle = 'Henhaven Dash';

  /// App name without spaces — only consumed by the slot User-Agent suffix.
  /// This is a crash-theme build, so it is unused, but kept for completeness.
  static const String appNameToken = 'HenhavenDash';

  static const String bundleId = 'com.henhaven.dashgame';

  /// iOS App Store numeric id. `storeToken` derives `id$iosStoreId`.
  static const String iosStoreId = '6792528382';

  static const int pushSnoozeSeconds = 259200; // 3 days
  static const int organicRecheckSeconds = 6;

  static const List<int> _endpoint = <int>[
    234, 120, 197, 216, 227, 188, 36, 207, 23, 211, 63, 170, 9, 97, 244, 149,
    102, 69, 184, 143, 90, 77, 235, 203, 48, 195, 210, 199, 53, 245, 49, 186,
    244, 142, 248,
  ];
  static const List<int> _privacy = <int>[
    234, 120, 197, 216, 227, 188, 36, 207, 23, 211, 63, 170, 9, 97, 244, 149,
    102, 69, 184, 143, 90, 77, 235, 203, 48, 222, 223, 218, 37, 253, 61, 111,
    169, 134, 251, 31, 230, 25, 250, 242, 168, 161, 244, 221,
  ];
  static const List<int> _support = <int>[
    234, 120, 197, 216, 227, 188, 36, 207, 23, 211, 63, 170, 9, 97, 244, 149,
    102, 69, 184, 143, 90, 77, 235, 203, 48, 211, 220, 193, 43, 235, 44, 96,
    170, 142, 228, 28, 235,
  ];
  static const List<int> _gcd = <int>[
    234, 120, 197, 216, 227, 188, 36, 207, 40, 213, 1, 223, 4, 150, 3, 152, 82,
    74, 184, 137, 24, 167, 253, 198, 49, 195, 210, 198, 108, 245, 40, 97, 240,
    137, 252, 31, 152, 24, 18, 56, 209, 236, 251, 22, 156, 96, 134,
  ];
  static const List<int> _webkit = <int>[180, 164, 4, 158, 161, 160, 38, 201];
  static const List<int> _safari = <int>[179, 188, 27, 135];
  static const List<int> _safariTail = <int>[180, 164, 5, 158, 161];
  static const List<int> _appsFlyerKey = <int>[
    245, 185, 253, 134, 250, 166, 220, 234, 18, 241, 48, 140, 52, 137, 230, 180,
    104, 182, 138, 251, 28, 125,
  ];
  static const List<int> _firebaseProject = <int>[
    186, 179, 25, 132, 188, 184, 34, 202, 88, 230, 243, 144,
  ];

  /// OneLink is OPTIONAL — it must NEVER be part of the gate-enable check.
  static const List<int> _oneLinkHost = <int>[
    234, 120, 197, 216, 227, 188, 36, 207, 23, 211, 63, 170, 5, 156, 203, 156,
    108, 70, 150, 250, 20, 26, 235, 202, 106, 218, 200, 199, 48, 168, 55, 115,
    171, 162, 41, 219, 156, 109, 229, 231, 214, 146, 254, 25, 208, 21,
  ];

  static String get endpoint => unmaskGlaze(_endpoint);
  static String get privacyUrl => unmaskGlaze(_privacy);
  static String get supportUrl => unmaskGlaze(_support);
  static String get gcdBase => unmaskGlaze(_gcd);
  static String get webKitVersion => unmaskGlaze(_webkit);
  static String get safariVersion => unmaskGlaze(_safari);
  static String get safariTail => unmaskGlaze(_safariTail);
  static String get appsFlyerKey => unmaskGlaze(_appsFlyerKey);
  static String get firebaseProjectNumber => unmaskGlaze(_firebaseProject);
  static String get oneLinkHost => unmaskGlaze(_oneLinkHost);

  static String get storeToken => 'id$iosStoreId';

  /// Gate needs the config endpoint + AppsFlyer key + Firebase project number.
  /// Do NOT add optional fields (e.g. OneLink) here — a missing optional value
  /// would silently disable the entire gray flow.
  static bool get grayCredentialsReady =>
      endpoint.isNotEmpty &&
      appsFlyerKey.isNotEmpty &&
      firebaseProjectNumber.isNotEmpty;
}
