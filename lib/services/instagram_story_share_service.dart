import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class InstagramStoryShareService {
  const InstagramStoryShareService();

  static const _channel = MethodChannel('screenshots/instagram_stories');
  static const _facebookAppId = String.fromEnvironment(
    'INSTAGRAM_FACEBOOK_APP_ID',
  );

  Future<void> shareTemplate(GlobalKey repaintBoundaryKey) async {
    if (!_isSupportedPlatform) {
      throw const InstagramStoryShareException(
        'Instagram Stories sharing is only available on Android and iOS.',
      );
    }

    final facebookAppId = _facebookAppId.trim();
    if (facebookAppId.isEmpty) {
      throw const InstagramStoryShareException(
        'Missing INSTAGRAM_FACEBOOK_APP_ID dart define.',
      );
    }

    final imageBytes = await _capturePng(repaintBoundaryKey);

    try {
      await _channel.invokeMethod<void>('shareImageToStory', {
        'imageBytes': imageBytes,
        'facebookAppId': facebookAppId,
      });
    } on PlatformException catch (error) {
      throw InstagramStoryShareException(_messageForPlatformError(error));
    } on MissingPluginException {
      throw const InstagramStoryShareException(
        'Instagram Stories sharing is not available on this platform.',
      );
    }
  }

  bool get _isSupportedPlatform {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<Uint8List> _capturePng(GlobalKey repaintBoundaryKey) async {
    await WidgetsBinding.instance.endOfFrame;

    final boundaryContext = repaintBoundaryKey.currentContext;
    final renderObject = boundaryContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw const InstagramStoryShareException(
        'Story template is not ready to share yet.',
      );
    }

    if (renderObject.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      await WidgetsBinding.instance.endOfFrame;
    }

    final width = renderObject.size.width;
    final pixelRatio = width <= 0 ? 1.0 : math.max(1.0, 1080 / width);
    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (byteData == null) {
      throw const InstagramStoryShareException(
        'Could not render the story template.',
      );
    }

    return byteData.buffer.asUint8List();
  }

  String _messageForPlatformError(PlatformException error) {
    return switch (error.code) {
      'instagram_not_installed' => 'Instagram is not installed.',
      'missing_app_id' => 'Missing Instagram Facebook App ID.',
      'invalid_image' => 'Story template image is invalid.',
      'share_failed' => 'Could not open Instagram Stories.',
      _ => error.message ?? 'Could not share to Instagram Stories.',
    };
  }
}

class InstagramStoryShareException implements Exception {
  const InstagramStoryShareException(this.message);

  final String message;

  @override
  String toString() => message;
}
