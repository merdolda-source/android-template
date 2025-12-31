package com.base.app;

import android.app.Activity; // Düz Activity kullanıyoruz (Çökmemesi için)
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

// AppCompatActivity YERİNE Activity KULLANIYORUZ
public class MainActivity extends Activity {

    // SCRIPT BURAYI DEGISTIRECEK
    private String CONFIG_URL = "https://panel.siteniz.com/default.json";
    
    private LinearLayout container;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Arka planı beyaz yap
        ScrollView scrollView = new ScrollView(this);
        scrollView.setBackgroundColor(0xFFFFFFFF); // Beyaz Arkaplan
        
        container = new LinearLayout(this);
        container.setOrientation(LinearLayout.VERTICAL);
        container.setPadding(50, 50, 50, 50);
        container.setGravity(Gravity.CENTER_HORIZONTAL);
        scrollView.addView(container);
        setContentView(scrollView);

        // Yükleniyor yazısı
        TextView loading = new TextView(this);
        loading.setText("Yükleniyor...");
        loading.setTextSize(20);
        loading.setGravity(Gravity.CENTER);
        loading.setPadding(0, 50, 0, 0);
        container.addView(loading);

        // Config Çek
        new FetchConfigTask().execute(CONFIG_URL);
    }

    private class FetchConfigTask extends AsyncTask<String, Void, String> {
        @Override
        protected String doInBackground(String... urls) {
            StringBuilder result = new StringBuilder();
            try {
                URL url = new URL(urls[0]);
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setConnectTimeout(5000); // 5 saniye zaman aşımı
                conn.setRequestMethod("GET");
                
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
            // Eğer activity kapandıysa işlem yapma
            if (isFinishing()) return;

            container.removeAllViews();
            if (result != null) {
                try {
                    JSONObject json = new JSONObject(result);
                    String appTitle = json.optString("app_name", "Uygulamam");
                    
                    // Başlık
                    TextView titleView = new TextView(MainActivity.this);
                    titleView.setText(appTitle);
                    titleView.setTextSize(24);
                    titleView.setGravity(Gravity.CENTER);
                    titleView.setPadding(0, 0, 0, 50);
                    titleView.setTextColor(0xFF000000); // Siyah yazı
                    container.addView(titleView);

                    JSONArray modules = json.getJSONArray("modules");
                    for (int i = 0; i < modules.length(); i++) {
                        JSONObject item = modules.getJSONObject(i);
                        if (item.optBoolean("active", true)) {
                            createButton(item.getString("title"), item.getString("type"), item.getString("url"));
                        }
                    }

                } catch (Exception e) {
                    showError("Veri Hatası: " + e.getMessage());
                }
            } else {
                showError("Bağlantı Hatası! İnternetinizi kontrol edin.");
            }
        }
    }

    private void showError(String msg) {
        TextView err = new TextView(this);
        err.setText(msg);
        err.setTextColor(0xFFFF0000); // Kırmızı
        container.addView(err);
    }

    private void createButton(String text, final String type, final String link) {
        Button btn = new Button(this);
        btn.setText(text);
        
        // Buton araları açılsın
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        params.setMargins(0, 10, 0, 20);
        btn.setLayoutParams(params);

        btn.setOnClickListener(v -> {
            try {
                if (type.equals("WEB") || type.equals("TELEGRAM")) {
                    Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(link));
                    startActivity(browserIntent);
                } else if (type.equals("IPTV")) {
                    Intent videoIntent = new Intent(Intent.ACTION_VIEW);
                    videoIntent.setDataAndType(Uri.parse(link), "video/*");
                    startActivity(videoIntent);
                }
            } catch (Exception e) {
                Toast.makeText(MainActivity.this, "Uygulama bulunamadı", Toast.LENGTH_SHORT).show();
            }
        });
        container.addView(btn);
    }
}
