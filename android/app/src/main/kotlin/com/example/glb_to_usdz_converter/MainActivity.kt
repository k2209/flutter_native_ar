package com.example.nativear_1 // <-- your package name

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.util.Log // <-- add this!

class MainActivity: FlutterActivity() {
    private val CHANNEL = "ar_intent_channel"
    private val TAG = "AR_LAUNCHER"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "launchARIntent") {
                val url = call.argument<String>("url")
                val launched = launchARIntent(url)
                result.success(launched)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun launchARIntent(glbUrl: String?): Boolean {
        if (glbUrl == null) return false

        val sceneViewerIntent = Intent(Intent.ACTION_VIEW)
        val intentUri = Uri.parse("https://arvr.google.com/scene-viewer/1.0?file=$glbUrl&mode=ar_preferred")
        sceneViewerIntent.data = intentUri
        sceneViewerIntent.setPackage("com.google.ar.core")
        sceneViewerIntent.putExtra("browser_fallback_url", glbUrl)

        return try {
            startActivity(sceneViewerIntent)
            Log.i(TAG, "Launched with Google Scene Viewer (ARCore)")
            true
        } catch (e: Exception) {
            // Fallback: Try to launch in browser if ARCore is not installed
            val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(glbUrl))
            try {
                startActivity(browserIntent)
                Log.w(TAG, "Launched in browser fallback: $glbUrl")
                true
            } catch (ex: Exception) {
                Log.e(TAG, "Could not launch in browser either: ${ex.localizedMessage}")
                false
            }
        }
    }
}
