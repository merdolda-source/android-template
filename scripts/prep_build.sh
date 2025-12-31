#!/bin/bash
set -e

PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3

echo "=========================================="
echo "   PROFESYONEL APP OLUŞTURUCU V3"
echo "   (WebView + M3U Listesi + Player)"
echo "=========================================="
echo "PAKET: $PACKAGE_NAME"
echo "URL: $CONFIG_URL"
echo "=========================================="

# --- 1. TEMİZLİK ---
echo "--- Temizlik Yapılıyor ---"
rm -rf app/src/main/res/drawable*
rm -rf app/src/main/res/mipmap*
rm -rf app/src/main/res/values/themes.xml
rm -rf app/src/main/res/values/styles.xml
rm -rf app/src/main/res/values/colors.xml
# Eski java dosyalarını temizle ki çakışma olmasın
rm -rf app/src/main/java/com/base/app/*

# --- 2. AYARLAR ---
TARGET_DIR="app/src/main/java/com/base/app"
mkdir -p "$TARGET_DIR"

# build.gradle paket adı
sed -i "s/applicationId \"com.base.app\"/applicationId \"$PACKAGE_NAME\"/g" app/build.gradle

# --- 3. MANIFEST OLUŞTURMA (Tüm Sayfalar Tanıtılıyor) ---
echo "--- Manifest Yeniden Yazılıyor ---"
cat > app/src/main/AndroidManifest.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.base.app">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:allowBackup="true"
        android:label="$APP_NAME"
        android:supportsRtl="true"
        android:icon="@android:drawable/sym_def_app_icon"
        android:roundIcon="@android:drawable/sym_def_app_icon"
        android:usesCleartextTraffic="true"
        android:theme="@android:style/Theme.DeviceDefault.Light.NoActionBar">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:configChanges="orientation|screenSize|keyboardHidden">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <activity android:name=".WebViewActivity" />

        <activity android:name=".ChannelListActivity" />

        <activity 
            android:name=".PlayerActivity"
            android:configChanges="orientation|screenSize|keyboardHidden|smallestScreenSize|screenLayout"
            android:theme="@android:style/Theme.Black.NoTitleBar.Fullscreen" />
            
    </application>
</manifest>
EOF

# --- 4. DOSYALARI OLUŞTURMA ---

# A) WebViewActivity.java (Uygulama İçi Tarayıcı)
cat > "$TARGET_DIR/WebViewActivity.java" <<EOF
package com.base.app;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class WebViewActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        WebView webView = new WebView(this);
        setContentView(webView);
        
        String url = getIntent().getStringExtra("WEB_URL");
        
        // Ayarlar
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        
        // Linklerin uygulama içinde açılmasını sağlar (Chrome'a atmaz)
        webView.setWebViewClient(new WebViewClient());
        
        webView.loadUrl(url);
    }
}
EOF

# B) ChannelListActivity.java (M3U Ayrıştırıcı ve Listeleyici)
cat > "$TARGET_DIR/ChannelListActivity.java" <<EOF
package com.base.app;

import android.app.Activity;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.Toast;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;

public class ChannelListActivity extends Activity {

    private ListView listView;
    private List<String> channelNames = new ArrayList<>();
    private List<String> channelUrls = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        listView = new ListView(this);
        setContentView(listView);
        
        String m3uUrl = getIntent().getStringExtra("M3U_URL");
        Toast.makeText(this, "Kanallar Yükleniyor...", Toast.LENGTH_SHORT).show();
        
        new FetchM3UTask().execute(m3uUrl);
        
        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                String videoUrl = channelUrls.get(position);
                Intent intent = new Intent(ChannelListActivity.this, PlayerActivity.class);
                intent.putExtra("VIDEO_URL", videoUrl);
                startActivity(intent);
            }
        });
    }

    private class FetchM3UTask extends AsyncTask<String, Void, String> {
        @Override
        protected String doInBackground(String... urls) {
            StringBuilder result = new StringBuilder();
            try {
                URL url = new URL(urls[0]);
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setConnectTimeout(10000);
                BufferedReader rd = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                String line;
                while ((line = rd.readLine()) != null) {
                    result.append(line).append("\n");
                }
                rd.close();
                return result.toString();
            } catch (Exception e) {
                return null;
            }
        }

        @Override
        protected void onPostExecute(String result) {
            if (result == null) {
                Toast.makeText(ChannelListActivity.this, "Liste İndirilemedi", Toast.LENGTH_LONG).show();
                return;
            }

            // Basit M3U Parser
            String[] lines = result.split("\n");
            String currentName = "Bilinmeyen Kanal";
            
            for (String line : lines) {
                line = line.trim();
                if (line.startsWith("#EXTINF")) {
                    // İsim bulmaya çalış (Virgülden sonrasını al)
                    if (line.contains(",")) {
                        currentName = line.substring(line.lastIndexOf(",") + 1).trim();
                    }
                } else if (!line.startsWith("#") && line.length() > 10) {
                    // Bu bir URL'dir
                    channelNames.add(currentName);
                    channelUrls.add(line);
                    currentName = "Bilinmeyen Kanal"; // Sıfırla
                }
            }
            
            ArrayAdapter<String> adapter = new ArrayAdapter<>(ChannelListActivity.this, android.R.layout.simple_list_item_1, channelNames);
            listView.setAdapter(adapter);
            Toast.makeText(ChannelListActivity.this, channelNames.size() + " Kanal Bulundu", Toast.LENGTH_SHORT).show();
        }
    }
}
EOF

# C) PlayerActivity.java (ExoPlayer - Oynatıcı)
cat > "$TARGET_DIR/PlayerActivity.java" <<EOF
package com.base.app;

import android.app.Activity;
import android.net.Uri;
import android.os.Bundle;
import android.view.WindowManager;
import androidx.media3.common.MediaItem;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.ui.PlayerView;

public class PlayerActivity extends Activity {
    private ExoPlayer player;
    private PlayerView playerView;
    private String videoUrl;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);

        playerView = new PlayerView(this);
        setContentView(playerView);

        videoUrl = getIntent().getStringExtra("VIDEO_URL");
        initializePlayer();
    }

    private void initializePlayer() {
        if (videoUrl == null) return;
        player = new ExoPlayer.Builder(this).build();
        playerView.setPlayer(player);
        MediaItem mediaItem = MediaItem.fromUri(Uri.parse(videoUrl));
        player.setMediaItem(mediaItem);
        player.prepare();
        player.play();
    }

    @Override
    protected void onStop() {
        super.onStop();
        if (player != null) { player.release(); player = null; }
    }
}
EOF

# D) MainActivity.java (Ana Menü - Yönlendirici)
cat > "$TARGET_DIR/MainActivity.java" <<EOF
package com.base.app;

import android.app.Activity;
import android.content.Intent;
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

    // SCRIPT BURAYI DEGISTIRECEK
    private String CONFIG_URL = "$CONFIG_URL"; 
    private LinearLayout container;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ScrollView sv = new ScrollView(this);
        sv.setBackgroundColor(0xFFFFFFFF);
        container = new LinearLayout(this);
        container.setOrientation(LinearLayout.VERTICAL);
        container.setPadding(50, 50, 50, 50);
        sv.addView(container);
        setContentView(sv);
        
        new FetchConfigTask().execute(CONFIG_URL);
    }

    private class FetchConfigTask extends AsyncTask<String, Void, String> {
        @Override
        protected String doInBackground(String... urls) {
            try {
                URL url = new URL(urls[0]);
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setRequestProperty("User-Agent", "AppFactory");
                BufferedReader rd = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                StringBuilder res = new StringBuilder();
                String line;
                while ((line = rd.readLine()) != null) res.append(line);
                return res.toString();
            } catch (Exception e) { return null; }
        }

        @Override
        protected void onPostExecute(String result) {
            if (result == null) {
                Toast.makeText(MainActivity.this, "Bağlantı Hatası", Toast.LENGTH_SHORT).show();
                return;
            }
            container.removeAllViews();
            try {
                JSONObject json = new JSONObject(result);
                String title = json.optString("app_name", "App");
                TextView tv = new TextView(MainActivity.this);
                tv.setText(title);
                tv.setTextSize(24);
                tv.setGravity(Gravity.CENTER);
                tv.setPadding(0,0,0,30);
                container.addView(tv);

                JSONArray mods = json.getJSONArray("modules");
                for(int i=0; i<mods.length(); i++){
                    JSONObject m = mods.getJSONObject(i);
                    createButton(m.getString("title"), m.getString("type"), m.getString("url"));
                }
            } catch(Exception e){}
        }
    }

    private void createButton(String text, final String type, final String link) {
        Button btn = new Button(this);
        btn.setText(text);
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, -2);
        p.setMargins(0,0,0,20);
        btn.setLayoutParams(p);
        btn.setBackgroundColor(0xFF2196F3);
        btn.setTextColor(0xFFFFFFFF);
        
        btn.setOnClickListener(v -> {
            if (type.equals("WEB")) {
                // WEB SAYFASINI UYGULAMA İÇİNDE AÇ (WebView)
                Intent intent = new Intent(MainActivity.this, WebViewActivity.class);
                intent.putExtra("WEB_URL", link);
                startActivity(intent);
            } else if (type.equals("IPTV")) {
                // M3U LİSTESİ SAYFASINI AÇ
                Intent intent = new Intent(MainActivity.this, ChannelListActivity.class);
                intent.putExtra("M3U_URL", link);
                startActivity(intent);
            } else {
                // Telegram vs için Dışarı At
                try {
                    startActivity(new Intent(Intent.ACTION_VIEW, android.net.Uri.parse(link)));
                } catch(Exception e){}
            }
        });
        container.addView(btn);
    }
}
EOF

echo "✅ TÜM DOSYALAR OLUŞTURULDU."
