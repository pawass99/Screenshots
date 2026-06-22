import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let instagramStoriesChannel = "screenshots/instagram_stories"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: instagramStoriesChannel,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(
          code: "share_failed",
          message: "Instagram sharing bridge is not available.",
          details: nil
        ))
        return
      }

      switch call.method {
      case "shareImageToStory":
        self.shareImageToInstagramStory(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func shareImageToInstagramStory(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard let arguments = call.arguments as? [String: Any],
      let imageBytes = arguments["imageBytes"] as? FlutterStandardTypedData,
      !imageBytes.data.isEmpty
    else {
      result(FlutterError(
        code: "invalid_image",
        message: "Story image is empty.",
        details: nil
      ))
      return
    }

    let facebookAppId = (arguments["facebookAppId"] as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !facebookAppId.isEmpty else {
      result(FlutterError(
        code: "missing_app_id",
        message: "Instagram Facebook App ID is required.",
        details: nil
      ))
      return
    }

    let encodedAppId = facebookAppId.addingPercentEncoding(
      withAllowedCharacters: .urlQueryAllowed
    ) ?? facebookAppId
    guard let instagramUrl = URL(
      string: "instagram-stories://share?source_application=\(encodedAppId)"
    ) else {
      result(FlutterError(
        code: "share_failed",
        message: "Instagram Stories URL is invalid.",
        details: nil
      ))
      return
    }

    guard UIApplication.shared.canOpenURL(instagramUrl) else {
      result(FlutterError(
        code: "instagram_not_installed",
        message: "Instagram is not installed.",
        details: nil
      ))
      return
    }

    let pasteboardItems: [String: Any] = [
      "com.instagram.sharedSticker.backgroundImage": imageBytes.data,
      "com.instagram.sharedSticker.backgroundTopColor": "#17130F",
      "com.instagram.sharedSticker.backgroundBottomColor": "#110E0A",
      "com.instagram.sharedSticker.appID": facebookAppId,
    ]
    UIPasteboard.general.setItems(
      [pasteboardItems],
      options: [.expirationDate: Date().addingTimeInterval(300)]
    )

    UIApplication.shared.open(instagramUrl, options: [:]) { success in
      if success {
        result(true)
      } else {
        result(FlutterError(
          code: "share_failed",
          message: "Could not open Instagram Stories.",
          details: nil
        ))
      }
    }
  }
}
