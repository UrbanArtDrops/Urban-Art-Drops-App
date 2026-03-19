import "package:flutter/foundation.dart";
import "package:flutter_web_auth_2/flutter_web_auth_2.dart";

class ExternalProviderAuthLauncher {
  const ExternalProviderAuthLauncher();

  Uri buildCallbackUri() {
    if (kIsWeb) {
      return Uri.parse("${Uri.base.origin}/auth.html");
    }

    return Uri.parse("urbanartdrops-auth://oauth/callback");
  }

  Future<Uri> authenticate({
    required String authorizationUrl,
    Uri? callbackUri,
  }) async {
    final effectiveCallbackUri = callbackUri ?? buildCallbackUri();
    final isHttpCallback =
        effectiveCallbackUri.scheme == "http" ||
        effectiveCallbackUri.scheme == "https";
    final result = await FlutterWebAuth2.authenticate(
      url: authorizationUrl,
      callbackUrlScheme: effectiveCallbackUri.scheme,
      options: FlutterWebAuth2Options(
        windowName: "UrbanArtDropsAuth",
        debugOrigin: kIsWeb ? Uri.base.origin : null,
        httpsHost: isHttpCallback ? effectiveCallbackUri.host : null,
        httpsPath: isHttpCallback ? effectiveCallbackUri.path : null,
      ),
    );

    return Uri.parse(result);
  }
}
