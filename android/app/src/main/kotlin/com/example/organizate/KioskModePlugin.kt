package com.example.organizate

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class KioskModePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.example.organizate/kiosk_mode")
        channel.setMethodCallHandler(this)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startKioskMode" -> {
                startKioskMode(result)
            }
            "stopKioskMode" -> {
                stopKioskMode(result)
            }
            "isKioskModeActive" -> {
                result.success(isLockTaskModeActive())
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun startKioskMode(result: MethodChannel.Result) {
        try {
            val act = activity
            if (act == null) {
                result.error("NO_ACTIVITY", "No se pudo obtener la actividad", null)
                return
            }

            // startLockTask() inicia el modo screen pinning
            // En Android 5.0+ bloquea la navegación fuera de la app
            // Requiere que el usuario confirme la primera vez (o que sea device owner)
            act.startLockTask()
            result.success(true)
        } catch (e: Exception) {
            result.error("KIOSK_ERROR", e.message, null)
        }
    }

    private fun stopKioskMode(result: MethodChannel.Result) {
        try {
            val act = activity
            if (act == null) {
                result.error("NO_ACTIVITY", "No se pudo obtener la actividad", null)
                return
            }

            act.stopLockTask()
            result.success(true)
        } catch (e: Exception) {
            result.error("KIOSK_ERROR", e.message, null)
        }
    }

    private fun isLockTaskModeActive(): Boolean {
        val act = activity ?: return false
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return activityManager.lockTaskModeState == ActivityManager.LOCK_TASK_MODE_PINNED
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }
}
