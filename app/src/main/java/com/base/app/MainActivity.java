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

    // !!! BURASI ÇOK ÖNEMLİ !!!
    // Script burayı hedef alacak. Boşluk bırakma.
    private String CONFIG_URL="REPLACE_THIS_URL"; 
    
    private LinearLayout container;
    private TextView statusText;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        ScrollView scrollView = new ScrollView(this);
        scrollView.setBackgroundColor(0xFFFFFFFF);
        
        container = new LinearLayout(this);
        container.setOrientation(LinearLayout.VERTICAL);
        container.setPadding(50, 80, 50, 50);
        container.setGravity(Gravity.CENTER_HORIZONTAL);
        scrollView.addView(container);
        setContentView(scrollView);

        statusText = new TextView(this);
        statusText.setText("Yükleniyor...\n" + CONFIG_URL); // Ekranda URL'yi görelim
        statusText.setTextSize(14);
        statusText.setGravity(Gravity.CENTER);
        statusText.setTextColor(0xFF555555);
        container.addView(statusText);

        new FetchConfigTask().execute(CONFIG_URL);
    }

    private class FetchConfigTask extends AsyncTask<String, Void, String> {
        @Override
        protected String doInBackground(String... urls) {
            StringBuilder result = new StringBuilder();
            try {
                if (urls[0].contains("REPLACE_THIS_URL")) {
                    return "SETUP_ERROR";
                }

                URL url = new URL(urls[0]);
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setConnectTimeout(15000);
                conn.setReadTimeout(15000);
                conn.setRequestMethod("GET");
                conn.setRequestProperty("User-Agent", "AppBuilder");
                
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

            if (result == null || result.startsWith("EXCEPTION") || result.startsWith("HTTP_ERROR") || result.equals("SETUP_ERROR")) {
                statusText.setText("⚠️ HATA OLUŞTU\n\n" + result);
                statusText.setTextColor(0xFFFF0000);
                return;
            }

            container.removeAllViews();
            try {
                JSONObject json = new JSONObject(result);
                String appTitle = json.optString("app_name", "Uygulama");
                
                TextView titleView = new TextView(MainActivity.this);
                titleView.setText(appTitle);
                titleView.setTextSize(26);
                titleView.setPadding(0, 0, 0, 60);
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
                statusText.setText("Veri Hatası: " + e.getMessage());
                container.addView(statusText);
            }
        }
    }

    private void createButton(String text, final String type, final String link) {
        Button btn = new Button(this);
        btn.setText(text);
        btn.setPadding(40, 30, 40, 30);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        params.setMargins(0, 0, 0, 30);
        btn.setLayoutParams(params);
        btn.setBackgroundColor(0xFF2196F3);
        btn.setTextColor(0xFFFFFFFF);

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
