import 'package:flutter_test/flutter_test.dart';

import 'package:dzds_agent/models/domain.dart';

void main() {
  test('UserSession parses the session JSON', () {
    final s = UserSession.fromJson({
      'user': {
        'id': 'abc123',
        'realname': 'Djallal',
        'realnameAr': 'جلال فكيرين',
        'username': 'djallalakira',
      },
    });
    expect(s.id, 'abc123');
    expect(s.displayName, 'جلال فكيرين');
  });

  test('CaptchaPuzzle parses the puzzle payload', () {
    final p = CaptchaPuzzle.fromJson({
      'data': {
        'originalImageBase64': 'aGVsbG8=',
        'jigsawImageBase64': 'd29ybGQ=',
        'token': 'token-123',
      },
    });
    expect(p.token, 'token-123');
    expect(p.originalImageBase64, 'aGVsbG8=');
  });
}
