#!/bin/bash
set -e

PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3

echo "=========================================="
echo "   EVRENSEL PLAYER (ALL FORMATS) V5"
echo "=========================================="
echo "PAKET: $PACKAGE_NAME"
echo "URL: $CONFIG_URL"
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

# --- 2. BUILD.GRADLE (HER ŞEYİ EKLE) ---
# Burada RTSP, DASH ve SmoothStreaming gibi tüm modülleri ekliyoruz.
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
    
    // --- EVRENSEL OYNATICI PAKETİ ---
    implementation 'androidx.media3:media3-exoplayer:1.2.0'
    implementation 'androidx.media3:media3-exoplayer-hls:1.2.0'  // m3u8
    implementation 'androidx.media3:media3-exoplayer-dash:1.2.0' // dash
    implementation 'androidx.media3:media3-exoplayer-rtsp:1.2.0' // rtsp (kameralar)
    implementation 'androidx.media3:media3-exoplayer-smoothstreaming:1.2.0' // smooth
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

# A) PlayerActivity.java (EVRENSEL MOD)
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

public class PlayerActivity extends Activity {
    private ExoPlayer player;
    private PlayerView playerView;
    private String videoUrl;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Tam ekran ve ekranı açık tut
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);

        playerView = new PlayerView(this);
        playerView.setShowNextButton(false);
        playerView.setShowPreviousButton(false);
        playerView.setControllerShowTimeoutMs(4000); 
        setContentView(playerView);

        videoUrl = getIntent().getStringExtra("VIDEO_URL");
        if (videoUrl != null) {
            videoUrl = videoUrl.trim(); // Boşlukları temizle
        }

        initializePlayer();
    }

    private void initializePlayer() {
        if (videoUrl == null || videoUrl.isEmpty()) return;

        // 1. CHROME TAKLİDİ (User-Agent)
        // Bazı sunucular Java/Player olduğunu anlayınca engeller.
        String userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";
        
        DefaultHttpDataSource.Factory httpDataSourceFactory = new DefaultHttpDataSource.Factory()
                .setUserAgent(userAgent)
                .setAllowCrossProtocolRedirects(true); // Yönlendirmelere izin ver

        // 2. OTOMATİK FORMAT ALGILAYICI (Universal Factory)
        // Bu Factory; HLS, DASH, MP4, MKV ne gelirse otomatik tanır.
        DefaultMediaSourceFactory mediaSourceFactory = new DefaultMediaSourceFactory(this)
                .setDataSourceFactory(httpDataSourceFactory);

        // 3. PLAYER OLUŞTUR
        player = new ExoPlayer.Builder(this)
                .setMediaSourceFactory(mediaSourceFactory)
                .build();
        
        playerView.setPlayer(player);

        // 4. OYNAT
        try {
            // MediaItem oluştururken MIME TYPE belirtmiyoruz, ExoPlayer kendisi bulacak.
            MediaItem mediaItem = MediaItem.fromUri(Uri.parse(videoUrl));
            player.setMediaItem(mediaItem);
            player.prepare();
            player.setPlayWhenReady(true);
        } catch (Exception e) {
            Toast.makeText(this, "Başlatma Hatası: " + e.getMessage(), Toast.LENGTH_LONG).show();
        }

        // 5. HATA YÖNETİMİ
        player.addListener(new Player.Listener() {
            @Override
            public void onPlayerError(PlaybackException error) {
                String errorMsg = "Oynatma Hatası";
                if (error.errorCode == PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_FAILED) {
                    errorMsg = "İnternet Yok veya Sunucu Kapalı";
                } else if (error.errorCode == PlaybackException.ERROR_CODE_PARSING_CONTAINER_MALFORMED) {
                    errorMsg = "Video Formatı Desteklenmiyor";
                } else if (error.errorCode == PlaybackException.ERROR_CODE_IO_BAD_HTTP_STATUS) {
                    errorMsg = "Sunucu Erişim İzni Vermedi (403/404)";
                }
                Toast.makeText(PlayerActivity.this, errorMsg + "\n" + error.getMessage(), Toast.LENGTH_LONG).show();
            }
        });
    }

    @Override
    protected void onStop() {
        super.onStop();
        if (player != null) {
            player.release();
            player = null;
        }
    }
}
EOF

# B) ChannelListActivity.java (Sadece Linkleri Listeler)
cat > "$TARGET_DIR/ChannelListActivity.java" <<EOF
package com.base.app;

import android.app.Activity;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
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
        Toast.makeText(this, "Liste Çekiliyor...", Toast.LENGTH_SHORT).show();
        new FetchM3UTask().execute(m3uUrl);
        
        listView.setOnItemClickListener((parent, view, position, id) -> {
            String videoUrl = channelUrls.get(position);
            Intent intent = new Intent(ChannelListActivity.this, PlayerActivity.class);
            intent.putExtra("VIDEO_URL", videoUrl);
            startActivity(intent);
        });
    }

    private class FetchM3UTask extends AsyncTask<String, Void, String> {
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
                Toast.makeText(ChannelListActivity.this, "HATA: Liste İndirilemedi!", Toast.LENGTH_LONG).show();
                return;
            }
            String[] lines = result.split("\n");
            String currentName = "Kanal";
            
            for (String line : lines) {
                line = line.trim();
                if (line.isEmpty()) continue;
                
                if (line.startsWith("#EXTINF")) {
                    if (line.contains(",")) {
                        currentName = line.substring(line.lastIndexOf(",") + 1).trim();
                    }
                } else if (!line.startsWith("#")) {
                    // M3U olmayan, MP4/TS vb linkler
                    channelNames.add(currentName);
                    channelUrls.add(line);
                    currentName = "Bilinmeyen Kanal";
                }
            }
            
            if (channelNames.isEmpty()) {
                Toast.makeText(ChannelListActivity.this, "Listede Kanal Bulunamadı!", Toast.LENGTH_LONG).show();
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

# D) MainActivity.java
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
                Intent intent = new Intent(MainActivity.this, WebViewActivity.class);
                intent.putExtra("WEB_URL", link);
                startActivity(intent);
            } else if (type.equals("IPTV")) {
                Intent intent = new Intent(MainActivity.this, ChannelListActivity.class);
                intent.putExtra("M3U_URL", link);
                startActivity(intent);
            } else {
                try { startActivity(new Intent(Intent.ACTION_VIEW, android.net.Uri.parse(link))); } catch(Exception e){}
            }
        });
        container.addView(btn);
    }
}
EOF

echo "✅ EVRENSEL PLAYER GÜNCELLENDİ (TÜM FORMATLAR AÇIK)"
