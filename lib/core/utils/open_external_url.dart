import 'package:url_launcher/url_launcher.dart';

/// Opens [url] externally (browser or mail app). Returns `false` if launch fails.
Future<bool> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  return openExternalUri(uri);
}

/// Opens [uri] externally. Allows `http(s)` and `mailto` only.
Future<bool> openExternalUri(Uri uri) async {
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'https' && scheme != 'http' && scheme != 'mailto') {
    return false;
  }
  return launchUrl(
    uri,
    mode: scheme == 'mailto'
        ? LaunchMode.platformDefault
        : LaunchMode.externalApplication,
  );
}
