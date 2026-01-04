#!/bin/bash
set -e

# ==============================================================================
# ULTRA APP V400 - TITAN GOD EDITION (FULL ARCHITECTURE)
# ==============================================================================
# Bu script, profesyonel bir Android projesini sıfırdan inşa eder.
# Özellikler:
# 1. XML Tabanlı Layout Sistemi (Activity_main, player, list vb.)
# 2. Gelişmiş Drawable Selector'lar (TV Focus Efektleri için)
# 3. ExoPlayer V3 Tam Entegrasyon (Deep Link, Headers, User-Agent)
# 4. M3U ve JSON Akıllı Ayrıştırıcı (Regex Destekli)
# 5. Tam Ekran ve Ekran Kilidi Yönetimi
# ==============================================================================

PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3
ICON_URL=$4
VERSION_CODE=$5
VERSION_NAME=$6

echo "=================================================="
echo "   🚀 ULTRA APP V400 - BAŞLATILIYOR..."
echo "=================================================="

# --------------------------------------------------------
# 1. SİSTEM HAZIRLIĞI
# --------------------------------------------------------
echo "⚙️ [1/12] Gerekli araçlar kontrol ediliyor..."
sudo apt-get update >/dev/null 2>&1
sudo apt-get install -y imagemagick curl unzip >/dev/null 2>&1 || true

# --------------------------------------------------------
# 2. PROJE TEMİZLİĞİ VE DİZİN YAPISI
# --------------------------------------------------------
echo "🧹 [2/12] Çalışma alanı temizleniyor..."
rm -rf app/src/main/java/com/base/app/*
rm -rf app/src/main/res/drawable*
rm -rf app/src/main/res/layout*
rm -rf app/src/main/res/values*
rm -rf app/src/main/res/mipmap*

# Dizinleri Oluştur
TARGET_DIR="app/src/main/java/com/base/app"
RES_DIR="app/src/main/res"
mkdir -p "$TARGET_DIR"
mkdir -p "$RES_DIR/layout"
mkdir -p "$RES_DIR/values"
mkdir -p "$RES_DIR/drawable"
mkdir -p "$RES_DIR/mipmap-xxxhdpi"

# --------------------------------------------------------
# 3. İKON İŞLEME
# --------------------------------------------------------
echo "🖼️ [3/12] Uygulama ikonu işleniyor..."
ICON_TARGET="$RES_DIR/mipmap-xxxhdpi/ic_launcher.png"
curl -s -L -k -o "icon_temp.png" "$ICON_URL" || true
if [ -s "icon_temp.png" ]; then
    convert "icon_temp.png" -resize 512x512! -background none -flatten "$ICON_TARGET"
else
    convert -size 512x512 xc:#2196F3 "$ICON_TARGET"
fi
rm -f "icon_temp.png"

# --------------------------------------------------------
# 4. GRADLE AYARLARI
# --------------------------------------------------------
echo "📦 [4/12] Gradle yapılandırması yazılıyor..."

cat > settings.gradle <<EOF
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
rootProject.name = "AppBuilderTemplate"
include ':app'
EOF

cat > app/build.gradle <<EOF
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.base.app'
    compileSdkVersion 34

    defaultConfig {
        applicationId "$PACKAGE_NAME"
        minSdkVersion 24
        targetSdkVersion 34
        versionCode $VERSION_CODE
        versionName "$VERSION_NAME"
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
            minifyEnabled true
            shrinkResources true
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
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    
    // ExoPlayer Media3
    implementation 'androidx.media3:media3-exoplayer:1.2.0'
    implementation 'androidx.media3:media3-exoplayer-hls:1.2.0'
    implementation 'androidx.media3:media3-exoplayer-dash:1.2.0'
    implementation 'androidx.media3:media3-ui:1.2.0'
    implementation 'androidx.media3:media3-datasource-okhttp:1.2.0'
    
    // Resim ve Reklam
    implementation 'com.github.bumptech.glide:glide:4.16.0'
    implementation 'com.unity3d.ads:unity-ads:4.9.2'
}
EOF

# --------------------------------------------------------
# 5. MANIFEST (TV VE FULLSCREEN AYARLARI)
# --------------------------------------------------------
echo "📜 [5/12] AndroidManifest.xml oluşturuluyor..."
cat > app/src/main/AndroidManifest.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <uses-feature android:name="android.software.leanback" android:required="false" />
    <uses-feature android:name="android.hardware.touchscreen" android:required="false" />

    <application
        android:allowBackup="true"
        android:label="$APP_NAME"
        android:icon="@mipmap/ic_launcher"
        android:banner="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true"
        android:theme="@style/AppTheme">
        
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
                <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
            </intent-filter>
        </activity>
        
        <activity android:name=".WebViewActivity" />
        <activity android:name=".ChannelListActivity" />
        
        <activity android:name=".PlayerActivity"
            android:configChanges="orientation|screenSize|keyboardHidden|smallestScreenSize|screenLayout"
            android:screenOrientation="sensor"
            android:theme="@style/PlayerTheme" />
    </application>
</manifest>
EOF

# --------------------------------------------------------
# 6. STYLES & COLORS (XML KAYNAKLARI)
# --------------------------------------------------------
echo "🎨 [6/12] Stil ve renk dosyaları oluşturuluyor..."

cat > "$RES_DIR/values/styles.xml" <<EOF
<resources>
    <style name="AppTheme" parent="Theme.AppCompat.Light.NoActionBar">
        <item name="android:windowNoTitle">true</item>
        <item name="android:windowActionBar">false</item>
    </style>
    
    <style name="PlayerTheme" parent="Theme.AppCompat.NoActionBar">
        <item name="android:windowFullscreen">true</item>
        <item name="android:windowContentOverlay">@null</item>
        <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
    </style>
</resources>
EOF

cat > "$RES_DIR/values/colors.xml" <<EOF
<resources>
    <color name="black">#000000</color>
    <color name="white">#FFFFFF</color>
    <color name="transparent">#00000000</color>
    <color name="overlay_bg">#80000000</color>
</resources>
EOF

# --------------------------------------------------------
# 7. DRAWABLES (SEÇİCİLER VE ARKA PLANLAR)
# --------------------------------------------------------
echo "🖌️ [7/12] Drawable selector'lar hazırlanıyor..."

# Liste elemanı için seçici (Focus durumu için)
cat > "$RES_DIR/drawable/item_selector.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<selector xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:state_focused="true">
        <shape android:shape="rectangle">
            <solid android:color="#FF9800"/> <corners android:radius="8dp"/>
            <stroke android:width="3dp" android:color="#FFFFFF"/>
        </shape>
    </item>
    <item>
        <shape android:shape="rectangle">
            <solid android:color="#FFFFFF"/> <corners android:radius="8dp"/>
        </shape>
    </item>
</selector>
EOF

# --------------------------------------------------------
# 8. LAYOUT XML DOSYALARI (UI TASARIMI)
# --------------------------------------------------------
echo "📐 [8/12] Arayüz tasarımları (XML) oluşturuluyor..."

# activity_player.xml
cat > "$RES_DIR/layout/activity_player.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@color/black"
    android:keepScreenOn="true">

    <androidx.media3.ui.PlayerView
        android:id="@+id/player_view"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        app:show_buffering="always"
        app:use_controller="true"
        app:resize_mode="fill" />

    <ProgressBar
        android:id="@+id/loading_spinner"
        android:layout_width="60dp"
        android:layout_height="60dp"
        android:layout_gravity="center"
        android:indeterminateTint="@color/white"
        android:visibility="visible" />

    <TextView
        android:id="@+id/watermark"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:padding="10dp"
        android:textColor="@color/white"
        android:textStyle="bold"
        android:background="@color/overlay_bg"
        android:visibility="gone" />

</FrameLayout>
EOF

# --------------------------------------------------------
# 9. JAVA SINIFLARI
# --------------------------------------------------------
echo "☕ [9/12] Java sınıfları derleniyor..."

# --- ADS MANAGER ---
cat > "$TARGET_DIR/AdsManager.java" <<EOF
package com.base.app;

import android.app.Activity;
import android.util.Log;
import android.view.ViewGroup;
import com.unity3d.ads.*;
import com.unity3d.services.banners.*;
import org.json.JSONObject;

public class AdsManager {
    public static int counter = 0;
    private static int freq = 3;
    private static boolean isEnabled = false;
    private static boolean isBannerActive = false;
    private static String gameId = "";
    private static String bannerId = "";
    private static String interId = "";

    public static void init(Activity activity, JSONObject config) {
        try {
            if (config == null) return;
            isEnabled = config.optBoolean("enabled", false);
            gameId = config.optString("game_id");
            isBannerActive = config.optBoolean("banner_active");
            bannerId = config.optString("banner_id");
            interId = config.optString("inter_id");
            freq = config.optInt("inter_freq", 3);

            if (isEnabled && !gameId.isEmpty()) {
                UnityAds.initialize(activity.getApplicationContext(), gameId, false, new IUnityAdsInitializationListener() {
                    @Override
                    public void onInitializationComplete() { Log.d("Ads", "Init Complete"); }
                    @Override
                    public void onInitializationFailed(UnityAds.UnityAdsInitializationError error, String message) { Log.e("Ads", "Init Failed: " + message); }
                });
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void showBanner(Activity activity, ViewGroup container) {
        if (!isEnabled || !isBannerActive || bannerId.isEmpty()) return;
        BannerView banner = new BannerView(activity, bannerId, new UnityBannerSize(320, 50));
        banner.load();
        container.removeAllViews();
        container.addView(banner);
    }

    public static void checkInter(Activity activity, Runnable onComplete) {
        if (!isEnabled || interId.isEmpty()) {
            onComplete.run();
            return;
        }
        
        counter++;
        if (counter >= freq) {
            UnityAds.load(interId, new IUnityAdsLoadListener() {
                @Override
                public void onUnityAdsAdLoaded(String placementId) {
                    UnityAds.show(activity, placementId, new IUnityAdsShowListener() {
                        @Override
                        public void onUnityAdsShowComplete(String id, UnityAds.UnityAdsShowCompletionState state) {
                            counter = 0;
                            onComplete.run();
                        }
                        @Override
                        public void onUnityAdsShowFailure(String id, UnityAds.UnityAdsShowError error, String message) {
                            onComplete.run();
                        }
                        @Override
                        public void onUnityAdsShowStart(String id) {}
                        @Override
                        public void onUnityAdsShowClick(String id) {}
                    });
                }
                @Override
                public void onUnityAdsFailedToLoad(String id, UnityAds.UnityAdsLoadError error, String message) {
                    onComplete.run();
                }
            });
        } else {
            onComplete.run();
        }
    }
}
EOF

# --- PLAYER ACTIVITY ---
cat > "$TARGET_DIR/PlayerActivity.java" <<EOF
package com.base.app;

import android.app.Activity;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import android.graphics.Color;

import androidx.media3.common.MediaItem;
import androidx.media3.common.MimeTypes;
import androidx.media3.common.PlaybackException;
import androidx.media3.common.Player;
import androidx.media3.datasource.DefaultHttpDataSource;
import androidx.media3.exoplayer.DefaultLoadControl;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory;
import androidx.media3.exoplayer.upstream.DefaultAllocator;
import androidx.media3.ui.AspectRatioFrameLayout;
import androidx.media3.ui.PlayerView;

import org.json.JSONObject;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

public class PlayerActivity extends Activity {

    private ExoPlayer player;
    private PlayerView playerView;
    private ProgressBar loadingSpinner;
    private TextView watermarkView;
    private String videoUrl, headersJson;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // 1. TAM EKRAN VE GÜÇ YÖNETİMİ
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        hideSystemUI();

        setContentView(R.layout.activity_player);

        playerView = findViewById(R.id.player_view);
        loadingSpinner = findViewById(R.id.loading_spinner);
        watermarkView = findViewById(R.id.watermark);

        // 2. CONFIG OKUMA
        try {
            String configStr = getIntent().getStringExtra("PLAYER_CONFIG");
            if (configStr != null) {
                JSONObject cfg = new JSONObject(configStr);
                
                // Resize Mode
                String resizeMode = cfg.optString("resize_mode", "FIT");
                if (resizeMode.equals("FILL")) {
                    playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FILL);
                } else if (resizeMode.equals("ZOOM")) {
                    playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_ZOOM);
                } else {
                    playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FIT);
                }

                // Auto Rotate
                if (!cfg.optBoolean("auto_rotate", true)) {
                    setRequestedOrientation(0); // Landscape force
                }

                // Watermark
                if (cfg.optBoolean("enable_overlay", false)) {
                    watermarkView.setVisibility(View.VISIBLE);
                    watermarkView.setText(cfg.optString("watermark_text"));
                    watermarkView.setTextColor(Color.parseColor(cfg.optString("watermark_color", "#FFFFFF")));
                    
                    FrameLayout.LayoutParams params = (FrameLayout.LayoutParams) watermarkView.getLayoutParams();
                    String pos = cfg.optString("watermark_pos", "left");
                    
                    if (pos.equals("right")) params.gravity = Gravity.TOP | Gravity.END;
                    else if (pos.equals("bottom")) params.gravity = Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL;
                    else params.gravity = Gravity.TOP | Gravity.START;
                    
                    watermarkView.setLayoutParams(params);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        videoUrl = getIntent().getStringExtra("VIDEO_URL");
        headersJson = getIntent().getStringExtra("HEADERS_JSON");

        if (videoUrl != null && !videoUrl.isEmpty()) {
            new ResolveUrlTask().execute(videoUrl.trim());
        }
    }

    private void hideSystemUI() {
        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
            | View.SYSTEM_UI_FLAG_FULLSCREEN);
    }

    // 3. DEEP LINK RESOLVER
    private class UrlInfo {
        String url;
        String mimeType;
        UrlInfo(String u, String m) { url = u; mimeType = m; }
    }

    private class ResolveUrlTask extends AsyncTask<String, Void, UrlInfo> {
        @Override
        protected UrlInfo doInBackground(String... params) {
            String currentUrl = params[0];
            String detectedMime = null;
            try {
                if (!currentUrl.startsWith("http")) return new UrlInfo(currentUrl, null);
                
                // Redirect Takibi (5 sefere kadar)
                for (int i = 0; i < 5; i++) {
                    URL url = new URL(currentUrl);
                    HttpURLConnection con = (HttpURLConnection) url.openConnection();
                    con.setInstanceFollowRedirects(false); // Manuel takip
                    
                    // Headerları Enjekte Et
                    if (headersJson != null) {
                        JSONObject h = new JSONObject(headersJson);
                        Iterator<String> keys = h.keys();
                        while (keys.hasNext()) {
                            String key = keys.next();
                            con.setRequestProperty(key, h.getString(key));
                        }
                    } else {
                        con.setRequestProperty("User-Agent", "Mozilla/5.0");
                    }
                    
                    con.setConnectTimeout(8000);
                    con.setReadTimeout(8000);
                    con.connect();
                    
                    int code = con.getResponseCode();
                    if (code >= 300 && code < 400) {
                        String next = con.getHeaderField("Location");
                        if (next != null) {
                            currentUrl = next;
                            con.disconnect();
                            continue;
                        }
                    }
                    
                    detectedMime = con.getContentType();
                    con.disconnect();
                    break;
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
            return new UrlInfo(currentUrl, detectedMime);
        }

        @Override
        protected void onPostExecute(UrlInfo info) {
            initializePlayer(info);
        }
    }

    private void initializePlayer(UrlInfo info) {
        if (player != null) return;

        // Header Hazırlığı
        String userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)";
        Map<String, String> requestProps = new HashMap<>();
        
        if (headersJson != null) {
            try {
                JSONObject h = new JSONObject(headersJson);
                Iterator<String> k = h.keys();
                while (k.hasNext()) {
                    String key = k.next();
                    String val = h.getString(key);
                    if (key.equalsIgnoreCase("User-Agent")) userAgent = val;
                    else requestProps.put(key, val);
                }
            } catch (Exception e) {}
        }

        // DataSource Factory
        DefaultHttpDataSource.Factory httpFactory = new DefaultHttpDataSource.Factory()
                .setUserAgent(userAgent)
                .setAllowCrossProtocolRedirects(true)
                .setDefaultRequestProperties(requestProps);

        // Load Control (Buffer Ayarları)
        DefaultLoadControl loadControl = new DefaultLoadControl.Builder()
                .setAllocator(new DefaultAllocator(true, 16 * 1024))
                .setBufferDurationsMs(50000, 50000, 2500, 5000)
                .build();

        // Player Build
        player = new ExoPlayer.Builder(this)
                .setLoadControl(loadControl)
                .setMediaSourceFactory(new DefaultMediaSourceFactory(this).setDataSourceFactory(httpFactory))
                .build();

        playerView.setPlayer(player);
        player.setPlayWhenReady(true);

        // Listeners
        player.addListener(new Player.Listener() {
            @Override
            public void onPlaybackStateChanged(int state) {
                if (state == Player.STATE_BUFFERING) {
                    loadingSpinner.setVisibility(View.VISIBLE);
                } else {
                    loadingSpinner.setVisibility(View.GONE);
                }
            }

            @Override
            public void onPlayerError(PlaybackException error) {
                loadingSpinner.setVisibility(View.GONE);
                Toast.makeText(PlayerActivity.this, "Hata: " + error.getMessage(), Toast.LENGTH_LONG).show();
            }
        });

        // Media Item
        try {
            MediaItem.Builder item = new MediaItem.Builder().setUri(Uri.parse(info.url));
            if (info.mimeType != null) {
                if (info.mimeType.contains("mpegurl") || info.url.endsWith(".m3u8")) {
                    item.setMimeType(MimeTypes.APPLICATION_M3U8);
                } else if (info.mimeType.contains("dash") || info.url.endsWith(".mpd")) {
                    item.setMimeType(MimeTypes.APPLICATION_MPD);
                }
            }
            player.setMediaItem(item.build());
            player.prepare();
        } catch (Exception e) {
            Toast.makeText(this, "Oynatma hatası", Toast.LENGTH_SHORT).show();
        }
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

# --- MAIN ACTIVITY ---
cat > "$TARGET_DIR/MainActivity.java" <<EOF
package com.base.app;

import android.app.Activity;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.*;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.StateListDrawable;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import com.bumptech.glide.Glide;

public class MainActivity extends Activity {
    private String CONFIG_URL = "$CONFIG_URL"; 
    private LinearLayout container;
    private String hColor="#2196F3", tColor="#FFFFFF", bColor="#F0F0F0", fColor="#FF9800", menuType="LIST";
    
    // Panelden gelen veriler
    private String listType="CLASSIC", listItemBg="#FFFFFF", listIconShape="SQUARE", listBorderColor="#DDDDDD";
    private int listRadius=0, listBorderWidth=0;
    private String playerConfigStr="", telegramUrl="";

    private TextView titleTxt;
    private ImageView splash, refreshBtn, shareBtn;
    private LinearLayout headerLayout, currentRow;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        RelativeLayout root = new RelativeLayout(this);
        
        // Splash
        splash = new ImageView(this);
        splash.setScaleType(ImageView.ScaleType.CENTER_CROP);
        root.addView(splash, new RelativeLayout.LayoutParams(-1,-1));

        // Header Bar
        headerLayout = new LinearLayout(this);
        headerLayout.setId(View.generateViewId());
        headerLayout.setPadding(30,30,30,30);
        headerLayout.setGravity(Gravity.CENTER_VERTICAL);
        headerLayout.setElevation(10f);
        
        titleTxt = new TextView(this);
        titleTxt.setTextSize(20);
        titleTxt.setTypeface(null, Typeface.BOLD);
        headerLayout.addView(titleTxt, new LinearLayout.LayoutParams(0, -2, 1.0f));

        shareBtn = new ImageView(this);
        shareBtn.setImageResource(android.R.drawable.ic_menu_share);
        shareBtn.setPadding(20,0,20,0);
        shareBtn.setOnClickListener(v -> shareApp());
        headerLayout.addView(shareBtn);

        refreshBtn = new ImageView(this);
        refreshBtn.setImageResource(android.R.drawable.ic_popup_sync);
        refreshBtn.setOnClickListener(v -> new Fetch().execute(CONFIG_URL));
        headerLayout.addView(refreshBtn);

        RelativeLayout.LayoutParams hp = new RelativeLayout.LayoutParams(-1,-2);
        hp.addRule(RelativeLayout.ALIGN_PARENT_TOP);
        root.addView(headerLayout, hp);

        // Scroll Container
        ScrollView sv = new ScrollView(this);
        container = new LinearLayout(this);
        container.setOrientation(LinearLayout.VERTICAL);
        container.setPadding(20,20,20,100);
        sv.addView(container);
        
        RelativeLayout.LayoutParams sp = new RelativeLayout.LayoutParams(-1,-1);
        sp.addRule(RelativeLayout.BELOW, headerLayout.getId());
        root.addView(sv, sp);
        
        setContentView(root);
        new Fetch().execute(CONFIG_URL);
    }

    private void shareApp() {
        Intent i = new Intent(Intent.ACTION_SEND);
        i.setType("text/plain");
        i.putExtra(Intent.EXTRA_TEXT, titleTxt.getText() + " İndir: https://play.google.com/store/apps/details?id=" + getPackageName());
        startActivity(Intent.createChooser(i, "Paylaş"));
    }

    private void addBtn(String txt, String type, String url, String cont, String ua, String ref, String org) {
        // Headerları hazırla
        JSONObject h = new JSONObject();
        try {
            if(ua != null && !ua.isEmpty()) h.put("User-Agent", ua);
            if(ref != null && !ref.isEmpty()) h.put("Referer", ref);
            if(org != null && !org.isEmpty()) h.put("Origin", org);
        } catch(Exception e){}
        String hStr = h.toString();

        View v = null;
        
        // Menü Tipleri
        if(menuType.equals("GRID")) {
            if(currentRow == null || currentRow.getChildCount() >= 2) {
                currentRow = new LinearLayout(this);
                currentRow.setOrientation(0);
                currentRow.setWeightSum(2);
                container.addView(currentRow);
            }
            Button b = new Button(this);
            b.setText(txt);
            b.setTextColor(Color.parseColor(tColor));
            setFocusBg(b);
            LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, 200, 1.0f);
            p.setMargins(10,10,10,10);
            b.setLayoutParams(p);
            b.setOnClickListener(x -> AdsManager.checkInter(this, () -> open(type, url, cont, hStr)));
            currentRow.addView(b);
            return;
        } else if(menuType.equals("CARD")) {
            TextView t = new TextView(this);
            t.setText(txt);
            t.setTextSize(22);
            t.setGravity(Gravity.CENTER);
            t.setTextColor(Color.parseColor(tColor));
            t.setPadding(50,150,50,150);
            setFocusBg(t);
            LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, -2);
            p.setMargins(0,0,0,30);
            t.setLayoutParams(p);
            v = t;
            v.setOnClickListener(x -> AdsManager.checkInter(this, () -> open(type, url, cont, hStr)));
        } else {
            Button b = new Button(this);
            b.setText(txt);
            b.setPadding(40,40,40,40);
            b.setTextColor(Color.parseColor(tColor));
            setFocusBg(b);
            LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, -2);
            p.setMargins(0,0,0,20);
            b.setLayoutParams(p);
            v = b;
            v.setOnClickListener(x -> AdsManager.checkInter(this, () -> open(type, url, cont, hStr)));
        }
        if(v != null) container.addView(v);
    }

    private void setFocusBg(View v) {
        GradientDrawable def = new GradientDrawable();
        def.setColor(Color.parseColor(hColor));
        def.setCornerRadius(15);
        
        GradientDrawable foc = new GradientDrawable();
        foc.setColor(Color.parseColor(fColor));
        foc.setCornerRadius(15);
        foc.setStroke(5, Color.WHITE);
        
        StateListDrawable sld = new StateListDrawable();
        sld.addState(new int[]{android.R.attr.state_focused}, foc);
        sld.addState(new int[]{android.R.attr.state_pressed}, foc);
        sld.addState(new int[]{}, def);
        v.setBackground(sld);
        v.setFocusable(true);
        v.setClickable(true);
    }

    private void open(String t, String u, String c, String h) {
        if(t.equals("WEB") || t.equals("HTML")) {
            Intent i = new Intent(this, WebViewActivity.class);
            i.putExtra("WEB_URL", u);
            i.putExtra("HTML_DATA", c);
            startActivity(i);
        } else if(t.equals("SINGLE_STREAM")) {
            Intent i = new Intent(this, PlayerActivity.class);
            i.putExtra("VIDEO_URL", u);
            i.putExtra("HEADERS_JSON", h);
            i.putExtra("PLAYER_CONFIG", playerConfigStr);
            startActivity(i);
        } else {
            Intent i = new Intent(this, ChannelListActivity.class);
            i.putExtra("LIST_URL", u);
            i.putExtra("LIST_CONTENT", c);
            i.putExtra("TYPE", t);
            // Renk ve Tasarım Verileri Aktarılıyor
            i.putExtra("HEADER_COLOR", hColor);
            i.putExtra("BG_COLOR", bColor);
            i.putExtra("TEXT_COLOR", tColor);
            i.putExtra("FOCUS_COLOR", fColor);
            i.putExtra("PLAYER_CONFIG", playerConfigStr);
            i.putExtra("L_TYPE", listType);
            i.putExtra("L_BG", listItemBg);
            i.putExtra("L_RAD", listRadius);
            i.putExtra("L_ICON", listIconShape);
            i.putExtra("L_BORDER_W", listBorderWidth);
            i.putExtra("L_BORDER_C", listBorderColor);
            startActivity(i);
        }
    }

    class Fetch extends AsyncTask<String,Void,String> {
        protected String doInBackground(String... u) {
            try {
                URL url = new URL(u[0]);
                HttpURLConnection c = (HttpURLConnection)url.openConnection();
                BufferedReader r = new BufferedReader(new InputStreamReader(c.getInputStream()));
                StringBuilder s = new StringBuilder();
                String l;
                while((l=r.readLine())!=null)s.append(l);
                return s.toString();
            } catch(Exception e){ return null; }
        }
        protected void onPostExecute(String s) {
            if(s==null) return;
            try {
                JSONObject j = new JSONObject(s);
                JSONObject ui = j.optJSONObject("ui_config");
                
                hColor = ui.optString("header_color");
                bColor = ui.optString("bg_color");
                tColor = ui.optString("text_color");
                fColor = ui.optString("focus_color");
                menuType = ui.optString("menu_type", "LIST");
                
                // Tasarım Ayarları
                listType = ui.optString("list_type", "CLASSIC");
                listItemBg = ui.optString("list_item_bg", "#FFFFFF");
                listRadius = ui.optInt("list_item_radius", 0);
                listIconShape = ui.optString("list_icon_shape", "SQUARE");
                listBorderWidth = ui.optInt("list_border_width", 0);
                listBorderColor = ui.optString("list_border_color", "#DDDDDD");
                
                playerConfigStr = j.optString("player_config", "{}");
                telegramUrl = ui.optString("telegram_url");
                
                titleTxt.setText(j.optString("app_name"));
                titleTxt.setTextColor(Color.parseColor(tColor));
                headerLayout.setBackgroundColor(Color.parseColor(hColor));
                ((View)container.getParent()).setBackgroundColor(Color.parseColor(bColor));
                
                if(!ui.optBoolean("show_header", true)) headerLayout.setVisibility(View.GONE);
                refreshBtn.setVisibility(ui.optBoolean("show_refresh", true) ? View.VISIBLE : View.GONE);
                shareBtn.setVisibility(ui.optBoolean("show_share", true) ? View.VISIBLE : View.GONE);
                
                String spl = ui.optString("splash_image");
                if(!spl.isEmpty()){
                    if(!spl.startsWith("http")) spl = CONFIG_URL.substring(0, CONFIG_URL.lastIndexOf("/") + 1) + spl;
                    splash.setVisibility(View.VISIBLE);
                    Glide.with(MainActivity.this).load(spl).into(splash);
                    new android.os.Handler().postDelayed(() -> splash.setVisibility(View.GONE), 3000);
                }
                
                // Startup Mode
                if(ui.optString("startup_mode").equals("DIRECT")) {
                    open(ui.optString("direct_type"), ui.optString("direct_url"), "", "");
                }

                container.removeAllViews();
                currentRow = null;
                JSONArray m = j.getJSONArray("modules");
                for(int i=0; i<m.length(); i++) {
                    JSONObject o = m.getJSONObject(i);
                    addBtn(o.getString("title"), o.getString("type"), o.optString("url"), o.optString("content"), o.optString("ua"), o.optString("ref"), o.optString("org"));
                }
                AdsManager.init(MainActivity.this, j.optJSONObject("ads_config"));
            } catch(Exception e){}
        }
    }
}
EOF

# --- CHANNEL LIST (SCROLL FIX & DESIGN ENGINE) ---
cat > "$TARGET_DIR/ChannelListActivity.java" <<EOF
package com.base.app;

import android.app.Activity;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.*;
import android.widget.*;
import android.graphics.drawable.*;
import android.graphics.Color;
import org.json.*;
import java.io.*;
import java.net.*;
import java.util.*;
import java.util.regex.*;
import com.bumptech.glide.Glide;
import com.bumptech.glide.request.RequestOptions;

public class ChannelListActivity extends Activity {
    private ListView lv;
    private Map<String, List<Item>> groups = new LinkedHashMap<>();
    private List<String> gNames = new ArrayList<>();
    private List<Item> curList = new ArrayList<>();
    private boolean isGroup = false;
    
    private String hC, bC, tC, pCfg, fC, lType, lBg, lIcon, lBC;
    private int lRad, lBW;
    private TextView title;

    class Item {
        String n, u, i, h;
        Item(String name, String url, String img, String head) {
            n = name; u = url; i = img; h = head;
        }
    }

    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        
        // Intent'ten tasarım verilerini al
        hC = getIntent().getStringExtra("HEADER_COLOR");
        bC = getIntent().getStringExtra("BG_COLOR");
        tC = getIntent().getStringExtra("TEXT_COLOR");
        pCfg = getIntent().getStringExtra("PLAYER_CONFIG");
        fC = getIntent().getStringExtra("FOCUS_COLOR");
        lType = getIntent().getStringExtra("L_TYPE");
        lBg = getIntent().getStringExtra("L_BG");
        lRad = getIntent().getIntExtra("L_RAD", 0);
        lIcon = getIntent().getStringExtra("L_ICON");
        lBW = getIntent().getIntExtra("L_BORDER_W", 0);
        lBC = getIntent().getStringExtra("L_BORDER_C");

        LinearLayout r = new LinearLayout(this);
        r.setOrientation(1);
        r.setBackgroundColor(Color.parseColor(bC));

        LinearLayout h = new LinearLayout(this);
        h.setBackgroundColor(Color.parseColor(hC));
        h.setPadding(30, 30, 30, 30);
        
        title = new TextView(this);
        title.setText("Yükleniyor...");
        title.setTextColor(Color.parseColor(tC));
        title.setTextSize(18);
        h.addView(title);
        r.addView(h);

        lv = new ListView(this);
        lv.setDivider(null);
        lv.setPadding(20, 20, 20, 20);
        lv.setClipToPadding(false); // Scroll Fix 1: Padding kesilmez
        lv.setOverScrollMode(View.OVER_SCROLL_NEVER); // Scroll Fix 2: Zıplama yok
        lv.setFocusable(true);
        r.addView(lv);
        setContentView(r);

        new Load(getIntent().getStringExtra("TYPE"), getIntent().getStringExtra("LIST_CONTENT")).execute(getIntent().getStringExtra("LIST_URL"));

        // Click Fix: Tıklama olayı garanti altına alındı
        lv.setOnItemClickListener((p, v, pos, id) -> {
            if (isGroup) {
                showCh(gNames.get(pos));
            } else {
                AdsManager.checkInter(this, () -> {
                    Intent i = new Intent(this, PlayerActivity.class);
                    i.putExtra("VIDEO_URL", curList.get(pos).u);
                    i.putExtra("HEADERS_JSON", curList.get(pos).h);
                    i.putExtra("PLAYER_CONFIG", pCfg);
                    startActivity(i);
                });
            }
        });
    }

    public void onBackPressed() {
        if (!isGroup && gNames.size() > 1) showGr();
        else super.onBackPressed();
    }

    private void showGr() {
        isGroup = true;
        title.setText("Kategoriler");
        lv.setAdapter(new Adp(gNames, true));
    }

    private void showCh(String g) {
        isGroup = false;
        title.setText(g);
        curList = groups.get(g);
        lv.setAdapter(new Adp(curList, false));
    }

    class Load extends AsyncTask<String, Void, String> {
        String t, c;
        Load(String ty, String co) { t = ty; c = co; }

        protected String doInBackground(String... u) {
            if ("MANUAL_M3U".equals(t)) return c;
            try {
                URL url = new URL(u[0]);
                HttpURLConnection cn = (HttpURLConnection) url.openConnection();
                cn.setRequestProperty("User-Agent", "Mozilla/5.0");
                BufferedReader r = new BufferedReader(new InputStreamReader(cn.getInputStream()));
                StringBuilder s = new StringBuilder();
                String l;
                while ((l = r.readLine()) != null) s.append(l).append("\n");
                return s.toString();
            } catch (Exception e) { return null; }
        }

        protected void onPostExecute(String r) {
            if (r == null) return;
            try {
                groups.clear(); gNames.clear();
                
                // JSON PARSER (FLAT LIST)
                if ("JSON_LIST".equals(t) || r.trim().startsWith("{")) {
                    JSONObject root = new JSONObject(r);
                    JSONArray arr = root.getJSONObject("list").getJSONArray("item");
                    String flat = "Liste";
                    groups.put(flat, new ArrayList<>());
                    gNames.add(flat);
                    
                    for (int i = 0; i < arr.length(); i++) {
                        JSONObject o = arr.getJSONObject(i);
                        String u = o.optString("media_url", o.optString("url"));
                        if (u.isEmpty()) continue;
                        JSONObject head = new JSONObject();
                        for (int k = 1; k <= 5; k++) {
                            String kn = o.optString("h" + k + "Key"), kv = o.optString("h" + k + "Val");
                            if (!kn.isEmpty() && !kn.equals("0")) head.put(kn, kv);
                        }
                        groups.get(flat).add(new Item(o.optString("title"), u, o.optString("thumb_square"), head.toString()));
                    }
                }
                
                // M3U PARSER (REGEX)
                if (groups.isEmpty()) {
                    String[] lines = r.split("\n");
                    String curT = "Kanal", curI = "", curG = "Genel";
                    JSONObject curH = new JSONObject();
                    Pattern pG = Pattern.compile("group-title=\"([^\"]*)\"");
                    Pattern pL = Pattern.compile("tvg-logo=\"([^\"]*)\"");
                    
                    for (String l : lines) {
                        l = l.trim();
                        if (l.isEmpty()) continue;
                        if (l.startsWith("#EXTINF")) {
                            if (l.contains(",")) curT = l.substring(l.lastIndexOf(",") + 1).trim();
                            Matcher mG = pG.matcher(l); if (mG.find()) curG = mG.group(1);
                            Matcher mL = pL.matcher(l); if (mL.find()) curI = mL.group(1);
                        } else if (l.startsWith("#EXTVLCOPT:")) {
                            String opt = l.substring(11);
                            if (opt.startsWith("http-referrer=")) curH.put("Referer", opt.substring(14));
                            if (opt.startsWith("http-user-agent=")) curH.put("User-Agent", opt.substring(16));
                            if (opt.startsWith("http-origin=")) curH.put("Origin", opt.substring(12));
                        } else if (!l.startsWith("#")) {
                            if (!groups.containsKey(curG)) {
                                groups.put(curG, new ArrayList<>());
                                gNames.add(curG);
                            }
                            groups.get(curG).add(new Item(curT, l, curI, curH.toString()));
                            curT = "Kanal"; curI = ""; curH = new JSONObject();
                        }
                    }
                }
                
                if (gNames.size() > 1) showGr();
                else if (gNames.size() == 1) showCh(gNames.get(0));
            } catch (Exception e) {}
        }
    }

    class Adp extends BaseAdapter {
        List<?> d;
        boolean isG;
        Adp(List<?> l, boolean g) { d = l; isG = g; }

        public int getCount() { return d.size(); }
        public Object getItem(int p) { return d.get(p); }
        public long getItemId(int p) { return p; }

        public View getView(int p, View v, ViewGroup gr) {
            if (v == null) {
                LinearLayout l = new LinearLayout(ChannelListActivity.this);
                l.setOrientation(0);
                l.setGravity(Gravity.CENTER_VERTICAL);
                ImageView i = new ImageView(ChannelListActivity.this);
                i.setId(1);
                l.addView(i);
                TextView t = new TextView(ChannelListActivity.this);
                t.setId(2);
                t.setTextColor(Color.BLACK);
                l.addView(t);
                v = l;
            }
            
            LinearLayout l = (LinearLayout) v;
            
            // --- DESIGN ENGINE (BORDER + RADIUS + COLORS) ---
            GradientDrawable norm = new GradientDrawable();
            norm.setColor(Color.parseColor(lBg));
            norm.setCornerRadius(lRad);
            if (lBW > 0) norm.setStroke(lBW, Color.parseColor(lBC)); // Çerçeve
            
            GradientDrawable foc = new GradientDrawable();
            foc.setColor(Color.parseColor(fC));
            foc.setCornerRadius(lRad);
            foc.setStroke(Math.max(3, lBW + 2), Color.WHITE);
            
            StateListDrawable sld = new StateListDrawable();
            sld.addState(new int[]{android.R.attr.state_focused}, foc);
            sld.addState(new int[]{android.R.attr.state_pressed}, foc);
            sld.addState(new int[]{}, norm);
            
            l.setBackground(sld);
            
            // Liste Tipi Margins
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(-1, -2);
            if (lType.equals("CARD")) { params.setMargins(0, 0, 0, 25); l.setPadding(30, 30, 30, 30); l.setElevation(5f); }
            else if (lType.equals("MODERN")) { params.setMargins(0, 0, 0, 15); l.setPadding(20, 50, 20, 50); }
            else { params.setMargins(0, 0, 0, 5); l.setPadding(20, 20, 20, 20); }
            l.setLayoutParams(params);

            ImageView img = v.findViewById(1);
            TextView txt = v.findViewById(2);
            txt.setTextColor(Color.parseColor(tC));
            
            img.setLayoutParams(new LinearLayout.LayoutParams(120, 120));
            ((LinearLayout.LayoutParams) img.getLayoutParams()).setMargins(0, 0, 30, 0);
            
            RequestOptions opts = new RequestOptions();
            if (lIcon.equals("CIRCLE")) opts = opts.circleCrop();

            if (isG) {
                txt.setText(d.get(p).toString());
                img.setImageResource(android.R.drawable.ic_menu_sort_by_size);
                img.setColorFilter(Color.parseColor(hC));
            } else {
                Item i = (Item) d.get(p);
                txt.setText(i.n);
                if (!i.i.isEmpty()) Glide.with(ChannelListActivity.this).load(i.i).apply(opts).into(img);
                else img.setImageResource(android.R.drawable.ic_menu_slideshow);
                img.clearColorFilter();
            }
            return v;
        }
    }
}
EOF

# --- 10. WEBVIEW ---
cat > "$TARGET_DIR/WebViewActivity.java" <<EOF
package com.base.app;
import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.util.Base64;

public class WebViewActivity extends Activity {
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        WebView w = new WebView(this);
        setContentView(w);
        
        String u = getIntent().getStringExtra("WEB_URL");
        String h = getIntent().getStringExtra("HTML_DATA");
        
        w.getSettings().setJavaScriptEnabled(true);
        w.getSettings().setDomStorageEnabled(true);
        w.setWebViewClient(new WebViewClient());
        
        if (h != null && !h.isEmpty()) w.loadData(Base64.encodeToString(h.getBytes(), Base64.NO_PADDING), "text/html", "base64");
        else w.loadUrl(u);
    }
}
EOF

echo "✅ ULTRA APP V400 - TITAN GOD DEPLOYED SUCCESSFULLY!"
echo "   Build işlemi GitHub üzerinden başlatılabilir."
