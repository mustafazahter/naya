import 'package:naya_api/server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test('/health ayakta olduğunu söyler', () async {
    final handler = buildHandler();
    final response = await handler(
      Request('GET', Uri.parse('http://localhost/health')),
    );
    expect(response.statusCode, 200);
    expect(await response.readAsString(), contains('"ok"'));
  });
}
