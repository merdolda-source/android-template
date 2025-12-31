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

    // !!! DOKUNMA !!!
    // Panelden "APK Üret" dediğinde script buraya senin siteni yazacak.
    private String CONFIG_URL = "REPLACE_THIS_URL"; 
    
    private LinearLayout container;
    private TextView statusText;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Beyaz Arkaplan ve Kaydırma Özelliği
        ScrollView scrollView = new ScrollView(this);
        scrollView.setBackgroundColor(0xFFFFFFFF);
        
        container = new LinearLayout(this);
        container.setOrientation(LinearLayout.VERTICAL);
        container.setPadding(50, 80, 50, 50);
        container.setGravity(Gravity.CENTER_HORIZONTAL);
        scrollView.addView(container);
        setContentView(scrollView);

        // Durum Mesajı
        statusText = new TextView(this);
        statusText.setText("Sunucuya Bağlanılıyor...\n\nLütfen Bekleyin");
        statusText.setTextSize(16);
        statusText.setGravity(Gravity.CENTER);
        statusText.setTextColor(0xFF555555);
        container.addView(statusText);

        // Config Çekme İşlemini Başlat
        new FetchConfigTask().execute(CONFIG_URL);
    }

    // Arka Planda Veri Çekme
    private class FetchConfigTask extends AsyncTask<String, Void, String> {
        @Override
        protected String doInBackground(String... urls) {
            StringBuilder result = new StringBuilder();
            try {
                // Eğer URL değişmemişse Script çalışmamış demektir
                if (urls[0].contains("REPLACE_THIS_URL")) {
                    return "SETUP_ERROR";
                }

                URL url = new URL(urls[0]);
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setConnectTimeout(15000); // 15 Saniye bekle
                conn.setReadTimeout(15000);
                conn.setRequestMethod("GET");
                conn.setRequestProperty("User-Agent", "AppBuilder-Android-Client");
                
                int responseCode = conn.getResponseCode();
                if (responseCode != 200) {
                    return "HTTP_ERROR:" + responseCode;
                }

                BufferedReader rd = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                String line;
                while ((line = rd.readLine()) != null) {
                    result.append(line);
                }
                rd.close();
                return result.toString();

            } catch (Exception e) {
                return "EXCEPTION:" + e.getMessage();
            }
        }

        @Override
        protected void onPostExecute(String result) {
            if (isFinishing()) return;

            if (result == null || result.startsWith("EXCEPTION") || result.startsWith("HTTP_ERROR")) {
                statusText.setText("⚠️ Bağlantı Hatası!\n\nİnternetinizi kontrol edin.\n\nDetay: " + result);
                statusText.setTextColor(0xFFFF0000);
                return;
            }

            if (result.equals("SETUP_ERROR")) {
                statusText.setText("⚠️ KURULUM HATASI\n\nGitHub Scripti URL'yi değiştiremedi.\nLütfen Panel Ayarlarını Kontrol Edin.");
                statusText.setTextColor(0xFFFF0000);
                return;
            }

            // Başarılı ise ekranı temizle ve butonları diz
            container.removeAllViews();
            try {
                JSONObject json = new JSONObject(result);
                
                // Uygulama Başlığı
                String appTitle = json.optString("app_name", "Uygulama");
                TextView titleView = new TextView(MainActivity.this);
                titleView.setText(appTitle);
                titleView.setTextSize(26);
                titleView.setPadding(0, 0, 0, 60);
                titleView.setGravity(Gravity.CENTER);
                titleView.setTextColor(0xFF000000); // Siyah
                container.addView(titleView);

                // Modülleri Listele
                JSONArray modules = json.getJSONArray("modules");
                if (modules.length() == 0) {
                    TextView empty = new TextView(MainActivity.this);
                    empty.setText("Henüz içerik eklenmemiş.");
                    container.addView(empty);
                }

                for (int i = 0; i < modules.length(); i++) {
                    JSONObject item = modules.getJSONObject(i);
                    // 'active' alanı true ise veya hiç yoksa göster
                    if (item.optBoolean("active", true)) {
                        createButton(item.getString("title"), item.getString("type"), item.getString("url"));
                    }
                }
            } catch (Exception e) {
                statusText.setText("Veri Hatası: " + e.getMessage());
                container.addView(statusText);
            }
        }
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
        
        // Buton Rengi (Mavimsi)
        btn.setBackgroundColor(0xFF2196F3);
        btn.setTextColor(0xFFFFFFFF); // Beyaz Yazı

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
                Toast.makeText(MainActivity.this, "Hata: " + e.getMessage(), Toast.LENGTH_SHORT).show();
            }
        });
        container.addView(btn);
    }
}
