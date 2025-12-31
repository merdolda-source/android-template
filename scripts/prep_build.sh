#!/bin/bash
set -e

PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3
ICON_URL=$4
ADS_CONFIG=$5 # YENİ: Panelden gelen reklam ayarları JSON formatında

echo "=========================================="
echo "   ULTRA APP - MULTI APP & UNITY ADS"
echo "=========================================="
echo "PAKET: $PACKAGE_NAME"
echo "REKLAM AYARLARI MEVCUT: ${#ADS_CONFIG} karakter"

# --- 1. TEMİZLİK ---
rm -rf app/src/main/res/drawable*
rm -rf app/src/main/res/mipmap*
rm -rf app/src/main/res/values/themes.xml
rm -rf app/src/main/java/com/base/app/*

TARGET_DIR="app/src/main/java/com/base/app"
mkdir -p "$TARGET_DIR"

# --- 2. ICON AYARLAMA ---
mkdir -p app/src/main/res/mipmap-xxxhdpi
if [ ! -z "$ICON_URL" ]; then
    curl -L -o app/src/main/res/mipmap-xxxhdpi/ic_launcher.png "$ICON_URL"
fi

# --- 3. BUILD.GRADLE (Unity Ads Eklendi) ---
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
    implementation 'androidx.media3:media3-ui:1.2.0'
    implementation 'androidx.media3:media3-common:1.2.0'
    implementation 'androidx.media3:media3-exoplayer-dash:1.2.0'
    
    // UNITY ADS SDK
    implementation 'com.unity3d.ads:unity-ads:4.9.2'
}
EOF

# --- 4. MANIFEST ---
cat > app/src/main/AndroidManifest.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.base.app">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <uses-permission android:name="android.permission.AD_ID" /> 

    <application
        android:allowBackup="true"
        android:label="$APP_NAME"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true"
        android:theme="@android:style/Theme.DeviceDefault.Light.NoActionBar">
        
        <activity android:name=".MainActivity" android:exported="true" android:hardwareAccelerated="true">
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

# --- 5. JAVA: REKLAM YÖNETİCİSİ (AdsManager.java) ---
# Bu sınıf tüm reklam mantığını yönetir (Sıklık kontrolü vb.)
cat > "$TARGET_DIR/AdsManager.java" <<EOF
package com.base.app;

import android.app.Activity;
import android.util.Log;
import android.view.ViewGroup;
import android.widget.RelativeLayout;
import com.unity3d.ads.IUnityAdsInitializationListener;
import com.unity3d.ads.IUnityAdsLoadListener;
import com.unity3d.ads.IUnityAdsShowListener;
import com.unity3d.ads.UnityAds;
import com.unity3d.services.banners.BannerErrorInfo;
import com.unity3d.services.banners.BannerView;
import com.unity3d.services.banners.UnityBannerSize;
import org.json.JSONObject;

public class AdsManager {
    private static String GAME_ID = "";
    private static boolean TEST_MODE = false; // Yayınlarken false yap
    private static boolean ENABLED = false;
    
    private static String BANNER_ID = "Banner_Android";
    private static boolean BANNER_ACTIVE = false;
    
    private static String INTER_ID = "Interstitial_Android";
    private static boolean INTER_ACTIVE = false;
    private static int INTER_FREQ = 3;
    private static int clickCount = 0;

    public static void init(Activity activity, String jsonConfig) {
        try {
            JSONObject json = new JSONObject(jsonConfig);
            ENABLED = json.optBoolean("enabled", false);
            GAME_ID = json.optString("game_id", "");
            
            BANNER_ACTIVE = json.optBoolean("banner_active", false);
            BANNER_ID = json.optString("banner_id", "Banner_Android");
            
            INTER_ACTIVE = json.optBoolean("inter_active", false);
            INTER_ID = json.optString("inter_id", "Interstitial_Android");
            INTER_FREQ = json.optInt("inter_freq", 3);

            if (ENABLED && !GAME_ID.isEmpty()) {
                UnityAds.initialize(activity.getApplicationContext(), GAME_ID, TEST_MODE, new IUnityAdsInitializationListener() {
                    public void onInitializationComplete() { Log.d("ADS", "Init Success"); loadInterstitial(); }
                    public void onInitializationFailed(UnityAds.UnityAdsInitializationError error, String message) { Log.e("ADS", "Init Failed: " + message); }
                });
            }
        } catch (Exception e) { e.printStackTrace(); }
    }

    public static void showBanner(Activity activity, ViewGroup container) {
        if (!ENABLED || !BANNER_ACTIVE) return;
        BannerView banner = new BannerView(activity, BANNER_ID, new UnityBannerSize(320, 50));
        banner.setListener(new BannerView.Listener(){
            public void onBannerLoaded(BannerView bannerAdView) { container.addView(bannerAdView); }
            public void onBannerFailedToLoad(BannerView bannerAdView, BannerErrorInfo errorInfo) {}
            public void onBannerClick(BannerView bannerAdView) {}
            public void onBannerLeftApplication(BannerView bannerAdView) {}
        });
        banner.load();
    }

    private static void loadInterstitial() {
        if (!ENABLED || !INTER_ACTIVE) return;
        UnityAds.load(INTER_ID, new IUnityAdsLoadListener() {
            public void onUnityAdsAdLoaded(String placementId) {}
            public void onUnityAdsFailedToLoad(String placementId, UnityAds.UnityAdsLoadError error, String message) {}
        });
    }

    // Bu fonksiyon geçiş reklamını sıklığa göre gösterir
    public static void showInterstitial(Activity activity) {
        if (!ENABLED || !INTER_ACTIVE) return;
        
        clickCount++;
        if (clickCount >= INTER_FREQ) {
            UnityAds.show(activity, INTER_ID, new IUnityAdsShowListener() {
                public void onUnityAdsShowStart(String placementId) {}
                public void onUnityAdsShowClick(String placementId) {}
                public void onUnityAdsShowComplete(String placementId, UnityAds.UnityAdsShowCompletionState state) {
                    clickCount = 0; // Sayacı sıfırla
                    loadInterstitial(); // Yenisini yükle
                }
                public void onUnityAdsShowFailure(String placementId, UnityAds.UnityAdsShowError error, String message) { loadInterstitial(); }
            });
        }
    }
}
EOF

# --- 6. MainActivity.java (Reklam Entegrasyonu) ---
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
import android.widget.RelativeLayout;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

public class MainActivity extends Activity {
    private String CONFIG_URL = "$CONFIG_URL"; 
    // Panelden gelen reklam ayarlarını Java stringine gömüyoruz (Escape yaparak)
    private String ADS_JSON = "$ADS_CONFIG".replace("\"", "\\\""); 
    
    private LinearLayout contentContainer;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // ANA DÜZEN (Relative Layout: Banner en altta kalsın diye)
        RelativeLayout root = new RelativeLayout(this);
        root.setBackgroundColor(0xFFFFFFFF);
        
        // Scroll View (İçerik)
        ScrollView sv = new ScrollView(this);
        contentContainer = new LinearLayout(this);
        contentContainer.setOrientation(LinearLayout.VERTICAL);
        contentContainer.setPadding(50, 50, 50, 150); // Banner için alttan boşluk
        sv.addView(contentContainer);
        
        root.addView(sv, new RelativeLayout.LayoutParams(-1, -1));

        // Banner Alanı (En Alt)
        LinearLayout bannerContainer = new LinearLayout(this);
        bannerContainer.setOrientation(LinearLayout.VERTICAL);
        bannerContainer.setGravity(Gravity.CENTER);
        RelativeLayout.LayoutParams bannerParams = new RelativeLayout.LayoutParams(-1, -2);
        bannerParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
        bannerContainer.setLayoutParams(bannerParams);
        root.addView(bannerContainer);

        setContentView(root);
        
        // REKLAMLARI BAŞLAT
        AdsManager.init(this, "$ADS_CONFIG");
        AdsManager.showBanner(this, bannerContainer);

        new FetchConfigTask().execute(CONFIG_URL);
    }

    private class FetchConfigTask extends AsyncTask<String, Void, String> {
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

        protected void onPostExecute(String result) {
            if (result == null) return;
            contentContainer.removeAllViews();
            try {
                JSONObject json = new JSONObject(result);
                String title = json.optString("app_name", "App");
                TextView tv = new TextView(MainActivity.this);
                tv.setText(title);
                tv.setTextSize(24);
                tv.setGravity(Gravity.CENTER);
                tv.setPadding(0,0,0,30);
                contentContainer.addView(tv);

                JSONArray mods = json.getJSONArray("modules");
                for(int i=0; i<mods.length(); i++){
                    JSONObject m = mods.getJSONObject(i);
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
            // REKLAM KONTROLÜ (Tıklayınca sayaç artar, limit dolunca reklam çıkar)
            AdsManager.showInterstitial(MainActivity.this);

            if (type.equals("WEB")) {
                Intent intent = new Intent(MainActivity.this, WebViewActivity.class);
                intent.putExtra("WEB_URL", link);
                startActivity(intent);
            } else if (type.equals("IPTV") || type.equals("JSON_LIST")) {
                Intent intent = new Intent(MainActivity.this, ChannelListActivity.class);
                intent.putExtra("LIST_URL", link);
                intent.putExtra("TYPE", type);
                startActivity(intent);
            } else {
                try { startActivity(new Intent(Intent.ACTION_VIEW, android.net.Uri.parse(link))); } catch(Exception e){}
            }
        });
        contentContainer.addView(btn);
    }
}
EOF

# Diğer dosyalar (PlayerActivity, WebView, ChannelList) aynı kaldığı için tekrar yazmıyorum,
# ama scriptin tam çalışması için önceki mesajlardaki gibi bunların da oluşturulması gerekir.
# (Burada önceki mesajdaki PlayerActivity, ChannelListActivity vb. kodlarını kullanmaya devam edecek)
# KODUN DEVAMINI ÖNCEKİ MESAJDAKİ GİBİ EKLEYEBİLİRSİN.

# --- PlayerActivity.java (Aynısı) ---
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
    private String videoUrl, headersJson;
    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        playerView = new PlayerView(this);
        playerView.setShowNextButton(false);
        playerView.setShowPreviousButton(false);
        setContentView(playerView);
        videoUrl = getIntent().getStringExtra("VIDEO_URL");
        headersJson = getIntent().getStringExtra("HEADERS_JSON");
        if(videoUrl != null) videoUrl = videoUrl.trim();
        initializePlayer();
    }
    private void initializePlayer() {
        if(videoUrl == null || videoUrl.isEmpty()) return;
        String ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36";
        Map<String, String> rp = new HashMap<>();
        if(headersJson != null && !headersJson.isEmpty()){
            try{
                JSONObject h = new JSONObject(headersJson);
                Iterator<String> k = h.keys();
                while(k.hasNext()){
                    String key = k.next();
                    String val = h.getString(key);
                    if(key.equalsIgnoreCase("User-Agent")) ua = val;
                    else rp.put(key, val);
                }
            }catch(Exception e){}
        }
        DefaultHttpDataSource.Factory hf = new DefaultHttpDataSource.Factory().setUserAgent(ua).setAllowCrossProtocolRedirects(true).setDefaultRequestProperties(rp);
        DefaultMediaSourceFactory mf = new DefaultMediaSourceFactory(this).setDataSourceFactory(hf);
        player = new ExoPlayer.Builder(this).setMediaSourceFactory(mf).build();
        playerView.setPlayer(player);
        try{ player.setMediaItem(MediaItem.fromUri(Uri.parse(videoUrl))); player.prepare(); player.setPlayWhenReady(true); }catch(Exception e){}
        player.addListener(new Player.Listener(){ public void onPlayerError(PlaybackException e){ Toast.makeText(PlayerActivity.this, "Hata: " + e.getMessage(), Toast.LENGTH_LONG).show(); } });
    }
    protected void onStop(){ super.onStop(); if(player!=null){player.release(); player=null;} }
}
EOF

# --- ChannelListActivity.java (Aynısı) ---
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
    private List<String> names = new ArrayList<>(), urls = new ArrayList<>(), headers = new ArrayList<>();
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        listView = new ListView(this);
        setContentView(listView);
        String listUrl = getIntent().getStringExtra("LIST_URL");
        String type = getIntent().getStringExtra("TYPE");
        new FetchListTask(type).execute(listUrl);
        listView.setOnItemClickListener((p,v,pos,id)->{
            Intent i = new Intent(ChannelListActivity.this, PlayerActivity.class);
            i.putExtra("VIDEO_URL", urls.get(pos));
            i.putExtra("HEADERS_JSON", headers.get(pos));
            startActivity(i);
        });
    }
    private class FetchListTask extends AsyncTask<String,Void,String>{
        String type; FetchListTask(String t){type=t;}
        protected String doInBackground(String... u){
            try{
                URL url=new URL(u[0]); HttpURLConnection c=(HttpURLConnection)url.openConnection();
                c.setConnectTimeout(15000); c.setRequestProperty("User-Agent","Mozilla/5.0");
                BufferedReader r=new BufferedReader(new InputStreamReader(c.getInputStream()));
                StringBuilder sb=new StringBuilder(); String l; while((l=r.readLine())!=null)sb.append(l);
                return sb.toString();
            }catch(Exception e){return null;}
        }
        protected void onPostExecute(String r){
            if(r==null)return;
            try{
                if("JSON_LIST".equals(type) || r.trim().startsWith("{")){
                    JSONObject root=new JSONObject(r); JSONArray arr=root.getJSONObject("list").getJSONArray("item");
                    for(int i=0;i<arr.length();i++){
                        JSONObject o=arr.getJSONObject(i);
                        String url=o.optString("media_url",o.optString("url",""));
                        if(url.isEmpty())continue;
                        JSONObject h=new JSONObject();
                        for(int k=1;k<=5;k++){
                            String kn=o.optString("h"+k+"Key"), kv=o.optString("h"+k+"Val");
                            if(!kn.isEmpty()&&!kn.equals("0")&&!kv.isEmpty()&&!kv.equals("0")) h.put(kn,kv);
                        }
                        names.add(o.optString("title")); urls.add(url); headers.add(h.toString());
                    }
                }else{
                    String[] lines=r.split("\n"); String name="Kanal";
                    for(String l:lines){
                        l=l.trim(); if(l.isEmpty())continue;
                        if(l.startsWith("#EXTINF")){ if(l.contains(",")) name=l.substring(l.lastIndexOf(",")+1).trim(); }
                        else if(!l.startsWith("#")){ names.add(name); urls.add(l); headers.add("{}"); name="Bilinmeyen"; }
                    }
                }
                listView.setAdapter(new ArrayAdapter<>(ChannelListActivity.this, android.R.layout.simple_list_item_1, names));
            }catch(Exception e){}
        }
    }
}
EOF

# --- WebViewActivity.java (Aynısı) ---
cat > "$TARGET_DIR/WebViewActivity.java" <<EOF
package com.base.app;
import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
public class WebViewActivity extends Activity {
    protected void onCreate(Bundle s) {
        super.onCreate(s); WebView w=new WebView(this); setContentView(w);
        String u=getIntent().getStringExtra("WEB_URL");
        w.getSettings().setJavaScriptEnabled(true); w.getSettings().setDomStorageEnabled(true);
        w.setWebViewClient(new WebViewClient()); w.loadUrl(u);
    }
}
EOF

echo "✅ APP GÜNCELLENDİ (ÇOKLU UYGULAMA + UNITY ADS)"
