/// Hosted legal pages for MythDusk (GitHub Pages).
///
/// Dot Clash uses the site root; MythDusk uses the `/mythdusk/` path prefix so
/// store listings and in-app links never open the wrong product's policy.
abstract final class LegalUrls {
  static const siteHome = 'https://vividmemories-games.github.io/mythdusk/';

  static const privacyPolicy =
      'https://vividmemories-games.github.io/mythdusk/privacy-policy/';

  static const termsAndConditions =
      'https://vividmemories-games.github.io/mythdusk/terms-and-conditions/';

  static const contact =
      'https://vividmemories-games.github.io/mythdusk/contact/';

  static const deleteData =
      'https://vividmemories-games.github.io/mythdusk/delete-data/';

  static const supportEmail = 'vividmemoriesgames@gmail.com';

  /// Prefills a support email; falls back to [contact] if mailto fails.
  static Uri get supportMailto => Uri(
        scheme: 'mailto',
        path: supportEmail,
        queryParameters: const {'subject': 'MythDusk Support'},
      );
}
