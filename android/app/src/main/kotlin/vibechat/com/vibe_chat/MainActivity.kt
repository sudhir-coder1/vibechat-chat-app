package vibechat.com.vibe_chat

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.vibe_chat/media"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveImageToGallery") {
                val byteArray = call.argument<ByteArray>("bytes")
                val fileName = call.argument<String>("name") ?: "VibeChat_${System.currentTimeMillis()}.jpg"

                if (byteArray == null) {
                    result.error("INVALID_ARGUMENT", "Bytes array is null", null)
                    return@setMethodCallHandler
                }

                try {
                    val savedPath = saveImageToMediaStore(byteArray, fileName)
                    if (savedPath != null) {
                        result.success(savedPath)
                    } else {
                        result.error("SAVE_FAILED", "Failed to save image to MediaStore", null)
                    }
                } catch (e: Exception) {
                    result.error("EXCEPTION", e.localizedMessage, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveImageToMediaStore(bytes: ByteArray, fileName: String): String? {
        val resolver = applicationContext.contentResolver
        val imageDetails = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
            put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/VibeChat")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            } else {
                val directory = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "VibeChat")
                if (!directory.exists()) {
                    directory.mkdirs()
                }
                val file = File(directory, fileName)
                put(MediaStore.Images.Media.DATA, file.absolutePath)
            }
        }

        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, imageDetails) ?: return null

        try {
            resolver.openOutputStream(uri)?.use { outputStream ->
                outputStream.write(bytes)
                outputStream.flush()
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                imageDetails.clear()
                imageDetails.put(MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, imageDetails, null, null)
            }

            return uri.toString()
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
    }
}
