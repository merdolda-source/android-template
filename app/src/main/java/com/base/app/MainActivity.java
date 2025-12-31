package com.base.app;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

public class MainActivity extends Activity {

    // SCRIPT BU SATIRI GÜNCELLEYECEK
    private String CONFIG_URL = "REPLACE_THIS_URL"; 
    
    private LinearLayout container;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Dinamik Arayüz (XML Yok)
        ScrollView scrollView = new ScrollView(this);
        scrollView.setBackgroundColor(0xFFF5F5F5); // Hafif Gri Arkaplan
        
        container = new LinearLayout(this);
        container.setOrientation(LinearLayout.VERTICAL);
        container.setPadding(40, 60, 40, 40);
        container.setGravity(Gravity.CENTER_HORIZONTAL);
        scrollView.addView(container);
        setContentView(scrollView);

        // Yükleniyor Mesajı
        TextView loading = new TextView(this);
        loading.setText("Yükleniyor...\nLütfen Bekleyin");
        loading.setTextSize(18);
        loading.setGravity(Gravity.CENTER);
        loading.setPadding(0, 100, 0, 0);
        container.addView(loading);

        // Config Çekme İşlemi
        new FetchConfigTask().execute(CONFIG_URL);
    }

    private class FetchConfigTask extends AsyncTask<String, Void, String> {
        @Override
        protected String doInBackground(String... urls) {
            StringBuilder result = new StringBuilder();
            try {
                if (urls[0].equals("REPLACE_THIS_URL")) return null; // Script çalışmamışsa

                URL url = new URL(urls[0]);
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setConnectTimeout(8000);
                conn.setReadTimeout(8000);
                conn.setRequestMethod("GET");
                conn.setRequestProperty("User-Agent", "AppFactory-Android");
                
                if (conn.getResponseCode() != 200) return "ERROR_NET";

                BufferedReader rd = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                String line;
                while ((line = rd.readLine()) != null) {
                    result.append(line);
                }
                rd.close();
                return result.toString();
            } catch (Exception e) {
                return null;
            }
        }

        @Override
        protected void onPostExecute(String result) {
            if (isFinishing()) return;
            container.removeAllViews();

            if (result == null || result.equals("ERROR_NET")) {
                showError("Bağlantı Hatası!\nİnternetinizi kontrol edin.");
                return;
            }

            try {
                JSONObject json = new JSONObject(result);
                String appTitle = json.optString("app_name", "Uygulamam");
                
                // Başlık
                TextView titleView = new TextView(MainActivity.this);
                titleView.setText(appTitle);
                titleView.setTextSize(26);
                titleView.setPadding(0, 0, 0, 60);
                titleView.setGravity(Gravity.CENTER);
                titleView.setTextColor(0xFF222222);
                container.addView(titleView);

                // Modülleri Listele
                JSONArray modules = json.getJSONArray("modules");
                for (int i = 0; i < modules.length(); i++) {
                    JSONObject item = modules.getJSONObject(i);
                    // active: true ise veya active alanı hiç yoksa göster
                    if (item.optBoolean("active", true)) {
                        createButton(item.getString("title"), item.getString("type"), item.getString("url"));
                    }
                }
            } catch (Exception e) {
                showError("Veri Hatası!\n" + e.getMessage());
            }
        }
    }

    private void showError(String msg) {
        TextView err = new TextView(this);
        err.setText(msg);
        err.setTextColor(0xFFFF0000);
        err.setTextSize(16);
        err.setGravity(Gravity.CENTER);
        container.addView(err);
    }

    private void createButton(String text, final String type, final String link) {
        Button btn = new Button(this);
        btn.setText(text);
        btn.setTextSize(16);
        btn.setPadding(40, 30, 40, 30);
        
        // Buton Tasarımı
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        params.setMargins(0, 0, 0, 30); // Alt boşluk
        btn.setLayoutParams(params);

        btn.setOnClickListener(v -> {
            try {
                if (type.equals("WEB") || type.equals("TELEGRAM")) {
                    // Linki tarayıcıda aç
                    Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(link));
                    startActivity(browserIntent);
                } else if (type.equals("IPTV")) {
                    // M3U Linkini DAHİLİ PLAYER ile aç
                    Intent intent = new Intent(MainActivity.this, PlayerActivity.class);
                    intent.putExtra("VIDEO_URL", link);
                    startActivity(intent);
                }
            } catch (Exception e) {
                Toast.makeText(MainActivity.this, "İşlem yapılamadı", Toast.LENGTH_SHORT).show();
            }
        });
        container.addView(btn);
    }
}
