#!/bin/bash
set -e
PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3
ICON_URL=$4
# ADS_CONFIG artık API'den canlı geliyor

echo "=========================================="
echo "   ULTRA APP V7 - PRO UI & TV SUPPORT"
echo "=========================================="

# --- 1. TEMİZLİK ---
rm -rf app/src/main/res/drawable*
rm -rf app/src/main/res/mipmap*
rm -rf app/src/main/java/com/base/app/*
TARGET_DIR="app/src/main/java/com/base/app"
mkdir -p "$TARGET_DIR"

# --- 2. ICON ---
mkdir -p app/src/main/res/mipmap-xxxhdpi
if [ ! -z "$ICON_URL" ]; then curl -L -o app/src/main/res/mipmap-xxxhdpi/ic_launcher.png "$ICON_URL"; fi

# --- 3. BUILD.GRADLE ---
cat > app/build.gradle <<EOF
plugins { id 'com.android.application' }
android {
    namespace 'com.base.app'
    compileSdk 34
    defaultConfig { applicationId "$PACKAGE_NAME"; minSdk 24; targetSdk 34; versionCode 1; versionName "1.0"; }
    compileOptions { sourceCompatibility 1.8; targetCompatibility 1.8; }
}
dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.media3:media3-exoplayer:1.2.0'
    implementation 'androidx.media3:media3-exoplayer-hls:1.2.0'
    implementation 'androidx.media3:media3-exoplayer-dash:1.2.0'
    implementation 'androidx.media3:media3-ui:1.2.0'
    implementation 'androidx.media3:media3-common:1.2.0'
    implementation 'com.unity3d.ads:unity-ads:4.9.2'
}
EOF

# --- 4. MANIFEST ---
cat > app/src/main/AndroidManifest.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.base.app">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.AD_ID" /> 
    <application android:allowBackup="true" android:label="$APP_NAME" android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true" android:theme="@android:style/Theme.DeviceDefault.Light.NoActionBar">
        <activity android:name=".MainActivity" android:exported="true" android:hardwareAccelerated="true">
            <intent-filter><action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" /></intent-filter>
        </activity>
        <activity android:name=".WebViewActivity" />
        <activity android:name=".ChannelListActivity" />
        <activity android:name=".PlayerActivity" android:configChanges="orientation|screenSize|keyboardHidden|smallestScreenSize|screenLayout" android:theme="@android:style/Theme.Black.NoTitleBar.Fullscreen" />
    </application>
</manifest>
EOF

# --- 5. ADS MANAGER (Aynı) ---
cat > "$TARGET_DIR/AdsManager.java" <<EOF
package com.base.app;
import android.app.Activity;
import android.util.Log;
import android.view.ViewGroup;
import com.unity3d.ads.*;
import com.unity3d.services.banners.*;
import org.json.JSONObject;
public class AdsManager {
    private static boolean ENABLED=false, BANNER_ACTIVE=false, INTER_ACTIVE=false;
    private static String GAME_ID="", BANNER_ID="", INTER_ID="";
    private static int INTER_FREQ=3, clickCount=0;
    public static void init(Activity a, JSONObject j){
        try{
            if(j==null)return;
            ENABLED=j.optBoolean("enabled",false); GAME_ID=j.optString("game_id");
            BANNER_ACTIVE=j.optBoolean("banner_active"); BANNER_ID=j.optString("banner_id");
            INTER_ACTIVE=j.optBoolean("inter_active"); INTER_ID=j.optString("inter_id"); INTER_FREQ=j.optInt("inter_freq",3);
            if(ENABLED && !GAME_ID.isEmpty()) UnityAds.initialize(a.getApplicationContext(), GAME_ID, false, new IUnityAdsInitializationListener(){
                public void onInitializationComplete(){ loadInterstitial(); }
                public void onInitializationFailed(UnityAds.UnityAdsInitializationError e, String m){}
            });
        }catch(Exception e){}
    }
    public static void showBanner(Activity a, ViewGroup c){
        if(!ENABLED || !BANNER_ACTIVE)return;
        BannerView b = new BannerView(a, BANNER_ID, new UnityBannerSize(320, 50));
        b.setListener(new BannerView.Listener(){ public void onBannerLoaded(BannerView v){c.removeAllViews(); c.addView(v);} });
        b.load();
    }
    private static void loadInterstitial(){ if(ENABLED && INTER_ACTIVE) UnityAds.load(INTER_ID, new IUnityAdsLoadListener(){public void onUnityAdsAdLoaded(String p){} public void onUnityAdsFailedToLoad(String p, UnityAds.UnityAdsLoadError e, String m){}}); }
    public static void showInterstitial(Activity a){
        if(!ENABLED || !INTER_ACTIVE)return;
        clickCount++;
        if(clickCount>=INTER_FREQ){
            UnityAds.show(a, INTER_ID, new IUnityAdsShowListener(){
                public void onUnityAdsShowStart(String p){} public void onUnityAdsShowClick(String p){}
                public void onUnityAdsShowComplete(String p, UnityAds.UnityAdsShowCompletionState s){clickCount=0; loadInterstitial();}
                public void onUnityAdsShowFailure(String p, UnityAds.UnityAdsShowError e, String m){loadInterstitial();}
            });
        }
    }
}
EOF

# --- 6. MainActivity.java (PROFESYONEL UI + HEADER + EXIT LOGIC) ---
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
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.StateListDrawable;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

public class MainActivity extends Activity {
    private String CONFIG_URL = "$CONFIG_URL"; 
    private RelativeLayout root;
    private LinearLayout contentContainer;
    private LinearLayout bannerContainer;
    private LinearLayout headerLayout;
    private TextView titleText;
    private ImageView refreshBtn, shareBtn;
    
    // UI Ayarları
    private String headerColor = "#2196F3", textColor = "#FFFFFF", bgColor = "#F0F0F0";
    private boolean showRefresh = true, showShare = true;
    private String appName = "$APP_NAME";
    
    // Çıkış Mantığı
    private long lastBackPressTime = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        root = new RelativeLayout(this);
        
        // --- 1. HEADER (Üst Bar) ---
        headerLayout = new LinearLayout(this);
        headerLayout.setId(View.generateViewId());
        headerLayout.setOrientation(LinearLayout.HORIZONTAL);
        headerLayout.setGravity(Gravity.CENTER_VERTICAL);
        headerLayout.setPadding(30, 30, 30, 30);
        headerLayout.setBackgroundColor(Color.parseColor(headerColor));
        headerLayout.setElevation(10f); // Gölge
        
        titleText = new TextView(this);
        titleText.setText(appName);
        titleText.setTextColor(Color.parseColor(textColor));
        titleText.setTextSize(20);
        titleText.setTypeface(null, android.graphics.Typeface.BOLD);
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(0, -2, 1.0f);
        headerLayout.addView(titleText, titleParams);

        // Paylaş Butonu
        shareBtn = new ImageView(this);
        shareBtn.setImageResource(android.R.drawable.ic_menu_share);
        shareBtn.setColorFilter(Color.parseColor(textColor));
        shareBtn.setPadding(20, 0, 20, 0);
        shareBtn.setOnClickListener(v -> shareApp());
        headerLayout.addView(shareBtn);

        // Yenile Butonu
        refreshBtn = new ImageView(this);
        refreshBtn.setImageResource(android.R.drawable.ic_popup_sync);
        refreshBtn.setColorFilter(Color.parseColor(textColor));
        refreshBtn.setPadding(20, 0, 0, 0);
        refreshBtn.setOnClickListener(v -> {
            Toast.makeText(this, "Yenileniyor...", Toast.LENGTH_SHORT).show();
            new FetchConfigTask().execute(CONFIG_URL);
        });
        headerLayout.addView(refreshBtn);

        RelativeLayout.LayoutParams headerParams = new RelativeLayout.LayoutParams(-1, -2);
        headerParams.addRule(RelativeLayout.ALIGN_PARENT_TOP);
        root.addView(headerLayout, headerParams);

        // --- 2. BANNER ---
        bannerContainer = new LinearLayout(this);
        bannerContainer.setId(View.generateViewId());
        bannerContainer.setOrientation(LinearLayout.VERTICAL);
        bannerContainer.setGravity(Gravity.CENTER);
        RelativeLayout.LayoutParams bannerRelParams = new RelativeLayout.LayoutParams(-1, -2);
        bannerRelParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
        root.addView(bannerContainer, bannerRelParams);

        // --- 3. İÇERİK (ScrollView) ---
        ScrollView sv = new ScrollView(this);
        sv.setBackgroundColor(Color.parseColor(bgColor)); // Dinamik arkaplan
        
        contentContainer = new LinearLayout(this);
        contentContainer.setOrientation(LinearLayout.VERTICAL);
        contentContainer.setPadding(30, 30, 30, 150); 
        sv.addView(contentContainer);
        
        RelativeLayout.LayoutParams scrollParams = new RelativeLayout.LayoutParams(-1, -1);
        scrollParams.addRule(RelativeLayout.BELOW, headerLayout.getId());
        scrollParams.addRule(RelativeLayout.ABOVE, bannerContainer.getId());
        root.addView(sv, scrollParams);

        setContentView(root);
        new FetchConfigTask().execute(CONFIG_URL);
    }

    private void shareApp() {
        Intent sendIntent = new Intent();
        sendIntent.setAction(Intent.ACTION_SEND);
        sendIntent.putExtra(Intent.EXTRA_TEXT, "Harika bir uygulama keşfettim: " + appName + "\n\nİndir: https://play.google.com/store/apps/details?id=" + getPackageName());
        sendIntent.setType("text/plain");
        startActivity(Intent.createChooser(sendIntent, "Paylaş"));
    }

    // Çıkış için 2 kere basma mantığı
    @Override
    public void onBackPressed() {
        if (this.lastBackPressTime < System.currentTimeMillis() - 2000) {
            Toast.makeText(this, "Çıkmak için tekrar basın", Toast.LENGTH_SHORT).show();
            this.lastBackPressTime = System.currentTimeMillis();
        } else {
            super.onBackPressed();
            System.exit(0);
        }
    }

    // TASARIMLI BUTON OLUŞTURUCU (TV UYUMLU)
    private void createStyledButton(String text, final String type, final String link) {
        Button btn = new Button(this);
        btn.setText(text);
        btn.setTextColor(Color.parseColor(textColor)); // Buton yazı rengi header ile uyumlu olsun
        btn.setTextSize(16);
        btn.setPadding(40, 40, 40, 40);
        btn.setGravity(Gravity.CENTER_VERTICAL | Gravity.START); // Yazı solda
        
        // --- PRO TASARIM (STATE LIST DRAWABLE) ---
        // Normal hali
        GradientDrawable normal = new GradientDrawable();
        normal.setColor(Color.parseColor(headerColor)); // Header rengini butona ver
        normal.setCornerRadius(15);
        normal.setStroke(2, Color.parseColor("#DDDDDD"));

        // Üzerine gelince / Basınca (TV Focus)
        GradientDrawable focused = new GradientDrawable();
        focused.setColor(Color.parseColor("#FF9800")); // Turuncu focus
        focused.setCornerRadius(15);
        focused.setStroke(4, Color.WHITE);

        StateListDrawable selector = new StateListDrawable();
        selector.addState(new int[]{android.R.attr.state_pressed}, focused);
        selector.addState(new int[]{android.R.attr.state_focused}, focused); // TV Kumandası için
        selector.addState(new int[]{}, normal);
        
        btn.setBackground(selector);
        
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, -2);
        p.setMargins(0, 0, 0, 25);
        btn.setLayoutParams(p);
        
        // İkon Ekleme (Metin başına)
        int iconRes = android.R.drawable.ic_menu_view; // Varsayılan
        if(type.equals("WEB")) iconRes = android.R.drawable.ic_menu_compass;
        if(type.equals("IPTV")) iconRes = android.R.drawable.ic_menu_slideshow;
        if(type.equals("JSON_LIST")) iconRes = android.R.drawable.ic_menu_sort_by_size;
        
        btn.setCompoundDrawablesWithIntrinsicBounds(iconRes, 0, 0, 0);
        btn.setCompoundDrawablePadding(30);

        btn.setOnClickListener(v -> {
            AdsManager.showInterstitial(MainActivity.this);
            if (type.equals("WEB")) {
                Intent intent = new Intent(MainActivity.this, WebViewActivity.class);
                intent.putExtra("WEB_URL", link);
                startActivity(intent);
            } else if (type.equals("IPTV") || type.equals("JSON_LIST")) {
                Intent intent = new Intent(MainActivity.this, ChannelListActivity.class);
                intent.putExtra("LIST_URL", link);
                intent.putExtra("TYPE", type);
                // Renkleri diğer sayfaya da taşı
                intent.putExtra("BG_COLOR", bgColor);
                intent.putExtra("HEADER_COLOR", headerColor);
                intent.putExtra("TEXT_COLOR", textColor);
                startActivity(intent);
            } else {
                try { startActivity(new Intent(Intent.ACTION_VIEW, android.net.Uri.parse(link))); } catch(Exception e){}
            }
        });
        contentContainer.addView(btn);
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
                appName = json.optString("app_name", "App");
                titleText.setText(appName);

                // --- UI AYARLARINI UYGULA ---
                JSONObject ui = json.optJSONObject("ui_config");
                if(ui != null) {
                    headerColor = ui.optString("header_color", "#2196F3");
                    textColor = ui.optString("text_color", "#FFFFFF");
                    bgColor = ui.optString("bg_color", "#F0F0F0");
                    
                    showRefresh = ui.optBoolean("show_refresh", true);
                    showShare = ui.optBoolean("show_share", true);
                    
                    // Renkleri Güncelle
                    headerLayout.setBackgroundColor(Color.parseColor(headerColor));
                    titleText.setTextColor(Color.parseColor(textColor));
                    root.setBackgroundColor(Color.parseColor(bgColor));
                    ((ScrollView)contentContainer.getParent()).setBackgroundColor(Color.parseColor(bgColor));
                    
                    refreshBtn.setVisibility(showRefresh ? View.VISIBLE : View.GONE);
                    shareBtn.setVisibility(showShare ? View.VISIBLE : View.GONE);
                    refreshBtn.setColorFilter(Color.parseColor(textColor));
                    shareBtn.setColorFilter(Color.parseColor(textColor));
                }

                JSONObject adsConfig = json.optJSONObject("ads_config");
                if (adsConfig != null) {
                    AdsManager.init(MainActivity.this, adsConfig);
                    AdsManager.showBanner(MainActivity.this, bannerContainer);
                }

                JSONArray mods = json.getJSONArray("modules");
                for(int i=0; i<mods.length(); i++){
                    JSONObject m = mods.getJSONObject(i);
                    if (m.optBoolean("active", true)) {
                        createStyledButton(m.getString("title"), m.getString("type"), m.getString("url"));
                    }
                }
            } catch(Exception e){}
        }
    }
}
EOF

# --- 7. ChannelListActivity.java (TV UYUMLU LİSTE TASARIMI) ---
cat > "$TARGET_DIR/ChannelListActivity.java" <<EOF
package com.base.app;
import android.app.Activity;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.*;
import android.widget.*;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.StateListDrawable;
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
    private String headerColor="#2196F3", textColor="#FFFFFF", bgColor="#F0F0F0";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Intent'ten renkleri al
        headerColor = getIntent().getStringExtra("HEADER_COLOR");
        if(headerColor==null) headerColor="#2196F3";
        bgColor = getIntent().getStringExtra("BG_COLOR");
        if(bgColor==null) bgColor="#F0F0F0";
        textColor = getIntent().getStringExtra("TEXT_COLOR");
        if(textColor==null) textColor="#FFFFFF";

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(Color.parseColor(bgColor));

        // Header
        LinearLayout header = new LinearLayout(this);
        header.setBackgroundColor(Color.parseColor(headerColor));
        header.setPadding(30,30,30,30);
        TextView title = new TextView(this);
        title.setText("Kanal Listesi");
        title.setTextColor(Color.parseColor(textColor));
        title.setTextSize(18);
        header.addView(title);
        root.addView(header);

        listView = new ListView(this);
        listView.setDivider(null); // Çizgileri kaldır, biz özel yapacağız
        listView.setPadding(20,20,20,20);
        listView.setClipToPadding(false);
        // TV Kumandası için seçimi belirt
        listView.setSelector(android.R.color.transparent); 
        
        root.addView(listView);
        setContentView(root);
        
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

    // ÖZEL ADAPTER (TV Uyumlu ve Şık)
    private class ChannelAdapter extends ArrayAdapter<String> {
        public ChannelAdapter(List<String> items) { super(ChannelListActivity.this, 0, items); }
        
        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            if (convertView == null) {
                LinearLayout layout = new LinearLayout(getContext());
                layout.setOrientation(LinearLayout.HORIZONTAL);
                layout.setPadding(30, 30, 30, 30);
                layout.setGravity(Gravity.CENTER_VERTICAL);
                
                // İkon
                ImageView icon = new ImageView(getContext());
                icon.setImageResource(android.R.drawable.ic_media_play);
                icon.setColorFilter(Color.DKGRAY);
                layout.addView(icon, new LinearLayout.LayoutParams(50, 50));
                
                // Metin
                TextView tv = new TextView(getContext());
                tv.setId(android.R.id.text1);
                tv.setTextSize(16);
                tv.setTextColor(Color.BLACK);
                tv.setPadding(30, 0, 0, 0);
                layout.addView(tv);
                
                convertView = layout;
            }
            
            TextView tv = convertView.findViewById(android.R.id.text1);
            tv.setText(getItem(position));
            
            // --- DİNAMİK ARKA PLAN (TV FOCUS) ---
            GradientDrawable normal = new GradientDrawable();
            normal.setColor(Color.WHITE);
            normal.setCornerRadius(10);
            normal.setStroke(1, Color.LTGRAY);

            GradientDrawable focused = new GradientDrawable();
            focused.setColor(Color.parseColor("#FFEB3B")); // Seçilince Sarımsı
            focused.setCornerRadius(10);
            focused.setStroke(3, Color.parseColor(headerColor));

            StateListDrawable bg = new StateListDrawable();
            bg.addState(new int[]{android.R.attr.state_pressed}, focused);
            bg.addState(new int[]{android.R.attr.state_selected}, focused); // TV
            bg.addState(new int[]{android.R.attr.state_hovered}, focused);
            bg.addState(new int[]{}, normal);
            
            convertView.setBackground(bg);
            
            // Margin verelim (ListView içinde margin zor olduğu için LayoutParams ile)
            AbsListView.LayoutParams params = new AbsListView.LayoutParams(-1, -2);
            convertView.setLayoutParams(params);
            convertView.setPadding(30,30,30,30); // İç boşluk
            
            return convertView;
        }
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
            if(r==null){Toast.makeText(ChannelListActivity.this,"Hata",Toast.LENGTH_SHORT).show();return;}
            try{
                names.clear(); urls.clear(); headers.clear();
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
                listView.setAdapter(new ChannelAdapter(names)); // Özel Adapter Kullan
            }catch(Exception e){Toast.makeText(ChannelListActivity.this,"Liste Hatasi",Toast.LENGTH_SHORT).show();}
        }
    }
}
EOF

# --- Diğerleri (WebView & Player) - Değişiklik yok, aynen yazıyoruz ---
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

echo "✅ ULTRA APP V7 TAMAMLANDI!"
