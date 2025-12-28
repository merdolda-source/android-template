package __PACKAGE__;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.*;

public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);

        WebView w = new WebView(this);
        setContentView(w);

        WebSettings s = w.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);

        w.setWebViewClient(new WebViewClient());
        w.loadUrl(getString(R.string.app_url));
    }

    @Override
    public void onBackPressed() {
        if (w.canGoBack()) w.goBack();
        else finish();
    }
}
