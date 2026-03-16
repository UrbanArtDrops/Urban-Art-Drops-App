import "package:url_launcher/url_launcher.dart";

abstract interface class ExternalDownloadLauncher {
  Future<bool> launchDownload(String url);
}

class UrlLauncherExternalDownloadLauncher implements ExternalDownloadLauncher {
  const UrlLauncherExternalDownloadLauncher();

  @override
  Future<bool> launchDownload(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }

    return launchUrl(uri, mode: LaunchMode.platformDefault);
  }
}
