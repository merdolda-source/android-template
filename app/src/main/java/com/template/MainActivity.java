package com.ornek.webviewapp;

import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    // PHP buradaki URL'yi değiştirecek
    private String hedefUrl = "DEGISTIR_URL"; 

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        WebView webView = new WebView(this);
        
        // JavaScript ve DOM depolamayı aç
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setDomStorageEnabled(true);
        
        // Linklerin tarayıcıda değil uygulama içinde açılmasını sağlar
        webView.setWebViewClient(new WebViewClient());
        
        webView.loadUrl(hedefUrl);
        setContentView(webView);
    }
}
