#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
trap 'echo "❌ [SCRIPTHOOK] HATA! satır=$LINENO komut=$BASH_COMMAND" >&2' ERR

# ==============================================================================
# TITAN APEX V6000.10 - ULTIMATE SOURCE GENERATOR (LEGAL/SAFE EDITION)
# ==============================================================================
# - Tek dosya: Android proje kaynaklarını üretir + Gradle/Media3 hatalarını düzeltir
# - ICON motoru (curl + convert varsa resize)
# - TR/EN strings
# - Active/Passive modül menüsü (JSON config)
# - Welcome popup + Rate dialog
# - FCM altyapı + token saklama
# - AdMob/Unity altyapı (config üzerinden)
# - Media3 Player (standart URL oynatma)  ✅
# - NOT: Referer/Origin/UA enjekte ederek erişim kısıtı aşan kullanım için tasarlanmamıştır.
# ==============================================================================

# ------------------------------------------------------------------------------
# INPUTS
# ------------------------------------------------------------------------------
PACKAGE_NAME="${1:-}"
APP_NAME="${2:-}"
CONFIG_URL="${3:-}"
ICON_URL="${4:-}"
VERSION_CODE="${5:-}"
VERSION_NAME="${6:-}"
PRIVACY_URL="${7:-}"   # opsiyonel

# ------------------------------------------------------------------------------
# VALIDATION
# ------------------------------------------------------------------------------
is_int() { [[ "${1:-}" =~ ^[0-9]+$ ]]; }
is_pkg() { [[ "${1:-}" =~ ^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z0-9_]+)+$ ]]; }
is_http_url() { [[ "${1:-}" =~ ^https?:// ]]; }
req_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Gerekli komut eksik: $1"; exit 1; }; }

req_cmd curl
req_cmd sed
req_cmd cat
req_cmd mkdir
req_cmd rm
req_cmd cp

if [[ -z "$PACKAGE_NAME" || -z "$APP_NAME" || -z "$CONFIG_URL" || -z "$VERSION_CODE" || -z "$VERSION_NAME" ]]; then
  echo "❌ Eksik parametre! Kullanım:"
  echo "   ./prep_build.sh <PACKAGE_NAME> <APP_NAME> <CONFIG_URL> <ICON_URL> <VERSION_CODE> <VERSION_NAME> [PRIVACY_URL]"
  exit 1
fi

if ! is_pkg "$PACKAGE_NAME"; then
  echo "❌ Paket adı formatı hatalı: $PACKAGE_NAME"
  exit 1
fi

if ! is_int "$VERSION_CODE"; then
  echo "❌ VERSION_CODE sayı olmalı: $VERSION_CODE"
  exit 1
fi

if ! is_http_url "$CONFIG_URL"; then
  echo "❌ CONFIG_URL http/https olmalı: $CONFIG_URL"
  exit 1
fi

if [[ -n "$ICON_URL" && ! is_http_url "$ICON_URL" ]]; then
  echo "❌ ICON_URL http/https olmalı: $ICON_URL"
  exit 1
fi

if [[ -n "$PRIVACY_URL" && ! is_http_url "$PRIVACY_URL" ]]; then
  echo "❌ PRIVACY_URL http/https olmalı: $PRIVACY_URL"
  exit 1
fi

PKG_PATH="${PACKAGE_NAME//./\/}"
JAVA_DIR="app/src/main/java/${PKG_PATH}"
RES_DIR="app/src/main/res"
APP_MANIFEST="app/src/main/AndroidManifest.xml"
APP_GRADLE="app/build.gradle"
ROOT_GRADLE="build.gradle"
SETTINGS_GRADLE="settings.gradle"
GRADLE_PROPERTIES="gradle.properties"

echo "============================================================"
echo "🚀 TITAN APEX V6000.10 - PROJE ÜRETİMİ"
echo "📦 PACKAGE_NAME : $PACKAGE_NAME"
echo "📱 APP_NAME     : $APP_NAME"
echo "🌍 CONFIG_URL   : $CONFIG_URL"
echo "🧩 VERSION      : $VERSION_NAME ($VERSION_CODE)"
echo "============================================================"

# ------------------------------------------------------------------------------
# 1) OPTIONAL: imagemagick (convert)
# ------------------------------------------------------------------------------
if ! command -v convert &> /dev/null; then
  echo "⚠️ ImageMagick (convert) yok. Deneniyor..."
  sudo apt-get update >/dev/null 2>&1 || true
  sudo apt-get install -y imagemagick >/dev/null 2>&1 || true
fi

# ------------------------------------------------------------------------------
# 2) CLEANUP
# ------------------------------------------------------------------------------
echo "🧹 Temizlik..."
rm -rf app/src/main/res/drawable* || true
rm -rf app/src/main/res/mipmap* || true
rm -rf app/src/main/res/values* || true
rm -rf app/src/main/res/values-tr* || true
rm -rf app/src/main/res/xml || true
rm -rf app/src/main/java || true
rm -rf app/build || true
rm -rf build || true
rm -rf .gradle || true

mkdir -p "${JAVA_DIR}"
mkdir -p "${RES_DIR}/mipmap-xxxhdpi" "${RES_DIR}/mipmap-xxhdpi" "${RES_DIR}/mipmap-xhdpi" "${RES_DIR}/mipmap-hdpi" "${RES_DIR}/mipmap-mdpi"
mkdir -p "${RES_DIR}/values" "${RES_DIR}/values-tr" "${RES_DIR}/xml"

# ------------------------------------------------------------------------------
# 3) ICON ENGINE (robust)
# ------------------------------------------------------------------------------
echo "🖼️ İkon hazırlanıyor..."
ICON_TARGET="${RES_DIR}/mipmap-xxxhdpi/ic_launcher.png"
TEMP_ICON="__icon_tmp.bin"

safe_curl() {
  local url="$1"
  local out="$2"
  curl --fail --silent --show-error -L \
    --retry 3 --retry-delay 1 --connect-timeout 10 --max-time 25 \
    -A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123 Safari/537.36" \
    -o "$out" "$url"
}

if [[ -n "$ICON_URL" ]]; then
  safe_curl "$ICON_URL" "$TEMP_ICON" || true
fi

if [[ -s "$TEMP_ICON" ]]; then
  if command -v convert &> /dev/null; then
    convert "$TEMP_ICON" -resize 512x512\! -background none -flatten "$ICON_TARGET" || cp "$TEMP_ICON" "$ICON_TARGET"
  else
    cp "$TEMP_ICON" "$ICON_TARGET"
  fi
else
  echo "⚠️ İkon indirilemedi. Placeholder ikon oluşturuluyor..."
  if command -v convert &> /dev/null; then
    convert -size 512x512 xc:#111827 -fill white -gravity center -pointsize 120 -annotate 0 "APP" "$ICON_TARGET" || true
  else
    printf '' > "$ICON_TARGET"
  fi
fi
rm -f "$TEMP_ICON" || true

for d in mipmap-xxhdpi mipmap-xhdpi mipmap-hdpi mipmap-mdpi; do
  cp -f "$ICON_TARGET" "${RES_DIR}/${d}/ic_launcher.png" 2>/dev/null || true
done

# ------------------------------------------------------------------------------
# 4) settings.gradle
# ------------------------------------------------------------------------------
echo "📦 settings.gradle..."
cat > "${SETTINGS_GRADLE}" <<'EOF'
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
rootProject.name = "TitanApp"
include ':app'
EOF

# ------------------------------------------------------------------------------
# 5) root build.gradle (AGP + google-services)
# ------------------------------------------------------------------------------
echo "📦 root build.gradle..."
cat > "${ROOT_GRADLE}" <<'EOF'
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.2.2'
        classpath 'com.google.gms:google-services:4.4.1'
    }
}
tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
EOF

# ------------------------------------------------------------------------------
# 6) gradle.properties (safe defaults)
# ------------------------------------------------------------------------------
echo "⚙️ gradle.properties..."
cat > "${GRADLE_PROPERTIES}" <<'EOF'
org.gradle.jvmargs=-Xmx3g -Dfile.encoding=UTF-8
android.useAndroidX=true
android.enableJetifier=true
org.gradle.parallel=true
org.gradle.caching=true
EOF

# ------------------------------------------------------------------------------
# 7) google-services.json (dummy if missing)
# ------------------------------------------------------------------------------
echo "🔧 google-services.json..."
mkdir -p app
JSON_FILE="app/google-services.json"
if [[ -f "$JSON_FILE" ]]; then
  sed -i 's/"package_name":[[:space:]]*"[^"]*"/"package_name": "'"$PACKAGE_NAME"'"/g' "$JSON_FILE" || true
else
  cat > "$JSON_FILE" <<EOF
{
  "project_info": {
    "project_number": "000000000000",
    "project_id": "dummy-project",
    "storage_bucket": "dummy-project.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:000000000000:android:0000000000000000",
        "android_client_info": {
          "package_name": "$PACKAGE_NAME"
        }
      },
      "api_key": [
        { "current_key": "dummy_api_key" }
      ]
    }
  ]
}
EOF
fi

# ------------------------------------------------------------------------------
# 8) app/build.gradle (MEDIA3_VER fix included)
# ------------------------------------------------------------------------------
echo "📚 app/build.gradle..."
mkdir -p app
cat > "${APP_GRADLE}" <<EOF
plugins {
    id 'com.android.application'
    id 'com.google.gms.google-services'
}

ext {
    // ✅ MEDIA3_VER tanımlı değil hatasını kesin çözer
    MEDIA3_VER = "1.3.1"
}

android {
    namespace "$PACKAGE_NAME"
    compileSdk 34

    defaultConfig {
        applicationId "$PACKAGE_NAME"
        minSdk 24
        targetSdk 34
        versionCode $VERSION_CODE
        versionName "$VERSION_NAME"
        multiDexEnabled true
        resValue "string", "app_name", "$APP_NAME"
    }

    signingConfigs {
        release {
            storeFile file("keystore.jks")
            storePassword System.getenv("SIGNING_STORE_PASSWORD")
            keyAlias System.getenv("SIGNING_KEY_ALIAS")
            keyPassword System.getenv("SIGNING_KEY_PASSWORD")
        }
    }

    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            signingConfig signingConfigs.release
        }
        debug {
            minifyEnabled false
            shrinkResources false
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    lint {
        abortOnError false
        checkReleaseBuilds false
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'

    // Firebase (dummy json varsa push mantığı test içindir)
    implementation(platform('com.google.firebase:firebase-bom:32.7.2'))
    implementation 'com.google.firebase:firebase-messaging'
    implementation 'com.google.firebase:firebase-analytics'

    // Media3 (standart oynatma)
    implementation "androidx.media3:media3-exoplayer:\$MEDIA3_VER"
    implementation "androidx.media3:media3-exoplayer-hls:\$MEDIA3_VER"
    implementation "androidx.media3:media3-ui:\$MEDIA3_VER"
    implementation "androidx.media3:media3-datasource-okhttp:\$MEDIA3_VER"

    // Glide
    implementation 'com.github.bumptech.glide:glide:4.16.0'

    // Ads
    implementation 'com.unity3d.ads:unity-ads:4.9.2'
    implementation 'com.google.android.gms:play-services-ads:22.6.0'
}
EOF

# ------------------------------------------------------------------------------
# 9) Resources (strings, styles, network config, proguard)
# ------------------------------------------------------------------------------
echo "🧩 Resource dosyaları..."
cat > "${RES_DIR}/values/strings.xml" <<EOF
<resources>
    <string name="app_name">$APP_NAME</string>
    <string name="loading">Loading...</string>
    <string name="ok">OK</string>
    <string name="later">Later</string>
    <string name="dont_show_again">Don\'t show again</string>
    <string name="rate_title">Rate us</string>
    <string name="rate_msg">If you like the app, would you rate it 5 stars?</string>
    <string name="rate_now">Rate now</string>
    <string name="privacy">Privacy Policy</string>
</resources>
EOF

cat > "${RES_DIR}/values-tr/strings.xml" <<EOF
<resources>
    <string name="app_name">$APP_NAME</string>
    <string name="loading">Yükleniyor...</string>
    <string name="ok">Tamam</string>
    <string name="later">Daha sonra</string>
    <string name="dont_show_again">Bir daha gösterme</string>
    <string name="rate_title">Bizi Değerlendir</string>
    <string name="rate_msg">Uygulamayı beğendiysen 5 yıldız verir misin?</string>
    <string name="rate_now">Şimdi puanla</string>
    <string name="privacy">Gizlilik Politikası</string>
</resources>
EOF

# cleartext sadece http ise true
CLEAR_OK="true"
if [[ "$CONFIG_URL" == https://* ]]; then CLEAR_OK="false"; fi

cat > "${RES_DIR}/xml/network_security_config.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="$CLEAR_OK">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
EOF

cat > "${RES_DIR}/values/styles.xml" <<'EOF'
<resources>
    <style name="AppTheme" parent="Theme.MaterialComponents.Light.NoActionBar">
        <item name="android:windowNoTitle">true</item>
        <item name="android:windowActionBar">false</item>
    </style>

    <style name="PlayerTheme" parent="Theme.AppCompat.NoActionBar">
        <item name="android:windowFullscreen">true</item>
        <item name="android:windowContentOverlay">@null</item>
    </style>
</resources>
EOF

cat > app/proguard-rules.pro <<'EOF'
-keep class org.json.** { *; }
-keep class androidx.media3.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.unity3d.** { *; }
-dontwarn okhttp3.**
-dontwarn org.conscrypt.**
EOF

# ------------------------------------------------------------------------------
# 10) AndroidManifest.xml
# ------------------------------------------------------------------------------
echo "📜 AndroidManifest.xml..."
cat > "${APP_MANIFEST}" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="com.google.android.gms.permission.AD_ID"/>

    <application
        android:allowBackup="true"
        android:label="@string/app_name"
        android:icon="@mipmap/ic_launcher"
        android:networkSecurityConfig="@xml/network_security_config"
        android:usesCleartextTraffic="$CLEAR_OK"
        android:theme="@style/AppTheme">

        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-3940256099942544~3347511713"/>

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:screenOrientation="portrait">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <activity android:name=".WebViewActivity" />
        <activity android:name=".PlayerActivity" android:theme="@style/PlayerTheme" />

        <service
            android:name=".MyFirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>

    </application>
</manifest>
EOF

# ------------------------------------------------------------------------------
# 11) Java sources
# ------------------------------------------------------------------------------
echo "☕ Java dosyaları..."

# AdsManager (config-based)
cat > "${JAVA_DIR}/AdsManager.java" <<'EOF'
package __PKG__;

import android.app.Activity;
import android.view.ViewGroup;
import org.json.JSONObject;
import androidx.annotation.NonNull;

import com.unity3d.ads.*;
import com.unity3d.services.banners.*;

import com.google.android.gms.ads.*;
import com.google.android.gms.ads.interstitial.*;

public class AdsManager {

    public static int counter = 0;
    private static int frequency = 3;
    private static boolean enabled = false;
    private static boolean bannerActive = false;
    private static boolean interActive = false;
    private static String provider = "UNITY";

    private static String unityGameId = "";
    private static String unityBannerId = "";
    private static String unityInterId = "";
    private static String admobBannerId = "";
    private static String admobInterId = "";

    private static InterstitialAd admobInter;

    public static void init(Activity a, JSONObject cfg) {
        try {
            if (cfg == null) return;

            enabled = cfg.optBoolean("enabled", false);
            provider = cfg.optString("provider", "UNITY");
            bannerActive = cfg.optBoolean("banner_active", false);
            interActive = cfg.optBoolean("inter_active", false);
            frequency = Math.max(1, cfg.optInt("inter_freq", 3));
            if (!enabled) return;

            if (provider.equals("UNITY") || provider.equals("BOTH")) {
                unityGameId = cfg.optString("unity_game_id", "");
                unityBannerId = cfg.optString("unity_banner_id", "");
                unityInterId = cfg.optString("unity_inter_id", "");
                if (!unityGameId.isEmpty()) {
                    UnityAds.initialize(a.getApplicationContext(), unityGameId, false, null);
                }
            }

            if (provider.equals("ADMOB") || provider.equals("BOTH")) {
                admobBannerId = cfg.optString("admob_banner_id", "");
                admobInterId = cfg.optString("admob_inter_id", "");
                MobileAds.initialize(a, status -> {});
                loadAdmobInter(a);
            }
        } catch (Exception ignored) {}
    }

    private static void loadAdmobInter(Activity a) {
        if (!interActive || admobInterId.isEmpty()) return;
        AdRequest req = new AdRequest.Builder().build();
        InterstitialAd.load(a, admobInterId, req, new InterstitialAdLoadCallback() {
            @Override public void onAdLoaded(@NonNull InterstitialAd ad) { admobInter = ad; }
        });
    }

    public static void showBanner(Activity a, ViewGroup container) {
        if (!enabled || !bannerActive) return;
        container.removeAllViews();

        if ((provider.equals("ADMOB") || provider.equals("BOTH")) && !admobBannerId.isEmpty()) {
            AdView v = new AdView(a);
            v.setAdSize(AdSize.BANNER);
            v.setAdUnitId(admobBannerId);
            container.addView(v);
            v.loadAd(new AdRequest.Builder().build());
        } else if ((provider.equals("UNITY") || provider.equals("BOTH")) && !unityBannerId.isEmpty()) {
            BannerView b = new BannerView(a, unityBannerId, new UnityBannerSize(320, 50));
            b.load();
            container.addView(b);
        }
    }

    public static void checkInter(Activity a, Runnable onComplete) {
        if (!enabled || !interActive) { onComplete.run(); return; }
        counter++;
        if (counter < frequency) { onComplete.run(); return; }
        counter = 0;

        if ((provider.equals("ADMOB") || provider.equals("BOTH")) && admobInter != null) {
            admobInter.show(a);
            admobInter = null;
            loadAdmobInter(a);
            onComplete.run();
            return;
        }

        if ((provider.equals("UNITY") || provider.equals("BOTH")) && !unityInterId.isEmpty() && UnityAds.isInitialized()) {
            UnityAds.load(unityInterId, new IUnityAdsLoadListener() {
                @Override public void onUnityAdsAdLoaded(String placementId) {
                    UnityAds.show(a, placementId, new IUnityAdsShowListener() {
                        @Override public void onUnityAdsShowComplete(String placementId, UnityAds.UnityAdsShowCompletionState state) { onComplete.run(); }
                        @Override public void onUnityAdsShowFailure(String placementId, UnityAds.UnityAdsShowError error, String message) { onComplete.run(); }
                        @Override public void onUnityAdsShowStart(String placementId) {}
                        @Override public void onUnityAdsShowClick(String placementId) {}
                    });
                }
                @Override public void onUnityAdsFailedToLoad(String placementId, UnityAds.UnityAdsLoadError error, String message) { onComplete.run(); }
            });
            return;
        }

        onComplete.run();
    }
}
EOF

# FCM
cat > "${JAVA_DIR}/MyFirebaseMessagingService.java" <<'EOF'
package __PKG__;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.media.RingtoneManager;
import android.os.Build;
import androidx.core.app.NotificationCompat;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

public class MyFirebaseMessagingService extends FirebaseMessagingService {

    @Override
    public void onMessageReceived(RemoteMessage msg) {
        if (msg.getNotification() != null) {
            send(msg.getNotification().getTitle(), msg.getNotification().getBody());
        } else if (msg.getData() != null && msg.getData().size() > 0) {
            String t = msg.getData().get("title");
            String b = msg.getData().get("body");
            if (t != null && b != null) send(t, b);
        }
    }

    @Override
    public void onNewToken(String token) {
        getSharedPreferences("TITAN_PREFS", MODE_PRIVATE)
                .edit()
                .putString("fcm_token", token)
                .apply();
    }

    private void send(String title, String body) {
        Intent intent = new Intent(this, MainActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);

        PendingIntent pi = PendingIntent.getActivity(
                this, 0, intent, PendingIntent.FLAG_ONE_SHOT | PendingIntent.FLAG_IMMUTABLE
        );

        String channelId = "TitanChannel";
        NotificationCompat.Builder nb = new NotificationCompat.Builder(this, channelId)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(title == null ? "Notification" : title)
                .setContentText(body == null ? "" : body)
                .setAutoCancel(true)
                .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
                .setContentIntent(pi);

        NotificationManager nm = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel ch = new NotificationChannel(channelId, "General", NotificationManager.IMPORTANCE_DEFAULT);
            nm.createNotificationChannel(ch);
        }
        nm.notify(0, nb.build());
    }
}
EOF

# WebViewActivity
cat > "${JAVA_DIR}/WebViewActivity.java" <<'EOF'
package __PKG__;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.*;
import android.view.KeyEvent;
import android.content.Intent;
import android.net.Uri;

public class WebViewActivity extends Activity {
    private WebView w;

    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);
        w = new WebView(this);
        setContentView(w);

        WebSettings s = w.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);

        w.setWebViewClient(new WebViewClient() {
            @Override public boolean shouldOverrideUrlLoading(WebView view, String url) {
                if (url == null) return false;
                if (url.startsWith("http")) return false;
                try { startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url))); } catch (Exception ignored) {}
                return true;
            }
        });

        String u = getIntent().getStringExtra("WEB_URL");
        if (u != null && !u.isEmpty()) w.loadUrl(u);
    }

    @Override public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK && w.canGoBack()) { w.goBack(); return true; }
        return super.onKeyDown(keyCode, event);
    }
}
EOF

# PlayerActivity (standard Media3 playback, no header injection)
cat > "${JAVA_DIR}/PlayerActivity.java" <<'EOF'
package __PKG__;

import android.app.Activity;
import android.net.Uri;
import android.os.Bundle;
import android.view.*;
import android.widget.*;
import android.graphics.Color;

import androidx.media3.common.MediaItem;
import androidx.media3.common.Player;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.ui.PlayerView;
import androidx.media3.ui.AspectRatioFrameLayout;

public class PlayerActivity extends Activity {
    private ExoPlayer player;
    private PlayerView pv;
    private ProgressBar spin;

    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);

        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION |
                View.SYSTEM_UI_FLAG_FULLSCREEN |
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        );

        FrameLayout root = new FrameLayout(this);
        root.setBackgroundColor(Color.BLACK);

        pv = new PlayerView(this);
        pv.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FIT);
        root.addView(pv, new FrameLayout.LayoutParams(-1, -1));

        spin = new ProgressBar(this);
        FrameLayout.LayoutParams sp = new FrameLayout.LayoutParams(-2, -2);
        sp.gravity = Gravity.CENTER;
        root.addView(spin, sp);

        setContentView(root);

        String url = getIntent().getStringExtra("VIDEO_URL");
        if (url != null && !url.isEmpty()) init(url);
    }

    private void init(String url) {
        player = new ExoPlayer.Builder(this).build();
        pv.setPlayer(player);

        player.addListener(new Player.Listener() {
            @Override public void onPlaybackStateChanged(int state) {
                spin.setVisibility(state == Player.STATE_BUFFERING ? View.VISIBLE : View.GONE);
            }
        });

        player.setMediaItem(new MediaItem.Builder().setUri(Uri.parse(url)).build());
        player.prepare();
        player.setPlayWhenReady(true);
    }

    @Override protected void onStop() {
        super.onStop();
        if (player != null) { player.release(); player = null; }
    }
}
EOF

# MainActivity (fetch JSON config, build menu, welcome/rate, open web/player)
cat > "${JAVA_DIR}/MainActivity.java" <<EOF
package ${PACKAGE_NAME};

import android.app.*;
import android.content.*;
import android.net.Uri;
import android.os.*;
import android.graphics.*;
import android.view.*;
import android.widget.*;

import org.json.*;
import java.io.*;
import java.net.*;
import java.util.*;

import com.bumptech.glide.Glide;
import com.google.firebase.messaging.FirebaseMessaging;

public class MainActivity extends Activity {

    private final String CONFIG_URL = "${CONFIG_URL}";
    private final String PRIVACY_URL = "${PRIVACY_URL:-}";

    private LinearLayout container;
    private LinearLayout header;
    private TextView title;
    private ImageView refresh, share, privacy;

    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);

        // Bildirim izni (Android 13+)
        if (Build.VERSION.SDK_INT >= 33) {
            try {
                if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                    requestPermissions(new String[]{android.Manifest.permission.POST_NOTIFICATIONS}, 101);
                }
            } catch (Exception ignored) {}
        }

        // FCM token kaydet
        FirebaseMessaging.getInstance().getToken().addOnCompleteListener(t -> {
            if (t.isSuccessful() && t.getResult() != null) {
                getSharedPreferences("TITAN_PREFS", MODE_PRIVATE)
                        .edit()
                        .putString("fcm_token", t.getResult())
                        .apply();
            }
        });

        RelativeLayout root = new RelativeLayout(this);

        header = new LinearLayout(this);
        header.setId(View.generateViewId());
        header.setPadding(30, 30, 30, 30);
        header.setGravity(Gravity.CENTER_VERTICAL);
        header.setBackgroundColor(Color.parseColor("#111827"));

        title = new TextView(this);
        title.setText(getString(R.string.loading));
        title.setTextColor(Color.WHITE);
        title.setTextSize(18);
        title.setTypeface(null, Typeface.BOLD);
        header.addView(title, new LinearLayout.LayoutParams(0, -2, 1f));

        privacy = new ImageView(this);
        privacy.setImageResource(android.R.drawable.ic_menu_info_details);
        privacy.setPadding(25,0,25,0);
        privacy.setOnClickListener(v -> {
            try {
                if (PRIVACY_URL != null && !PRIVACY_URL.isEmpty()) {
                    startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(PRIVACY_URL)));
                }
            } catch (Exception ignored) {}
        });
        header.addView(privacy);

        share = new ImageView(this);
        share.setImageResource(android.R.drawable.ic_menu_share);
        share.setPadding(25,0,25,0);
        share.setOnClickListener(v -> shareApp());
        header.addView(share);

        refresh = new ImageView(this);
        refresh.setImageResource(android.R.drawable.ic_popup_sync);
        refresh.setOnClickListener(v -> new Fetch().execute(CONFIG_URL));
        header.addView(refresh);

        RelativeLayout.LayoutParams hp = new RelativeLayout.LayoutParams(-1, -2);
        hp.addRule(RelativeLayout.ALIGN_PARENT_TOP);
        root.addView(header, hp);

        ScrollView sv = new ScrollView(this);
        container = new LinearLayout(this);
        container.setOrientation(LinearLayout.VERTICAL);
        container.setPadding(20, 20, 20, 40);
        sv.addView(container);

        RelativeLayout.LayoutParams sp = new RelativeLayout.LayoutParams(-1, -1);
        sp.addRule(RelativeLayout.BELOW, header.getId());
        root.addView(sv, sp);

        setContentView(root);

        new Fetch().execute(CONFIG_URL);
    }

    private void shareApp() {
        try {
            String url = "https://play.google.com/store/apps/details?id=" + getPackageName();
            Intent i = new Intent(Intent.ACTION_SEND);
            i.setType("text/plain");
            i.putExtra(Intent.EXTRA_TEXT, getString(R.string.app_name) + " - " + url);
            startActivity(Intent.createChooser(i, "Share"));
        } catch (Exception ignored) {}
    }

    private void rateDialog(JSONObject features) {
        try {
            if (features == null) return;
            JSONObject rate = features.optJSONObject("rate_us");
            if (rate == null || !rate.optBoolean("active", false)) return;

            SharedPreferences p = getSharedPreferences("TITAN_PREFS", MODE_PRIVATE);
            if (p.getBoolean("rate_dont_show", false)) return;

            int count = p.getInt("launch_count", 0) + 1;
            p.edit().putInt("launch_count", count).apply();

            int freq = Math.max(1, rate.optInt("freq", 5));
            if (count % freq != 0) return;

            new AlertDialog.Builder(this)
                .setTitle(getString(R.string.rate_title))
                .setMessage(getString(R.string.rate_msg))
                .setPositiveButton(getString(R.string.rate_now), (d,w)->{
                    try { startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=" + getPackageName()))); } catch(Exception ignored){}
                })
                .setNeutralButton(getString(R.string.dont_show_again), (d,w)-> p.edit().putBoolean("rate_dont_show", true).apply())
                .setNegativeButton(getString(R.string.later), null)
                .show();
        } catch (Exception ignored) {}
    }

    private void welcomeDialog(JSONObject features) {
        try {
            if (features == null) return;
            JSONObject pop = features.optJSONObject("welcome_popup");
            if (pop == null || !pop.optBoolean("active", false)) return;

            SharedPreferences p = getSharedPreferences("TITAN_PREFS", MODE_PRIVATE);
            if (p.getBoolean("welcome_dont_show", false)) return;

            AlertDialog.Builder b = new AlertDialog.Builder(this)
                .setTitle(pop.optString("title", "Welcome"))
                .setMessage(pop.optString("message", ""));

            b.setPositiveButton(getString(R.string.ok), null);
            b.setNeutralButton(getString(R.string.dont_show_again), (d,w)-> p.edit().putBoolean("welcome_dont_show", true).apply());
            b.show();
        } catch (Exception ignored) {}
    }

    private void addButton(String text, JSONObject mod) {
        Button b = new Button(this);
        b.setText(text);
        b.setAllCaps(false);
        b.setPadding(40, 40, 40, 40);

        GradientDrawable bg = new GradientDrawable();
        bg.setColor(Color.WHITE);
        bg.setCornerRadius(20);
        b.setBackground(bg);

        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-1, -2);
        lp.setMargins(0,0,0,18);
        b.setLayoutParams(lp);

        b.setOnClickListener(v -> {
            AdsManager.checkInter(this, () -> openModule(mod));
        });

        container.addView(b);
    }

    private void openModule(JSONObject mod) {
        try {
            String type = mod.optString("type","WEB");
            String url  = mod.optString("url","");
            if (type.equalsIgnoreCase("WEB")) {
                Intent i = new Intent(this, WebViewActivity.class);
                i.putExtra("WEB_URL", url);
                startActivity(i);
                return;
            }
            if (type.equalsIgnoreCase("PLAYER")) {
                // Standart URL oynatma (erişim kısıtı aşmaya yönelik header işlemleri yok)
                Intent i = new Intent(this, PlayerActivity.class);
                i.putExtra("VIDEO_URL", url);
                startActivity(i);
                return;
            }
        } catch (Exception ignored) {}
    }

    class Fetch extends AsyncTask<String,Void,String> {
        protected String doInBackground(String... u) {
            try {
                URL url = new URL(u[0]);
                HttpURLConnection c = (HttpURLConnection) url.openConnection();
                c.setConnectTimeout(8000);
                c.setReadTimeout(12000);
                BufferedReader r = new BufferedReader(new InputStreamReader(c.getInputStream()));
                StringBuilder s = new StringBuilder();
                String l;
                while((l=r.readLine())!=null) s.append(l);
                return s.toString();
            } catch(Exception e){ return null; }
        }
        protected void onPostExecute(String s) {
            if (s == null) return;
            try {
                JSONObject j = new JSONObject(s);

                String app = j.optString("app_name", getString(R.string.app_name));
                title.setText(app);

                JSONObject ui = j.optJSONObject("ui_config");
                if (ui != null) {
                    String headerColor = ui.optString("header_color", "#111827");
                    header.setBackgroundColor(Color.parseColor(headerColor));
                    boolean showPrivacy = ui.optBoolean("show_privacy", true);
                    privacy.setVisibility((showPrivacy && PRIVACY_URL != null && !PRIVACY_URL.isEmpty()) ? View.VISIBLE : View.GONE);
                } else {
                    privacy.setVisibility((PRIVACY_URL != null && !PRIVACY_URL.isEmpty()) ? View.VISIBLE : View.GONE);
                }

                container.removeAllViews();

                JSONArray mods = j.optJSONArray("modules");
                if (mods != null) {
                    for (int i=0;i<mods.length();i++) {
                        JSONObject m = mods.getJSONObject(i);
                        if (!m.optBoolean("active", true)) continue; // aktif/pasif
                        addButton(m.optString("title","Item"), m);
                    }
                }

                // Ads init
                AdsManager.init(MainActivity.this, j.optJSONObject("ads_config"));

                // Features
                JSONObject features = j.optJSONObject("features");
                if (ui != null && ui.has("features")) features = ui.optJSONObject("features");
                welcomeDialog(features);
                rateDialog(features);

            } catch (Exception ignored) {}
        }
    }
}
EOF

# ------------------------------------------------------------------------------
# 12) Replace placeholder package in heredocs (__PKG__)
# ------------------------------------------------------------------------------
echo "🔁 Paket isimleri uygulanıyor..."
find "${JAVA_DIR}" -type f -name "*.java" -print0 | xargs -0 sed -i "s/package __PKG__;/package ${PACKAGE_NAME};/g" || true

echo "✅ TITAN APEX V6000.10 kaynak üretimi tamamlandı."
echo "➡️ Şimdi build: ./gradlew clean assembleRelease --no-daemon"
