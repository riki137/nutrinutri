package sk.popelis.nutrinutri

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import com.google.android.gms.oss.licenses.OssLicensesMenuActivity

class MainActivity : FlutterActivity() {
    private val CHANNEL = "sk.popelis.nutrinutri/licenses"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "showLicenses") {
                startActivity(Intent(this, OssLicensesMenuActivity::class.java))
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
