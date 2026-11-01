package com.smartrent.smartrent_my

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.webkit.MimeTypeMap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val photoChannel = "smartrent_my/profile_photo"
    private val vehiclePhotoChannel = "smartrent_my/vehicle_photo"
    private val storageChannel = "smartrent_my/local_storage"
    private val pickPhotoRequest = 7104
    private val pickVehiclePhotoRequest = 7105
    private var pendingPhotoResult: MethodChannel.Result? = null
    private var pendingVehiclePhotoResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            vehiclePhotoChannel
        ).setMethodCallHandler { call, result ->
            if (call.method == "pickVehiclePhoto") {
                openVehiclePhotoPicker(result)
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            photoChannel
        ).setMethodCallHandler { call, result ->
            if (call.method == "deleteProfilePhoto") {
                val path = call.argument<String>("path")
                deletePrivateProfilePhoto(path)
                result.success(null)
                return@setMethodCallHandler
            }
            if (call.method == "pickProfilePhoto") {
                openProfilePhotoPicker(result)
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            storageChannel
        ).setMethodCallHandler { call, result ->
            if (call.method == "getAppFilesPath") {
                result.success(filesDir.absolutePath)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun openVehiclePhotoPicker(result: MethodChannel.Result) {
        if (pendingVehiclePhotoResult != null || pendingPhotoResult != null) {
            result.error(
                "picker_busy",
                "Another photo is already being selected.",
                null
            )
            return
        }
        pendingVehiclePhotoResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
        }
        try {
            startActivityForResult(intent, pickVehiclePhotoRequest)
        } catch (error: Exception) {
            pendingVehiclePhotoResult = null
            result.error(
                "picker_unavailable",
                "No photo picker is available on this device.",
                error.message
            )
        }
    }

    private fun openProfilePhotoPicker(result: MethodChannel.Result) {
        if (pendingPhotoResult != null) {
            result.error(
                "picker_busy",
                "A profile photo is already being selected.",
                null
            )
            return
        }
        pendingPhotoResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
        }
        try {
            startActivityForResult(intent, pickPhotoRequest)
        } catch (error: Exception) {
            pendingPhotoResult = null
            result.error(
                "picker_unavailable",
                "No photo picker is available on this device.",
                error.message
            )
        }
    }

    @Deprecated("Deprecated in Android")
    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickPhotoRequest && requestCode != pickVehiclePhotoRequest) {
            return
        }
        val selectingVehicle = requestCode == pickVehiclePhotoRequest
        val result = if (selectingVehicle) {
            pendingVehiclePhotoResult.also { pendingVehiclePhotoResult = null }
        } else {
            pendingPhotoResult.also { pendingPhotoResult = null }
        }
        if (resultCode != Activity.RESULT_OK) {
            result?.success(null)
            return
        }
        val uri = data?.data
        if (uri == null) {
            result?.error("photo_missing", "No photo was selected.", null)
            return
        }
        try {
            val saved = if (selectingVehicle) {
                copyPhotoToPrivateStorage(
                    uri = uri,
                    directoryName = "vehicles",
                    prefix = "vehicle",
                    cleanupExisting = false
                )
            } else {
                copyPhotoToPrivateStorage(
                    uri = uri,
                    directoryName = "profile",
                    prefix = "avatar",
                    cleanupExisting = true
                )
            }
            result?.success(saved.absolutePath)
        } catch (error: Exception) {
            result?.error(
                "photo_copy_failed",
                error.message ?: "The selected photo could not be saved.",
                null
            )
        }
    }

    private fun copyPhotoToPrivateStorage(
        uri: Uri,
        directoryName: String,
        prefix: String,
        cleanupExisting: Boolean
    ): File {
        val descriptorLength = contentResolver
            .openAssetFileDescriptor(uri, "r")
            ?.use { it.length } ?: -1
        if (descriptorLength > 8 * 1024 * 1024) {
            throw IllegalArgumentException("Choose a photo smaller than 8 MB.")
        }
        val mimeType = contentResolver.getType(uri)
        val extension = MimeTypeMap.getSingleton()
            .getExtensionFromMimeType(mimeType)
            ?.lowercase()
            ?.takeIf { it in setOf("jpg", "jpeg", "png", "webp") }
            ?: "jpg"
        val targetDirectory = File(filesDir, directoryName).apply { mkdirs() }
        val destination = File(
            targetDirectory,
            "${prefix}_${System.currentTimeMillis()}.$extension"
        )
        val input = contentResolver.openInputStream(uri)
            ?: throw IllegalArgumentException("The selected photo could not be opened.")
        try {
            input.use { source ->
                destination.outputStream().use { output ->
                    val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                    var totalBytes = 0L
                    while (true) {
                        val count = source.read(buffer)
                        if (count < 0) {
                            break
                        }
                        totalBytes += count
                        if (totalBytes > 8 * 1024 * 1024) {
                            throw IllegalArgumentException(
                                "Choose a photo smaller than 8 MB."
                            )
                        }
                        output.write(buffer, 0, count)
                    }
                }
            }
        } catch (error: Exception) {
            destination.delete()
            throw error
        }
        if (cleanupExisting) {
            targetDirectory.listFiles()
                ?.filter { it != destination && it.name.startsWith("${prefix}_") }
                ?.forEach { it.delete() }
        }
        return destination
    }

    private fun deletePrivateProfilePhoto(path: String?) {
        if (path.isNullOrBlank()) {
            return
        }
        val profileDirectory = File(filesDir, "profile").canonicalFile
        val selectedFile = File(path).canonicalFile
        if (selectedFile.parentFile == profileDirectory) {
            selectedFile.delete()
        }
    }
}
