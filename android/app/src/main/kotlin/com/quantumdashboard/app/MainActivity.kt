package com.quantumdashboard.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {
    private val downloadsChannelName = "quantum_dashboard/downloads"

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Create notification channel for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "quantum_dashboard_channel",
                "Quantum Dashboard Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for Quantum Dashboard app"
                enableVibration(true)
                setShowBadge(true)
            }
            
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            downloadsChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveBytesToDownloads" -> {
                    try {
                        val bytes = call.argument<ByteArray>("bytes")
                        val rawFileName = call.argument<String>("fileName")
                        val mimeType =
                            call.argument<String>("mimeType") ?: "application/octet-stream"

                        if (bytes == null || bytes.isEmpty()) {
                            result.error("EMPTY_FILE", "No file bytes were provided.", null)
                            return@setMethodCallHandler
                        }

                        val fileName = sanitizeFileName(rawFileName)
                        val saved = saveBytesToDownloads(bytes, fileName, mimeType)
                        result.success(saved)
                    } catch (error: Exception) {
                        result.error("SAVE_FAILED", error.message, null)
                    }
                }
                "openDownloadUri" -> {
                    try {
                        val uriValue = call.argument<String>("uri")
                        val mimeType =
                            call.argument<String>("mimeType") ?: "application/octet-stream"

                        if (uriValue.isNullOrBlank()) {
                            result.success(
                                mapOf(
                                    "opened" to false,
                                    "message" to "File URI not found."
                                )
                            )
                            return@setMethodCallHandler
                        }

                        openUri(Uri.parse(uriValue), mimeType)
                        result.success(mapOf("opened" to true, "message" to ""))
                    } catch (error: Exception) {
                        result.success(
                            mapOf(
                                "opened" to false,
                                "message" to (error.message ?: "Unable to open file.")
                            )
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveBytesToDownloads(
        bytes: ByteArray,
        fileName: String,
        mimeType: String
    ): Map<String, String?> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }

            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Unable to create file in Downloads.")

            resolver.openOutputStream(uri)?.use { output ->
                output.write(bytes)
            } ?: throw IllegalStateException("Unable to write file to Downloads.")

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)

            return mapOf(
                "fileName" to fileName,
                "displayPath" to "Downloads/$fileName",
                "filePath" to null,
                "uri" to uri.toString(),
                "mimeType" to mimeType
            )
        }

        @Suppress("DEPRECATION")
        val downloadsDir =
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!downloadsDir.exists()) {
            downloadsDir.mkdirs()
        }

        val file = File(downloadsDir, fileName)
        FileOutputStream(file).use { output ->
            output.write(bytes)
        }

        val uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            file
        )

        return mapOf(
            "fileName" to fileName,
            "displayPath" to file.absolutePath,
            "filePath" to file.absolutePath,
            "uri" to uri.toString(),
            "mimeType" to mimeType
        )
    }

    private fun openUri(uri: Uri, mimeType: String) {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mimeType)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun sanitizeFileName(rawFileName: String?): String {
        val cleaned = rawFileName
            ?.trim()
            ?.replace(Regex("[\\\\/:*?\"<>|]"), "_")
            .orEmpty()

        return cleaned.ifBlank { "download" }
    }
}
