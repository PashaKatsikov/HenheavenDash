enum ServeRoute {
  diner,
  web,
  undecided;

  String get storageValue => switch (this) {
    ServeRoute.diner => 'diner',
    ServeRoute.web => 'web',
    ServeRoute.undecided => 'undecided',
  };

  static ServeRoute parse(String? value) => switch (value) {
    'web' || 'portal' => ServeRoute.web,
    'diner' || 'native' || 'game' => ServeRoute.diner,
    _ => ServeRoute.undecided,
  };
}

class GateReply {
  const GateReply({
    required this.accepted,
    this.url,
    this.expiresAt,
    this.reason,
  });

  factory GateReply.fromJson(Map<String, dynamic> json) {
    final rawExpiry = json['expires'];
    return GateReply(
      accepted: json['ok'] == true,
      url: json['url'] is String ? json['url'] as String : null,
      expiresAt: rawExpiry is num
          ? rawExpiry.toInt()
          : int.tryParse(rawExpiry?.toString() ?? ''),
      reason: json['message']?.toString(),
    );
  }

  factory GateReply.rejected(String reason) =>
      GateReply(accepted: false, reason: reason);

  final bool accepted;
  final String? url;
  final int? expiresAt;
  final String? reason;

  bool get hasDestination => accepted && (url?.isNotEmpty ?? false);
}

sealed class GateTarget {
  const GateTarget();
}

final class DinerTarget extends GateTarget {
  const DinerTarget();
}

final class WebTarget extends GateTarget {
  const WebTarget(this.url, {this.coldLaunch = false});

  final String url;
  final bool coldLaunch;
}

final class OfflineTarget extends GateTarget {
  const OfflineTarget({required this.returnToDiner});

  final bool returnToDiner;
}
