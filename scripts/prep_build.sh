#!/bin/bash
set -e

PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3

echo "=========================================="
echo "   ULTRA APP OLUŞTURUCU (HLS DESTEKLI)"
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
# Çakışma olmaması için eski kodları siliyoruz
rm -rf app/src/main/java/com/base/app/*

TARGET_DIR="app/src/main/java/com/base/app"
mkdir -p "$TARGET_DIR"

# --- 2. BUILD.GRADLE (HLS DESTEĞİ İÇİN KRİTİK ADIM) ---
# Bu adım ExoPlayer'ın HLS modülünü projeye ekler.
echo "--- Build.gradle Yeniden Yazılıyor (HLS Library) ---"
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

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    compileOptions {
        sourceCompatibility 1.8
        targetCompatibility 1.8
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    
    // --- GÜÇLÜ PLAYER İÇİN GEREKLİ KÜTÜPHANELER ---
    implementation 'androidx.media3:media3-exoplayer:1.2.0'
    implementation 'androidx.media3:media3-exoplayer-hls:1.2.0'  // .m3u8 İÇİN ŞART
    implementation 'androidx.media3:media3-exoplayer-dash:1.2.0' // DASH YAYINLARI İÇİN
    implementation 'androidx.media3:media3-ui:1.2.0'
    implementation 'androidx.media3:media3-common:1.2.0'
}
EOF

# --- 3. MANIFEST ---
echo "--- Manifest Oluşturuluyor ---"
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

# --- 4. JAVA DOSYALARI ---

# A) PlayerActivity.java (GÜÇLENDİRİLMİŞ PLAYER)
# Hata yakalama eklendi ve HLS desteği varsayılan yapıldı.
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
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.ui.PlayerView;

public class PlayerActivity extends Activity {
    private ExoPlayer player;
    private PlayerView playerView;
    private String videoUrl;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Ekran kapanmasın
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);

        playerView = new PlayerView(this);
        playerView.setShowNextButton(false);
        playerView.setShowPreviousButton(false);
        // Kontrollerin ekranda kalma süresi (4 saniye)
        playerView.setControllerShowTimeoutMs(4000); 
        setContentView(playerView);

        videoUrl = getIntent().getStringExtra("VIDEO_URL");
        initializePlayer();
    }

    private void initializePlayer() {
        if (videoUrl == null) return;

        // Player Oluştur
        player = new ExoPlayer.Builder(this).build();
        playerView.setPlayer(player);

        // Hata Dinleyicisi (Yayın açılmazsa uyarı verir)
        player.addListener(new Player.Listener() {
            @Override
            public void onPlayerError(PlaybackException error) {
                Toast.makeText(PlayerActivity.this, "Oynatma Hatası: " + error.getMessage(), Toast.LENGTH_LONG).show();
            }
        });

        // Medyayı Yükle
        MediaItem mediaItem = MediaItem.fromUri(Uri.parse(videoUrl));
        player.setMediaItem(mediaItem);
        player.prepare();
        player.setPlayWhenReady(true);
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

# B) ChannelListActivity.java (Aynı Kalıyor - Çalışıyor)
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
                conn.setConnectTimeout(10000);
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
                Toast.makeText(ChannelListActivity.this, "Liste İndirilemedi", Toast.LENGTH_LONG).show();
                return;
            }
            String[] lines = result.split("\n");
            String currentName = "Bilinmeyen Kanal";
            
            for (String line : lines) {
                line = line.trim();
                if (line.startsWith("#EXTINF")) {
                    if (line.contains(",")) currentName = line.substring(line.lastIndexOf(",") + 1).trim();
                } else if (!line.startsWith("#") && line.length() > 5) {
                    channelNames.add(currentName);
                    channelUrls.add(line);
                    currentName = "Bilinmeyen Kanal";
                }
            }
            ArrayAdapter<String> adapter = new ArrayAdapter<>(ChannelListActivity.this, android.R.layout.simple_list_item_1, channelNames);
            listView.setAdapter(adapter);
        }
    }
}
EOF

# C) WebViewActivity.java (Aynı Kalıyor)
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

# D) MainActivity.java (Aynı Kalıyor)
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

echo "✅ TÜM DOSYALAR OLUŞTURULDU."
