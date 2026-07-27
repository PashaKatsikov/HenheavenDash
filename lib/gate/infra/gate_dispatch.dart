import 'dart:convert';

import '../config/dash_gate_config.dart';
import '../core/gate_models.dart';
import 'gate_store.dart';
import 'masked_agent.dart';
import 'trail_signal.dart';

/// POSTs the flat attribution body to the config endpoint and parses the
/// reply. On success with a URL, the destination is cached for returning
/// launches.
class GateDispatch {
  GateDispatch(this._agent, this._store);

  final MaskedAgent _agent;
  final GateStore _store;

  Future<GateReply> request(Map<String, dynamic> payload) async {
    if (!DashGateConfig.grayCredentialsReady) {
      return GateReply.rejected('credentials_unavailable');
    }
    try {
      gateTrace(() => '[HD.DISPATCH] request ${jsonEncode(payload)}');
      final response = await _agent
          .post(
            Uri.parse(DashGateConfig.endpoint),
            headers: const <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      gateTrace(
        () => '[HD.DISPATCH] response ${response.statusCode} ${response.body}',
      );
      if (response.statusCode != 200) {
        return GateReply.rejected('http_${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return GateReply.rejected('invalid_response');
      final reply = GateReply.fromJson(Map<String, dynamic>.from(decoded));
      if (reply.hasDestination) {
        await _store.cacheUrl(reply.url!, reply.expiresAt);
      }
      return reply;
    } catch (error) {
      gateTrace(() => '[HD.DISPATCH] failed: $error');
      return GateReply.rejected('network_failure');
    }
  }
}
