package com.base.app;

import android.os.Bundle;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import org.json.JSONObject;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

public class MainActivity extends AppCompatActivity {

    private String m3uUrl = "";
    private String appName = "";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Basit bir arayüz oluşturuyoruz (Layout XML kullanmadan kodla)
        // Normalde layout dosyası kullanılır ama tek dosya istediğin için buraya gömdüm.
        setContentView(R.layout.activity_main); 
        
        TextView titleView = findViewById(R.id.txtTitle);
        TextView urlView = findViewById(R.id.txtUrl);
        Button playButton = findViewById(R.id.btnPlay);

        // 1. Config Yükle
        loadConfig();

        // 2. Verileri Ekrana Bas
        titleView.setText(appName);
        urlView.setText(m3uUrl);

        // 3. Buton Aksiyonu
        playButton.setOnClickListener(v -> {
            Toast.makeText(this, "Oynatılıyor: " + m3uUrl, Toast.LENGTH_SHORT).show();
            // BURAYA VIDEO PLAYER ACILMA KODU GELECEK
        });
    }

    private void loadConfig() {
        try {
            // assets/config.json dosyasını oku
            InputStream is = getAssets().open("config.json");
            int size = is.available();
            byte[] buffer = new byte[size];
            is.read(buffer);
            is.close();

            String jsonString = new String(buffer, StandardCharsets.UTF_8);
            JSONObject jsonObject = new JSONObject(jsonString);

            appName = jsonObject.optString("app_name", "Varsayılan Uygulama");
            m3uUrl = jsonObject.optString("m3u_url", "");

        } catch (Exception e) {
            e.printStackTrace();
            appName = "Hata Oluştu";
            m3uUrl = "Config Okunamadı";
        }
    }
}
