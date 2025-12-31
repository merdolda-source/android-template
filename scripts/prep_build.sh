#!/bin/bash
set -e

PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3

echo "=========================================="
echo "   ULTRA APP - HEADER & JSON DESTEKLI"
echo "=========================================="

# --- 1. TEMİZLİK ---
rm -rf app/src/main/res/drawable*
rm -rf app/src/main/res/mipmap*
rm -rf app/src/main/res/values/themes.xml
rm -rf app/src/main/res/values/styles.xml
rm -rf app/src/main/res/values/colors.xml
rm -rf app/src/main/java/com/base/app/*

TARGET_DIR="app/src/main/java/com/base/app"
mkdir -p "$TARGET_DIR"

# --- 2. BUILD.GRADLE ---
cat > app/build.gradle <<EOF
plugins {
    id 'com.android.application'
}
android {
    namespace 'com.base.app'
    compileSdk 34
    defaultConfig {
        applicationId "$PACKAGE_NAME"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }
    compileOptions {
        sourceCompatibility 1.8
        targetCompatibility 1.8
    }
}
dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.media3:media3-exoplayer:1.2.0'
    implementation 'androidx.media3:media3-exoplayer-hls:1.2.0'
    implementation 'androidx.media3:media3-exoplayer-dash:1.2.0'
    implementation 'androidx.media3:media3-exoplayer-rtsp:1.2.0'
    implementation 'androidx.media3:media3-datasource:1.2.0'
    implementation 'androidx.media3:media3-ui:1.2.0'
    implementation 'androidx.media3:media3-common:1.2.0'
}
EOF

# --- 3. MANIFEST ---
cat > app/src/main/AndroidManifest.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.base.app">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <application
        android:allowBackup="true"
        android:label="$APP_NAME"
        android:icon="@android:drawable/sym_def_app_icon"
        android:usesCleartextTraffic="true"
        android:theme="@android:style/Theme.DeviceDefault.Light.NoActionBar">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <activity android:name=".WebViewActivity" />
        <activity android:name=".ChannelListActivity" />
        <activity android:name=".PlayerActivity" 
            android:configChanges="orientation|screenSize|keyboardHidden|smallestScreenSize|screenLayout"
            android:theme="@android:style/Theme.Black.NoTitleBar.Fullscreen" />
    </application>
</manifest>
EOF

# --- 4. JAVA DOSYALARI ---

# A) PlayerActivity.java (HEADER DESTEĞİ EKLENDİ)
cat > "$TARGET_DIR/PlayerActivity.java" <<EOF
package com.base.app;

import android.app.Activity;
import android.net.Uri;
import android.os.Bundle;
import android.view.WindowManager;
import android.widget.Toast;
import androidx.media3.common.MediaItem;
import androidx.media3.common.PlaybackException;
import androidx.media3.common.Player;
import androidx.media3.datasource.DefaultHttpDataSource;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory;
import androidx.media3.ui.PlayerView;
import org.json.JSONObject;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

public class PlayerActivity extends Activity {
    private ExoPlayer player;
    private PlayerView playerView;
    private String videoUrl;
    private String headersJson;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);

        playerView = new PlayerView(this);
        playerView.setShowNextButton(false);
        playerView.setShowPreviousButton(false);
        setContentView(playerView);

        videoUrl = getIntent().getStringExtra("VIDEO_URL");
        headersJson = getIntent().getStringExtra("HEADERS_JSON");

        if (videoUrl != null) videoUrl = videoUrl.trim();
        initializePlayer();
    }

    private void initializePlayer() {
        if (videoUrl == null || videoUrl.isEmpty()) return;

        // Varsayılan User-Agent
        String userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36";
        Map<String, String> requestProperties = new HashMap<>();

        // JSON'dan gelen özel Header'ları işle (Referer, Origin vb.)
        if (headersJson != null && !headersJson.isEmpty()) {
            try {
                JSONObject hObj = new JSONObject(headersJson);
                Iterator<String> keys = hObj.keys();
                while(keys.hasNext()) {
                    String key = keys.next();
                    String val = hObj.getString(key);
                    // User-Agent özel olarak ayarlanmalı, diğerleri requestProperty
                    if (key.equalsIgnoreCase("User-Agent")) {
                        userAgent = val;
                    } else {
                        requestProperties.put(key, val);
                    }
                }
            } catch (Exception e) {}
        }

        DefaultHttpDataSource.Factory httpDataSourceFactory = new DefaultHttpDataSource.Factory()
                .setUserAgent(userAgent)
                .setAllowCrossProtocolRedirects(true)
                .setDefaultRequestProperties(requestProperties);

        DefaultMediaSourceFactory mediaSourceFactory = new DefaultMediaSourceFactory(this)
                .setDataSourceFactory(httpDataSourceFactory);

        player = new ExoPlayer.Builder(this)
                .setMediaSourceFactory(mediaSourceFactory)
                .build();
        
        playerView.setPlayer(player);

        try {
            MediaItem mediaItem = MediaItem.fromUri(Uri.parse(videoUrl));
            player.setMediaItem(mediaItem);
            player.prepare();
            player.setPlayWhenReady(true);
        } catch (Exception e) {
            Toast.makeText(this, "Hata: " + e.getMessage(), Toast.LENGTH_LONG).show();
        }

        player.addListener(new Player.Listener() {
            @Override
            public void onPlayerError(PlaybackException error) {
                Toast.makeText(PlayerActivity.this, "Oynatma Hatası: " + error.getMessage(), Toast.LENGTH_LONG).show();
            }
        });
    }

    @Override
    protected void onStop() {
        super.onStop();
        if (player != null) { player.release(); player = null; }
    }
}
EOF

# B) ChannelListActivity.java (HEM M3U HEM JSON DESTEĞİ)
cat > "$TARGET_DIR/ChannelListActivity.java" <<EOF
package com.base.app;

import android.app.Activity;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.Toast;
import org.json.JSONArray;
import org.json.JSONObject;
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
    private List<String> channelHeaders = new ArrayList<>(); // Her kanal için özel header JSON'u

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        listView = new ListView(this);
        setContentView(listView);
        
        String listUrl = getIntent().getStringExtra("LIST_URL");
        String type = getIntent().getStringExtra("TYPE"); // IPTV veya JSON_LIST

        Toast.makeText(this, "Liste Yükleniyor...", Toast.LENGTH_SHORT).show();
        new FetchListTask(type).execute(listUrl);
        
        listView.setOnItemClickListener((parent, view, position, id) -> {
            String videoUrl = channelUrls.get(position);
            String headers = channelHeaders.get(position);
            
            Intent intent = new Intent(ChannelListActivity.this, PlayerActivity.class);
            intent.putExtra("VIDEO_URL", videoUrl);
            intent.putExtra("HEADERS_JSON", headers); // Headerları Playera gönder
            startActivity(intent);
        });
    }

    private class FetchListTask extends AsyncTask<String, Void, String> {
        private String listType;
        public FetchListTask(String type) { this.listType = type; }

        @Override
        protected String doInBackground(String... urls) {
            try {
                URL url = new URL(urls[0]);
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setConnectTimeout(15000);
                conn.setRequestProperty("User-Agent", "Mozilla/5.0");
                BufferedReader rd = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                StringBuilder res = new StringBuilder();
                String line;
                while ((line = rd.readLine()) != null) res.append(line).append("\n");
                return res.toString();
            } catch (Exception e) { return null; }
        }

        @Override
        protected void onPostExecute(String result) {
            if (result == null) {
                Toast.makeText(ChannelListActivity.this, "Liste İndirilemedi!", Toast.LENGTH_LONG).show();
                return;
            }

            try {
                if ("JSON_LIST".equals(listType) || result.trim().startsWith("{")) {
                    // --- JSON PARSER (Selbuk Formatı) ---
                    JSONObject root = new JSONObject(result);
                    JSONObject listObj = root.getJSONObject("list");
                    JSONArray items = listObj.getJSONArray("item");

                    for (int i = 0; i < items.length(); i++) {
                        JSONObject item = items.getJSONObject(i);
                        String title = item.optString("title", "Kanal " + i);
                        String url = item.optString("media_url", item.optString("url", ""));
                        
                        // Headerları topla
                        JSONObject headersObj = new JSONObject();
                        // h1Key, h2Key... h5Key döngüsü
                        for(int k=1; k<=5; k++) {
                            String keyName = item.optString("h" + k + "Key");
                            String valName = item.optString("h" + k + "Val");
                            if(!keyName.isEmpty() && !keyName.equals("0") && !valName.isEmpty() && !valName.equals("0")) {
                                headersObj.put(keyName, valName);
                            }
                        }

                        if (!url.isEmpty()) {
                            channelNames.add(title);
                            channelUrls.add(url);
                            channelHeaders.add(headersObj.toString());
                        }
                    }

                } else {
                    // --- M3U PARSER (Standart) ---
                    String[] lines = result.split("\n");
                    String currentName = "Kanal";
                    for (String line : lines) {
                        line = line.trim();
                        if (line.isEmpty()) continue;
                        if (line.startsWith("#EXTINF")) {
                            if (line.contains(",")) currentName = line.substring(line.lastIndexOf(",") + 1).trim();
                        } else if (!line.startsWith("#")) {
                            channelNames.add(currentName);
                            channelUrls.add(line);
                            channelHeaders.add("{}"); // M3U için boş header
                            currentName = "Bilinmeyen Kanal";
                        }
                    }
                }
            } catch (Exception e) {
                Toast.makeText(ChannelListActivity.this, "Format Hatası: " + e.getMessage(), Toast.LENGTH_LONG).show();
            }

            if (channelNames.isEmpty()) {
                Toast.makeText(ChannelListActivity.this, "Kanal Bulunamadı!", Toast.LENGTH_LONG).show();
            } else {
                ArrayAdapter<String> adapter = new ArrayAdapter<>(ChannelListActivity.this, android.R.layout.simple_list_item_1, channelNames);
                listView.setAdapter(adapter);
            }
        }
    }
}
EOF

# C) WebViewActivity.java
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
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        webView.setWebViewClient(new WebViewClient());
        webView.loadUrl(url);
    }
}
EOF

# D) MainActivity.java (Aktiflik Kontrolü)
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
                    // SADECE AKTİF OLANLARI GÖSTER
                    if (m.optBoolean("active", true)) {
                        createButton(m.getString("title"), m.getString("type"), m.getString("url"));
                    }
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
                Intent intent = new Intent(MainActivity.this, WebViewActivity.class);
                intent.putExtra("WEB_URL", link);
                startActivity(intent);
            } else if (type.equals("IPTV") || type.equals("JSON_LIST")) {
                // HEM M3U HEM JSON AYNI YERE GİDER, TYPE PARAMETRESİ İLE AYRILIR
                Intent intent = new Intent(MainActivity.this, ChannelListActivity.class);
                intent.putExtra("LIST_URL", link);
                intent.putExtra("TYPE", type);
                startActivity(intent);
            } else {
                try { startActivity(new Intent(Intent.ACTION_VIEW, android.net.Uri.parse(link))); } catch(Exception e){}
            }
        });
        container.addView(btn);
    }
}
EOF

echo "✅ JSON LİSTE VE HEADER SİSTEMİ EKLENDİ!"
