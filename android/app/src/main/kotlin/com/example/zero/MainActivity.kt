package com.example.zero

import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val methodChannelName = "zero/deep_links"
    private val eventChannelName = "zero/deep_links/events"
    private var eventSink: EventChannel.EventSink? = null
    private var pendingLink: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            methodChannelName,
        ).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "getInitialLink" -> result.success(pendingLink ?: intent?.dataString)
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            eventChannelName,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    pendingLink?.let {
                        eventSink?.success(it)
                        pendingLink = null
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            },
        )

        captureIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureIntent(intent)
    }

    private fun captureIntent(intent: Intent?) {
        val deepLink = intent?.dataString ?: return
        pendingLink = deepLink
        eventSink?.success(deepLink)
    }
}
