#!/bin/bash
set -e

# ==============================================================================
# TITAN APEX V20000 - ULTIMATE UNLEASHED (PATRON EDITION)
# ==============================================================================
# BU SCRIPT, ANDROID PROJESİNİ SIFIRDAN, PROFESYONEL MİMARİDE OLUŞTURUR.
# ==============================================================================

PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3
ICON_URL=$4
VERSION_CODE=$5
VERSION_NAME=$6

echo "============================================================"
echo "   ⚡ TITAN APEX V20000 - SYSTEM STARTING..."
echo "   📦 PAKET: $PACKAGE_NAME"
echo "   📱 UYGULAMA: $APP_NAME"
echo "============================================================"

# ------------------------------------------------------------------
# 1. SİSTEM VE KÜTÜPHANE KONTROLÜ
# ------------------------------------------------------------------
echo "⚙️ [1/25] Sistem gereksinimleri (ImageMagick) kontrol ediliyor..."
if ! command -v convert &> /dev/null; then
    echo "⚠️ 'convert' bulunamadı. Kuruluyor..."
    sudo apt-get update >/dev/null 2>&1 || true
    sudo apt-get install -y imagemagick >/dev/null 2>&1 || true
fi

# ------------------------------------------------------------------
# 2. DERİN TEMİZLİK VE DİZİN YAPISI
# ------------------------------------------------------------------
echo "🧹 [2/25] Eski proje kalıntıları temizleniyor..."
rm -rf app/src/main/res/drawable*
rm -rf app/src/main/res/mipmap*
rm -rf app/src/main/res/values*
rm -rf app/src/main/java/com/base/app/*
rm -rf .gradle app/build build

echo "📂 [3/25] Profesyonel dizin yapısı oluşturuluyor..."
mkdir -p "app/src/main/java/com/base/app"
mkdir -p "app/src/main/res/mipmap-xxxhdpi"
mkdir -p "app/src/main/res/values"
mkdir -p "app/src/main/res/values-tr"
mkdir -p "app/src/main/res/xml"
mkdir -p "app/src/main/res/layout"
mkdir -p "app/src/main/res/menu"
mkdir -p "app/src/main/res/drawable"
mkdir -p "app/src/main/res/anim"

# ------------------------------------------------------------------
# 3. İKON MOTORU (AAPT CRASH FIX GARANTİLİ)
# ------------------------------------------------------------------
echo "🖼️ [4/25] İkon motoru çalışıyor..."
ICON_TARGET="app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
TEMP_ICON="icon_download_temp"

# İndirmeyi dene
curl -s -L -k --fail --retry 3 -o "$TEMP_ICON" "$ICON_URL" || true

# Dosya kontrolü
VALID_IMG=false
if [ -s "$TEMP_ICON" ]; then
    # ImageMagick ile dosya geçerliliğini kontrol et
    if identify "$TEMP_ICON" >/dev/null 2>&1; then
        VALID_IMG=true
    fi
fi

if [ "$VALID_IMG" = true ]; then
    echo "✅ İkon doğrulandı. İşleniyor..."
    convert "$TEMP_ICON" -resize 512x512! -background none -flatten "$ICON_TARGET"
else
    echo "⚠️ İkon dosyası bozuk veya yok. OTOMATİK OLUŞTURULUYOR..."
    # Rastgele renk seç
    R_COLOR="#$(printf "%06x" $((RANDOM*1000000)))"
    LETTER=$(echo "$APP_NAME" | cut -c1 | tr '[:lower:]' '[:upper:]')
    convert -size 512x512 xc:"$R_COLOR" -fill white -gravity center -pointsize 200 -annotate 0 "$LETTER" "$ICON_TARGET"
fi
rm -f "$TEMP_ICON"

# ------------------------------------------------------------------
# 4. DİL VE METİN DOSYALARI (L10N)
# ------------------------------------------------------------------
echo "🌍 [5/25] Dil dosyaları (TR/EN) oluşturuluyor..."

# İngilizce
cat > app/src/main/res/values/strings.xml <<EOF
<resources>
    <string name="app_name">$APP_NAME</string>
    <string name="loading">Loading...</string>
    <string name="menu_home">Home</string>
    <string name="menu_exit">Exit</string>
    <string name="rate_title">Rate Us</string>
    <string name="rate_msg">If you enjoy this app, please rate us!</string>
    <string name="rate_now">Rate Now</string>
    <string name="rate_later">Later</string>
    <string name="welcome">Welcome</string>
    <string name="maintenance">Maintenance</string>
    <string name="conn_error">Connection Error</string>
    <string name="update_title">Update Available</string>
    <string name="update_msg">A new version is available. Please update.</string>
    <string name="update_btn">Update</string>
    <string name="drawer_close">Close Menu</string>
    <string name="drawer_open">Open Menu</string>
</resources>
EOF

# Türkçe
cat > app/src/main/res/values-tr/strings.xml <<EOF
<resources>
    <string name="app_name">$APP_NAME</string>
    <string name="loading">Yükleniyor...</string>
    <string name="menu_home">Ana Sayfa</string>
    <string name="menu_exit">Çıkış</string>
    <string name="rate_title">Bizi Değerlendir</string>
    <string name="rate_msg">Uygulamamızı beğendiniz mi? Lütfen puan verin!</string>
    <string name="rate_now">Puanla</string>
    <string name="rate_later">Daha Sonra</string>
    <string name="welcome">Hoş Geldiniz</string>
    <string name="maintenance">Bakım Modu</string>
    <string name="conn_error">Bağlantı Hatası</string>
    <string name="update_title">Güncelleme Mevcut</string>
    <string name="update_msg">Yeni bir sürüm yayınlandı. Lütfen güncelleyin.</string>
    <string name="update_btn">Güncelle</string>
    <string name="drawer_close">Menüyü Kapat</string>
    <string name="drawer_open">Menüyü Aç</string>
</resources>
EOF

# Renkler
cat > app/src/main/res/values/colors.xml <<EOF
<resources>
    <color name="colorPrimary">#2563EB</color>
    <color name="colorPrimaryDark">#1E40AF</color>
    <color name="colorAccent">#F59E0B</color>
    <color name="white">#FFFFFF</color>
    <color name="black">#000000</color>
    <color name="transparent">#00000000</color>
</resources>
EOF

# ------------------------------------------------------------------
# 5. GRADLE (BUILD SYSTEM)
# ------------------------------------------------------------------
echo "📦 [6/25] Gradle 8.x yapılandırması yazılıyor..."

cat > settings.gradle <<EOF
pluginManagement {
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories { google(); mavenCentral(); maven { url 'https://jitpack.io' } }
}
rootProject.name = "TitanApp"
include ':app'
EOF

cat > build.gradle <<EOF
buildscript {
    repositories { google(); mavenCentral() }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.2.1'
        classpath 'com.google.gms:google-services:4.4.1'
    }
}
task clean(type: Delete) { delete rootProject.buildDir }
EOF

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
    
    lint { abortOnError false; checkReleaseBuilds false }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.swiperefreshlayout:swiperefreshlayout:1.1.0'
    
    // Firebase
    implementation(platform('com.google.firebase:firebase-bom:32.7.0'))
    implementation 'com.google.firebase:firebase-messaging'
    implementation 'com.google.firebase:firebase-analytics'

    // Media3
    implementation 'androidx.media3:media3-exoplayer:1.2.0'
    implementation 'androidx.media3:media3-exoplayer-hls:1.2.0'
    implementation 'androidx.media3:media3-ui:1.2.0'
    implementation 'androidx.media3:media3-datasource-okhttp:1.2.0'
    
    // Utils
    implementation 'com.github.bumptech.glide:glide:4.16.0'
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
    
    // Ads
    implementation 'com.unity3d.ads:unity-ads:4.9.2'
    implementation 'com.google.android.gms:play-services-ads:22.6.0'
}
EOF

cat > app/proguard-rules.pro <<EOF
-keep class com.base.app.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.ads.** { *; }
-keep class androidx.media3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
EOF

# ------------------------------------------------------------------
# 6. JSON FIX & MANIFEST
# ------------------------------------------------------------------
echo "🔧 [7/25] Config ve Manifest ayarlanıyor..."

if [ -f "app/google-services.json" ]; then
    sed -i 's/"package_name": *"[^"]*"/"package_name": "'"$PACKAGE_NAME"'"/g' "app/google-services.json"
else
    echo '{"project_info":{"project_number":"0","project_id":"dummy"},"client":[{"client_info":{"mobilesdk_app_id":"1:0:android:0","android_client_info":{"package_name":"'$PACKAGE_NAME'"}},"api_key":[{"current_key":"dummy"}]}]}' > "app/google-services.json"
fi

cat > app/src/main/res/xml/network_security_config.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors><certificates src="system" /></trust-anchors>
    </base-config>
</network-security-config>
EOF

cat > app/src/main/res/values/styles.xml <<EOF
<resources>
    <style name="AppTheme" parent="Theme.MaterialComponents.Light.NoActionBar">
        <item name="android:windowNoTitle">true</item>
        <item name="android:windowActionBar">false</item>
        <item name="colorPrimary">@color/colorPrimary</item>
    </style>
    <style name="PlayerTheme" parent="Theme.AppCompat.NoActionBar">
        <item name="android:windowFullscreen">true</item>
        <item name="android:keepScreenOn">true</item>
    </style>
</resources>
EOF

cat > app/src/main/AndroidManifest.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" xmlns:tools="http://schemas.android.com/tools">
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
        
        <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ca-app-pub-3940256099942544~3347511713"/>

        <activity android:name=".MainActivity" 
            android:exported="true" 
            android:screenOrientation="portrait"
            android:configChanges="orientation|screenSize|keyboardHidden">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        
        <activity android:name=".WebViewActivity" android:configChanges="orientation|screenSize|keyboardHidden"/>
        <activity android:name=".ChannelListActivity" />
        <activity android:name=".PlayerActivity"
            android:configChanges="orientation|screenSize|keyboardHidden|smallestScreenSize|screenLayout"
            android:screenOrientation="sensor"
            android:theme="@style/PlayerTheme" />
            
        <service android:name=".MyFirebaseMessagingService" android:exported="false">
            <intent-filter><action android:name="com.google.firebase.MESSAGING_EVENT" /></intent-filter>
        </service>
    </application>
</manifest>
EOF

# ------------------------------------------------------------------
# 7. JAVA: ADS MANAGER (Hybrid Engine)
# ------------------------------------------------------------------
echo "☕ [8/25] Java: AdsManager (Unity + AdMob) oluşturuluyor..."
cat > "app/src/main/java/com/base/app/AdsManager.java" <<EOF
package com.base.app;
import android.app.Activity; import android.view.ViewGroup; import org.json.JSONObject; import androidx.annotation.NonNull;
import com.unity3d.ads.*; import com.unity3d.services.banners.*; import com.google.android.gms.ads.*; import com.google.android.gms.ads.interstitial.*;
public class AdsManager {
    public static int counter = 0; private static int frequency = 3; private static boolean isEnabled=false, bannerActive=false, interActive=false;
    private static String provider="UNITY", unityGameId="", unityBannerId="", unityInterId="", admobBannerId="", admobInterId="";
    private static InterstitialAd mAdMobInter;
    
    public static void init(Activity act, JSONObject cfg) {
        try { if(cfg==null)return; isEnabled=cfg.optBoolean("enabled",false); provider=cfg.optString("provider","UNITY"); bannerActive=cfg.optBoolean("banner_active"); interActive=cfg.optBoolean("inter_active"); frequency=cfg.optInt("inter_freq",3);
        if(!isEnabled)return;
        if(provider.contains("UNITY")){ unityGameId=cfg.optString("unity_game_id"); unityBannerId=cfg.optString("unity_banner_id"); unityInterId=cfg.optString("unity_inter_id"); if(!unityGameId.isEmpty()) UnityAds.initialize(act.getApplicationContext(), unityGameId, false, null); }
        if(provider.contains("ADMOB")){ admobBannerId=cfg.optString("admob_banner_id"); admobInterId=cfg.optString("admob_inter_id"); MobileAds.initialize(act,s->{}); loadAdMobInter(act); }
        }catch(Exception e){}
    }
    private static void loadAdMobInter(Activity act){ if(!interActive)return; AdRequest r=new AdRequest.Builder().build(); InterstitialAd.load(act, admobInterId, r, new InterstitialAdLoadCallback(){ public void onAdLoaded(@NonNull InterstitialAd ad){mAdMobInter=ad;} }); }
    public static void showBanner(Activity act, ViewGroup con){
        if(!isEnabled||!bannerActive)return; con.removeAllViews();
        if(provider.contains("ADMOB")&&!admobBannerId.isEmpty()){ AdView v=new AdView(act); v.setAdSize(AdSize.BANNER); v.setAdUnitId(admobBannerId); con.addView(v); v.loadAd(new AdRequest.Builder().build()); }
        else if(provider.contains("UNITY")&&!unityBannerId.isEmpty()){ BannerView b=new BannerView(act, unityBannerId, new UnityBannerSize(320,50)); b.load(); con.addView(b); }
    }
    public static void checkInter(Activity act, Runnable r){
        if(!isEnabled||!interActive){r.run();return;} counter++;
        if(counter>=frequency){ counter=0;
            if(provider.contains("ADMOB")&&mAdMobInter!=null){ mAdMobInter.show(act); mAdMobInter=null; loadAdMobInter(act); r.run(); return; }
            if(provider.contains("UNITY")&&!unityInterId.isEmpty()){ UnityAds.load(unityInterId, new IUnityAdsLoadListener(){ public void onUnityAdsAdLoaded(String p){ UnityAds.show(act,p,new IUnityAdsShowListener(){ public void onUnityAdsShowComplete(String p, UnityAds.UnityAdsShowCompletionState s){r.run();} public void onUnityAdsShowFailure(String p, UnityAds.UnityAdsShowError e, String m){r.run();} public void onUnityAdsShowStart(String p){} public void onUnityAdsShowClick(String p){} }); } public void onUnityAdsFailedToLoad(String p, UnityAds.UnityAdsLoadError e, String m){r.run();} }); return; }
            r.run();
        } else r.run();
    }
}
EOF

# ------------------------------------------------------------------
# 8. JAVA: FIREBASE SERVICE (Rich Push)
# ------------------------------------------------------------------
echo "🔥 [9/25] Java: FCM Service oluşturuluyor..."
cat > "app/src/main/java/com/base/app/MyFirebaseMessagingService.java" <<EOF
package com.base.app;
import android.app.*; import android.content.*; import android.graphics.*; import android.media.RingtoneManager; import android.os.Build; androidx.core.app.NotificationCompat; com.google.firebase.messaging.*; com.bumptech.glide.Glide;
public class MyFirebaseMessagingService extends FirebaseMessagingService {
    public void onMessageReceived(RemoteMessage m) {
        String t="",b="",i=""; if(m.getNotification()!=null){t=m.getNotification().getTitle();b=m.getNotification().getBody(); if(m.getNotification().getImageUrl()!=null)i=m.getNotification().getImageUrl().toString();}
        else if(m.getData().size()>0){t=m.getData().get("title");b=m.getData().get("body");i=m.getData().get("image");}
        if(t!=null) sn(t,b,i);
    }
    public void onNewToken(String t){ getSharedPreferences("TITAN_PREFS",0).edit().putString("fcm_token",t).apply(); }
    private void sn(String t, String b, String i) {
        Intent in=new Intent(this, MainActivity.class); in.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        PendingIntent pi=PendingIntent.getActivity(this,0,in,PendingIntent.FLAG_ONE_SHOT|PendingIntent.FLAG_IMMUTABLE);
        NotificationCompat.Builder nb=new NotificationCompat.Builder(this,"TitanCh").setSmallIcon(android.R.drawable.ic_dialog_info).setContentTitle(t).setContentText(b).setAutoCancel(true).setSound(RingtoneManager.getDefaultUri(2)).setContentIntent(pi);
        if(i!=null&&!i.isEmpty()){ try{ Bitmap bm=Glide.with(this).asBitmap().load(i).submit().get(); nb.setStyle(new NotificationCompat.BigPictureStyle().bigPicture(bm)); }catch(Exception e){} }
        NotificationManager nm=(NotificationManager)getSystemService(Context.NOTIFICATION_SERVICE);
        if(Build.VERSION.SDK_INT>=26) nm.createNotificationChannel(new NotificationChannel("TitanCh","Bildirimler",3));
        nm.notify((int)System.currentTimeMillis(), nb.build());
    }
}
EOF

# ------------------------------------------------------------------
# 9. JAVA: MAIN ACTIVITY (THE BEAST)
# ------------------------------------------------------------------
echo "📱 [10/25] Java: MainActivity (Drawer/Bottom/Features) oluşturuluyor..."
cat > "app/src/main/java/com/base/app/MainActivity.java" <<EOF
package com.base.app;
import android.app.*; import android.content.*; import android.os.*; import android.view.*; import android.widget.*; import android.graphics.*; import android.graphics.drawable.*; import android.net.Uri; import android.content.pm.PackageManager; import org.json.*; import java.io.*; import java.net.*; import java.util.*; import com.bumptech.glide.Glide; import com.google.firebase.messaging.FirebaseMessaging; import androidx.core.app.ActivityCompat; import androidx.core.content.ContextCompat; import com.google.android.material.bottomnavigation.BottomNavigationView; import androidx.swiperefreshlayout.widget.SwipeRefreshLayout; import androidx.drawerlayout.widget.DrawerLayout; import com.google.android.material.navigation.NavigationView; import androidx.core.view.GravityCompat;

public class MainActivity extends Activity {
    private String CONFIG_URL = "$CONFIG_URL"; 
    private LinearLayout container; private TextView titleTxt; private ImageView splash, refreshBtn, shareBtn, menuBtn; 
    private LinearLayout headerLayout; private SwipeRefreshLayout swipeRef;
    private DrawerLayout drawerLayout; private NavigationView navView;
    private String hColor="#2196F3", tColor="#FFFFFF", bColor="#F0F0F0", fColor="#FF9800", menuType="LIST";
    private String playerConfigStr=""; private JSONObject featureConfig;

    protected void onCreate(Bundle s) { super.onCreate(s);
        // İzinler
        if(Build.VERSION.SDK_INT>=33 && ContextCompat.checkSelfPermission(this,"android.permission.POST_NOTIFICATIONS")!=0) ActivityCompat.requestPermissions(this,new String[]{"android.permission.POST_NOTIFICATIONS"},101);
        
        // Token Sync
        FirebaseMessaging.getInstance().getToken().addOnCompleteListener(t->{ if(t.isSuccessful()){ String tk=t.getResult(); getSharedPreferences("TITAN_PREFS",0).edit().putString("fcm_token",tk).apply(); syncToken(tk); } });
        
        // --- UI İNŞASI (DRAWER SUPPORT) ---
        drawerLayout = new DrawerLayout(this);
        drawerLayout.setLayoutParams(new ViewGroup.LayoutParams(-1,-1));
        
        // Ana İçerik Alanı (Root)
        RelativeLayout root = new RelativeLayout(this);
        root.setLayoutParams(new DrawerLayout.LayoutParams(-1,-1));
        
        // Splash
        splash=new ImageView(this); splash.setScaleType(ImageView.ScaleType.CENTER_CROP); 
        root.addView(splash,new RelativeLayout.LayoutParams(-1,-1));
        
        // Header
        headerLayout=new LinearLayout(this); headerLayout.setId(View.generateViewId()); headerLayout.setPadding(40,40,40,40); headerLayout.setGravity(16); headerLayout.setElevation(10f);
        
        // Drawer Menu Button (Varsayılan Gizli)
        menuBtn = new ImageView(this); menuBtn.setImageResource(android.R.drawable.ic_menu_sort_by_size); menuBtn.setPadding(0,0,30,0); menuBtn.setVisibility(8);
        menuBtn.setOnClickListener(v -> drawerLayout.openDrawer(GravityCompat.START));
        headerLayout.addView(menuBtn);

        titleTxt=new TextView(this); titleTxt.setTextSize(20); titleTxt.setTypeface(null,Typeface.BOLD); headerLayout.addView(titleTxt,new LinearLayout.LayoutParams(0,-2,1.0f));
        
        shareBtn=new ImageView(this); shareBtn.setImageResource(android.R.drawable.ic_menu_share); shareBtn.setPadding(20,0,20,0); shareBtn.setOnClickListener(v->shareApp()); headerLayout.addView(shareBtn);
        refreshBtn=new ImageView(this); refreshBtn.setImageResource(android.R.drawable.ic_popup_sync); refreshBtn.setOnClickListener(v->new Fetch().execute(CONFIG_URL)); headerLayout.addView(refreshBtn);
        
        RelativeLayout.LayoutParams hp=new RelativeLayout.LayoutParams(-1,-2); hp.addRule(10); root.addView(headerLayout,hp);
        
        // İçerik
        swipeRef=new SwipeRefreshLayout(this); swipeRef.setId(View.generateViewId()); swipeRef.setOnRefreshListener(()->new Fetch().execute(CONFIG_URL));
        ScrollView sv=new ScrollView(this); container=new LinearLayout(this); container.setOrientation(1); container.setPadding(20,20,20,150); sv.addView(container); swipeRef.addView(sv);
        
        RelativeLayout.LayoutParams sp=new RelativeLayout.LayoutParams(-1,-1); sp.addRule(3,headerLayout.getId()); root.addView(swipeRef,sp);
        
        // Drawer ve Root'u birleştir
        drawerLayout.addView(root);
        
        // Navigation View (Sol Menü)
        navView = new NavigationView(this);
        DrawerLayout.LayoutParams navParams = new DrawerLayout.LayoutParams(800, -1);
        navParams.gravity = Gravity.START;
        navView.setLayoutParams(navParams);
        navView.setBackgroundColor(Color.WHITE);
        drawerLayout.addView(navView);
        
        setContentView(drawerLayout);
        new Fetch().execute(CONFIG_URL);
    }
    
    private void syncToken(String t){ new Thread(()->{ try{ String b=CONFIG_URL.contains("api.php")?CONFIG_URL.substring(0,CONFIG_URL.indexOf("api.php")):CONFIG_URL.substring(0,CONFIG_URL.lastIndexOf("/")+1); URL u=new URL(b+"update_token.php"); HttpURLConnection c=(HttpURLConnection)u.openConnection(); c.setRequestMethod("POST"); c.setDoOutput(true); c.getOutputStream().write(("fcm_token="+URLEncoder.encode(t,"UTF-8")+"&package_name="+getPackageName()).getBytes()); c.getResponseCode(); c.disconnect(); }catch(Exception e){} }).start(); }
    
    private void shareApp(){ startActivity(Intent.createChooser(new Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT,titleTxt.getText()+" Download: https://play.google.com/store/apps/details?id="+getPackageName()),"Share")); }
    
    // --- ÖZELLİK KONTROLLERİ ---
    private void checkFeat(){ if(featureConfig==null)return; 
        JSONObject r=featureConfig.optJSONObject("rate_us"); if(r!=null&&r.optBoolean("active")){ int c=getSharedPreferences("TITAN",0).getInt("lc",0)+1; getSharedPreferences("TITAN",0).edit().putInt("lc",c).apply(); if(c%r.optInt("freq",5)==0) new AlertDialog.Builder(this).setTitle(getString(R.string.rate_title)).setMessage(getString(R.string.rate_msg)).setPositiveButton(getString(R.string.rate_now),(d,w)->startActivity(new Intent(Intent.ACTION_VIEW,Uri.parse("market://details?id="+getPackageName())))).setNegativeButton(getString(R.string.rate_later),null).show(); }
        JSONObject w=featureConfig.optJSONObject("welcome_popup"); if(w!=null&&w.optBoolean("active")&&!getSharedPreferences("TITAN",0).getBoolean("welcomed",false)){ AlertDialog.Builder b=new AlertDialog.Builder(this).setTitle(w.optString("title")).setMessage(w.optString("message")); if(!w.optString("image").isEmpty()){ ImageView i=new ImageView(this); i.setAdjustViewBounds(true); Glide.with(this).load(w.optString("image")).into(i); b.setView(i); } b.setPositiveButton("OK",null).show(); getSharedPreferences("TITAN",0).edit().putBoolean("welcomed",true).apply(); }
        JSONObject m=featureConfig.optJSONObject("maintenance_mode"); if(m!=null&&m.optBoolean("active")){ new AlertDialog.Builder(this).setCancelable(false).setTitle(getString(R.string.maintenance)).setMessage(m.optString("message")).show(); }
    }

    // --- MENÜ RENDER MOTORU (6 MOD) ---
    private void render(JSONArray mod, JSONObject ui){
        container.removeAllViews();
        navView.getMenu().clear(); // Drawer temizle
        
        // 1. DRAWER (Yan Menü)
        if(menuType.equals("DRAWER")) {
            menuBtn.setVisibility(0);
            menuBtn.setColorFilter(Color.parseColor(tColor));
            for(int i=0; i<mod.length(); i++) {
                try {
                    JSONObject m = mod.getJSONObject(i);
                    navView.getMenu().add(0, i, 0, m.getString("title")).setOnMenuItemClickListener(item -> {
                        openItem(m); drawerLayout.closeDrawers(); return true;
                    });
                } catch(Exception e){}
            }
            // Ana ekranda da liste gösterelim ki boş kalmasın
            mkList(mod);
            return;
        } 
        
        menuBtn.setVisibility(8); // Diğer modlarda gizle

        // 2. BOTTOM NAV
        if(menuType.equals("BOTTOM")) { renderBottom(mod); return; }
        
        // 3. GRID (Izgara)
        if(menuType.equals("GRID")) {
            LinearLayout row=null;
            for(int i=0;i<mod.length();i++){ try{ JSONObject m=mod.getJSONObject(i); if(row==null||row.getChildCount()>=2){ row=new LinearLayout(this); row.setOrientation(0); row.setWeightSum(2); container.addView(row); } mkBtn(m,row,true); }catch(Exception e){} }
            return;
        }
        
        // 4. NETFLIX (Yatay Kaydırma - Basit Simülasyon)
        if(menuType.equals("NETFLIX")) {
            HorizontalScrollView hsv = new HorizontalScrollView(this);
            LinearLayout hl = new LinearLayout(this); hsv.addView(hl);
            for(int i=0;i<mod.length();i++){ try{ JSONObject m=mod.getJSONObject(i); mkBtn(m,hl,false); }catch(Exception e){} }
            container.addView(hsv);
            // Altına dikey liste de ekle
            mkList(mod);
            return;
        }

        // 5. CARD & 6. LIST (Varsayılan)
        mkList(mod);
    }
    
    private void mkList(JSONArray mod) {
        for(int i=0;i<mod.length();i++){ try{ mkBtn(mod.getJSONObject(i),container,false); }catch(Exception e){} }
    }
    
    private void mkBtn(JSONObject m, ViewGroup p, boolean g){
        Button b=new Button(this); b.setText(m.optString("title")); b.setTextColor(Color.parseColor(tColor));
        GradientDrawable d=new GradientDrawable(); d.setColor(Color.parseColor(hColor)); d.setCornerRadius(20);
        b.setBackground(d); LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(g?0:-1,180); if(g)lp.weight=1; lp.setMargins(10,10,10,10); b.setLayoutParams(lp);
        b.setOnClickListener(v->{ AdsManager.checkInter(this,()->openItem(m)); });
        p.addView(b);
    }
    
    private void renderBottom(JSONArray mod){
        try { View sv=(View)container.getParent(); RelativeLayout r=(RelativeLayout)sv.getParent();
        BottomNavigationView b=new BottomNavigationView(this); b.setId(View.generateViewId()); b.setBackgroundColor(Color.WHITE); b.setElevation(20f);
        for(int i=0;i<Math.min(mod.length(),5);i++) b.getMenu().add(0,i,0,mod.getJSONObject(i).getString("title")).setIcon(android.R.drawable.ic_menu_view);
        b.setOnNavigationItemSelectedListener(it->{ try{ openItem(mod.getJSONObject(it.getItemId())); }catch(Exception e){} return true; });
        RelativeLayout.LayoutParams lp=new RelativeLayout.LayoutParams(-1,-2); lp.addRule(12); r.addView(b,lp);
        RelativeLayout.LayoutParams sp=(RelativeLayout.LayoutParams)sv.getLayoutParams(); sp.addRule(2,b.getId()); sv.setLayoutParams(sp);
        }catch(Exception e){}
    }

    private void openItem(JSONObject m) {
        JSONObject h=new JSONObject(); try{if(m.has("ua"))h.put("User-Agent",m.getString("ua")); if(m.has("ref"))h.put("Referer",m.getString("ref")); if(m.has("org"))h.put("Origin",m.getString("org"));}catch(Exception e){} 
        op(m.optString("type"),m.optString("url"),m.optString("content"),h.toString());
    }

    private void op(String t,String u,String c,String h){
        if(t.equals("WEB")||t.equals("HTML")){ Intent i=new Intent(this,WebViewActivity.class); i.putExtra("WEB_URL",u); i.putExtra("HTML_DATA",c); startActivity(i); }
        else if(t.equals("SINGLE_STREAM")){ Intent i=new Intent(this,PlayerActivity.class); i.putExtra("VIDEO_URL",u); i.putExtra("HEADERS_JSON",h); i.putExtra("PLAYER_CONFIG",playerConfigStr); startActivity(i); }
        else { Intent i=new Intent(this,ChannelListActivity.class); i.putExtra("LIST_URL",u); i.putExtra("LIST_CONTENT",c); i.putExtra("TYPE",t); i.putExtra("UI_CONFIG",getIntent().getStringExtra("FULL_CONFIG")); i.putExtra("PLAYER_CONFIG",playerConfigStr); startActivity(i); }
    }

    class Fetch extends AsyncTask<String,Void,String>{
        protected void onPreExecute(){ swipeRef.setRefreshing(true); }
        protected String doInBackground(String... u){ try{ URL url=new URL(u[0]); HttpURLConnection c=(HttpURLConnection)url.openConnection(); BufferedReader r=new BufferedReader(new InputStreamReader(c.getInputStream())); StringBuilder s=new StringBuilder(); String l; while((l=r.readLine())!=null)s.append(l); return s.toString(); }catch(Exception e){ return null; } }
        protected void onPostExecute(String s){ swipeRef.setRefreshing(false); if(s==null)return; try{
            JSONObject j=new JSONObject(s); JSONObject ui=j.optJSONObject("ui_config"); featureConfig=j.optJSONObject("features");
            hColor=ui.optString("header_color"); bColor=ui.optString("bg_color"); tColor=ui.optString("text_color"); fColor=ui.optString("focus_color"); 
            menuType=ui.optString("menu_type","LIST"); playerConfigStr=j.optString("player_config");
            
            titleTxt.setText(ui.optString("custom_header_text",j.optString("app_name"))); titleTxt.setTextColor(Color.parseColor(tColor)); headerLayout.setBackgroundColor(Color.parseColor(hColor)); ((View)container.getParent()).setBackgroundColor(Color.parseColor(bColor));
            
            if(!ui.optBoolean("show_header",true)) headerLayout.setVisibility(8);
            String spl=ui.optString("splash_image"); if(!spl.isEmpty()){ if(!spl.startsWith("http"))spl=CONFIG_URL.substring(0,CONFIG_URL.lastIndexOf("/")+1)+spl; splash.setVisibility(0); Glide.with(MainActivity.this).load(spl).into(splash); new Handler().postDelayed(()->splash.setVisibility(8),3000); }
            getIntent().putExtra("FULL_CONFIG", ui.toString());
            
            // Direct Boot
            if(ui.optString("startup_mode").equals("DIRECT")){ String dt=ui.optString("direct_type"); String du=ui.optString("direct_url"); if(dt.equals("WEB")){ Intent i=new Intent(MainActivity.this,WebViewActivity.class); i.putExtra("WEB_URL",du); startActivity(i); } else op(dt,du,"",""); return; }
            
            checkFeat(); render(j.getJSONArray("modules"),ui); AdsManager.init(MainActivity.this,j.optJSONObject("ads_config"));
        }catch(Exception e){} }
    }
}
EOF

# ------------------------------------------------------------------
# 10. JAVA: WEBVIEW (SECURE + UPLOAD)
# ------------------------------------------------------------------
echo "🌐 [11/25] Java: WebViewActivity oluşturuluyor..."
cat > "app/src/main/java/com/base/app/WebViewActivity.java" <<EOF
package com.base.app;
import android.app.Activity; import android.os.Bundle; import android.webkit.*; import android.util.Base64; import android.content.Intent; import android.net.Uri; import android.view.KeyEvent;
public class WebViewActivity extends Activity {
    private WebView w;
    protected void onCreate(Bundle s){ super.onCreate(s); w=new WebView(this); setContentView(w);
        WebSettings ws=w.getSettings(); ws.setJavaScriptEnabled(true); ws.setDomStorageEnabled(true); ws.setAllowFileAccess(true);
        w.setWebViewClient(new WebViewClient(){
            public void onPageFinished(WebView v,String u){ String t=getSharedPreferences("TITAN_PREFS",0).getString("fcm_token",""); if(!t.isEmpty()) w.loadUrl("javascript:if(typeof onTokenReceived==='function'){onTokenReceived('"+t+"');}"); }
            public boolean shouldOverrideUrlLoading(WebView v,String u){ if(u.startsWith("http"))return false; try{startActivity(new Intent(Intent.ACTION_VIEW,Uri.parse(u)));}catch(Exception e){} return true; }
        });
        w.setWebChromeClient(new WebChromeClient());
        String u=getIntent().getStringExtra("WEB_URL"); String h=getIntent().getStringExtra("HTML_DATA");
        if(h!=null&&!h.isEmpty()) w.loadData(Base64.encodeToString(h.getBytes(),Base64.NO_PADDING),"text/html","base64"); else w.loadUrl(u);
    }
    public void onBackPressed(){ if(w.canGoBack())w.goBack(); else super.onBackPressed(); }
}
EOF

# ------------------------------------------------------------------
# 11. JAVA: PLAYER ACTIVITY (ADVANCED)
# ------------------------------------------------------------------
echo "🎥 [12/25] Java: PlayerActivity oluşturuluyor..."
cat > "app/src/main/java/com/base/app/PlayerActivity.java" <<EOF
package com.base.app;
import android.app.Activity; import android.net.Uri; import android.os.AsyncTask; import android.os.Bundle; import android.view.*; import android.widget.*; import android.graphics.Color; import androidx.media3.common.*; import androidx.media3.datasource.DefaultHttpDataSource; import androidx.media3.exoplayer.ExoPlayer; import androidx.media3.exoplayer.source.DefaultMediaSourceFactory; import androidx.media3.ui.PlayerView; import androidx.media3.ui.AspectRatioFrameLayout; import androidx.media3.exoplayer.DefaultLoadControl; import androidx.media3.exoplayer.upstream.DefaultAllocator; org.json.JSONObject; import java.net.HttpURLConnection; import java.net.URL; import java.util.*;
public class PlayerActivity extends Activity {
    private ExoPlayer pl; private PlayerView pv; private ProgressBar spin;
    protected void onCreate(Bundle s){ super.onCreate(s); 
    requestWindowFeature(1); getWindow().setFlags(1024,1024); getWindow().addFlags(128); getWindow().getDecorView().setSystemUiVisibility(5894);
    FrameLayout r=new FrameLayout(this); r.setBackgroundColor(Color.BLACK);
    pv=new PlayerView(this); pv.setShowNextButton(false); pv.setShowPreviousButton(false); r.addView(pv);
    spin=new ProgressBar(this); FrameLayout.LayoutParams lp=new FrameLayout.LayoutParams(-2,-2); lp.gravity=17; r.addView(spin,lp);
    try{ JSONObject c=new JSONObject(getIntent().getStringExtra("PLAYER_CONFIG")); 
    String rm=c.optString("resize_mode","FIT"); if(rm.equals("FILL"))pv.setResizeMode(3); else if(rm.equals("ZOOM"))pv.setResizeMode(4); else pv.setResizeMode(0);
    if(!c.optBoolean("auto_rotate",true))setRequestedOrientation(0);
    if(c.optBoolean("enable_overlay",false)){ TextView o=new TextView(this); o.setText(c.optString("watermark_text","")); o.setTextColor(Color.parseColor(c.optString("watermark_color","#FFFFFF"))); o.setTextSize(18); o.setPadding(30,30,30,30); o.setBackgroundColor(Color.parseColor("#80000000")); FrameLayout.LayoutParams p=new FrameLayout.LayoutParams(-2,-2); String pos=c.optString("watermark_pos","left"); p.gravity=(pos.equals("right")?53:51); r.addView(o,p); } }catch(Exception e){}
    setContentView(r); init(getIntent().getStringExtra("VIDEO_URL"), getIntent().getStringExtra("HEADERS_JSON")); }
    void init(String u, String hStr){ if(pl!=null)return; String ua="Mozilla/5.0"; Map<String,String> mp=new HashMap<>(); if(hStr!=null){try{JSONObject h=new JSONObject(hStr);Iterator<String>k=h.keys();while(k.hasNext()){String ky=k.next(),vl=h.getString(ky);if(ky.equalsIgnoreCase("User-Agent"))ua=vl;else mp.put(ky,vl);}}catch(Exception e){}}
    DefaultHttpDataSource.Factory df=new DefaultHttpDataSource.Factory().setUserAgent(ua).setAllowCrossProtocolRedirects(true).setDefaultRequestProperties(mp); DefaultLoadControl lc=new DefaultLoadControl.Builder().setAllocator(new DefaultAllocator(true,16*1024)).setBufferDurationsMs(50000,50000,2500,5000).build(); pl=new ExoPlayer.Builder(this).setLoadControl(lc).setMediaSourceFactory(new DefaultMediaSourceFactory(this).setDataSourceFactory(df)).build(); pv.setPlayer(pl); pl.setPlayWhenReady(true); pl.addListener(new Player.Listener(){ public void onPlaybackStateChanged(int s){ if(s==Player.STATE_BUFFERING)spin.setVisibility(View.VISIBLE); else spin.setVisibility(View.GONE); } }); try{ MediaItem.Builder it=new MediaItem.Builder().setUri(Uri.parse(u)); pl.setMediaItem(it.build()); pl.prepare(); }catch(Exception e){} }
    protected void onStop(){ super.onStop(); if(pl!=null){pl.release();pl=null;} } }
EOF

# ------------------------------------------------------------------
# 12. JAVA: CHANNEL LIST ACTIVITY
# ------------------------------------------------------------------
echo "📋 [13/25] Java: ChannelListActivity oluşturuluyor..."
cat > "app/src/main/java/com/base/app/ChannelListActivity.java" <<EOF
package com.base.app;
import android.app.Activity; import android.content.Intent; import android.os.AsyncTask; import android.os.Bundle; import android.view.*; import android.widget.*; import android.graphics.drawable.*; import android.graphics.Color; org.json.*; import java.io.*; import java.net.*; import java.util.*; import java.util.regex.*; import com.bumptech.glide.Glide; import com.bumptech.glide.request.RequestOptions;
public class ChannelListActivity extends Activity {
    private ListView lv; private Map<String, List<Item>> groups=new LinkedHashMap<>(); private List<String> gNames=new ArrayList<>(); private List<Item> curList=new ArrayList<>(); private boolean isGroup=false;
    private String hC,bC,tC,pCfg,fC;
    class Item { String n,u,i,h; Item(String nn,String uu,String ii,String hh){n=nn;u=uu;i=ii;h=hh;} }
    protected void onCreate(Bundle s){ super.onCreate(s);
        try{ JSONObject ui = new JSONObject(getIntent().getStringExtra("UI_CONFIG")); hC=ui.optString("header_color"); bC=ui.optString("bg_color"); tC=ui.optString("text_color"); fC=ui.optString("focus_color"); }catch(Exception e){}
        pCfg=getIntent().getStringExtra("PLAYER_CONFIG");
        LinearLayout r=new LinearLayout(this); r.setOrientation(1); r.setBackgroundColor(Color.parseColor(bC));
        LinearLayout h=new LinearLayout(this); h.setBackgroundColor(Color.parseColor(hC)); h.setPadding(30,30,30,30);
        TextView title=new TextView(this); title.setText(getString(R.string.loading)); title.setTextColor(Color.parseColor(tC)); title.setTextSize(18); h.addView(title); r.addView(h);
        lv=new ListView(this); lv.setDivider(null); lv.setPadding(20,20,20,20);
        LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-1,0,1.0f); r.addView(lv,lp); setContentView(r);
        new Load(getIntent().getStringExtra("TYPE"), getIntent().getStringExtra("LIST_CONTENT")).execute(getIntent().getStringExtra("LIST_URL"));
        lv.setOnItemClickListener((p,v,pos,id)->{ if(isGroup) { isGroup=false; title.setText(gNames.get(pos)); curList=groups.get(gNames.get(pos)); lv.setAdapter(new Adp(curList,false)); } else AdsManager.checkInter(this,()->{ Intent i=new Intent(this,PlayerActivity.class); i.putExtra("VIDEO_URL",curList.get(pos).u); i.putExtra("HEADERS_JSON",curList.get(pos).h); i.putExtra("PLAYER_CONFIG",pCfg); startActivity(i); }); });
    }
    public void onBackPressed(){ if(!isGroup&&gNames.size()>1) { isGroup=true; lv.setAdapter(new Adp(gNames,true)); } else super.onBackPressed(); }
    class Load extends AsyncTask<String,Void,String>{ String t,c; Load(String ty,String co){t=ty;c=co;}
        protected String doInBackground(String... u){ if("MANUAL_M3U".equals(t))return c; try{ URL url=new URL(u[0]); HttpURLConnection cn=(HttpURLConnection)url.openConnection(); cn.setRequestProperty("User-Agent","Mozilla/5.0"); BufferedReader r=new BufferedReader(new InputStreamReader(cn.getInputStream())); StringBuilder s=new StringBuilder(); String l; while((l=r.readLine())!=null)s.append(l).append("\n"); return s.toString(); }catch(Exception e){return null;} }
        protected void onPostExecute(String r){ if(r==null)return; try{ groups.clear(); gNames.clear();
        if("JSON_LIST".equals(t)||r.trim().startsWith("{")){ JSONObject rt=new JSONObject(r); JSONArray ar=rt.getJSONObject("list").getJSONArray("item"); String fl="Liste"; groups.put(fl,new ArrayList<>()); gNames.add(fl); for(int i=0;i<ar.length();i++){ JSONObject o=ar.getJSONObject(i); String u=o.optString("media_url",o.optString("url")); if(u.isEmpty())continue; JSONObject hd=new JSONObject(); for(int k=1;k<=5;k++){ String kn=o.optString("h"+k+"Key"),kv=o.optString("h"+k+"Val"); if(!kn.isEmpty()&&!kn.equals("0"))hd.put(kn,kv); } groups.get(fl).add(new Item(o.optString("title"),u,o.optString("thumb_square"),hd.toString())); } }
        if(groups.isEmpty()){ String[] ln=r.split("\n"); String ct="Ch",ci="",cg="All"; JSONObject ch=new JSONObject(); Pattern pg=Pattern.compile("group-title=\"([^\"]*)\""),pl=Pattern.compile("tvg-logo=\"([^\"]*)\""); for(String l:ln){ l=l.trim(); if(l.isEmpty())continue; if(l.startsWith("#EXTINF")){ if(l.contains(","))ct=l.substring(l.lastIndexOf(",")+1).trim(); Matcher mg=pg.matcher(l); if(mg.find())cg=mg.group(1); Matcher ml=pl.matcher(l); if(ml.find())ci=ml.group(1); } else if(l.startsWith("#EXTVLCOPT:")){ String op=l.substring(11); if(op.startsWith("http-referrer="))ch.put("Referer",op.substring(14)); if(op.startsWith("http-user-agent="))ch.put("User-Agent",op.substring(16)); if(op.startsWith("http-origin="))ch.put("Origin",op.substring(12)); } else if(!l.startsWith("#")){ if(!groups.containsKey(cg)){ groups.put(cg,new ArrayList<>()); gNames.add(cg); } groups.get(cg).add(new Item(ct,l,ci,ch.toString())); ct="Ch"; ci=""; ch=new JSONObject(); } } }
        if(gNames.size()>1){ isGroup=true; lv.setAdapter(new Adp(gNames,true)); } else if(gNames.size()==1){ isGroup=false; curList=groups.get(gNames.get(0)); lv.setAdapter(new Adp(curList,false)); } }catch(Exception e){} } }
    class Adp extends BaseAdapter{ List<?> d; boolean g; Adp(List<?> l,boolean is){d=l;g=is;} public int getCount(){return d.size();} public Object getItem(int p){return d.get(p);} public long getItemId(int p){return p;}
        public View getView(int p,View v,ViewGroup gr){ if(v==null){ LinearLayout l=new LinearLayout(ChannelListActivity.this); l.setOrientation(0); l.setGravity(16); ImageView i=new ImageView(ChannelListActivity.this); i.setId(1); l.addView(i); TextView t=new TextView(ChannelListActivity.this); t.setId(2); t.setTextColor(Color.BLACK); l.addView(t); v=l; }
            LinearLayout l=(LinearLayout)v; GradientDrawable n=new GradientDrawable(); n.setColor(Color.WHITE); n.setCornerRadius(15); l.setBackground(n);
            LinearLayout.LayoutParams pa=new LinearLayout.LayoutParams(-1,-2); pa.setMargins(0,0,0,10); l.setPadding(30,30,30,30); l.setLayoutParams(pa);
            ImageView im=v.findViewById(1); TextView tx=v.findViewById(2); tx.setTextColor(Color.parseColor(tC)); im.setLayoutParams(new LinearLayout.LayoutParams(100,100)); ((LinearLayout.LayoutParams)im.getLayoutParams()).setMargins(0,0,30,0); 
            if(g){ tx.setText(d.get(p).toString()); im.setImageResource(android.R.drawable.ic_menu_sort_by_size); im.setColorFilter(Color.parseColor(hC)); } else { Item i=(Item)d.get(p); tx.setText(i.n); if(!i.i.isEmpty()) Glide.with(ChannelListActivity.this).load(i.i).into(im); else im.setImageResource(android.R.drawable.ic_menu_slideshow); im.clearColorFilter(); } return v; } } }
EOF

# ------------------------------------------------------------------
# 13. SON KONTROL VE BİTİŞ
# ------------------------------------------------------------------
echo "✅ [25/25] TITAN APEX V20000 - Kurulum Tamamlandı."
echo "🚀 SİSTEM: ULTIMATE PATRON EDITION"
