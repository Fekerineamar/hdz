package dz.dzds.dzds_agent

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Telephony
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        const val SMS_METHOD_CHANNEL = "dzds_agent/sms"
        const val SMS_EVENT_CHANNEL = "dzds_agent/sms_events"
        const val PERMISSION_REQUEST_CODE = 1001
    }

    private var smsReceiver: BroadcastReceiver? = null
    private var eventSink: EventChannel.EventSink? = null
    private var latestSmsBody: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    startListening()
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    stopListening()
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> result.success(hasSmsPermission())
                    "requestPermission" -> {
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(
                                Manifest.permission.RECEIVE_SMS,
                                Manifest.permission.READ_SMS
                            ),
                            PERMISSION_REQUEST_CODE
                        )
                        result.success(true)
                    }
                    "getLatestSms" -> result.success(latestSmsBody)
                    else -> result.notImplemented()
                }
            }
    }

    private fun startListening() {
        if (smsReceiver != null) return
        smsReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val body = extractSmsBody(intent)
                if (body != null) {
                    latestSmsBody = body
                    eventSink?.success(body)
                }
            }
        }
        val filter = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(smsReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(smsReceiver, filter)
        }
    }

    private fun stopListening() {
        smsReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (_: IllegalArgumentException) {
            }
        }
        smsReceiver = null
    }

    private fun extractSmsBody(intent: Intent?): String? {
        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isEmpty()) return null
        val sb = StringBuilder()
        for (msg in messages) {
            sb.append(msg.displayMessageBody ?: "")
        }
        return sb.toString()
    }

    private fun hasSmsPermission(): Boolean {
        return ActivityCompat.checkSelfPermission(
            this,
            Manifest.permission.RECEIVE_SMS
        ) == PackageManager.PERMISSION_GRANTED
    }

    override fun onDestroy() {
        stopListening()
        super.onDestroy()
    }
}
