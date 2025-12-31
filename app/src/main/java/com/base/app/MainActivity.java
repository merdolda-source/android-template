package com.base.app;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.Gravity;
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

    // EĞER SİTEN HTTP İSE (SADECE http://) ANDROID BUNU ENGELLER!
    // GÜVENLİK İÇİN HTTPS:// OLMASI GEREKİR.
    private String CONFIG_URL = "REPLACE_THIS_URL"; 
    
    private LinearLayout container;
    private TextView statusText;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        ScrollView scrollView = new ScrollView(this);
        scrollView.setBackgroundColor(0xFFF0F0F0);
        
        container = new LinearLayout(this);
        container.setOrientation(LinearLayout.VERTICAL);
        container.setPadding(50, 50, 50, 50);
        container.setGravity(Gravity.CENTER_HORIZONTAL);
        scrollView.addView(container);
        setContentView(scrollView);

        statusText = new TextView(this);
        statusText.setText("Bağlantı deneniyor...\n\nURL: " + CONFIG_URL);
        statusText.setTextSize(14);
        statusText.setGravity(Gravity.CENTER);
        container.addView(statusText);

        new FetchConfigTask().execute(CONFIG_URL);
    }

    private class FetchConfigTask extends AsyncTask<String, Void, String> {
        @Override
        protected String doInBackground(String... urls) {
            StringBuilder result = new StringBuilder();
            try {
                if (urls[0].contains("REPLACE_THIS_URL")) {
                    return "HATA: URL Değişmemiş! Script çalışmıyor.";
                }

                URL url = new URL(urls[0]);
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setConnectTimeout(10000);
                conn.setReadTimeout(10000);
                conn.setRequestMethod("GET");
                // User Agent ekliyoruz (Bazı hostingler botsanırsa engeller)
                conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Android)");

                int responseCode = conn.getResponseCode();
                if (responseCode != 200) {
                    return "SUNUCU HATASI: Kod " + responseCode;
                }

                BufferedReader rd = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                String line;
                while ((line = rd.readLine()) != null) {
                    result.append(line);
                }
                rd.close();
                return result.toString();

            } catch (java.net.UnknownHostException e) {
                return "DNS HATASI: Site adresi bulunamadı.\nHosting adresini kontrol et.";
            } catch (java.io.IOException e) {
                if (e.getMessage().contains("Cleartext HTTP traffic")) {
                    return "GÜVENLİK HATASI: Siteniz 'HTTP'.\nAndroid sadece 'HTTPS' kabul eder.\nManifest ayarı yapılmalı.";
                }
                return "BAĞLANTI HATASI: " + e.getMessage();
            } catch (Exception e) {
                return "GENEL HATA: " + e.toString();
            }
        }

        @Override
        protected void onPostExecute(String result) {
            if (isFinishing()) return;

            // Eğer sonuç JSON değilse HATA mesajıdır
            if (result == null || !result.trim().startsWith("{")) {
                statusText.setText("⚠️ BAŞARISIZ OLDU ⚠️\n\n" + result);
                statusText.setTextColor(0xFFFF0000); // Kırmızı
                return;
            }

            // Başarılıysa ekranı temizle ve butonları koy
            container.removeAllViews();
            try {
                JSONObject json = new JSONObject(result);
                String appTitle = json.optString("app_name", "Uygulama");
                
                TextView titleView = new TextView(MainActivity.this);
                titleView.setText(appTitle);
                titleView.setTextSize(24);
                titleView.setPadding(0, 0, 0, 50);
                titleView.setGravity(Gravity.CENTER);
                titleView.setTextColor(0xFF000000);
                container.addView(titleView);

                JSONArray modules = json.getJSONArray("modules");
                for (int i = 0; i < modules.length(); i++) {
                    JSONObject item = modules.getJSONObject(i);
                    if (item.optBoolean("active", true)) {
                        createButton(item.getString("title"), item.getString("type"), item.getString("url"));
                    }
                }
            } catch (Exception e) {
                statusText.setText("JSON BOZUK: " + e.getMessage() + "\n\nGelen Veri: " + result);
                container.addView(statusText);
            }
        }
    }

    private void createButton(String text, final String type, final String link) {
        Button btn = new Button(this);
        btn.setText(text);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        params.setMargins(0, 10, 0, 20);
        btn.setLayoutParams(params);

        btn.setOnClickListener(v -> {
            try {
                if (type.equals("IPTV")) {
                    Intent intent = new Intent(MainActivity.this, PlayerActivity.class);
                    intent.putExtra("VIDEO_URL", link);
                    startActivity(intent);
                } else {
                    Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(link));
                    startActivity(browserIntent);
                }
            } catch (Exception e) {
                Toast.makeText(MainActivity.this, "Hata", Toast.LENGTH_SHORT).show();
            }
        });
        container.addView(btn);
    }
}
