package com.kodhocasi.template;

import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {

    private WebView myWebView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        myWebView = findViewById(R.id.webview);
        WebSettings webSettings = myWebView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);

        // Linklerin tarayıcıda değil uygulama içinde açılmasını sağlar
        myWebView.setWebViewClient(new WebViewClient());

        // OTOMASYON BURADAKİ "REPLACE_THIS_URL" YAZISINI DEĞİŞTİRECEK
        myWebView.loadUrl("REPLACE_THIS_URL");
    }

    @Override
    public void onBackPressed() {
        if (myWebView.canGoBack()) {
            myWebView.goBack();
        } else {
            super.onBackPressed();
        }
    }
}
