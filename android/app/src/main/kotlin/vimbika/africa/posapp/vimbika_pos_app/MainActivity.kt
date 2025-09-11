package vimbika.africa.posapp.vimbika_pos_app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import sunmi.ds.DSKernel
import sunmi.ds.callback.IConnectionCallback

class MainActivity: FlutterActivity(){
    private val CHANNEL = "vimbika.pos/secondScreen"
    private var mDSKernel: DSKernel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        mDSKernel = DSKernel.newInstance()
        mDSKernel?.init(this, mConnectCallback)

        flutterEngine?.dartExecutor?.binaryMessenger?.let { MethodChannel(it, CHANNEL) }
            ?.setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateScreen" -> {
                        val html = call.argument<String>("html") ?: ""

//                        SecondScreenDisplay.getInstance().showHtml(mDSKernel, html)
                        result.success("Displayed on second screen")
                    }
                    "resetScreen" -> {
                        val html = "<html><body><h2>Welcome to Vimbika POS</h2></body></html>"
//                        SecondScreenDisplay.getInstance().showHtml(mDSKernel, html)
                        result.success("Reset screen")
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private val mConnectCallback = object : IConnectionCallback {
//        override fun onException(p0: Exception?) {}
        override fun onDisConnect() {
            TODO("Not yet implemented")
        }

        override fun onConnected(p0: IConnectionCallback.ConnState?) {
            TODO("Not yet implemented")
        }
    }
}
