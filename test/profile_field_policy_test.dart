import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/profile/domain/profile_field_policy.dart';

void main() {
  test('client and function field sets do not overlap', () {
    expect(
      ProfileFieldPolicy.clientWritable
          .intersection(ProfileFieldPolicy.functionOnly),
      isEmpty,
    );
    expect(ProfileFieldPolicy.isFunctionOnly('coins'), isTrue);
    expect(ProfileFieldPolicy.isClientWritable('coins'), isFalse);
    expect(ProfileFieldPolicy.isClientWritable('selectedHeroId'), isTrue);
    expect(ProfileFieldPolicy.schemaVersion, 14);
  });

  test('clientPatch strips economy fields', () {
    final patch = ProfileFieldPolicy.clientPatch({
      'schemaVersion': 14,
      'selectedHeroId': 'mage',
      'coins': 9999,
      'gems': 9999,
      'lives': 99,
      'displayName': 'Ash',
    });
    expect(patch.containsKey('coins'), isFalse);
    expect(patch.containsKey('gems'), isFalse);
    expect(patch['displayName'], 'Ash');
    expect(patch['selectedHeroId'], 'mage');
  });

  test('firestore rules deny client economy writes', () {
    final rules = File('firestore.rules').readAsStringSync();
    expect(rules, contains("allow create: if false"));
    expect(rules, contains('coinReward'));
    expect(rules, contains('clientUserKeys'));
    expect(rules, contains("allow update, delete: if false"));
    expect(rules.contains("allow read: if true"), isFalse);
  });
}
