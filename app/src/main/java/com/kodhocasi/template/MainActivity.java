package com.kodhocasi.template;

import androidx.appcompat.app.AppCompatActivity;
import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends AppCompatActivity {

    private WebView myWebView;
    // PHP'nin değiştireceği yer
    private String siteUrl = "DEGISTIR_URL"; 

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        myWebView = findViewById(R.id.webview);
        
        // Gelişmiş Ayarlar
        WebSettings webSettings = myWebView.getSettings();
        webSettings.setJavaScriptEnabled(true); // JS Açık
        webSettings.setDomStorageEnabled(true); // Veri kaydetme açık
        webSettings.setLoadWithOverviewMode(true);
        webSettings.setUseWideViewPort(true);

        // Linklerin uygulama içinde açılması için
        myWebView.setWebViewClient(new WebViewClient());
        
        myWebView.loadUrl(siteUrl);
    }

    // Geri tuşuna basıldığında geçmişe git, yoksa çık
    @Override
    public void onBackPressed() {
        if (myWebView.canGoBack()) {
            myWebView.goBack();
        } else {
            super.onBackPressed();
        }
    }
}
