import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/social/domain/privacy_level.dart';

void main() {
  group('PrivacyLevel.value', () {
    test('devuelve string correcto', () {
      expect(PrivacyLevel.everyone.value, 'everyone');
      expect(PrivacyLevel.followers.value, 'followers');
      expect(PrivacyLevel.nobody.value, 'nobody');
    });
  });

  group('PrivacyLevel.fromString', () {
    test('mapea valores válidos', () {
      expect(PrivacyLevelX.fromString('everyone'), PrivacyLevel.everyone);
      expect(PrivacyLevelX.fromString('followers'), PrivacyLevel.followers);
      expect(PrivacyLevelX.fromString('nobody'), PrivacyLevel.nobody);
    });

    test('backward compat: friends → followers', () {
      expect(PrivacyLevelX.fromString('friends'), PrivacyLevel.followers);
    });

    test('default para null y desconocido', () {
      expect(PrivacyLevelX.fromString(null), PrivacyLevel.everyone);
      expect(PrivacyLevelX.fromString('xyz'), PrivacyLevel.everyone);
      expect(PrivacyLevelX.fromString(''), PrivacyLevel.everyone);
    });
  });

  group('PrivacyLevel.label', () {
    test('todos tienen label en español', () {
      expect(PrivacyLevel.everyone.label, 'Todos');
      expect(PrivacyLevel.followers.label, 'Seguidores');
      expect(PrivacyLevel.nobody.label, 'Nadie');
    });
  });
}
