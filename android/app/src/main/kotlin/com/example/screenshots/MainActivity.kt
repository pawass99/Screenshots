package com.example.screenshots

import android.content.ClipData
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "screenshots/instagram_stories"
        const val INSTAGRAM_PACKAGE = "com.instagram.android"
        const val ADD_TO_STORY_ACTION = "com.instagram.share.ADD_TO_STORY"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareImageToStory" -> shareImageToInstagramStory(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun shareImageToInstagramStory(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val imageBytes = call.argument<ByteArray>("imageBytes")
        if (imageBytes == null || imageBytes.isEmpty()) {
            result.error("invalid_image", "Story image is empty.", null)
            return
        }

        val facebookAppId = call.argument<String>("facebookAppId")?.trim().orEmpty()
        if (facebookAppId.isEmpty()) {
            result.error("missing_app_id", "Instagram Facebook App ID is required.", null)
            return
        }

        val storyFile = writeStoryImage(imageBytes)
        val storyUri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            storyFile,
        )

        val intent = Intent(ADD_TO_STORY_ACTION).apply {
            setPackage(INSTAGRAM_PACKAGE)
            setDataAndType(storyUri, "image/png")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            clipData = ClipData.newUri(contentResolver, "Screenshot story", storyUri)
            putExtra("source_application", facebookAppId)
        }

        if (intent.resolveActivity(packageManager) == null) {
            result.error("instagram_not_installed", "Instagram is not installed.", null)
            return
        }

        grantUriPermission(
            INSTAGRAM_PACKAGE,
            storyUri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION,
        )

        try {
            startActivity(intent)
            result.success(true)
        } catch (error: Exception) {
            result.error("share_failed", error.localizedMessage, null)
        }
    }

    private fun writeStoryImage(imageBytes: ByteArray): File {
        val storyDirectory = File(cacheDir, "instagram_stories").apply {
            mkdirs()
        }
        val storyFile = File(storyDirectory, "screenshot_story_${System.currentTimeMillis()}.png")
        storyFile.writeBytes(imageBytes)
        return storyFile
    }
}
