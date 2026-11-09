import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/core/config/legal_urls.dart';
import 'package:mythdusk/core/utils/open_external_url.dart';

void main() {
  group('LegalUrls', () {
    test('privacy policy uses MythDusk path, not Dot Clash root', () {
      final uri = Uri.parse(LegalUrls.privacyPolicy);

      expect(uri.scheme, 'https');
      expect(uri.host, 'vividmemories-games.github.io');
      expect(uri.path, '/mythdusk/privacy-policy/');
      expect(LegalUrls.privacyPolicy.contains('/mythdusk/'), isTrue);
      expect(
        LegalUrls.privacyPolicy,
        isNot(equals('https://vividmemories-games.github.io/privacy-policy/')),
      );
    });

    test('all store-facing legal URLs stay under /mythdusk/', () {
      final paths = {
        LegalUrls.siteHome: '/mythdusk/',
        LegalUrls.privacyPolicy: '/mythdusk/privacy-policy/',
        LegalUrls.termsAndConditions: '/mythdusk/terms-and-conditions/',
        LegalUrls.contact: '/mythdusk/contact/',
        LegalUrls.deleteData: '/mythdusk/delete-data/',
      };

      for (final entry in paths.entries) {
        final uri = Uri.parse(entry.key);
        expect(uri.host, 'vividmemories-games.github.io');
        expect(uri.path, entry.value, reason: entry.key);
      }
    });

    test('support mailto targets MythDusk support inbox', () {
      final mailto = LegalUrls.supportMailto;
      expect(mailto.scheme, 'mailto');
      expect(mailto.path, LegalUrls.supportEmail);
      expect(mailto.queryParameters['subject'], 'MythDusk Support');
    });
  });

  group('openExternalUrl', () {
    test('rejects non-http(s)/mailto schemes without launching', () async {
      expect(await openExternalUrl('ftp://example.com'), isFalse);
      expect(await openExternalUrl('not a url'), isFalse);
      expect(await openExternalUrl(''), isFalse);
      expect(await openExternalUri(Uri.parse('javascript:alert(1)')), isFalse);
    });
  });
}
