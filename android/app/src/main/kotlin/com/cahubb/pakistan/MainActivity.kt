package com.cahubb.pakistan

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.cahubb.pakistan/whatsapp"
        ).setMethodCallHandler { call, result ->
            if (call.method != "openWhatsApp") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val phone = call.argument<String>("phone").orEmpty()
            val message = call.argument<String>("message").orEmpty()
            if (phone.isBlank()) {
                result.success(false)
                return@setMethodCallHandler
            }

            result.success(
                openWhatsAppPackage("com.whatsapp", phone, message) ||
                    openWhatsAppPackage("com.whatsapp.w4b", phone, message)
            )
        }
    }

    private fun openWhatsAppPackage(packageName: String, phone: String, message: String): Boolean {
        val uriBuilder = Uri.parse("https://wa.me/$phone").buildUpon()
        if (message.isNotBlank()) {
            uriBuilder.appendQueryParameter("text", message)
        }

        val intent = Intent(Intent.ACTION_VIEW, uriBuilder.build()).apply {
            setPackage(packageName)
        }

        return try {
            startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: SecurityException) {
            false
        }
    }
}
