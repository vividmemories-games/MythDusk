import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/firebase/firebase_bootstrap.dart';
import 'package:mythdusk/firebase/firebase_options.dart';

void main() {
  test('FlutterFire options point at the console project', () {
    expect(DefaultFirebaseOptions.android.projectId, 'mythdusk-ec0c7');
    expect(DefaultFirebaseOptions.ios.projectId, 'mythdusk-ec0c7');
    expect(DefaultFirebaseOptions.hasProductionOptions, isTrue);
    expect(
      DefaultFirebaseOptions.googleWebClientId,
      endsWith('.apps.googleusercontent.com'),
    );
  });

  test('prod flavor initializes Firebase without dart-define', () {
    expect(FirebaseBootstrap.shouldInitialize, isTrue);
  });
}
