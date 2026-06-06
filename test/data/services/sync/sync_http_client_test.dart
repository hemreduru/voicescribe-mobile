import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_http_client.dart';

void main() {
  test(
    'postJson sends a UTF-8 body so Turkish text syncs (regression: latin1 crash)',
    () async {
      // Spin up a throwaway local server that echoes back what it received.
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      String? receivedTitle;
      String? receivedContentType;
      unawaited(
        server.first.then((request) async {
          receivedContentType = request.headers.contentType?.toString();
          // Decode the raw bytes as UTF-8 — the client must have encoded them
          // as UTF-8, not latin1.
          final body = await utf8.decoder.bind(request).join();
          receivedTitle =
              (jsonDecode(body) as Map<String, Object?>)['title'] as String?;
          request.response.statusCode = 200;
          request.response.write('{"data":{}}');
          await request.response.close();
        }),
      );

      // 'ı' (U+0131) and 'İ' (U+0130) are NOT representable in latin1; the old
      // request.write path threw "Contains invalid characters" on these.
      const turkish = 'Fenerbahçe yönetimi finansal açıdan zorlu — ışık İğne';

      final result = await const SyncHttpClient().postJson(
        url: 'http://${server.address.host}:${server.port}/api/v1/sync/push',
        token: 'test-token',
        payload: const {'title': turkish},
      );

      expect(result.statusCode, 200);
      expect(receivedTitle, turkish);
      expect(receivedContentType, contains('utf-8'));

      await server.close(force: true);
    },
  );
}
