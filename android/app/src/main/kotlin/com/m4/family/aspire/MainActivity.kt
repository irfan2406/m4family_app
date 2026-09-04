package com.m4.family.aspire

import android.app.DownloadManager
import android.app.PictureInPictureParams
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val pipChannel = "m4/pip"
    private val downloadChannel = "m4/download"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, pipChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enter" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            enterPictureInPictureMode(
                                PictureInPictureParams.Builder().build()
                            )
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // Hands the URL to Android's DownloadManager, which saves into the
        // public Downloads folder and posts its own progress notification.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enqueue" -> {
                        val url = call.argument<String>("url")
                        if (url.isNullOrBlank()) {
                            result.error("bad_url", "No URL to download", null)
                            return@setMethodCallHandler
                        }
                        val fileName = call.argument<String>("fileName") ?: "M4-Document"
                        val title = call.argument<String>("title") ?: fileName
                        try {
                            val request = DownloadManager.Request(Uri.parse(url))
                                .setTitle(title)
                                .setDescription("M4 Family")
                                .setNotificationVisibility(
                                    DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED
                                )
                                .setDestinationInExternalPublicDir(
                                    Environment.DIRECTORY_DOWNLOADS,
                                    fileName
                                )
                                .setAllowedOverMetered(true)
                                .setAllowedOverRoaming(true)
                            val manager =
                                getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
                            result.success(manager.enqueue(request))
                        } catch (e: Exception) {
                            result.error("enqueue_failed", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
