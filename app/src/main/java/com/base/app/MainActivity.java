package com.base.app;

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
import androidx.appcompat.app.AppCompatActivity;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

public class MainActivity extends AppCompatActivity {

    // SCRIPT BURAYI DEGISTIRECEK
    private String CONFIG_URL = "https://panel.siteniz.com/default.json";
    
    private LinearLayout container;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Dinamik Layout (XML Kullanmadan)
        ScrollView scrollView = new ScrollView(this);
        container = new LinearLayout(this);
        container.setOrientation(LinearLayout.VERTICAL);
        container.setPadding(50, 50, 50, 50);
        container.setGravity(Gravity.CENTER_HORIZONTAL);
        scrollView.addView(container);
        setContentView(scrollView);

        // Yükleniyor yazısı
        TextView loading = new TextView(this);
        loading.setText("Menü Yükleniyor...");
        loading.setTextSize(20);
        container.addView(loading);

        // Config Çek
        new FetchConfigTask().execute(CONFIG_URL);
    }

    // Arka Planda JSON Çekme İşlemi
    private class FetchConfigTask extends AsyncTask<String, Void, String> {
        @Override
        protected String doInBackground(String... urls) {
            StringBuilder result = new StringBuilder();
            try {
                URL url = new URL(urls[0]);
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
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
            container.removeAllViews();
            if (result != null) {
                try {
                    JSONObject json = new JSONObject(result);
                    String appTitle = json.optString("app_name", "Uygulamam");
                    
                    // Başlık Ekle
                    TextView titleView = new TextView(MainActivity.this);
                    titleView.setText(appTitle);
                    titleView.setTextSize(24);
                    titleView.setGravity(Gravity.CENTER);
                    titleView.setPadding(0, 0, 0, 50);
                    container.addView(titleView);

                    // Butonları Oluştur
                    JSONArray modules = json.getJSONArray("modules");
                    for (int i = 0; i < modules.length(); i++) {
                        JSONObject item = modules.getJSONObject(i);
                        if (item.getBoolean("active")) {
                            createButton(item.getString("title"), item.getString("type"), item.getString("url"));
                        }
                    }

                } catch (Exception e) {
                    Toast.makeText(MainActivity.this, "JSON Hatası", Toast.LENGTH_SHORT).show();
                }
            } else {
                Toast.makeText(MainActivity.this, "İnternet Bağlantısı Yok", Toast.LENGTH_SHORT).show();
            }
        }
    }

    private void createButton(String text, final String type, final String link) {
        Button btn = new Button(this);
        btn.setText(text);
        btn.setPadding(20, 20, 20, 20);
        
        btn.setOnClickListener(v -> {
            if (type.equals("WEB") || type.equals("TELEGRAM")) {
                // Tarayıcıda veya Telegramda aç
                Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(link));
                startActivity(browserIntent);
            } else if (type.equals("IPTV")) {
                // Video Player'da aç (VLC vb.)
                Intent videoIntent = new Intent(Intent.ACTION_VIEW);
                videoIntent.setDataAndType(Uri.parse(link), "video/*");
                try {
                    startActivity(videoIntent);
                } catch (Exception e) {
                    Toast.makeText(MainActivity.this, "Video oynatıcı bulunamadı!", Toast.LENGTH_SHORT).show();
                }
            }
        });
        container.addView(btn);
    }
}
