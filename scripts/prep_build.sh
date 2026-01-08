#!/bin/bash
set -Eeuo pipefail
IFS=$'\n\t'
trap 'echo "❌ [SCRIPTHOOK] HATA! satır=$LINENO komut=$BASH_COMMAND" >&2' ERR

# ==============================================================================
# TITAN APEX V6000.10 - ULTIMATE SOURCE GENERATOR (PLAYER MAX COMPAT EDITION)
# ==============================================================================
# - Tek dosyada tam üretim
# - Strict güvenlik + input doğrulama
# - Güçlü ikon motoru + tüm mipmap boyutları
# - TR/EN strings
# - Aktif/Pasif modül + Welcome Popup + Rate Us + Maintenance altyapısı
# - Watermark overlay
# - PLAYER: Redirect çözme + Content-Type sniff + uzantısız link desteği
# - PLAYER: HLS (.m3u8), DASH (.mpd), SmoothStreaming, RTSP, MP4/TS/AUDIO progressive
# ==============================================================================

# -----------------------
# Parametreler
# -----------------------
PACKAGE_NAME="${1:-}"
APP_NAME="${2:-}"
CONFIG_URL="${3:-}"
ICON_URL="${4:-}"
VERSION_CODE="${5:-}"
VERSION_NAME="${6:-}"
PRIVACY_URL="${7:-}"   # opsiyonel

# FFmpeg extension opsiyonel (GPL risk) - varsayılan kapalı
ENABLE_FFMPEG_EXT="${ENABLE_FFMPEG_EXT:-false}"

# Media3 sürümü (stabil bir sürüm seçildi)
MEDIA3_VER="${MEDIA3_VER:-1.9.0}"

# -----------------------
# Yardımcılar
# -----------------------
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
if ! is_pkg "$PACKAGE_NAME"; then echo "❌ Paket adı formatı hatalı: $PACKAGE_NAME"; exit 1; fi
if ! is_int "$VERSION_CODE"; then echo "❌ VERSION_CODE sayı olmalı: $VERSION_CODE"; exit 1; fi
if ! is_http_url "$CONFIG_URL"; then echo "❌ CONFIG_URL http/https olmalı: $CONFIG_URL"; exit 1; fi
if [[ -n "$ICON_URL" ]] && ! is_http_url "$ICON_URL"; then echo "❌ ICON_URL http/https olmalı: $ICON_URL"; exit 1; fi
if [[ -n "$PRIVACY_URL" ]] && ! is_http_url "$PRIVACY_URL"; then echo "❌ PRIVACY_URL http/https olmalı: $PRIVACY_URL"; exit 1; fi

echo "============================================================"
echo "   🚀 TITAN APEX V6000.10 - PROJE OLUŞTURMA BAŞLIYOR"
echo "   📦 PAKET ADI  : $PACKAGE_NAME"
echo "   📱 UYGULAMA   : $APP_NAME"
echo "   🌍 CONFIG URL : $CONFIG_URL"
echo "   🧩 MEDIA3     : $MEDIA3_VER"
echo "============================================================"

# ------------------------------------------------------------------
# 1) ImageMagick (opsiyonel)
# ------------------------------------------------------------------
echo "⚙️ [1/18] Sistem bağımlılıkları kontrol ediliyor..."
if ! command -v convert &> /dev/null; then
    echo "⚠️ 'convert' (ImageMagick) yok. Kurmayı deniyorum..."
    sudo apt-get update >/dev/null 2>&1 || true
    sudo apt-get install -y imagemagick >/dev/null 2>&1 || true
fi

# ------------------------------------------------------------------
# 2) Temizlik
# ------------------------------------------------------------------
echo "🧹 [2/18] Eski proje dosyaları temizleniyor..."
rm -rf app/src/main/res/drawable* || true
rm -rf app/src/main/res/mipmap* || true
rm -rf app/src/main/res/values* || true
rm -rf app/src/main/res/values-tr* || true
rm -rf app/src/main/java/com/base/app/* || true
rm -rf .gradle app/build build || true

# ------------------------------------------------------------------
# 3) Dizinler
# ------------------------------------------------------------------
echo "📂 [3/18] Dizin yapısı oluşturuluyor..."
mkdir -p app/src/main/java/com/base/app
mkdir -p app/src/main/res/xml
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/menu
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/values-tr

# mipmap klasörleri
mkdir -p app/src/main/res/mipmap-mdpi
mkdir -p app/src/main/res/mipmap-hdpi
mkdir -p app/src/main/res/mipmap-xhdpi
mkdir -p app/src/main/res/mipmap-xxhdpi
mkdir -p app/src/main/res/mipmap-xxxhdpi

# ------------------------------------------------------------------
# 4) İkon motoru (güçlü)
# ------------------------------------------------------------------
echo "🖼️ [4/18] Uygulama ikonu işleniyor..."
TEMP_ICON="icon_temp.png"

safe_curl_icon() {
  local url="$1"
  local out="$2"
  curl --fail --silent --show-error -L \
    --retry 3 --retry-delay 1 --connect-timeout 10 --max-time 25 \
    -A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123 Safari/537.36" \
    -o "$out" "$url" || return 1
  return 0
}

if [[ -n "$ICON_URL" ]]; then
  safe_curl_icon "$ICON_URL" "$TEMP_ICON" || true
fi

make_placeholder() {
  local out="$1"
  if command -v convert &> /dev/null; then
    convert -size 1024x1024 xc:#4f46e5 -fill white -gravity center -pointsize 260 -annotate 0 "APP" "$out"
  else
    printf '' > "$out"
  fi
}

if [ ! -s "$TEMP_ICON" ]; then
  echo "⚠️ İkon indirilemedi. Placeholder üretiliyor..."
  make_placeholder "$TEMP_ICON"
fi

gen_icon() {
  local size="$1"
  local out="$2"
  if command -v convert &> /dev/null; then
    convert "$TEMP_ICON" -resize "${size}x${size}!" -background none -flatten "$out"
  else
    cp "$TEMP_ICON" "$out"
  fi
}

gen_icon 48   app/src/main/res/mipmap-mdpi/ic_launcher.png
gen_icon 72   app/src/main/res/mipmap-hdpi/ic_launcher.png
gen_icon 96   app/src/main/res/mipmap-xhdpi/ic_launcher.png
gen_icon 144  app/src/main/res/mipmap-xxhdpi/ic_launcher.png
gen_icon 192  app/src/main/res/mipmap-xxxhdpi/ic_launcher.png

rm -f "$TEMP_ICON" || true

# ------------------------------------------------------------------
# 5) settings.gradle
# ------------------------------------------------------------------
echo "📦 [5/18] settings.gradle oluşturuluyor..."
cat > settings.gradle <<'EOF'
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

# ------------------------------------------------------------------
# 6) root build.gradle
# ------------------------------------------------------------------
echo "📦 [6/18] Root build.gradle oluşturuluyor..."
cat > build.gradle <<'EOF'
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.2.1'
        classpath 'com.google.gms:google-services:4.4.1'
    }
}
task clean(type: Delete) {
    delete rootProject.buildDir
}
EOF

# ------------------------------------------------------------------
# 7) google-services.json kontrol/onarım
# ------------------------------------------------------------------
echo "🔧 [7/18] google-services.json kontrol ediliyor..."
JSON_FILE="app/google-services.json"
if [ -f "$JSON_FILE" ]; then
    echo "✅ JSON bulundu, package_name güncelleniyor: $PACKAGE_NAME"
    sed -i 's/"package_name": *"[^"]*"/"package_name": "'"$PACKAGE_NAME"'"/g' "$JSON_FILE" || true
else
    echo "⚠️ JSON yok. Dummy oluşturuluyor (Push çalışmaz)."
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

# ------------------------------------------------------------------
# 8) app/build.gradle
# ------------------------------------------------------------------
echo "📚 [8/18] App modülü yapılandırılıyor..."
# cleartext sadece config_url https değilse açık
CLEAR_OK="true"
if [[ "$CONFIG_URL" == https://* ]]; then
  CLEAR_OK="false"
fi

# FFmpeg opsiyonel dependency (GPL) - kapalıysa eklenmez
FFMPEG_DEP=""
if [[ "$ENABLE_FFMPEG_EXT" == "true" ]]; then
  # UYARI: GPL lisanslı olabilir; ticari dağıtımda risk.
  # Jellyfin prebuilt örnek artifact:
  FFMPEG_DEP="implementation 'org.jellyfin.media3:media3-ffmpeg-decoder:1.8.0+1'"
fi

cat > app/build.gradle <<EOF
plugins {
    id 'com.android.application'
    id 'com.google.gms.google-services'
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
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'

    implementation(platform('com.google.firebase:firebase-bom:32.7.0'))
    implementation 'com.google.firebase:firebase-messaging'
    implementation 'com.google.firebase:firebase-analytics'

    // Media3 - MAX COMPAT
    implementation "androidx.media3:media3-exoplayer:\$MEDIA3_VER"
    implementation "androidx.media3:media3-exoplayer-hls:\$MEDIA3_VER"
    implementation "androidx.media3:media3-exoplayer-dash:\$MEDIA3_VER"
    implementation "androidx.media3:media3-exoplayer-smoothstreaming:\$MEDIA3_VER"
    implementation "androidx.media3:media3-exoplayer-rtsp:\$MEDIA3_VER"
    implementation "androidx.media3:media3-ui:\$MEDIA3_VER"
    implementation "androidx.media3:media3-datasource-okhttp:\$MEDIA3_VER"

    // Glide
    implementation 'com.github.bumptech.glide:glide:4.16.0'

    // Ads
    implementation 'com.unity3d.ads:unity-ads:4.9.2'
    implementation 'com.google.android.gms:play-services-ads:22.6.0'

    // OkHttp (bazı build’lerde datasource-okhttp için net olsun)
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'

    $FFMPEG_DEP
}
EOF

# ------------------------------------------------------------------
# 9) Resources + Manifest + Proguard
# ------------------------------------------------------------------
echo "📜 [9/18] Manifest ve kaynaklar oluşturuluyor..."

cat > app/src/main/res/values/strings.xml <<EOF
<resources>
    <string name="app_name">$APP_NAME</string>
    <string name="rate_title">Rate us</string>
    <string name="rate_msg">If you like the app, would you rate it 5 stars?</string>
    <string name="rate_now">Rate now</string>
    <string name="later">Later</string>
    <string name="ok">OK</string>
    <string name="dont_show_again">Don\'t show again</string>
    <string name="categories">Categories</string>
    <string name="loading">Loading...</string>
</resources>
EOF

cat > app/src/main/res/values-tr/strings.xml <<EOF
<resources>
    <string name="app_name">$APP_NAME</string>
    <string name="rate_title">Bizi Değerlendir</string>
    <string name="rate_msg">Uygulamamızı beğendiysen 5 yıldız verir misin?</string>
    <string name="rate_now">Şimdi Puanla</string>
    <string name="later">Daha Sonra</string>
    <string name="ok">Tamam</string>
    <string name="dont_show_again">Bir daha gösterme</string>
    <string name="categories">Kategoriler</string>
    <string name="loading">Yükleniyor...</string>
</resources>
EOF

cat > app/src/main/res/xml/network_security_config.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="$CLEAR_OK">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
EOF

cat > app/src/main/res/values/styles.xml <<'EOF'
<resources>
    <style name="AppTheme" parent="Theme.MaterialComponents.Light.NoActionBar">
        <item name="android:windowNoTitle">true</item>
        <item name="android:windowActionBar">false</item>
        <item name="colorPrimary">#6200EE</item>
        <item name="colorPrimaryDark">#3700B3</item>
        <item name="colorAccent">#03DAC5</item>
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

cat > app/src/main/AndroidManifest.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

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

        <activity android:name=".MainActivity"
            android:exported="true"
            android:screenOrientation="portrait">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <activity android:name=".WebViewActivity"
            android:configChanges="orientation|screenSize|keyboardHidden"/>

        <activity android:name=".ChannelListActivity" />

        <activity android:name=".PlayerActivity"
            android:configChanges="orientation|screenSize|keyboardHidden|smallestScreenSize|screenLayout"
            android:screenOrientation="sensor"
            android:theme="@style/PlayerTheme" />

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

# ------------------------------------------------------------------
# 10) AdsManager.java
# ------------------------------------------------------------------
echo "☕ [10/18] Java: AdsManager oluşturuluyor..."
cat > app/src/main/java/com/base/app/AdsManager.java <<'EOF'
package com.base.app;

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
    private static boolean isEnabled = false;
    private static boolean bannerActive = false;
    private static boolean interActive = false;
    private static String provider = "UNITY";

    private static String unityGameId = "";
    private static String unityBannerId = "";
    private static String unityInterId = "";
    private static String admobBannerId = "";
    private static String admobInterId = "";

    private static InterstitialAd mAdMobInter;

    public static void init(Activity activity, JSONObject config) {
        try {
            if (config == null) return;

            isEnabled = config.optBoolean("enabled", false);
            provider = config.optString("provider", "UNITY");
            bannerActive = config.optBoolean("banner_active");
            interActive = config.optBoolean("inter_active");
            frequency = Math.max(1, config.optInt("inter_freq", 3));
            if (!isEnabled) return;

            if (provider.equals("UNITY") || provider.equals("BOTH")) {
                unityGameId = config.optString("unity_game_id");
                unityBannerId = config.optString("unity_banner_id");
                unityInterId = config.optString("unity_inter_id");
                if (!unityGameId.isEmpty()) {
                    UnityAds.initialize(activity.getApplicationContext(), unityGameId, false, null);
                }
            }

            if (provider.equals("ADMOB") || provider.equals("BOTH")) {
                admobBannerId = config.optString("admob_banner_id");
                admobInterId = config.optString("admob_inter_id");
                MobileAds.initialize(activity, initializationStatus -> {});
                loadAdMobInter(activity);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static void loadAdMobInter(Activity activity) {
        if (!interActive || admobInterId.isEmpty()) return;

        AdRequest adRequest = new AdRequest.Builder().build();
        InterstitialAd.load(activity, admobInterId, adRequest, new InterstitialAdLoadCallback() {
            @Override
            public void onAdLoaded(@NonNull InterstitialAd interstitialAd) {
                mAdMobInter = interstitialAd;
            }
        });
    }

    public static void showBanner(Activity activity, ViewGroup container) {
        if (!isEnabled || !bannerActive) return;

        container.removeAllViews();

        if ((provider.equals("ADMOB") || provider.equals("BOTH")) && !admobBannerId.isEmpty()) {
            AdView adView = new AdView(activity);
            adView.setAdSize(AdSize.BANNER);
            adView.setAdUnitId(admobBannerId);
            container.addView(adView);
            adView.loadAd(new AdRequest.Builder().build());
        } else if ((provider.equals("UNITY") || provider.equals("BOTH")) && !unityBannerId.isEmpty()) {
            BannerView bannerView = new BannerView(activity, unityBannerId, new UnityBannerSize(320, 50));
            bannerView.load();
            container.addView(bannerView);
        }
    }

    public static void checkInter(Activity activity, Runnable onComplete) {
        if (!isEnabled || !interActive) { onComplete.run(); return; }

        counter++;
        if (counter >= frequency) {
            counter = 0;

            if ((provider.equals("ADMOB") || provider.equals("BOTH")) && mAdMobInter != null) {
                mAdMobInter.show(activity);
                mAdMobInter = null;
                loadAdMobInter(activity);
                onComplete.run();
                return;
            }

            if ((provider.equals("UNITY") || provider.equals("BOTH")) && !unityInterId.isEmpty()) {
                if (UnityAds.isInitialized()) {
                    UnityAds.load(unityInterId, new IUnityAdsLoadListener() {
                        @Override
                        public void onUnityAdsAdLoaded(String placementId) {
                            UnityAds.show(activity, placementId, new IUnityAdsShowListener() {
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
            }

            onComplete.run();
        } else {
            onComplete.run();
        }
    }
}
EOF

# ------------------------------------------------------------------
# 11) MyFirebaseMessagingService.java
# ------------------------------------------------------------------
echo "🔥 [11/18] Java: FirebaseMessagingService oluşturuluyor..."
cat > app/src/main/java/com/base/app/MyFirebaseMessagingService.java <<'EOF'
package com.base.app;

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
    public void onMessageReceived(RemoteMessage remoteMessage) {
        if (remoteMessage.getNotification() != null) {
            sendNotification(remoteMessage.getNotification().getTitle(), remoteMessage.getNotification().getBody());
        } else if (remoteMessage.getData().size() > 0) {
            String title = remoteMessage.getData().get("title");
            String body = remoteMessage.getData().get("body");
            if(title != null && body != null) sendNotification(title, body);
        }
    }

    @Override
    public void onNewToken(String token) {
        getSharedPreferences("TITAN_PREFS", MODE_PRIVATE)
            .edit()
            .putString("fcm_token", token)
            .apply();
    }

    private void sendNotification(String title, String messageBody) {
        Intent intent = new Intent(this, MainActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);

        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent,
                PendingIntent.FLAG_ONE_SHOT | PendingIntent.FLAG_IMMUTABLE);

        String channelId = "TitanChannel";

        NotificationCompat.Builder notificationBuilder =
                new NotificationCompat.Builder(this, channelId)
                        .setSmallIcon(android.R.drawable.ic_dialog_info)
                        .setContentTitle(title)
                        .setContentText(messageBody)
                        .setAutoCancel(true)
                        .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
                        .setContentIntent(pendingIntent);

        NotificationManager notificationManager =
                (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(channelId, "Genel Bildirimler", NotificationManager.IMPORTANCE_DEFAULT);
            notificationManager.createNotificationChannel(channel);
        }

        notificationManager.notify(0, notificationBuilder.build());
    }
}
EOF

# ------------------------------------------------------------------
# 12) MainActivity.java (senin sistemin - korunarak)
# ------------------------------------------------------------------
echo "📱 [12/18] Java: MainActivity oluşturuluyor..."
cat > app/src/main/java/com/base/app/MainActivity.java <<EOF
package com.base.app;

import android.app.*;
import android.content.*;
import android.os.*;
import android.view.*;
import android.widget.*;
import android.graphics.*;
import android.graphics.drawable.*;
import android.net.Uri;
import android.content.pm.PackageManager;

import org.json.*;
import java.io.*;
import java.net.*;
import java.util.*;

import com.bumptech.glide.Glide;
import com.google.firebase.messaging.FirebaseMessaging;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import com.google.android.material.bottomnavigation.BottomNavigationView;

public class MainActivity extends Activity {

    private String CONFIG_URL = "$CONFIG_URL";
    private String PRIVACY_URL = "${PRIVACY_URL}";
    private LinearLayout container;
    private TextView titleTxt;
    private ImageView splash, refreshBtn, shareBtn, tgBtn;
    private LinearLayout headerLayout, currentRow;

    private String hColor="#2196F3", tColor="#FFFFFF", bColor="#F0F0F0", fColor="#FF9800", menuType="LIST";
    private String listType="CLASSIC", listItemBg="#FFFFFF", listIconShape="SQUARE", listBorderColor="#DDDDDD";
    private int listRadius=0, listBorderWidth=0;
    private String playerConfigStr="{}";
    private String telegramUrl="";
    private JSONObject featureConfig;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        if (Build.VERSION.SDK_INT >= 33) {
            if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, new String[]{android.Manifest.permission.POST_NOTIFICATIONS}, 101);
            }
        }

        FirebaseMessaging.getInstance().getToken().addOnCompleteListener(task -> {
            if (task.isSuccessful() && task.getResult() != null) {
                String token = task.getResult();
                getSharedPreferences("TITAN_PREFS", MODE_PRIVATE).edit().putString("fcm_token", token).apply();
                syncToken(token);
            }
        });

        RelativeLayout root = new RelativeLayout(this);

        splash = new ImageView(this);
        splash.setScaleType(ImageView.ScaleType.CENTER_CROP);
        root.addView(splash, new RelativeLayout.LayoutParams(-1,-1));

        headerLayout = new LinearLayout(this);
        headerLayout.setId(View.generateViewId());
        headerLayout.setPadding(30,30,30,30);
        headerLayout.setGravity(Gravity.CENTER_VERTICAL);
        headerLayout.setElevation(10f);

        titleTxt = new TextView(this);
        titleTxt.setTextSize(20);
        titleTxt.setTypeface(null, Typeface.BOLD);
        headerLayout.addView(titleTxt, new LinearLayout.LayoutParams(0, -2, 1.0f));

        tgBtn = new ImageView(this);
        tgBtn.setImageResource(android.R.drawable.ic_dialog_email);
        tgBtn.setPadding(20,0,20,0);
        tgBtn.setOnClickListener(v -> {
            try { if(telegramUrl != null && !telegramUrl.isEmpty()) startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(telegramUrl))); }
            catch(Exception e){}
        });
        headerLayout.addView(tgBtn);

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

        ScrollView sv = new ScrollView(this);
        sv.setId(View.generateViewId());
        container = new LinearLayout(this);
        container.setOrientation(LinearLayout.VERTICAL);
        container.setPadding(20,20,20,150);
        sv.addView(container);

        RelativeLayout.LayoutParams sp = new RelativeLayout.LayoutParams(-1,-1);
        sp.addRule(RelativeLayout.BELOW, headerLayout.getId());
        root.addView(sv, sp);

        setContentView(root);
        new Fetch().execute(CONFIG_URL);
    }

    private void syncToken(String token) {
        new Thread(() -> {
            try {
                String baseUrl;
                if (CONFIG_URL.contains("api.php")) baseUrl = CONFIG_URL.substring(0, CONFIG_URL.indexOf("api.php"));
                else baseUrl = CONFIG_URL.substring(0, CONFIG_URL.lastIndexOf("/") + 1);

                URL url = new URL(baseUrl + "update_token.php");
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setRequestMethod("POST");
                conn.setDoOutput(true);
                conn.setConnectTimeout(8000);
                conn.setReadTimeout(12000);

                String data = "fcm_token=" + URLEncoder.encode(token, "UTF-8") +
                        "&package_name=" + URLEncoder.encode(getPackageName(), "UTF-8");

                OutputStream os = conn.getOutputStream();
                os.write(data.getBytes());
                os.flush();
                os.close();

                conn.getResponseCode();
                conn.disconnect();
            } catch (Exception e) {}
        }).start();
    }

    private void shareApp() {
        startActivity(Intent.createChooser(
            new Intent(Intent.ACTION_SEND)
                .setType("text/plain")
                .putExtra(Intent.EXTRA_TEXT, titleTxt.getText() + " Download: https://play.google.com/store/apps/details?id=" + getPackageName()),
            "Share"
        ));
    }

    private void checkRateUs() {
        SharedPreferences prefs = getSharedPreferences("TITAN_PREFS", MODE_PRIVATE);
        boolean dont = prefs.getBoolean("rate_dont_show", false);
        if(dont) return;

        int count = prefs.getInt("launch_count", 0) + 1;
        prefs.edit().putInt("launch_count", count).apply();

        if (featureConfig == null) return;
        JSONObject rate = featureConfig.optJSONObject("rate_us");
        if (rate != null && rate.optBoolean("active", false)) {
            int freq = Math.max(1, rate.optInt("freq", 5));
            if (count % freq == 0) {
                new AlertDialog.Builder(this)
                    .setTitle(getString(R.string.rate_title))
                    .setMessage(getString(R.string.rate_msg))
                    .setPositiveButton(getString(R.string.rate_now), (d, w) -> {
                        try { startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=" + getPackageName()))); } catch(Exception e){}
                    })
                    .setNeutralButton(getString(R.string.dont_show_again), (d, w) -> prefs.edit().putBoolean("rate_dont_show", true).apply())
                    .setNegativeButton(getString(R.string.later), null)
                    .show();
            }
        }
    }

    private void checkWelcomePopup() {
        if (featureConfig == null) return;
        JSONObject pop = featureConfig.optJSONObject("welcome_popup");
        if (pop != null && pop.optBoolean("active", false)) {

            SharedPreferences prefs = getSharedPreferences("TITAN_PREFS", MODE_PRIVATE);
            boolean dont = prefs.getBoolean("welcome_dont_show", false);
            if(dont) return;

            AlertDialog.Builder b = new AlertDialog.Builder(this);
            b.setTitle(pop.optString("title", "Notice"));
            b.setMessage(pop.optString("message", "Welcome!"));

            String imgUrl = pop.optString("image", "");
            if(!imgUrl.isEmpty()) {
                ImageView iv = new ImageView(this);
                iv.setAdjustViewBounds(true);
                Glide.with(this).load(imgUrl).into(iv);
                b.setView(iv);
            }

            b.setPositiveButton(getString(R.string.ok), null);
            b.setNeutralButton(getString(R.string.dont_show_again), (d, w) -> prefs.edit().putBoolean("welcome_dont_show", true).apply());
            b.show();
        }
    }

    private void renderBottomNav(JSONArray modules) {
        try {
            View svParent = (View) container.getParent();
            RelativeLayout root = (RelativeLayout) svParent.getParent();

            BottomNavigationView bnv = new BottomNavigationView(this);
            bnv.setId(View.generateViewId());
            bnv.setBackgroundColor(Color.WHITE);
            bnv.setElevation(20f);

            ArrayList<Integer> map = new ArrayList<>();
            for(int i=0;i<modules.length();i++){
                JSONObject m = modules.getJSONObject(i);
                if(m.optBoolean("active", true)) map.add(i);
                if(map.size()>=5) break;
            }

            for(int i=0;i<map.size();i++){
                JSONObject m = modules.getJSONObject(map.get(i));
                bnv.getMenu().add(0, i, 0, m.optString("title","Item")).setIcon(android.R.drawable.ic_menu_view);
            }

            bnv.setOnNavigationItemSelectedListener(item -> {
                try {
                    int idx = map.get(item.getItemId());
                    JSONObject m = modules.getJSONObject(idx);
                    JSONObject h = new JSONObject();
                    if(m.has("ua")) h.put("User-Agent", m.optString("ua",""));
                    if(m.has("ref")) h.put("Referer", m.optString("ref",""));
                    if(m.has("org")) h.put("Origin", m.optString("org",""));
                    open(m.getString("type"), m.optString("url",""), m.optString("content",""), h.toString());
                } catch(Exception e){}
                return true;
            });

            RelativeLayout.LayoutParams lp = new RelativeLayout.LayoutParams(-1, -2);
            lp.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
            root.addView(bnv, lp);

            View sv = (View) container.getParent();
            RelativeLayout.LayoutParams sp = (RelativeLayout.LayoutParams) sv.getLayoutParams();
            sp.addRule(RelativeLayout.ABOVE, bnv.getId());
            sv.setLayoutParams(sp);

        } catch(Exception e) { e.printStackTrace(); }
    }

    private void applyMenuStyle(View v, int mode) {
        int base = Color.parseColor(hColor);
        int focus = Color.parseColor(fColor);

        GradientDrawable normal = new GradientDrawable();
        GradientDrawable focused = new GradientDrawable();

        if(mode==0){
            normal.setColor(base); normal.setCornerRadius(18);
            focused.setColor(focus); focused.setCornerRadius(18);
            focused.setStroke(5, Color.WHITE);
        } else if(mode==1){
            normal.setColor(adjust(base, 0.10f)); normal.setCornerRadius(28);
            focused.setColor(adjust(focus, 0.10f)); focused.setCornerRadius(28);
            focused.setStroke(6, Color.WHITE);
        } else if(mode==2){
            normal.setColor(adjust(base, -0.10f)); normal.setCornerRadius(22);
            normal.setStroke(2, Color.parseColor("#80FFFFFF"));
            focused.setColor(focus); focused.setCornerRadius(22);
            focused.setStroke(6, Color.WHITE);
        } else {
            normal.setColor(Color.parseColor("#ffffff"));
            normal.setCornerRadius(26);
            normal.setStroke(3, base);
            focused.setColor(Color.parseColor("#ffffff"));
            focused.setCornerRadius(26);
            focused.setStroke(7, focus);
        }

        StateListDrawable s = new StateListDrawable();
        s.addState(new int[]{android.R.attr.state_focused}, focused);
        s.addState(new int[]{android.R.attr.state_pressed}, focused);
        s.addState(new int[]{}, normal);
        v.setBackground(s);
        v.setFocusable(true);
        v.setClickable(true);
    }

    private int adjust(int color, float amount){
        int r = (int)Math.min(255, Math.max(0, Color.red(color) * (1f+amount)));
        int g = (int)Math.min(255, Math.max(0, Color.green(color) * (1f+amount)));
        int b = (int)Math.min(255, Math.max(0, Color.blue(color) * (1f+amount)));
        return Color.rgb(r,g,b);
    }

    private void addBtn(String txt, String type, String url, String cont, String ua, String ref, String org) {
        JSONObject h = new JSONObject();
        try {
            if(ua!=null && !ua.isEmpty()) h.put("User-Agent",ua);
            if(ref!=null && !ref.isEmpty()) h.put("Referer",ref);
            if(org!=null && !org.isEmpty()) h.put("Origin",org);
        } catch(Exception e){}
        String hStr = h.toString();

        if(menuType.equals("GRID")) {
            if(currentRow == null || currentRow.getChildCount() >= 2) {
                currentRow = new LinearLayout(this);
                currentRow.setOrientation(LinearLayout.HORIZONTAL);
                currentRow.setWeightSum(2);
                container.addView(currentRow);
            }
            Button b = new Button(this);
            b.setText(txt);
            b.setTextColor(Color.parseColor(tColor));
            applyMenuStyle(b, 1);

            LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, 220, 1.0f);
            p.setMargins(10,10,10,10);
            b.setLayoutParams(p);

            b.setOnClickListener(x -> AdsManager.checkInter(this, () -> open(type, url, cont, hStr)));
            currentRow.addView(b);
            return;
        }

        if(menuType.equals("CARD")) {
            TextView t = new TextView(this);
            t.setText(txt);
            t.setTextSize(22);
            t.setGravity(Gravity.CENTER);
            t.setTextColor(Color.parseColor(tColor));
            t.setPadding(50,150,50,150);
            applyMenuStyle(t, 2);

            LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, -2);
            p.setMargins(0,0,0,30);
            t.setLayoutParams(p);
            t.setOnClickListener(x -> AdsManager.checkInter(this, () -> open(type, url, cont, hStr)));
            container.addView(t);
            return;
        }

        if(menuType.equals("ULTRA")) {
            LinearLayout box = new LinearLayout(this);
            box.setOrientation(LinearLayout.VERTICAL);
            box.setPadding(35,35,35,35);
            applyMenuStyle(box, 3);

            TextView t = new TextView(this);
            t.setText(txt);
            t.setTextSize(18);
            t.setTypeface(null, Typeface.BOLD);
            t.setTextColor(Color.parseColor("#111827"));
            box.addView(t);

            TextView sub = new TextView(this);
            sub.setText(type);
            sub.setTextSize(12);
            sub.setTextColor(Color.parseColor("#6b7280"));
            box.addView(sub);

            LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, -2);
            p.setMargins(0,0,0,18);
            box.setLayoutParams(p);

            box.setOnClickListener(x -> AdsManager.checkInter(this, () -> open(type, url, cont, hStr)));
            container.addView(box);
            return;
        }

        Button b = new Button(this);
        b.setText(txt);
        b.setPadding(40,40,40,40);
        b.setTextColor(Color.parseColor(tColor));
        applyMenuStyle(b, 0);

        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, -2);
        p.setMargins(0,0,0,20);
        b.setLayoutParams(p);
        b.setOnClickListener(x -> AdsManager.checkInter(this, () -> open(type, url, cont, hStr)));
        container.addView(b);
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
            if(s==null) return;
            try {
                JSONObject j = new JSONObject(s);
                JSONObject ui = j.optJSONObject("ui_config");
                featureConfig = (ui!=null && ui.has("features")) ? ui.optJSONObject("features") : j.optJSONObject("features");

                if(ui != null) {
                    hColor = ui.optString("header_color", hColor);
                    bColor = ui.optString("bg_color", bColor);
                    tColor = ui.optString("text_color", tColor);
                    fColor = ui.optString("focus_color", fColor);
                    menuType = ui.optString("menu_type", menuType);

                    listType = ui.optString("list_type", listType);
                    listItemBg = ui.optString("list_item_bg", listItemBg);
                    listRadius = ui.optInt("list_item_radius", listRadius);
                    listIconShape = ui.optString("list_icon_shape", listIconShape);
                    listBorderWidth = ui.optInt("list_border_width", listBorderWidth);
                    listBorderColor = ui.optString("list_border_color", listBorderColor);

                    telegramUrl = ui.optString("telegram_url", "");
                    String customHeader = ui.optString("custom_header_text", "");

                    titleTxt.setText(customHeader.isEmpty() ? j.optString("app_name", getString(R.string.app_name)) : customHeader);
                    titleTxt.setTextColor(Color.parseColor(tColor));
                    headerLayout.setBackgroundColor(Color.parseColor(hColor));
                    ((View)container.getParent()).setBackgroundColor(Color.parseColor(bColor));

                    if(!ui.optBoolean("show_header", true)) headerLayout.setVisibility(View.GONE);
                    refreshBtn.setVisibility(ui.optBoolean("show_refresh", true) ? View.VISIBLE : View.GONE);
                    shareBtn.setVisibility(ui.optBoolean("show_share", true) ? View.VISIBLE : View.GONE);
                    tgBtn.setVisibility((telegramUrl!=null && !telegramUrl.isEmpty()) ? View.VISIBLE : View.GONE);

                    String spl = ui.optString("splash_image", "");
                    if(!spl.isEmpty()){
                        if(!spl.startsWith("http")) {
                            String base = CONFIG_URL.substring(0, CONFIG_URL.lastIndexOf("/") + 1);
                            spl = base + spl;
                        }
                        splash.setVisibility(View.VISIBLE);
                        Glide.with(MainActivity.this).load(spl).into(splash);
                        new Handler().postDelayed(() -> splash.setVisibility(View.GONE), 3000);
                    }

                    String sm = ui.optString("startup_mode", "MENU");
                    if(sm.equals("DIRECT")) {
                        String dType = ui.optString("direct_type", "WEB");
                        String dUrl = ui.optString("direct_url", "");
                        if(dType.equals("WEB")) {
                            Intent i = new Intent(MainActivity.this, WebViewActivity.class);
                            i.putExtra("WEB_URL", dUrl);
                            startActivity(i);
                        } else {
                            open(dType, dUrl, "", "{}");
                        }
                        finish();
                        return;
                    } else if(sm.equals("KIOSK_WEB")) {
                        String dUrl = ui.optString("direct_url", "");
                        Intent i = new Intent(MainActivity.this, WebViewActivity.class);
                        i.putExtra("WEB_URL", dUrl);
                        startActivity(i);
                        finish();
                        return;
                    } else if(sm.equals("FIRST_ACTIVE")) {
                        JSONArray mods = j.optJSONArray("modules");
                        if(mods != null) {
                            for(int x=0;x<mods.length();x++){
                                JSONObject m = mods.getJSONObject(x);
                                if(m.optBoolean("active", true)){
                                    JSONObject h = new JSONObject();
                                    if(m.has("ua")) h.put("User-Agent", m.optString("ua",""));
                                    if(m.has("ref")) h.put("Referer", m.optString("ref",""));
                                    if(m.has("org")) h.put("Origin", m.optString("org",""));
                                    open(m.optString("type","WEB"), m.optString("url",""), m.optString("content",""), h.toString());
                                    finish();
                                    return;
                                }
                            }
                        }
                    }
                }

                JSONObject pc = j.optJSONObject("player_config");
                if(pc != null) playerConfigStr = pc.toString();

                container.removeAllViews();
                currentRow = null;

                JSONArray m = j.optJSONArray("modules");
                if(m == null) return;

                if(menuType.equals("BOTTOM")) {
                    renderBottomNav(m);
                } else {
                    for(int i=0; i<m.length(); i++) {
                        JSONObject o = m.getJSONObject(i);
                        if(!o.optBoolean("active", true)) continue;
                        addBtn(
                            o.optString("title","Item"),
                            o.optString("type","WEB"),
                            o.optString("url",""),
                            o.optString("content",""),
                            o.optString("ua",""),
                            o.optString("ref",""),
                            o.optString("org","")
                        );
                    }
                }

                AdsManager.init(MainActivity.this, j.optJSONObject("ads_config"));
                checkRateUs();
                checkWelcomePopup();

            } catch(Exception e){}
        }
    }
}
EOF

# ------------------------------------------------------------------
# 13) WebViewActivity.java
# ------------------------------------------------------------------
echo "🌐 [13/18] Java: WebViewActivity oluşturuluyor..."
cat > app/src/main/java/com/base/app/WebViewActivity.java <<'EOF'
package com.base.app;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.*;
import android.util.Base64;
import android.content.Intent;
import android.net.Uri;
import android.view.KeyEvent;

public class WebViewActivity extends Activity {
    private WebView w;

    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        w = new WebView(this);
        setContentView(w);

        WebSettings ws = w.getSettings();
        ws.setJavaScriptEnabled(true);
        ws.setDomStorageEnabled(true);
        ws.setAllowFileAccess(true);
        ws.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);

        w.addJavascriptInterface(new WebAppInterface(this), "Android");

        w.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                String token = getSharedPreferences("TITAN_PREFS", MODE_PRIVATE).getString("fcm_token", "");
                if(!token.isEmpty()) {
                    w.loadUrl("javascript:if(typeof onTokenReceived === 'function'){ onTokenReceived('" + token + "'); }");
                }
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                if (url.startsWith("http")) return false;
                try { startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url))); } catch (Exception e) {}
                return true;
            }
        });

        String u = getIntent().getStringExtra("WEB_URL");
        String h = getIntent().getStringExtra("HTML_DATA");

        if(h != null && !h.isEmpty()) {
            w.loadData(Base64.encodeToString(h.getBytes(), Base64.NO_PADDING), "text/html", "base64");
        } else {
            w.loadUrl(u);
        }
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK && w.canGoBack()) {
            w.goBack();
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }

    public class WebAppInterface {
        Activity mContext;
        WebAppInterface(Activity c) { mContext = c; }

        @JavascriptInterface
        public void saveUserId(String userId) {
            mContext.getSharedPreferences("TITAN_PREFS", MODE_PRIVATE)
                .edit()
                .putString("user_id", userId)
                .apply();
        }
    }
}
EOF

# ------------------------------------------------------------------
# 14) ChannelListActivity.java
# ------------------------------------------------------------------
echo "📋 [14/18] Java: ChannelListActivity oluşturuluyor..."
cat > app/src/main/java/com/base/app/ChannelListActivity.java <<'EOF'
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

    protected void onCreate(Bundle s) {
        super.onCreate(s);
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
        title.setText(getString(R.string.loading));
        title.setTextColor(Color.parseColor(tC));
        title.setTextSize(18);
        h.addView(title);
        r.addView(h);

        lv = new ListView(this);
        lv.setDivider(null);
        lv.setPadding(20, 20, 20, 20);
        lv.setClipToPadding(false);
        lv.setOverScrollMode(2);
        lv.setFastScrollEnabled(true);

        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-1, 0, 1.0f);
        r.addView(lv, lp);
        setContentView(r);

        new Load(getIntent().getStringExtra("TYPE"), getIntent().getStringExtra("LIST_CONTENT"))
            .execute(getIntent().getStringExtra("LIST_URL"));

        lv.setOnItemClickListener((p, v, pos, id) -> {
            if (isGroup) showCh(gNames.get(pos));
            else AdsManager.checkInter(this, () -> {
                Intent i = new Intent(this, PlayerActivity.class);
                i.putExtra("VIDEO_URL", curList.get(pos).u);
                i.putExtra("HEADERS_JSON", curList.get(pos).h);
                i.putExtra("PLAYER_CONFIG", pCfg);
                startActivity(i);
            });
        });
    }

    public void onBackPressed() {
        if (!isGroup && gNames.size() > 1) showGr();
        else super.onBackPressed();
    }

    void showGr() { isGroup = true; title.setText(getString(R.string.categories)); lv.setAdapter(new Adp(gNames, true)); }
    void showCh(String g) { isGroup = false; title.setText(g); curList = groups.get(g); lv.setAdapter(new Adp(curList, false)); }

    class Load extends AsyncTask<String, Void, String> {
        String t, c;
        Load(String ty, String co) { t = ty; c = co; }

        protected String doInBackground(String... u) {
            if ("MANUAL_M3U".equals(t)) return c;
            try {
                URL url = new URL(u[0]);
                HttpURLConnection cn = (HttpURLConnection) url.openConnection();
                cn.setRequestProperty("User-Agent", "Mozilla/5.0");
                cn.setConnectTimeout(8000);
                cn.setReadTimeout(12000);
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

                if ("JSON_LIST".equals(t) || r.trim().startsWith("{")) {
                    JSONObject rt = new JSONObject(r);
                    JSONArray ar = rt.getJSONObject("list").getJSONArray("item");
                    String fl = "List";
                    groups.put(fl, new ArrayList<>());
                    gNames.add(fl);
                    for (int i = 0; i < ar.length(); i++) {
                        JSONObject o = ar.getJSONObject(i);
                        String u = o.optString("media_url", o.optString("url"));
                        if (u.isEmpty()) continue;
                        JSONObject hd = new JSONObject();
                        for (int k = 1; k <= 5; k++) {
                            String kn = o.optString("h" + k + "Key"), kv = o.optString("h" + k + "Val");
                            if (!kn.isEmpty() && !kn.equals("0")) hd.put(kn, kv);
                        }
                        groups.get(fl).add(new Item(o.optString("title"), u.trim(), o.optString("thumb_square"), hd.toString()));
                    }
                }

                if (groups.isEmpty()) {
                    String[] ln = r.split("\n");
                    String ct = "Channel", ci = "", cg = "General";
                    JSONObject ch = new JSONObject();
                    Pattern pg = Pattern.compile("group-title=\"([^\"]*)\"");
                    Pattern pl = Pattern.compile("tvg-logo=\"([^\"]*)\"");

                    for (String l : ln) {
                        l = l.trim();
                        if (l.isEmpty()) continue;

                        if (l.startsWith("#EXTINF")) {
                            if (l.contains(",")) ct = l.substring(l.lastIndexOf(",") + 1).trim();
                            Matcher mg = pg.matcher(l); if (mg.find()) cg = mg.group(1);
                            Matcher ml = pl.matcher(l); if (ml.find()) ci = ml.group(1);

                        } else if (l.startsWith("#EXTVLCOPT:")) {
                            String op = l.substring(11);
                            if (op.startsWith("http-referrer=")) ch.put("Referer", op.substring(14));
                            if (op.startsWith("http-user-agent=")) ch.put("User-Agent", op.substring(16));
                            if (op.startsWith("http-origin=")) ch.put("Origin", op.substring(12));

                        } else if (!l.startsWith("#")) {
                            if (!groups.containsKey(cg)) { groups.put(cg, new ArrayList<>()); gNames.add(cg); }
                            groups.get(cg).add(new Item(ct, l.trim(), ci, ch.toString()));
                            ct = "Channel"; ci = ""; ch = new JSONObject();
                        }
                    }
                }

                if (gNames.size() > 1) showGr();
                else if (gNames.size() == 1) showCh(gNames.get(0));

            } catch (Exception e) {}
        }
    }

    class Adp extends BaseAdapter {
        List<?> d; boolean g;
        Adp(List<?> l, boolean is) { d = l; g = is; }
        public int getCount() { return d.size(); }
        public Object getItem(int p) { return d.get(p); }
        public long getItemId(int p) { return p; }
        public View getView(int p, View v, ViewGroup gr) {
            if (v == null) {
                LinearLayout l = new LinearLayout(ChannelListActivity.this);
                l.setOrientation(0);
                l.setGravity(16);

                ImageView i = new ImageView(ChannelListActivity.this);
                i.setId(1);
                l.addView(i);

                TextView t = new TextView(ChannelListActivity.this);
                t.setId(2);
                l.addView(t);

                v = l;
            }
            LinearLayout l = (LinearLayout) v;

            GradientDrawable n = new GradientDrawable();
            n.setColor(Color.parseColor(lBg));
            n.setCornerRadius(lRad);
            if (lBW > 0) n.setStroke(lBW, Color.parseColor(lBC));

            GradientDrawable f = new GradientDrawable();
            f.setColor(Color.parseColor(fC));
            f.setCornerRadius(lRad);
            f.setStroke(Math.max(3, lBW + 2), Color.WHITE);

            StateListDrawable sl = new StateListDrawable();
            sl.addState(new int[]{android.R.attr.state_focused}, f);
            sl.addState(new int[]{android.R.attr.state_pressed}, f);
            sl.addState(new int[]{}, n);
            l.setBackground(sl);

            LinearLayout.LayoutParams pa = new LinearLayout.LayoutParams(-1, -2);
            if ("CARD".equals(lType)) { pa.setMargins(0, 0, 0, 25); l.setPadding(30, 30, 30, 30); l.setElevation(5f); }
            else if ("MODERN".equals(lType)) { pa.setMargins(0, 0, 0, 15); l.setPadding(20, 50, 20, 50); }
            else { pa.setMargins(0, 0, 0, 8); l.setPadding(20, 20, 20, 20); }
            l.setLayoutParams(pa);

            ImageView im = v.findViewById(1);
            TextView tx = v.findViewById(2);
            tx.setTextColor(Color.parseColor(tC));

            im.setLayoutParams(new LinearLayout.LayoutParams(120, 120));
            ((LinearLayout.LayoutParams) im.getLayoutParams()).setMargins(0, 0, 30, 0);

            RequestOptions op = new RequestOptions();
            if ("CIRCLE".equals(lIcon)) op = op.circleCrop();

            if (g) {
                tx.setText(d.get(p).toString());
                im.setImageResource(android.R.drawable.ic_menu_sort_by_size);
                im.setColorFilter(Color.parseColor(hC));
            } else {
                Item i = (Item) d.get(p);
                tx.setText(i.n);
                if (!i.i.isEmpty()) Glide.with(ChannelListActivity.this).load(i.i).apply(op).into(im);
                else im.setImageResource(android.R.drawable.ic_menu_slideshow);
                im.clearColorFilter();
            }
            return v;
        }
    }
}
EOF

# ------------------------------------------------------------------
# 15) PlayerActivity.java (MAX FORMAT + uzantısız + redirect + sniff)
# ------------------------------------------------------------------
echo "🎥 [15/18] Java: PlayerActivity (MAX COMPAT) oluşturuluyor..."
cat > app/src/main/java/com/base/app/PlayerActivity.java <<'EOF'
package com.base.app;

import android.app.Activity;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.*;
import android.widget.*;
import android.graphics.Color;
import android.graphics.Typeface;

import androidx.media3.common.*;
import androidx.media3.datasource.DefaultHttpDataSource;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory;
import androidx.media3.ui.PlayerView;
import androidx.media3.ui.AspectRatioFrameLayout;
import androidx.media3.exoplayer.DefaultLoadControl;
import androidx.media3.exoplayer.upstream.DefaultAllocator;

import org.json.JSONObject;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.*;

public class PlayerActivity extends Activity {
    private ExoPlayer pl;
    private PlayerView pv;
    private ProgressBar spin;
    private String vid, hdr, cfgStr;

    // Sniff limit
    private static final int SNIFF_BYTES = 2048;

    protected void onCreate(Bundle s) {
        super.onCreate(s);

        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION |
            View.SYSTEM_UI_FLAG_FULLSCREEN |
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        );

        FrameLayout r = new FrameLayout(this);
        r.setBackgroundColor(Color.BLACK);

        pv = new PlayerView(this);
        pv.setShowNextButton(false);
        pv.setShowPreviousButton(false);
        r.addView(pv);

        spin = new ProgressBar(this);
        FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(-2, -2);
        lp.gravity = Gravity.CENTER;
        r.addView(spin, lp);

        cfgStr = getIntent().getStringExtra("PLAYER_CONFIG");
        vid = getIntent().getStringExtra("VIDEO_URL");
        hdr = getIntent().getStringExtra("HEADERS_JSON");

        // Overlay + resize + rotate
        try {
            JSONObject c = (cfgStr != null && !cfgStr.isEmpty()) ? new JSONObject(cfgStr) : new JSONObject();

            String rm = c.optString("resize_mode", "FIT");
            if (rm.equals("FILL")) pv.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FILL);
            else if (rm.equals("ZOOM")) pv.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_ZOOM);
            else pv.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FIT);

            if (!c.optBoolean("auto_rotate", true)) setRequestedOrientation(0);

            boolean overlay = c.optBoolean("enable_overlay", false);
            if (overlay) {
                String txt = c.optString("watermark_text", "");
                String col = c.optString("watermark_color", "#FFFFFF");
                String pos = c.optString("watermark_pos", "left");
                String bg  = c.optString("watermark_bg", "#80000000");
                int size = Math.max(10, c.optInt("watermark_size", 16));

                TextView o = new TextView(this);
                o.setText(txt);
                o.setTextColor(Color.parseColor(col));
                o.setTextSize(size);
                o.setTypeface(Typeface.DEFAULT_BOLD);
                o.setPadding(22, 16, 22, 16);
                o.setBackgroundColor(Color.parseColor(bg));

                FrameLayout.LayoutParams p = new FrameLayout.LayoutParams(-2, -2);
                if (pos.equals("right")) p.gravity = Gravity.TOP | Gravity.END;
                else p.gravity = Gravity.TOP | Gravity.START;

                p.topMargin = 26;
                p.leftMargin = 26;
                p.rightMargin = 26;

                r.addView(o, p);
            }
        } catch (Exception e) {}

        setContentView(r);

        if (vid != null && !vid.isEmpty()) new Resolve().execute(vid.trim());
    }

    static class Info {
        String finalUrl;
        String mime; // Media3 MimeTypes or null
        Info(String u, String m) { finalUrl = u; mime = m; }
    }

    private HttpURLConnection openConn(String url, String method, boolean range) throws Exception {
        URL u = new URL(url);
        HttpURLConnection c = (HttpURLConnection) u.openConnection();
        c.setRequestMethod(method);
        c.setInstanceFollowRedirects(false);
        c.setConnectTimeout(9000);
        c.setReadTimeout(14000);

        // headers
        String ua = "Mozilla/5.0";
        if (hdr != null && !hdr.isEmpty()) {
            JSONObject h = new JSONObject(hdr);
            Iterator<String> k = h.keys();
            while (k.hasNext()) {
                String key = k.next();
                String val = h.optString(key, "");
                if (val == null) val = "";
                if (key.equalsIgnoreCase("User-Agent")) ua = val;
                else c.setRequestProperty(key, val);
            }
        }
        c.setRequestProperty("User-Agent", ua);

        if (range) {
            c.setRequestProperty("Range", "bytes=0-" + (SNIFF_BYTES - 1));
        }
        return c;
    }

    private boolean looksLikeM3U(String s) {
        if (s == null) return false;
        s = s.trim();
        return s.startsWith("#EXTM3U") || s.contains("#EXT-X-STREAM-INF") || s.contains("#EXT-X-TARGETDURATION");
    }

    private boolean looksLikeMPD(String s) {
        if (s == null) return false;
        String t = s.trim();
        return t.startsWith("<?xml") && t.contains("<MPD") || t.startsWith("<MPD");
    }

    private boolean looksLikeSS(String s) {
        if (s == null) return false;
        String t = s.trim();
        return t.contains("SmoothStreamingMedia");
    }

    private String mimeFromUrl(String u) {
        String x = u.toLowerCase(Locale.ROOT);
        if (x.contains(".m3u8")) return MimeTypes.APPLICATION_M3U8;
        if (x.contains(".mpd")) return MimeTypes.APPLICATION_MPD;
        if (x.contains(".ism/manifest") || x.contains("manifest(format=mpd-time-csf)") || x.contains("smoothstreaming")) return MimeTypes.APPLICATION_SS;
        if (x.startsWith("rtsp://")) return MimeTypes.APPLICATION_RTSP;

        if (x.endsWith(".mp3")) return MimeTypes.AUDIO_MPEG;
        if (x.endsWith(".m4a")) return MimeTypes.AUDIO_MP4;
        if (x.endsWith(".aac")) return MimeTypes.AUDIO_AAC;
        if (x.endsWith(".wav")) return MimeTypes.AUDIO_WAV;
        if (x.endsWith(".flac")) return MimeTypes.AUDIO_FLAC;
        if (x.endsWith(".ogg") || x.endsWith(".opus")) return MimeTypes.AUDIO_OGG;

        if (x.endsWith(".ts")) return MimeTypes.VIDEO_MP2T;
        if (x.endsWith(".mp4") || x.endsWith(".mkv") || x.endsWith(".webm") || x.endsWith(".mov")) return MimeTypes.VIDEO_MP4; // progressive için net olmak adına
        return null;
    }

    private String mimeFromContentType(String ct) {
        if (ct == null) return null;
        ct = ct.toLowerCase(Locale.ROOT);
        if (ct.contains("mpegurl") || ct.contains("application/vnd.apple.mpegurl")) return MimeTypes.APPLICATION_M3U8;
        if (ct.contains("dash") || ct.contains("mpd")) return MimeTypes.APPLICATION_MPD;
        if (ct.contains("smoothstreaming") || ct.contains("application/vnd.ms-sstr+xml")) return MimeTypes.APPLICATION_SS;
        if (ct.contains("video/mp2t")) return MimeTypes.VIDEO_MP2T;
        if (ct.contains("audio/mpeg")) return MimeTypes.AUDIO_MPEG;
        if (ct.contains("audio/aac")) return MimeTypes.AUDIO_AAC;
        if (ct.contains("audio/mp4")) return MimeTypes.AUDIO_MP4;
        if (ct.contains("audio/ogg")) return MimeTypes.AUDIO_OGG;
        if (ct.contains("audio/flac")) return MimeTypes.AUDIO_FLAC;
        if (ct.contains("video/mp4")) return MimeTypes.VIDEO_MP4;
        return null;
    }

    class Resolve extends AsyncTask<String, Void, Info> {
        protected Info doInBackground(String... p) {
            String cur = p[0];
            String guessed = mimeFromUrl(cur);
            String contentType = null;

            try {
                if (!cur.startsWith("http") && !cur.startsWith("rtsp")) {
                    return new Info(cur, guessed);
                }

                // Redirect çöz (maks 8)
                for (int i = 0; i < 8; i++) {
                    HttpURLConnection c = openConn(cur, "HEAD", false);
                    c.connect();
                    int code = c.getResponseCode();
                    contentType = c.getContentType();
                    String loc = c.getHeaderField("Location");
                    c.disconnect();

                    if (code >= 300 && code < 400 && loc != null && !loc.isEmpty()) {
                        // relative redirect olabilir
                        if (loc.startsWith("/")) {
                            URL base = new URL(cur);
                            loc = base.getProtocol() + "://" + base.getHost() + loc;
                        }
                        cur = loc;
                        guessed = mimeFromUrl(cur);
                        continue;
                    }
                    break;
                }

                // Content-Type ile mime çıkar
                String m = mimeFromContentType(contentType);
                if (m != null) return new Info(cur, m);

                // URL ile çıkarabildiysek dön
                if (guessed != null) return new Info(cur, guessed);

                // Uzantısız ise sniff (Range GET)
                HttpURLConnection g = openConn(cur, "GET", true);
                g.connect();

                InputStream is = g.getInputStream();
                byte[] buf = new byte[SNIFF_BYTES];
                int n = is.read(buf);
                is.close();

                String head = "";
                if (n > 0) head = new String(buf, 0, n);
                String ct2 = g.getContentType();
                g.disconnect();

                // önce ct2
                String m2 = mimeFromContentType(ct2);
                if (m2 != null) return new Info(cur, m2);

                // sonra içerik sniff
                if (looksLikeM3U(head)) return new Info(cur, MimeTypes.APPLICATION_M3U8);
                if (looksLikeMPD(head)) return new Info(cur, MimeTypes.APPLICATION_MPD);
                if (looksLikeSS(head)) return new Info(cur, MimeTypes.APPLICATION_SS);

                // TS / MP4 / audio için ExoPlayer sniff’e bırak
                return new Info(cur, null);

            } catch (Exception e) {
                return new Info(cur, guessed);
            }
        }

        protected void onPostExecute(Info i) { init(i); }
    }

    void init(Info i) {
        if (pl != null) return;

        String ua = "Mozilla/5.0";
        Map<String, String> mp = new HashMap<>();

        if (hdr != null) {
            try {
                JSONObject h = new JSONObject(hdr);
                Iterator<String> k = h.keys();
                while (k.hasNext()) {
                    String ky = k.next();
                    String vl = h.optString(ky, "");
                    if (ky.equalsIgnoreCase("User-Agent")) ua = vl;
                    else mp.put(ky, vl);
                }
            } catch (Exception e) {}
        }

        DefaultHttpDataSource.Factory df = new DefaultHttpDataSource.Factory()
            .setUserAgent(ua)
            .setAllowCrossProtocolRedirects(true)
            .setDefaultRequestProperties(mp);

        DefaultLoadControl lc = new DefaultLoadControl.Builder()
            .setAllocator(new DefaultAllocator(true, 16 * 1024))
            .setBufferDurationsMs(50000, 50000, 2500, 5000)
            .build();

        pl = new ExoPlayer.Builder(this)
            .setLoadControl(lc)
            .setMediaSourceFactory(new DefaultMediaSourceFactory(this).setDataSourceFactory(df))
            .build();

        pv.setPlayer(pl);
        pl.setPlayWhenReady(true);
        pl.addListener(new Player.Listener() {
            public void onPlaybackStateChanged(int s) {
                if (s == Player.STATE_BUFFERING) spin.setVisibility(View.VISIBLE);
                else spin.setVisibility(View.GONE);
            }
        });

        try {
            MediaItem.Builder it = new MediaItem.Builder().setUri(Uri.parse(i.finalUrl));
            if (i.mime != null && !i.mime.isEmpty()) it.setMimeType(i.mime);
            pl.setMediaItem(it.build());
            pl.prepare();
        } catch (Exception e) {}
    }

    protected void onStop() {
        super.onStop();
        if (pl != null) {
            pl.release();
            pl = null;
        }
    }
}
EOF

# ------------------------------------------------------------------
# 16) Bitti
# ------------------------------------------------------------------
echo "✅ [16/18] TITAN APEX V6000.10 kaynak kodları oluşturuldu."
echo "🧩 PLAYER: Redirect + uzantısız link + sniff + HLS/DASH/SS/RTSP + MP4/TS/AUDIO aktif."
echo "⚠️ FFmpeg extension: ENABLE_FFMPEG_EXT=true yaparsan GPL lisans riskini kabul etmiş olursun."
echo "🚀 Sıradaki adım: GitHub Actions 'Build Signed Release' çalışacak."
echo "============================================================"
