#!/bin/bash
set -e
PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3
ICON_URL=$4
VERSION_CODE=$5
VERSION_NAME=$6

echo "=========================================="
echo "   ULTRA APP V14 - CONNECTION FIX"
echo "=========================================="

# --- 1. TEMİZLİK ---
rm -rf app/src/main/res/drawable*
rm -rf app/src/main/res/mipmap*
rm -rf app/src/main/java/com/base/app/*
TARGET_DIR="app/src/main/java/com/base/app"
mkdir -p "$TARGET_DIR"

# --- 2. ICON (BAĞLANTI GÜÇLENDİRİLDİ) ---
# Eğer ikon inmezse hata verip durmasın, devam etsin diye "|| true" ekledik.
mkdir -p app/src/main/res/mipmap-xxxhdpi
if [ ! -z "$ICON_URL" ]; then 
    echo "İkon indiriliyor..."
    curl -L -k -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" --connect-timeout 30 --max-time 60 -o app/src/main/res/mipmap-xxxhdpi/ic_launcher.png "$ICON_URL" || echo "İkon indirilemedi, varsayılan kullanılacak."
fi

# --- 3. BUILD.GRADLE ---
cat > app/build.gradle <<EOF
plugins { id 'com.android.application' }
android {
    namespace 'com.base.app'
    compileSdk 34
    defaultConfig { 
        applicationId "$PACKAGE_NAME"
        minSdk 24
        targetSdk 34
        versionCode $VERSION_CODE
        versionName "$VERSION_NAME"
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
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    compileOptions { sourceCompatibility 1.8; targetCompatibility 1.8; }
}
dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.media3:media3-exoplayer:1.2.0'
    implementation 'androidx.media3:media3-exoplayer-hls:1.2.0'
    implementation 'androidx.media3:media3-ui:1.2.0'
    implementation 'androidx.media3:media3-common:1.2.0'
    implementation 'com.unity3d.ads:unity-ads:4.9.2'
    implementation 'com.github.bumptech.glide:glide:4.16.0'
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

# --- 5. ADS MANAGER ---
cat > "$TARGET_DIR/AdsManager.java" <<EOF
package com.base.app;
import android.app.Activity;
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
            if(ENABLED && !GAME_ID.isEmpty()) UnityAds.initialize(a.getApplicationContext(), GAME_ID, false, null);
        }catch(Exception e){}
    }
    public static void showBanner(Activity a, ViewGroup c){
        if(!ENABLED || !BANNER_ACTIVE)return;
        BannerView b = new BannerView(a, BANNER_ID, new UnityBannerSize(320, 50));
        b.setListener(new BannerView.Listener(){ public void onBannerLoaded(BannerView v){c.removeAllViews(); c.addView(v);} });
        b.load();
    }
    private static void loadInterstitial(){ if(ENABLED && INTER_ACTIVE) UnityAds.load(INTER_ID, null); }
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

# --- 6. MainActivity ---
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

public class MainActivity extends Activity {
    private String CONFIG_URL = "$CONFIG_URL"; 
    private RelativeLayout root;
    private LinearLayout contentContainer, bannerContainer, headerLayout;
    private TextView titleText;
    private ImageView refreshBtn, shareBtn;
    
    private String headerColor = "#2196F3", textColor = "#FFFFFF", bgColor = "#F0F0F0", focusColor = "#FF9800";
    private boolean showRefresh = true, showShare = true, showHeader = true;
    private String headerTitle = "", appName = "$APP_NAME";
    private int fontSize = 16;
    private int fontStyle = Typeface.BOLD;
    private long lastBackPressTime = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        root = new RelativeLayout(this);
        
        headerLayout = new LinearLayout(this);
        headerLayout.setId(View.generateViewId());
        headerLayout.setOrientation(LinearLayout.HORIZONTAL);
        headerLayout.setGravity(Gravity.CENTER_VERTICAL);
        headerLayout.setPadding(30, 30, 30, 30);
        headerLayout.setElevation(10f);
        
        titleText = new TextView(this);
        titleText.setText(appName);
        titleText.setTextSize(20);
        titleText.setTypeface(null, Typeface.BOLD);
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(0, -2, 1.0f);
        headerLayout.addView(titleText, titleParams);

        shareBtn = new ImageView(this);
        shareBtn.setImageResource(android.R.drawable.ic_menu_share);
        shareBtn.setPadding(20, 0, 20, 0);
        shareBtn.setOnClickListener(v -> shareApp());
        headerLayout.addView(shareBtn);

        refreshBtn = new ImageView(this);
        refreshBtn.setImageResource(android.R.drawable.ic_popup_sync);
        refreshBtn.setPadding(20, 0, 0, 0);
        refreshBtn.setOnClickListener(v -> new FetchConfigTask().execute(CONFIG_URL));
        headerLayout.addView(refreshBtn);

        RelativeLayout.LayoutParams hp = new RelativeLayout.LayoutParams(-1, -2);
        hp.addRule(RelativeLayout.ALIGN_PARENT_TOP);
        root.addView(headerLayout, hp);

        bannerContainer = new LinearLayout(this);
        bannerContainer.setId(View.generateViewId());
        bannerContainer.setOrientation(LinearLayout.VERTICAL);
        bannerContainer.setGravity(Gravity.CENTER);
        RelativeLayout.LayoutParams bp = new RelativeLayout.LayoutParams(-1, -2);
        bp.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
        root.addView(bannerContainer, bp);

        ScrollView sv = new ScrollView(this);
        contentContainer = new LinearLayout(this);
        contentContainer.setOrientation(LinearLayout.VERTICAL);
        contentContainer.setPadding(30, 30, 30, 150); 
        sv.addView(contentContainer);
        
        RelativeLayout.LayoutParams sp = new RelativeLayout.LayoutParams(-1, -1);
        sp.addRule(RelativeLayout.BELOW, headerLayout.getId());
        sp.addRule(RelativeLayout.ABOVE, bannerContainer.getId());
        root.addView(sv, sp);

        setContentView(root);
        new FetchConfigTask().execute(CONFIG_URL);
    }

    private void shareApp() {
        Intent i = new Intent(Intent.ACTION_SEND);
        i.setType("text/plain");
        i.putExtra(Intent.EXTRA_TEXT, appName + " uygulamasını indir: https://play.google.com/store/apps/details?id=" + getPackageName());
        startActivity(Intent.createChooser(i, "Paylaş"));
    }

    public void onBackPressed() {
        if (this.lastBackPressTime < System.currentTimeMillis() - 2000) {
            Toast.makeText(this, "Çıkmak için tekrar basın", Toast.LENGTH_SHORT).show();
            this.lastBackPressTime = System.currentTimeMillis();
        } else {
            super.onBackPressed();
            System.exit(0);
        }
    }

    private void createStyledButton(String text, final String type, final String link) {
        Button btn = new Button(this);
        btn.setText(text);
        btn.setTextColor(Color.parseColor(textColor));
        btn.setTextSize(fontSize);
        btn.setTypeface(null, fontStyle);
        btn.setPadding(40, 40, 40, 40);
        btn.setGravity(Gravity.CENTER_VERTICAL | Gravity.START);
        
        GradientDrawable normal = new GradientDrawable();
        normal.setColor(Color.parseColor(headerColor));
        normal.setCornerRadius(15);

        GradientDrawable focused = new GradientDrawable();
        focused.setColor(Color.parseColor(focusColor)); 
        focused.setCornerRadius(15);
        focused.setStroke(4, Color.WHITE);

        StateListDrawable selector = new StateListDrawable();
        selector.addState(new int[]{android.R.attr.state_pressed}, focused);
        selector.addState(new int[]{android.R.attr.state_focused}, focused);
        selector.addState(new int[]{}, normal);
        
        btn.setBackground(selector);
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, -2);
        p.setMargins(0, 0, 0, 25);
        btn.setLayoutParams(p);
        
        btn.setOnClickListener(v -> openContent(type, link));
        contentContainer.addView(btn);
    }

    private void openContent(String type, String link) {
        AdsManager.showInterstitial(MainActivity.this);
        if (type.equals("WEB")) {
            Intent i = new Intent(MainActivity.this, WebViewActivity.class);
            i.putExtra("WEB_URL", link); startActivity(i);
        } else if (type.equals("IPTV") || type.equals("JSON_LIST")) {
            Intent i = new Intent(MainActivity.this, ChannelListActivity.class);
            i.putExtra("LIST_URL", link); i.putExtra("TYPE", type);
            i.putExtra("BG_COLOR", bgColor); i.putExtra("HEADER_COLOR", headerColor); 
            i.putExtra("TEXT_COLOR", textColor); i.putExtra("FOCUS_COLOR", focusColor);
            startActivity(i);
        } else {
            try { startActivity(new Intent(Intent.ACTION_VIEW, android.net.Uri.parse(link))); } catch(Exception e){}
        }
    }

    private class FetchConfigTask extends AsyncTask<String, Void, String> {
        protected String doInBackground(String... urls) {
            try {
                URL url = new URL(urls[0]);
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36");
                conn.setConnectTimeout(10000); 
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
                
                JSONObject ui = json.optJSONObject("ui_config");
                if(ui != null) {
                    headerColor = ui.optString("header_color", "#2196F3");
                    textColor = ui.optString("text_color", "#FFFFFF");
                    bgColor = ui.optString("bg_color", "#F0F0F0");
                    focusColor = ui.optString("focus_color", "#FF9800");
                    
                    showRefresh = ui.optBoolean("show_refresh", true);
                    showShare = ui.optBoolean("show_share", true);
                    showHeader = ui.optBoolean("show_header", true);
                    headerTitle = ui.optString("header_title", "");
                    
                    fontSize = ui.optInt("font_size", 16);
                    String fStyle = ui.optString("font_style", "BOLD");
                    if(fStyle.equals("NORMAL")) fontStyle = Typeface.NORMAL;
                    else if(fStyle.equals("ITALIC")) fontStyle = Typeface.ITALIC;
                    else fontStyle = Typeface.BOLD;

                    if (showHeader) {
                        headerLayout.setVisibility(View.VISIBLE);
                        titleText.setText(headerTitle.isEmpty() ? appName : headerTitle);
                    } else {
                        headerLayout.setVisibility(View.GONE);
                    }

                    headerLayout.setBackgroundColor(Color.parseColor(headerColor));
                    titleText.setTextColor(Color.parseColor(textColor));
                    root.setBackgroundColor(Color.parseColor(bgColor));
                    ((ScrollView)contentContainer.getParent()).setBackgroundColor(Color.parseColor(bgColor));
                    
                    refreshBtn.setVisibility(showRefresh ? View.VISIBLE : View.GONE);
                    shareBtn.setVisibility(showShare ? View.VISIBLE : View.GONE);
                    refreshBtn.setColorFilter(Color.parseColor(textColor));
                    shareBtn.setColorFilter(Color.parseColor(textColor));

                    String startupMode = ui.optString("startup_mode", "MENU");
                    if ("DIRECT".equals(startupMode)) {
                        String dType = ui.optString("direct_type", "WEB");
                        String dUrl = ui.optString("direct_url", "");
                        if (!dUrl.isEmpty()) { openContent(dType, dUrl); }
                    }
                } else {
                    titleText.setText(appName);
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

# --- 7. ChannelListActivity.java ---
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
import com.bumptech.glide.Glide; 

public class ChannelListActivity extends Activity {
    private ListView listView;
    private List<ChannelItem> channelList = new ArrayList<>();
    private String headerColor="#2196F3", textColor="#FFFFFF", bgColor="#F0F0F0", focusColor="#FF9800";

    class ChannelItem {
        String name; String url; String image; String headers;
        ChannelItem(String n, String u, String i, String h) { name=n; url=u; image=i; headers=h; }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        headerColor = getIntent().getStringExtra("HEADER_COLOR");
        bgColor = getIntent().getStringExtra("BG_COLOR");
        textColor = getIntent().getStringExtra("TEXT_COLOR");
        focusColor = getIntent().getStringExtra("FOCUS_COLOR"); 
        if(focusColor == null) focusColor = "#FF9800";

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(Color.parseColor(bgColor));

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
        listView.setDivider(null); 
        listView.setPadding(20,20,20,20);
        listView.setClipToPadding(false);
        listView.setSelector(android.R.color.transparent);
        
        root.addView(listView);
        setContentView(root);
        
        String listUrl = getIntent().getStringExtra("LIST_URL");
        String type = getIntent().getStringExtra("TYPE");
        new FetchListTask(type).execute(listUrl);
        
        listView.setOnItemClickListener((p,v,pos,id)->{
            ChannelItem item = channelList.get(pos);
            Intent i = new Intent(ChannelListActivity.this, PlayerActivity.class);
            i.putExtra("VIDEO_URL", item.url);
            i.putExtra("HEADERS_JSON", item.headers);
            startActivity(i);
        });
    }

    private class ChannelAdapter extends ArrayAdapter<ChannelItem> {
        public ChannelAdapter(List<ChannelItem> items) { super(ChannelListActivity.this, 0, items); }
        public View getView(int position, View convertView, ViewGroup parent) {
            if (convertView == null) {
                LinearLayout layout = new LinearLayout(getContext());
                layout.setOrientation(LinearLayout.HORIZONTAL);
                layout.setPadding(20, 20, 20, 20);
                layout.setGravity(Gravity.CENTER_VERTICAL);
                
                ImageView icon = new ImageView(getContext());
                icon.setId(101); icon.setScaleType(ImageView.ScaleType.CENTER_CROP);
                LinearLayout.LayoutParams imgParams = new LinearLayout.LayoutParams(120, 120);
                imgParams.setMargins(0, 0, 30, 0);
                layout.addView(icon, imgParams);
                
                TextView tv = new TextView(getContext());
                tv.setId(102); tv.setTextSize(16); tv.setTextColor(Color.BLACK); tv.setTypeface(null, android.graphics.Typeface.BOLD);
                layout.addView(tv);
                convertView = layout;
            }
            ChannelItem item = getItem(position);
            ImageView img = convertView.findViewById(101);
            TextView txt = convertView.findViewById(102);
            txt.setText(item.name);
            
            if(item.image != null && !item.image.isEmpty()) Glide.with(getContext()).load(item.image).into(img);
            else img.setImageResource(android.R.drawable.ic_menu_slideshow);

            GradientDrawable normal = new GradientDrawable();
            normal.setColor(Color.WHITE); normal.setCornerRadius(15); normal.setStroke(1, Color.LTGRAY);
            GradientDrawable focused = new GradientDrawable();
            focused.setColor(Color.parseColor(focusColor)); focused.setCornerRadius(15); focused.setStroke(3, Color.parseColor(headerColor));
            StateListDrawable bg = new StateListDrawable();
            bg.addState(new int[]{android.R.attr.state_pressed}, focused);
            bg.addState(new int[]{android.R.attr.state_selected}, focused);
            bg.addState(new int[]{android.R.attr.state_hovered}, focused);
            bg.addState(new int[]{}, normal);
            convertView.setBackground(bg);
            
            AbsListView.LayoutParams params = new AbsListView.LayoutParams(-1, -2);
            convertView.setLayoutParams(params);
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
                StringBuilder sb=new StringBuilder(); String l; while((l=r.readLine())!=null)sb.append(l).append("\n");
                return sb.toString();
            }catch(Exception e){return null;}
        }
        protected void onPostExecute(String r){
            if(r==null){Toast.makeText(ChannelListActivity.this,"Hata",Toast.LENGTH_SHORT).show();return;}
            try{
                channelList.clear();
                
                // JSON ve M3U AYRIMI
                if("JSON_LIST".equals(type) || r.trim().startsWith("{")){
                    try {
                        JSONObject root=new JSONObject(r); JSONArray arr=root.getJSONObject("list").getJSONArray("item");
                        for(int i=0;i<arr.length();i++){
                            JSONObject o=arr.getJSONObject(i);
                            String url=o.optString("media_url",o.optString("url",""));
                            if(url.isEmpty())continue;
                            String title = o.optString("title");
                            String image = o.optString("thumb_square", o.optString("image", ""));
                            JSONObject h=new JSONObject();
                            for(int k=1;k<=5;k++){
                                String kn=o.optString("h"+k+"Key"), kv=o.optString("h"+k+"Val");
                                if(!kn.isEmpty()&&!kn.equals("0")&&!kv.isEmpty()&&!kv.equals("0")) h.put(kn,kv);
                            }
                            channelList.add(new ChannelItem(title, url, image, h.toString()));
                        }
                    } catch(Exception e) {}
                } 
                
                // M3U PARSING (VLC OPTION SUPPORT)
                if(channelList.isEmpty()) {
                    String[] lines = r.split("\n");
                    String currentTitle = "Kanal";
                    String currentImage = "";
                    JSONObject currentHeaders = new JSONObject();
                    
                    for(String line : lines) {
                        line = line.trim();
                        if(line.isEmpty()) continue;
                        
                        if(line.startsWith("#EXTINF")) {
                            if(line.contains(",")) currentTitle = line.substring(line.lastIndexOf(",")+1).trim();
                            if(line.contains("tvg-logo=\"")) {
                                int s = line.indexOf("tvg-logo=\"")+10;
                                int e = line.indexOf("\"", s);
                                if(e>s) currentImage = line.substring(s, e);
                            }
                        } 
                        else if(line.startsWith("#EXTVLCOPT:")) {
                            String opt = line.substring(11);
                            String[] parts = opt.split("=", 2);
                            if(parts.length == 2) {
                                String key = parts[0].toLowerCase();
                                String val = parts[1];
                                try {
                                    if(key.equals("http-referrer")) currentHeaders.put("Referer", val);
                                    else if(key.equals("http-origin")) currentHeaders.put("Origin", val);
                                    else if(key.equals("http-user-agent")) currentHeaders.put("User-Agent", val);
                                } catch(Exception e){}
                            }
                        }
                        else if(!line.startsWith("#")) {
                            channelList.add(new ChannelItem(currentTitle, line, currentImage, currentHeaders.toString()));
                            currentTitle = "Bilinmeyen Kanal";
                            currentImage = "";
                            currentHeaders = new JSONObject(); 
                        }
                    }
                }
                listView.setAdapter(new ChannelAdapter(channelList));
            }catch(Exception e){Toast.makeText(ChannelListActivity.this,"Liste Hatasi",Toast.LENGTH_SHORT).show();}
        }
    }
}
EOF

# --- Player & WebView ---
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

echo "✅ ULTRA APP V14 - CONNECTION FIX + M3U FIX"
