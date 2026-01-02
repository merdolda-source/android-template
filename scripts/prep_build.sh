#!/bin/bash
set -e
PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3
ICON_URL=$4
VERSION_CODE=$5
VERSION_NAME=$6

echo "=========================================="
echo "   ULTRA APP V19 - DEEP RESOLVER FIX"
echo "=========================================="

# --- 1. TEMİZLİK ---
rm -rf app/src/main/res/drawable*
rm -rf app/src/main/res/mipmap*
rm -rf app/src/main/java/com/base/app/*
TARGET_DIR="app/src/main/java/com/base/app"
mkdir -p "$TARGET_DIR"

# --- 2. ICON ---
mkdir -p app/src/main/res/mipmap-xxxhdpi
ICON_TARGET="app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
if [ ! -z "$ICON_URL" ]; then 
    curl -L -k -A "Mozilla/5.0" --connect-timeout 20 --max-time 60 -o "$ICON_TARGET" "$ICON_URL" || echo "İkon inemedi."
fi
if [ ! -s "$ICON_TARGET" ]; then
    curl -L -k -o "$ICON_TARGET" "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Android_new_logo_2019.svg/512px-Android_new_logo_2019.svg.png"
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
    implementation 'androidx.media3:media3-exoplayer-dash:1.2.0'
    implementation 'androidx.media3:media3-exoplayer-rtsp:1.2.0'
    implementation 'androidx.media3:media3-exoplayer-smoothstreaming:1.2.0'
    implementation 'androidx.media3:media3-ui:1.2.0'
    implementation 'androidx.media3:media3-common:1.2.0'
    implementation 'androidx.media3:media3-datasource-okhttp:1.2.0'
    implementation 'com.unity3d.ads:unity-ads:4.9.2'
    implementation 'com.github.bumptech.glide:glide:4.16.0'
}
EOF

# --- 4. MANIFEST ---
cat > app/src/main/AndroidManifest.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
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
        Intent i = new Intent(Intent.ACTION_SEND); i.setType("text/plain");
        i.putExtra(Intent.EXTRA_TEXT, appName + " uygulamasını indir: https://play.google.com/store/apps/details?id=" + getPackageName());
        startActivity(Intent.createChooser(i, "Paylaş"));
    }

    public void onBackPressed() {
        if (this.lastBackPressTime < System.currentTimeMillis() - 2000) {
            Toast.makeText(this, "Çıkmak için tekrar basın", Toast.LENGTH_SHORT).show();
            this.lastBackPressTime = System.currentTimeMillis();
        } else { super.onBackPressed(); System.exit(0); }
    }

    private void createStyledButton(String text, final String type, final String link) {
        Button btn = new Button(this);
        btn.setText(text); btn.setTextColor(Color.parseColor(textColor));
        btn.setTextSize(fontSize); btn.setTypeface(null, fontStyle);
        btn.setPadding(40, 40, 40, 40); btn.setGravity(Gravity.CENTER_VERTICAL | Gravity.START);
        GradientDrawable normal = new GradientDrawable(); normal.setColor(Color.parseColor(headerColor)); normal.setCornerRadius(15);
        GradientDrawable focused = new GradientDrawable(); focused.setColor(Color.parseColor(focusColor)); focused.setCornerRadius(15); focused.setStroke(4, Color.WHITE);
        StateListDrawable selector = new StateListDrawable();
        selector.addState(new int[]{android.R.attr.state_pressed}, focused);
        selector.addState(new int[]{android.R.attr.state_focused}, focused);
        selector.addState(new int[]{}, normal);
        btn.setBackground(selector);
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, -2); p.setMargins(0, 0, 0, 25); btn.setLayoutParams(p);
        btn.setOnClickListener(v -> openContent(type, link)); contentContainer.addView(btn);
    }

    private void openContent(String type, String link) {
        AdsManager.showInterstitial(MainActivity.this);
        if (type.equals("WEB")) { Intent i = new Intent(MainActivity.this, WebViewActivity.class); i.putExtra("WEB_URL", link); startActivity(i); }
        else if (type.equals("IPTV") || type.equals("JSON_LIST")) {
            Intent i = new Intent(MainActivity.this, ChannelListActivity.class);
            i.putExtra("LIST_URL", link); i.putExtra("TYPE", type);
            i.putExtra("BG_COLOR", bgColor); i.putExtra("HEADER_COLOR", headerColor); 
            i.putExtra("TEXT_COLOR", textColor); i.putExtra("FOCUS_COLOR", focusColor);
            startActivity(i);
        } else { try { startActivity(new Intent(Intent.ACTION_VIEW, android.net.Uri.parse(link))); } catch(Exception e){} }
    }

    private class FetchConfigTask extends AsyncTask<String, Void, String> {
        protected String doInBackground(String... urls) {
            try {
                URL url = new URL(urls[0]); HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setRequestProperty("User-Agent", "Mozilla/5.0"); conn.setConnectTimeout(10000);
                BufferedReader rd = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                StringBuilder res = new StringBuilder(); String line; while ((line = rd.readLine()) != null) res.append(line);
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
                    if(fStyle.equals("NORMAL")) fontStyle = Typeface.NORMAL; else if(fStyle.equals("ITALIC")) fontStyle = Typeface.ITALIC; else fontStyle = Typeface.BOLD;

                    if (showHeader) { headerLayout.setVisibility(View.VISIBLE); titleText.setText(headerTitle.isEmpty() ? appName : headerTitle); } else { headerLayout.setVisibility(View.GONE); }
                    
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
                        String dType = ui.optString("direct_type", "WEB"); String dUrl = ui.optString("direct_url", "");
                        if (!dUrl.isEmpty()) { openContent(dType, dUrl); }
                    }
                } else { titleText.setText(appName); }

                JSONObject adsConfig = json.optJSONObject("ads_config");
                if (adsConfig != null) { AdsManager.init(MainActivity.this, adsConfig); AdsManager.showBanner(MainActivity.this, bannerContainer); }

                JSONArray mods = json.getJSONArray("modules");
                for(int i=0; i<mods.length(); i++){
                    JSONObject m = mods.getJSONObject(i);
                    if (m.optBoolean("active", true)) { createStyledButton(m.getString("title"), m.getString("type"), m.getString("url")); }
                }
            } catch(Exception e){}
        }
    }
}
EOF

# --- 7. ChannelListActivity ---
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
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import com.bumptech.glide.Glide; 

public class ChannelListActivity extends Activity {
    private ListView listView;
    private Map<String, List<ChannelItem>> groupedChannels = new LinkedHashMap<>();
    private List<String> groupNames = new ArrayList<>();
    private List<ChannelItem> currentList = new ArrayList<>();
    private boolean isShowingGroups = false;
    private String headerColor="#2196F3", textColor="#FFFFFF", bgColor="#F0F0F0", focusColor="#FF9800";
    private TextView titleText;

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
        
        titleText = new TextView(this);
        titleText.setText("Yükleniyor...");
        titleText.setTextColor(Color.parseColor(textColor));
        titleText.setTextSize(18);
        titleText.setTypeface(null, android.graphics.Typeface.BOLD);
        header.addView(titleText);
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
            if (isShowingGroups) {
                showChannels(groupNames.get(pos));
            } else {
                ChannelItem item = currentList.get(pos);
                Intent i = new Intent(ChannelListActivity.this, PlayerActivity.class);
                i.putExtra("VIDEO_URL", item.url);
                i.putExtra("HEADERS_JSON", item.headers);
                startActivity(i);
            }
        });
    }

    @Override
    public void onBackPressed() {
        if (!isShowingGroups && groupNames.size() > 1) { showGroups(); } else { super.onBackPressed(); }
    }

    private void showGroups() {
        isShowingGroups = true;
        titleText.setText("Kategoriler");
        listView.setAdapter(new CategoryAdapter(groupNames));
    }

    private void showChannels(String groupName) {
        isShowingGroups = false;
        titleText.setText(groupName);
        currentList = groupedChannels.get(groupName);
        listView.setAdapter(new ChannelAdapter(currentList));
    }

    private class CategoryAdapter extends ArrayAdapter<String> {
        public CategoryAdapter(List<String> items) { super(ChannelListActivity.this, 0, items); }
        public View getView(int position, View convertView, ViewGroup parent) { return createRow(convertView, getItem(position), null, true); }
    }

    private class ChannelAdapter extends ArrayAdapter<ChannelItem> {
        public ChannelAdapter(List<ChannelItem> items) { super(ChannelListActivity.this, 0, items); }
        public View getView(int position, View convertView, ViewGroup parent) {
            ChannelItem item = getItem(position);
            return createRow(convertView, item.name, item.image, false);
        }
    }

    private View createRow(View convertView, String text, String imageUrl, boolean isFolder) {
        if (convertView == null) {
            LinearLayout layout = new LinearLayout(ChannelListActivity.this);
            layout.setOrientation(LinearLayout.HORIZONTAL);
            layout.setPadding(25, 25, 25, 25);
            layout.setGravity(Gravity.CENTER_VERTICAL);
            
            ImageView icon = new ImageView(ChannelListActivity.this);
            icon.setId(101); icon.setScaleType(ImageView.ScaleType.CENTER_CROP);
            LinearLayout.LayoutParams imgParams = new LinearLayout.LayoutParams(100, 100);
            imgParams.setMargins(0, 0, 30, 0);
            layout.addView(icon, imgParams);
            
            TextView tv = new TextView(ChannelListActivity.this);
            tv.setId(102); tv.setTextSize(16); tv.setTextColor(Color.BLACK); 
            tv.setTypeface(null, android.graphics.Typeface.BOLD);
            layout.addView(tv);
            convertView = layout;
        }
        
        ImageView img = convertView.findViewById(101);
        TextView txt = convertView.findViewById(102);
        txt.setText(text);
        
        if (isFolder) {
            img.setImageResource(android.R.drawable.ic_menu_sort_by_size);
            img.setColorFilter(Color.parseColor(headerColor));
        } else {
            img.clearColorFilter();
            if(imageUrl != null && !imageUrl.isEmpty()) Glide.with(ChannelListActivity.this).load(imageUrl).into(img);
            else img.setImageResource(android.R.drawable.ic_menu_slideshow);
        }

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
                groupedChannels.clear(); groupNames.clear();
                
                if("JSON_LIST".equals(type) || r.trim().startsWith("{")) {
                    try {
                        JSONObject root=new JSONObject(r); JSONArray arr=root.getJSONObject("list").getJSONArray("item");
                        String defaultGroup = "Genel";
                        for(int i=0;i<arr.length();i++){
                            JSONObject o=arr.getJSONObject(i);
                            String url=o.optString("media_url",o.optString("url",""));
                            if(url.isEmpty())continue;
                            String title = o.optString("title");
                            String image = o.optString("thumb_square", o.optString("image", ""));
                            String group = o.optString("group", defaultGroup);
                            JSONObject h=new JSONObject();
                            for(int k=1;k<=5;k++){
                                String kn=o.optString("h"+k+"Key"), kv=o.optString("h"+k+"Val");
                                if(!kn.isEmpty()&&!kn.equals("0")&&!kv.isEmpty()&&!kv.equals("0")) h.put(kn,kv);
                            }
                            if(!groupedChannels.containsKey(group)) { groupedChannels.put(group, new ArrayList<>()); groupNames.add(group); }
                            groupedChannels.get(group).add(new ChannelItem(title, url, image, h.toString()));
                        }
                    } catch(Exception e){}
                } 
                
                if(groupedChannels.isEmpty() && !r.trim().startsWith("{")) {
                    String[] lines = r.split("\n");
                    String currentTitle = "Kanal";
                    String currentImage = "";
                    String currentGroup = "Genel";
                    JSONObject currentHeaders = new JSONObject();
                    Pattern groupPattern = Pattern.compile("group-title=\"([^\"]*)\"");
                    Pattern logoPattern = Pattern.compile("tvg-logo=\"([^\"]*)\"");

                    for(String line : lines) {
                        line = line.trim(); if(line.isEmpty()) continue;
                        if(line.startsWith("#EXTINF")) {
                            if(line.contains(",")) currentTitle = line.substring(line.lastIndexOf(",")+1).trim();
                            Matcher mGroup = groupPattern.matcher(line);
                            if(mGroup.find()) currentGroup = mGroup.group(1); else currentGroup = "Genel";
                            Matcher mLogo = logoPattern.matcher(line);
                            if(mLogo.find()) currentImage = mLogo.group(1);
                        } 
                        else if(line.startsWith("#EXTVLCOPT:")) {
                            String opt = line.substring(11); String[] parts = opt.split("=", 2);
                            if(parts.length==2) {
                                try {
                                    if(parts[0].equalsIgnoreCase("http-referrer")) currentHeaders.put("Referer", parts[1]);
                                    if(parts[0].equalsIgnoreCase("http-origin")) currentHeaders.put("Origin", parts[1]);
                                    if(parts[0].equalsIgnoreCase("http-user-agent")) currentHeaders.put("User-Agent", parts[1]);
                                } catch(Exception e){}
                            }
                        } 
                        else if(!line.startsWith("#")) {
                            if(!groupedChannels.containsKey(currentGroup)) {
                                groupedChannels.put(currentGroup, new ArrayList<>());
                                groupNames.add(currentGroup);
                            }
                            groupedChannels.get(currentGroup).add(new ChannelItem(currentTitle, line, currentImage, currentHeaders.toString()));
                            currentTitle = "Bilinmeyen Kanal"; currentImage = ""; currentHeaders = new JSONObject();
                        }
                    }
                }

                if (groupNames.size() > 1) showGroups(); 
                else if (groupNames.size() == 1) showChannels(groupNames.get(0));
                else Toast.makeText(ChannelListActivity.this,"Kanal Bulunamadı",Toast.LENGTH_SHORT).show();

            }catch(Exception e){Toast.makeText(ChannelListActivity.this,"Liste Hatasi",Toast.LENGTH_SHORT).show();}
        }
    }
}
EOF

# --- 8. PlayerActivity (DEEP RESOLVER & UNIVERSAL PLAYER) ---
cat > "$TARGET_DIR/PlayerActivity.java" <<EOF
package com.base.app;
import android.app.Activity;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.WindowManager;
import android.widget.Toast;
import androidx.media3.common.MediaItem;
import androidx.media3.common.MimeTypes;
import androidx.media3.common.PlaybackException;
import androidx.media3.common.Player;
import androidx.media3.datasource.DefaultHttpDataSource;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory;
import androidx.media3.ui.PlayerView;
import org.json.JSONObject;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
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
        
        if(videoUrl != null && !videoUrl.isEmpty()) {
            Toast.makeText(this, "Bağlanılıyor...", Toast.LENGTH_SHORT).show();
            new ResolveUrlTask().execute(videoUrl.trim());
        }
    }

    // URL Bilgisi Tutan Sınıf
    class UrlInfo {
        String url;
        String mimeType;
        UrlInfo(String u, String m) { url = u; mimeType = m; }
    }

    // Arkaplan URL Çözücü
    private class ResolveUrlTask extends AsyncTask<String, Void, UrlInfo> {
        @Override
        protected UrlInfo doInBackground(String... params) {
            String currentUrl = params[0];
            String detectedMime = null;
            
            try {
                // Sadece HTTP/HTTPS ise işlem yap
                if (!currentUrl.startsWith("http")) return new UrlInfo(currentUrl, null);

                // Yönlendirmeleri takip et (Max 5)
                for (int i = 0; i < 5; i++) {
                    URL url = new URL(currentUrl);
                    HttpURLConnection con = (HttpURLConnection) url.openConnection();
                    con.setInstanceFollowRedirects(false); // Manuel takip
                    con.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
                    con.setConnectTimeout(8000);
                    con.connect();

                    int code = con.getResponseCode();
                    if (code >= 300 && code < 400) {
                        String next = con.getHeaderField("Location");
                        if (next != null) {
                            currentUrl = next; // Yeni URL'ye geç
                            continue;
                        }
                    }
                    
                    // Son durağa geldik, MIME type alalım
                    detectedMime = con.getContentType();
                    con.disconnect();
                    break;
                }
            } catch (Exception e) {
                // Hata olursa orijinal URL ile devam et
            }
            return new UrlInfo(currentUrl, detectedMime);
        }

        @Override
        protected void onPostExecute(UrlInfo info) {
            initializePlayer(info);
        }
    }

    private void initializePlayer(UrlInfo info) {
        String userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36";
        Map<String, String> requestProps = new HashMap<>();
        
        if(headersJson != null && !headersJson.isEmpty()){
            try{
                JSONObject h = new JSONObject(headersJson);
                Iterator<String> k = h.keys();
                while(k.hasNext()){
                    String key = k.next();
                    String val = h.getString(key);
                    if(key.equalsIgnoreCase("User-Agent")) userAgent = val;
                    else requestProps.put(key, val);
                }
            }catch(Exception e){}
        }

        DefaultHttpDataSource.Factory httpFactory = new DefaultHttpDataSource.Factory()
                .setUserAgent(userAgent)
                .setAllowCrossProtocolRedirects(true)
                .setDefaultRequestProperties(requestProps);
                
        DefaultMediaSourceFactory mediaFactory = new DefaultMediaSourceFactory(this)
                .setDataSourceFactory(httpFactory);

        player = new ExoPlayer.Builder(this)
                .setMediaSourceFactory(mediaFactory)
                .build();
        
        playerView.setPlayer(player);
        
        try {
            MediaItem.Builder item = new MediaItem.Builder().setUri(Uri.parse(info.url));
            
            // Eğer MIME Type belliyse ve uzantı yoksa, ExoPlayer'a ipucu ver
            if (info.mimeType != null) {
                if (info.mimeType.contains("mpegurl") || info.mimeType.contains("hls")) {
                    item.setMimeType(MimeTypes.APPLICATION_M3U8);
                } else if (info.mimeType.contains("dash")) {
                    item.setMimeType(MimeTypes.APPLICATION_MPD);
                } else if (info.mimeType.contains("video/mp4")) {
                    item.setMimeType(MimeTypes.APPLICATION_MP4);
                }
            }
            
            player.setMediaItem(item.build());
            player.prepare();
            player.setPlayWhenReady(true);
        } catch(Exception e){ 
            Toast.makeText(this, "Hata: " + e.getMessage(), Toast.LENGTH_LONG).show(); 
        }
        
        player.addListener(new Player.Listener(){ 
            public void onPlayerError(PlaybackException e){ 
                String err = "Hata oluştu";
                if(e.errorCode == PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_FAILED) err = "Bağlantı Hatası";
                else if(e.errorCode == PlaybackException.ERROR_CODE_PARSING_CONTAINER_MALFORMED) err = "Format Desteklenmiyor";
                Toast.makeText(PlayerActivity.this, err, Toast.LENGTH_LONG).show(); 
            } 
        });
    }

    protected void onStop(){ super.onStop(); if(player!=null){player.release(); player=null;} }
}
EOF

# --- 9. WebView ---
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

echo "✅ ULTRA APP V19 - FULL & FINAL"
