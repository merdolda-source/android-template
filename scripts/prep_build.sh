#!/bin/bash
set -e

# ==============================================================================
# TITAN APEX V4000 - ULTIMATE UNCOMPRESSED EDITION (FULL SOURCE)
# ==============================================================================
# BU SCRIPT AŞAĞIDAKİ ÖZELLİKLERİ İÇERİR:
# 1. TAM KAYNAK KODU: Java dosyaları sıkıştırılmadan, profesyonel formatta oluşturulur.
# 2. GRADLE 8.13 FIX: Repository çakışmaları ve sürüm uyumsuzlukları giderilmiştir.
# 3. MULTI-TENANT PUSH: Her uygulama kendi paket adıyla token kaydı yapar.
# 4. HYBRID ADS: Unity ve AdMob reklamları arasında otomatik geçiş yapar.
# 5. AUTO-HEAL: google-services.json ve ikon hatalarını otomatik onarır.
# ==============================================================================

# Parametreleri Al
PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3
ICON_URL=$4
VERSION_CODE=$5
VERSION_NAME=$6

echo "=================================================="
echo "   🚀 TITAN APEX V4000 - SYSTEM INITIATED"
echo "   📦 PAKET: $PACKAGE_NAME"
echo "   📱 İSİM : $APP_NAME"
echo "=================================================="

# --------------------------------------------------------
# 1. SİSTEM VE KÜTÜPHANE KONTROLÜ
# --------------------------------------------------------
echo "⚙️ [1/16] Sistem kontrolleri yapılıyor..."

# Convert (ImageMagick) kontrolü
if ! command -v convert &> /dev/null; then
    echo "⚠️ 'convert' komutu bulunamadı. Yüklenmeye çalışılıyor..."
    sudo apt-get update >/dev/null 2>&1 || true
    sudo apt-get install -y imagemagick >/dev/null 2>&1 || true
fi

# --------------------------------------------------------
# 2. DERİN TEMİZLİK
# --------------------------------------------------------
echo "🧹 [2/16] Proje alanı temizleniyor..."
rm -rf app/src/main/res/drawable*
rm -rf app/src/main/res/mipmap*
rm -rf app/src/main/res/values*
rm -rf app/src/main/java/com/base/app/*
rm -rf .gradle 
rm -rf app/build 
rm -rf build

# Yeni Dizin Yapısı
mkdir -p "app/src/main/java/com/base/app"
mkdir -p "app/src/main/res/mipmap-xxxhdpi"
mkdir -p "app/src/main/res/values"
mkdir -p "app/src/main/res/xml"
mkdir -p "app/src/main/res/layout"

# --------------------------------------------------------
# 3. İKON MOTORU (FALLBACK DESTEKLİ)
# --------------------------------------------------------
echo "🖼️ [3/16] Uygulama ikonu işleniyor..."
ICON_TARGET="app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
TEMP_ICON="icon_temp.png"

# İndirmeyi dene
curl -s -L -k -A "Mozilla/5.0" -o "$TEMP_ICON" "$ICON_URL" || true

if [ -s "$TEMP_ICON" ]; then
    if command -v convert &> /dev/null; then
        # ImageMagick varsa boyutlandır
        convert "$TEMP_ICON" -resize 512x512! -background none -flatten "$ICON_TARGET"
    else
        # Yoksa olduğu gibi kopyala
        cp "$TEMP_ICON" "$ICON_TARGET"
    fi
else
    echo "⚠️ İkon indirilemedi. Varsayılan (Dummy) ikon oluşturuluyor..."
    if command -v convert &> /dev/null; then
        convert -size 512x512 xc:#1e293b -fill white -gravity center -pointsize 150 -annotate 0 "TV" "$ICON_TARGET"
    fi
fi
rm -f "$TEMP_ICON"

# --------------------------------------------------------
# 4. SETTINGS.GRADLE (GRADLE 8.13 FIX)
# --------------------------------------------------------
echo "📦 [4/16] Settings.gradle yapılandırılıyor..."
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
rootProject.name = "TitanApp"
include ':app'
EOF

# --------------------------------------------------------
# 5. ROOT BUILD.GRADLE
# --------------------------------------------------------
echo "📦 [5/16] Root Build.gradle yapılandırılıyor..."
cat > build.gradle <<EOF
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

# --------------------------------------------------------
# 6. GOOGLE SERVICES JSON TAMİRİ
# --------------------------------------------------------
echo "🔧 [6/16] google-services.json onarılıyor..."
JSON_FILE="app/google-services.json"

if [ -f "$JSON_FILE" ]; then
    echo "✅ JSON bulundu. Paket adı: $PACKAGE_NAME olarak ayarlanıyor."
    sed -i 's/"package_name": *"[^"]*"/"package_name": "'"$PACKAGE_NAME"'"/g' "$JSON_FILE"
else
    echo "⚠️ JSON Dosyası Yok! Dummy JSON oluşturuluyor..."
    cat > "$JSON_FILE" <<EOF
{
  "project_info": { "project_number": "000", "project_id": "none", "storage_bucket": "none" },
  "client": [{
    "client_info": { "mobilesdk_app_id": "1:0:android:0", "android_client_info": { "package_name": "$PACKAGE_NAME" } },
    "api_key": [{ "current_key": "dummy" }]
  }]
}
EOF
fi

# --------------------------------------------------------
# 7. APP BUILD.GRADLE (MODULE LEVEL)
# --------------------------------------------------------
echo "📚 [7/16] App Modülü yapılandırılıyor..."
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
    }

    // İMZALAMA (YAML SECRETLARI OKUR)
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
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    
    // Hataları Yoksay (Build Başarısı İçin)
    lint {
        abortOnError false
        checkReleaseBuilds false
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    
    // Firebase Core
    implementation(platform('com.google.firebase:firebase-bom:32.7.0'))
    implementation 'com.google.firebase:firebase-messaging'
    implementation 'com.google.firebase:firebase-analytics'

    // Media Player
    implementation 'androidx.media3:media3-exoplayer:1.2.0'
    implementation 'androidx.media3:media3-exoplayer-hls:1.2.0'
    implementation 'androidx.media3:media3-ui:1.2.0'
    
    // Image Loader
    implementation 'com.github.bumptech.glide:glide:4.16.0'
    
    // Ads
    implementation 'com.unity3d.ads:unity-ads:4.9.2'
    implementation 'com.google.android.gms:play-services-ads:22.6.0'
}
EOF

# --------------------------------------------------------
# 8. MANIFEST & RESOURCES
# --------------------------------------------------------
echo "📜 [8/16] Kaynak dosyaları (XML) oluşturuluyor..."

# Network Security
cat > app/src/main/res/xml/network_security_config.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
EOF

# Styles
cat > app/src/main/res/values/styles.xml <<EOF
<resources>
    <style name="AppTheme" parent="Theme.AppCompat.Light.NoActionBar">
        <item name="android:windowNoTitle">true</item>
        <item name="android:windowActionBar">false</item>
    </style>
    <style name="PlayerTheme" parent="Theme.AppCompat.NoActionBar">
        <item name="android:windowFullscreen">true</item>
        <item name="android:windowContentOverlay">@null</item>
    </style>
</resources>
EOF

# AndroidManifest.xml
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
        android:label="$APP_NAME"
        android:icon="@mipmap/ic_launcher"
        android:networkSecurityConfig="@xml/network_security_config"
        android:usesCleartextTraffic="true"
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

# --------------------------------------------------------
# 9. JAVA: ADS MANAGER (UNCOMPRESSED)
# --------------------------------------------------------
echo "☕ [9/16] Java: AdsManager oluşturuluyor..."
cat > "app/src/main/java/com/base/app/AdsManager.java" <<EOF
package com.base.app;

import android.app.Activity;
import android.view.ViewGroup;
import org.json.JSONObject;
import androidx.annotation.NonNull;

// Unity Ads
import com.unity3d.ads.*;
import com.unity3d.services.banners.*;

// AdMob
import com.google.android.gms.ads.*;
import com.google.android.gms.ads.interstitial.*;

public class AdsManager {
    public static int counter = 0;
    private static int frequency = 3;
    private static boolean isEnabled = false;
    private static boolean bannerActive = false;
    private static boolean interActive = false;
    private static String provider = "UNITY"; 
    
    // IDs
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
            frequency = config.optInt("inter_freq", 3);

            if (!isEnabled) return;

            // Unity Init
            if (provider.equals("UNITY") || provider.equals("BOTH")) {
                unityGameId = config.optString("unity_game_id");
                unityBannerId = config.optString("unity_banner_id");
                unityInterId = config.optString("unity_inter_id");
                
                if (!unityGameId.isEmpty()) {
                    UnityAds.initialize(activity.getApplicationContext(), unityGameId, false, null);
                }
            }

            // AdMob Init
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

        // AdMob Banner
        if ((provider.equals("ADMOB") || provider.equals("BOTH")) && !admobBannerId.isEmpty()) {
            AdView adView = new AdView(activity);
            adView.setAdSize(AdSize.BANNER);
            adView.setAdUnitId(admobBannerId);
            container.addView(adView);
            adView.loadAd(new AdRequest.Builder().build());
        } 
        // Unity Banner
        else if ((provider.equals("UNITY") || provider.equals("BOTH")) && !unityBannerId.isEmpty()) {
            BannerView bannerView = new BannerView(activity, unityBannerId, new UnityBannerSize(320, 50));
            bannerView.load();
            container.addView(bannerView);
        }
    }

    public static void checkInter(Activity activity, Runnable onComplete) {
        if (!isEnabled || !interActive) {
            onComplete.run();
            return;
        }

        counter++;
        if (counter >= frequency) {
            counter = 0;

            // AdMob Inter
            if ((provider.equals("ADMOB") || provider.equals("BOTH")) && mAdMobInter != null) {
                mAdMobInter.show(activity);
                mAdMobInter = null;
                loadAdMobInter(activity);
                onComplete.run();
                return;
            }

            // Unity Inter
            if ((provider.equals("UNITY") || provider.equals("BOTH")) && !unityInterId.isEmpty()) {
                if (UnityAds.isInitialized()) {
                    UnityAds.load(unityInterId, new IUnityAdsLoadListener() {
                        @Override
                        public void onUnityAdsAdLoaded(String placementId) {
                            UnityAds.show(activity, placementId, new IUnityAdsShowListener() {
                                @Override
                                public void onUnityAdsShowComplete(String placementId, UnityAds.UnityAdsShowCompletionState state) { onComplete.run(); }
                                @Override
                                public void onUnityAdsShowFailure(String placementId, UnityAds.UnityAdsShowError error, String message) { onComplete.run(); }
                                @Override
                                public void onUnityAdsShowStart(String placementId) {}
                                @Override
                                public void onUnityAdsShowClick(String placementId) {}
                            });
                        }
                        @Override
                        public void onUnityAdsFailedToLoad(String placementId, UnityAds.UnityAdsLoadError error, String message) {
                            onComplete.run();
                        }
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

# --------------------------------------------------------
# 10. JAVA: FIREBASE SERVICE (UNCOMPRESSED)
# --------------------------------------------------------
echo "🔥 [10/16] Java: FirebaseService oluşturuluyor..."
cat > "app/src/main/java/com/base/app/MyFirebaseMessagingService.java" <<EOF
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
        } 
        else if (remoteMessage.getData().size() > 0) {
            String title = remoteMessage.getData().get("title");
            String body = remoteMessage.getData().get("body");
            if(title != null && body != null) {
                sendNotification(title, body);
            }
        }
    }

    @Override
    public void onNewToken(String token) {
        // Yeni token geldiğinde kaydet
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
            NotificationChannel channel = new NotificationChannel(channelId,
                    "Genel Bildirimler",
                    NotificationManager.IMPORTANCE_DEFAULT);
            notificationManager.createNotificationChannel(channel);
        }

        notificationManager.notify(0, notificationBuilder.build());
    }
}
EOF

# --------------------------------------------------------
# 11. JAVA: MAIN ACTIVITY (PERMISSION REQUESTER + TOKEN SYNC)
# --------------------------------------------------------
echo "📱 [11/16] Java: MainActivity (Permissions Fix) oluşturuluyor..."
cat > "app/src/main/java/com/base/app/MainActivity.java" <<EOF
package com.base.app;

import android.app.Activity;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Build;
import android.content.pm.PackageManager;
import android.view.*;
import android.widget.*;
import android.graphics.*;
import android.graphics.drawable.*;
import org.json.*;
import java.io.*;
import java.net.*;
import com.bumptech.glide.Glide;
import com.google.firebase.messaging.FirebaseMessaging;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

public class MainActivity extends Activity {
    
    private String CONFIG_URL = "$CONFIG_URL"; 
    private LinearLayout container;
    private TextView titleTxt; 
    private ImageView splash, refreshBtn, shareBtn;
    private LinearLayout headerLayout, currentRow;
    
    private String hColor="#2196F3", tColor="#FFFFFF", bColor="#F0F0F0", fColor="#FF9800", menuType="LIST";
    private String listType="CLASSIC", listItemBg="#FFFFFF", listIconShape="SQUARE", listBorderColor="#DDDDDD";
    private int listRadius=0, listBorderWidth=0;
    private String playerConfigStr="", telegramUrl="";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // --- 1. İZİN İSTEME (ANDROID 13+ FIX) ---
        if (Build.VERSION.SDK_INT >= 33) {
            if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, new String[]{android.Manifest.permission.POST_NOTIFICATIONS}, 101);
            }
        }

        // --- 2. TOKEN SYNC ---
        FirebaseMessaging.getInstance().getToken().addOnCompleteListener(task -> {
            if (task.isSuccessful() && task.getResult() != null) {
                String token = task.getResult();
                getSharedPreferences("TITAN_PREFS", MODE_PRIVATE).edit().putString("fcm_token", token).apply();
                
                new Thread(() -> {
                    try {
                        String baseUrl = "";
                        if(CONFIG_URL.contains("api.php")) {
                            baseUrl = CONFIG_URL.substring(0, CONFIG_URL.indexOf("api.php"));
                        } else {
                            baseUrl = CONFIG_URL.substring(0, CONFIG_URL.lastIndexOf("/") + 1);
                        }
                        
                        String postUrl = baseUrl + "update_token.php";
                        
                        URL url = new URL(postUrl);
                        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                        conn.setRequestMethod("POST");
                        conn.setDoOutput(true);
                        conn.setConnectTimeout(5000);
                        
                        String postData = "fcm_token=" + URLEncoder.encode(token, "UTF-8") 
                                        + "&package_name=" + URLEncoder.encode(getPackageName(), "UTF-8");
                        
                        OutputStream os = conn.getOutputStream();
                        os.write(postData.getBytes());
                        os.flush();
                        os.close();
                        conn.getResponseCode();
                        conn.disconnect();
                    } catch (Exception e) {}
                }).start();
            }
        });

        // UI OLUŞTURMA
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
        JSONObject h = new JSONObject();
        try {
            if(ua != null && !ua.isEmpty()) h.put("User-Agent", ua);
            if(ref != null && !ref.isEmpty()) h.put("Referer", ref);
            if(org != null && !org.isEmpty()) h.put("Origin", org);
        } catch(Exception e){}
        String hStr = h.toString();

        View v = null;
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
        def.setCornerRadius(20);
        GradientDrawable foc = new GradientDrawable();
        foc.setColor(Color.parseColor(fColor));
        foc.setCornerRadius(20);
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
                
                listType = ui.optString("list_type", "CLASSIC");
                listItemBg = ui.optString("list_item_bg", "#FFFFFF");
                listRadius = ui.optInt("list_item_radius", 0);
                listIconShape = ui.optString("list_icon_shape", "SQUARE");
                listBorderWidth = ui.optInt("list_border_width", 0);
                listBorderColor = ui.optString("list_border_color", "#DDDDDD");
                
                playerConfigStr = j.optString("player_config", "{}");
                telegramUrl = ui.optString("telegram_url");
                
                String customHeader = ui.optString("custom_header_text", "");
                titleTxt.setText(customHeader.isEmpty() ? j.optString("app_name") : customHeader);
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
                
                // Direct Boot Fix
                if(ui.optString("startup_mode").equals("DIRECT")) {
                    String dType = ui.optString("direct_type");
                    String dUrl = ui.optString("direct_url");
                    if(dType.equals("WEB")) {
                        Intent i = new Intent(MainActivity.this, WebViewActivity.class);
                        i.putExtra("WEB_URL", dUrl);
                        startActivity(i);
                    } else {
                        open(dType, dUrl, "", "");
                    }
                    finish();
                    return;
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
# --------------------------------------------------------
# 12. JAVA: WEBVIEW ACTIVITY (UNCOMPRESSED)
# --------------------------------------------------------
echo "🌐 [12/16] Java: WebViewActivity oluşturuluyor..."
cat > "app/src/main/java/com/base/app/WebViewActivity.java" <<EOF
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
        
        // JS Bridge
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
                try {
                    Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
                    startActivity(intent);
                } catch (Exception e) {}
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

# --------------------------------------------------------
# 13. JAVA: CHANNEL LIST ACTIVITY (UNCOMPRESSED)
# --------------------------------------------------------
echo "📋 [13/16] Java: ChannelListActivity oluşturuluyor..."
cat > "app/src/main/java/com/base/app/ChannelListActivity.java" <<EOF
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
        title.setText("Yükleniyor...");
        title.setTextColor(Color.parseColor(tC));
        title.setTextSize(18);
        h.addView(title);
        r.addView(h);

        lv = new ListView(this);
        lv.setDivider(null);
        lv.setPadding(20, 20, 20, 20);
        lv.setClipToPadding(false);
        lv.setOverScrollMode(2);
        
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

    void showGr() { isGroup = true; title.setText("Kategoriler"); lv.setAdapter(new Adp(gNames, true)); }
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
                    String fl = "Liste";
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
                        groups.get(fl).add(new Item(o.optString("title"), u, o.optString("thumb_square"), hd.toString()));
                    }
                }
                
                if (groups.isEmpty()) {
                    String[] ln = r.split("\n");
                    String ct = "Kanal", ci = "", cg = "Genel";
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
                            groups.get(cg).add(new Item(ct, l, ci, ch.toString()));
                            ct = "Kanal"; ci = ""; ch = new JSONObject();
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
                t.setTextColor(Color.BLACK);
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
            if (lType.equals("CARD")) { pa.setMargins(0, 0, 0, 25); l.setPadding(30, 30, 30, 30); l.setElevation(5f); }
            else if (lType.equals("MODERN")) { pa.setMargins(0, 0, 0, 15); l.setPadding(20, 50, 20, 50); }
            else { pa.setMargins(0, 0, 0, 5); l.setPadding(20, 20, 20, 20); }
            l.setLayoutParams(pa);

            ImageView im = v.findViewById(1);
            TextView tx = v.findViewById(2);
            tx.setTextColor(Color.parseColor(tC));
            im.setLayoutParams(new LinearLayout.LayoutParams(120, 120));
            ((LinearLayout.LayoutParams) im.getLayoutParams()).setMargins(0, 0, 30, 0);
            
            RequestOptions op = new RequestOptions();
            if (lIcon.equals("CIRCLE")) op = op.circleCrop();

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

# --------------------------------------------------------
# 14. JAVA: PLAYER ACTIVITY (UNCOMPRESSED)
# --------------------------------------------------------
echo "🎥 [14/16] Java: PlayerActivity oluşturuluyor..."
cat > "app/src/main/java/com/base/app/PlayerActivity.java" <<EOF
package com.base.app;

import android.app.Activity;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.*;
import android.widget.*;
import android.graphics.Color;
import androidx.media3.common.*;
import androidx.media3.datasource.DefaultHttpDataSource;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory;
import androidx.media3.ui.PlayerView;
import androidx.media3.ui.AspectRatioFrameLayout;
import androidx.media3.exoplayer.DefaultLoadControl;
import androidx.media3.exoplayer.upstream.DefaultAllocator;
import org.json.JSONObject;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.*;

public class PlayerActivity extends Activity {
    private ExoPlayer pl;
    private PlayerView pv;
    private ProgressBar spin;
    private String vid, hdr;

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
        
        try {
            JSONObject c = new JSONObject(getIntent().getStringExtra("PLAYER_CONFIG"));
            String rm = c.optString("resize_mode", "FIT");
            if (rm.equals("FILL")) pv.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FILL);
            else if (rm.equals("ZOOM")) pv.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_ZOOM);
            else pv.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FIT);
            
            if (!c.optBoolean("auto_rotate", true)) setRequestedOrientation(0);
            
            if (c.optBoolean("enable_overlay", false)) {
                TextView o = new TextView(this);
                o.setText(c.optString("watermark_text", ""));
                o.setTextColor(Color.parseColor(c.optString("watermark_color", "#FFFFFF")));
                o.setTextSize(18);
                o.setPadding(30, 30, 30, 30);
                o.setBackgroundColor(Color.parseColor("#80000000"));
                FrameLayout.LayoutParams p = new FrameLayout.LayoutParams(-2, -2);
                String pos = c.optString("watermark_pos", "left");
                p.gravity = (pos.equals("right") ? Gravity.TOP | Gravity.END : Gravity.TOP | Gravity.START);
                r.addView(o, p);
            }
        } catch (Exception e) {}
        
        setContentView(r);
        vid = getIntent().getStringExtra("VIDEO_URL");
        hdr = getIntent().getStringExtra("HEADERS_JSON");
        
        if (vid != null && !vid.isEmpty()) new Res().execute(vid.trim());
    }

    class Inf { String u, m; Inf(String uu, String mm) { u = uu; m = mm; } }

    class Res extends AsyncTask<String, Void, Inf> {
        protected Inf doInBackground(String... p) {
            String cu = p[0], dm = null;
            try {
                if (!cu.startsWith("http")) return new Inf(cu, null);
                for (int i = 0; i < 5; i++) {
                    URL u = new URL(cu);
                    HttpURLConnection c = (HttpURLConnection) u.openConnection();
                    c.setInstanceFollowRedirects(false);
                    if (hdr != null) {
                        JSONObject h = new JSONObject(hdr);
                        Iterator<String> k = h.keys();
                        while (k.hasNext()) {
                            String ky = k.next();
                            c.setRequestProperty(ky, h.getString(ky));
                        }
                    } else c.setRequestProperty("User-Agent", "Mozilla/5.0");
                    
                    c.setConnectTimeout(8000);
                    c.connect();
                    int cd = c.getResponseCode();
                    if (cd >= 300 && cd < 400) {
                        String n = c.getHeaderField("Location");
                        if (n != null) { cu = n; continue; }
                    }
                    dm = c.getContentType();
                    c.disconnect();
                    break;
                }
            } catch (Exception e) {}
            return new Inf(cu, dm);
        }

        protected void onPostExecute(Inf i) { init(i); }
    }

    void init(Inf i) {
        if (pl != null) return;
        String ua = "Mozilla/5.0";
        Map<String, String> mp = new HashMap<>();
        if (hdr != null) {
            try {
                JSONObject h = new JSONObject(hdr);
                Iterator<String> k = h.keys();
                while (k.hasNext()) {
                    String ky = k.next(), vl = h.getString(ky);
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
            MediaItem.Builder it = new MediaItem.Builder().setUri(Uri.parse(i.u));
            if (i.m != null) {
                if (i.m.contains("mpegurl")) it.setMimeType(MimeTypes.APPLICATION_M3U8);
                else if (i.m.contains("dash")) it.setMimeType(MimeTypes.APPLICATION_MPD);
            }
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

# --------------------------------------------------------
# 15. SON KONTROL
# --------------------------------------------------------
echo "✅ [15/16] Kaynak kodları oluşturuldu."
echo "✅ [16/16] TITAN APEX V4000 Kurulumu Tamam."
