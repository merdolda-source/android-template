package com.template.app;

import android.os.Bundle;
import android.widget.LinearLayout;
import android.widget.Button;
import androidx.appcompat.app.AppCompatActivity;
import okhttp3.*; // API isteği için OkHttp kütüphanesi
import org.json.JSONObject;
import java.io.IOException;

public class MainActivity extends AppCompatActivity {

    private String apiURL = "https://seninsiten.com/api/get_settings.php?package=";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Layout'u kodla oluşturuyoruz (Style/XML bağımlılığını azaltmak için)
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        setContentView(layout);

        fetchSettings(layout);
    }

    private void fetchSettings(LinearLayout layout) {
        OkHttpClient client = new OkHttpClient();
        String currentPackage = getPackageName();

        Request request = new Request.Builder()
                .url(apiURL + currentPackage)
                .build();

        client.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(Call call, IOException e) { e.printStackTrace(); }

            @Override
            public void onResponse(Call call, Response response) throws IOException {
                if (response.isSuccessful()) {
                    final String jsonData = response.body().string();
                    runOnUiThread(() -> {
                        try {
                            JSONObject obj = new JSONObject(jsonData);
                            
                            // Canlı TV Butonu Aktif mi?
                            if (obj.getBoolean("canli_tv_aktif")) {
                                Button btnTv = new Button(MainActivity.this);
                                btnTv.setText("Canlı TV İzle");
                                layout.addView(btnTv);
                            }

                            // M3U Listesi Aktif mi?
                            if (obj.getBoolean("m3u_aktif")) {
                                Button btnM3u = new Button(MainActivity.this);
                                btnM3u.setText("Oynatma Listem");
                                layout.addView(btnM3u);
                            }

                        } catch (Exception e) { e.printStackTrace(); }
                    });
                }
            }
        });
    }
}
