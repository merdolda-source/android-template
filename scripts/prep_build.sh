#!/bin/bash
set -e
# ULTRA APP V50 - CONVERT (IMAGE MAGIC) EDITION
PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3
ICON_URL=$4
VERSION_CODE=$5
VERSION_NAME=$6

echo "=========================================="
echo "   ULTRA APP V50 - CONVERT FIX"
echo "=========================================="

# --- 1. TEMİZLİK ---
rm -rf app/src/main/res/drawable*
rm -rf app/src/main/res/mipmap*
rm -rf app/src/main/java/com/base/app/*
TARGET_DIR="app/src/main/java/com/base/app"
mkdir -p "$TARGET_DIR"

# --- 2. ICON İŞLEME (ESKİ USÜL SAĞLAM YÖNTEM) ---
mkdir -p app/src/main/res/mipmap-xxxhdpi
ICON_TARGET="app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
TEMP_ICON="temp_icon_raw"

echo "1. İkon indiriliyor: $ICON_URL"

# wget ile tarayıcı taklidi yaparak indir (curl yerine wget bazen daha iyidir)
wget --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -O "$TEMP_ICON" "$ICON_URL" || echo "İndirme uyarısı."

echo "2. İkon 'convert' ile işleniyor..."

# İŞTE SENİN HATIRLADIĞIN SİHİRLİ KOMUT:
# Bu komut dosyayı alır, ne olursa olsun temiz bir 512x512 PNG'ye çevirir.
# Header hatalarını, bozuk verileri temizler.
if command -v convert >/dev/null 2>&1; then
    convert "$TEMP_ICON" -resize 512x512! -background none -flatten "$ICON_TARGET" || echo "Convert başarısız, orijinali deniyoruz."
else
    # Eğer convert yoksa (ki github'da vardır), direkt taşı
    mv "$TEMP_ICON" "$ICON_TARGET"
fi

# Son kontrol: Eğer convert başarısız olduysa ve dosya boşsa varsayılanı koy (Çökmesin diye)
if [ ! -s "$ICON_TARGET" ]; then
    echo "⚠️ İkon oluşturulamadı! Varsayılan kullanılıyor."
    wget -O "$ICON_TARGET" "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Android_new_logo_2019.svg/512px-Android_new_logo_2019.svg.png"
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
    implementation 'androidx.media3:media3-ui:1.2.0'
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
        <activity android:name=".PlayerActivity" 
            android:configChanges="orientation|screenSize|keyboardHidden|smallestScreenSize|screenLayout" 
            android:screenOrientation="sensor"
            android:theme="@android:style/Theme.Black.NoTitleBar.Fullscreen" />
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
    public static int GLOBAL_CLICK_COUNT = 0; 
    private static int INTER_FREQ = 3;
    private static boolean ENABLED = false, BANNER_ACTIVE = false;
    private static String GAME_ID="", BANNER_ID="", INTER_ID="";

    public static void init(Activity a, JSONObject j){
        try{
            if(j==null)return;
            ENABLED=j.optBoolean("enabled",false); 
            GAME_ID=j.optString("game_id");
            BANNER_ACTIVE=j.optBoolean("banner_active"); 
            BANNER_ID=j.optString("banner_id");
            INTER_ID=j.optString("inter_id"); 
            INTER_FREQ=j.optInt("inter_freq", 3);
            if(ENABLED && !GAME_ID.isEmpty()) UnityAds.initialize(a.getApplicationContext(), GAME_ID, false, null);
        }catch(Exception e){}
    }

    public static void showBanner(Activity a, ViewGroup c){
        if(!ENABLED || !BANNER_ACTIVE)return;
        BannerView b = new BannerView(a, BANNER_ID, new UnityBannerSize(320, 50));
        b.load();
        c.removeAllViews(); c.addView(b);
    }

    public static void checkInterstitial(Activity a, Runnable onComplete) {
        if(!ENABLED) { onComplete.run(); return; }
        GLOBAL_CLICK_COUNT++;
        if(GLOBAL_CLICK_COUNT >= INTER_FREQ) {
            if(UnityAds.isReady(INTER_ID)) {
                UnityAds.show(a, INTER_ID, new IUnityAdsShowListener(){
                    public void onUnityAdsShowComplete(String p, UnityAds.UnityAdsShowCompletionState s){ 
                        GLOBAL_CLICK_COUNT = 0; 
                        onComplete.run(); 
                    }
                    public void onUnityAdsShowFailure(String p, UnityAds.UnityAdsShowError e, String m){ onComplete.run(); }
                    public void onUnityAdsShowStart(String p){}
                    public void onUnityAdsShowClick(String p){}
                });
            } else { onComplete.run(); }
        } else {
            onComplete.run();
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
import com.bumptech.glide.Glide;

public class MainActivity extends Activity {
    private String CONFIG_URL = "$CONFIG_URL"; 
    private RelativeLayout root;
    private LinearLayout contentContainer, bannerContainer, headerLayout;
    private TextView titleText;
    private ImageView splashImage;
    private ProgressBar loadingSpinner;
    private ImageView refreshBtn, shareBtn;
    
    private String headerColor = "#2196F3", textColor = "#FFFFFF", bgColor = "#F0F0F0", focusColor = "#FF9800";
    private boolean showHeader = true;
    private String appName = "$APP_NAME";
    private int fontSize = 16;
    private int fontStyle = Typeface.BOLD;
    private String playerConfigStr = "";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        root = new RelativeLayout(this);
        root.setBackgroundColor(Color.WHITE);

        splashImage = new ImageView(this);
        splashImage.setScaleType(ImageView.ScaleType.CENTER_CROP);
        splashImage.setVisibility(View.GONE); 
        root.addView(splashImage, new RelativeLayout.LayoutParams(-1, -1));

        loadingSpinner = new ProgressBar(this);
        RelativeLayout.LayoutParams lp = new RelativeLayout.LayoutParams(-2, -2);
        lp.addRule(RelativeLayout.CENTER_IN_PARENT);
        root.addView(loadingSpinner, lp);

        headerLayout = new LinearLayout(this);
        headerLayout.setId(View.generateViewId());
        headerLayout.setOrientation(LinearLayout.HORIZONTAL);
        headerLayout.setGravity(Gravity.CENTER_VERTICAL);
        headerLayout.setPadding(30, 30, 30, 30);
        headerLayout.setElevation(10f);
        headerLayout.setVisibility(View.GONE);
        
        titleText = new TextView(this);
        titleText.setText(appName);
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
        bannerContainer.setVisibility(View.GONE);
        RelativeLayout.LayoutParams bp = new RelativeLayout.LayoutParams(-1, -2);
        bp.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
        root.addView(bannerContainer, bp);

        ScrollView sv = new ScrollView(this);
        contentContainer = new LinearLayout(this);
        contentContainer.setOrientation(LinearLayout.VERTICAL);
        contentContainer.setPadding(30, 30, 30, 150); 
        sv.addView(contentContainer);
        sv.setVisibility(View.GONE);
        
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

    private void createStyledButton(String text, final String type, final String link, final String content) {
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
        btn.setOnClickListener(v -> AdsManager.checkInterstitial(MainActivity.this, () -> openContent(type, link, content))); 
        contentContainer.addView(btn);
    }

    private void openContent(String type, String link, String content) {
        if (type.equals("WEB")) { 
            Intent i = new Intent(MainActivity.this, WebViewActivity.class); 
            i.putExtra("WEB_URL", link); 
            i.putExtra("HTML_DATA", "");
            startActivity(i); 
        }
        else if (type.equals("HTML")) {
            Intent i = new Intent(MainActivity.this, WebViewActivity.class);
            i.putExtra("HTML_DATA", content); 
            startActivity(i);
        }
        else if (type.equals("IPTV") || type.equals("JSON_LIST") || type.equals("MANUAL_M3U")) {
            Intent i = new Intent(MainActivity.this, ChannelListActivity.class);
            i.putExtra("LIST_URL", link); 
            i.putExtra("LIST_CONTENT", content);
            i.putExtra("TYPE", type);
            i.putExtra("BG_COLOR", bgColor); i.putExtra("HEADER_COLOR", headerColor); 
            i.putExtra("TEXT_COLOR", textColor); i.putExtra("FOCUS_COLOR", focusColor);
            i.putExtra("PLAYER_CONFIG", playerConfigStr);
            startActivity(i);
        } 
        else if (type.equals("SINGLE_STREAM")) {
            Intent i = new Intent(MainActivity.this, PlayerActivity.class);
            i.putExtra("VIDEO_URL", link);
            i.putExtra("PLAYER_CONFIG", playerConfigStr);
            startActivity(i);
        }
        else { 
            try { startActivity(new Intent(Intent.ACTION_VIEW, android.net.Uri.parse(link))); } catch(Exception e){} 
        }
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
            try {
                JSONObject json = new JSONObject(result);
                appName = json.optString("app_name", "App");
                playerConfigStr = json.optString("player_config", "{}"); 
                
                JSONObject ui = json.optJSONObject("ui_config");
                if(ui != null) {
                    headerColor = ui.optString("header_color", "#2196F3");
                    textColor = ui.optString("text_color", "#FFFFFF");
                    bgColor = ui.optString("bg_color", "#F0F0F0");
                    focusColor = ui.optString("focus_color", "#FF9800");
                    showHeader = ui.optBoolean("show_header", true);
                    fontSize = ui.optInt("font_size", 16);
                    String fStyle = ui.optString("font_style", "BOLD");
                    if(fStyle.equals("NORMAL")) fontStyle = Typeface.NORMAL; else if(fStyle.equals("ITALIC")) fontStyle = Typeface.ITALIC; else fontStyle = Typeface.BOLD;

                    String splashUrl = ui.optString("splash_image", "");
                    if(!splashUrl.isEmpty()) {
                        if(!splashUrl.startsWith("http")) splashUrl = CONFIG_URL.substring(0, CONFIG_URL.lastIndexOf("/") + 1) + splashUrl;
                        splashImage.setVisibility(View.VISIBLE);
                        loadingSpinner.setVisibility(View.GONE);
                        Glide.with(MainActivity.this).load(splashUrl).into(splashImage);
                        new android.os.Handler().postDelayed(() -> {
                            splashImage.setVisibility(View.GONE);
                            finishSetup(json, ui);
                        }, 3000);
                    } else { finishSetup(json, ui); }
                } else { finishSetup(json, ui); }
            } catch(Exception e){}
        }

        private void finishSetup(JSONObject json, JSONObject ui) {
            try {
                loadingSpinner.setVisibility(View.GONE);
                ((ScrollView)contentContainer.getParent()).setVisibility(View.VISIBLE);
                bannerContainer.setVisibility(View.VISIBLE);
                if (showHeader) headerLayout.setVisibility(View.VISIBLE);
                
                root.setBackgroundColor(Color.parseColor(bgColor));
                headerLayout.setBackgroundColor(Color.parseColor(headerColor));
                titleText.setText(appName);
                titleText.setTextColor(Color.parseColor(textColor));
                titleText.setTextSize(20);
                titleText.setTypeface(null, fontStyle);
                refreshBtn.setColorFilter(Color.parseColor(textColor));
                shareBtn.setColorFilter(Color.parseColor(textColor));

                contentContainer.removeAllViews();
                JSONArray mods = json.getJSONArray("modules");
                for(int i=0; i<mods.length(); i++){
                    JSONObject m = mods.getJSONObject(i);
                    createStyledButton(m.getString("title"), m.getString("type"), m.optString("url"), m.optString("content"));
                }
                
                JSONObject adsConfig = json.optJSONObject("ads_config");
                if (adsConfig != null) { 
                    AdsManager.init(MainActivity.this, adsConfig); 
                    AdsManager.showBanner(MainActivity.this, bannerContainer); 
                }
            } catch (Exception e) {}
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
    private String headerColor, textColor, bgColor, focusColor, playerConfig;
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
        playerConfig = getIntent().getStringExtra("PLAYER_CONFIG");

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
        String listContent = getIntent().getStringExtra("LIST_CONTENT"); 
        String type = getIntent().getStringExtra("TYPE");
        
        new FetchListTask(type, listContent).execute(listUrl);
        
        listView.setOnItemClickListener((p,v,pos,id)->{
            if (isShowingGroups) {
                showChannels(groupNames.get(pos));
            } else {
                ChannelItem item = currentList.get(pos);
                AdsManager.checkInterstitial(ChannelListActivity.this, () -> {
                    Intent i = new Intent(ChannelListActivity.this, PlayerActivity.class);
                    i.putExtra("VIDEO_URL", item.url);
                    i.putExtra("HEADERS_JSON", item.headers);
                    i.putExtra("PLAYER_CONFIG", playerConfig);
                    startActivity(i);
                });
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
        public View getView(int p, View v, ViewGroup pa) { return createRow(v, getItem(p), null, true); }
    }
    private class ChannelAdapter extends ArrayAdapter<ChannelItem> {
        public ChannelAdapter(List<ChannelItem> items) { super(ChannelListActivity.this, 0, items); }
        public View getView(int p, View v, ViewGroup pa) { ChannelItem i=getItem(p); return createRow(v, i.name, i.image, false); }
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
        GradientDrawable normal = new GradientDrawable(); normal.setColor(Color.WHITE); normal.setCornerRadius(15); normal.setStroke(1, Color.LTGRAY);
        GradientDrawable focused = new GradientDrawable(); focused.setColor(Color.parseColor(focusColor)); focused.setCornerRadius(15); focused.setStroke(3, Color.parseColor(headerColor));
        StateListDrawable bg = new StateListDrawable();
        bg.addState(new int[]{android.R.attr.state_pressed}, focused);
        bg.addState(new int[]{}, normal);
        convertView.setBackground(bg);
        return convertView;
    }

    private class FetchListTask extends AsyncTask<String,Void,String>{
        String type, manualContent; 
        FetchListTask(String t, String mc){type=t; manualContent=mc;}
        
        protected String doInBackground(String... u){
            if("MANUAL_M3U".equals(type) && manualContent != null && !manualContent.isEmpty()) {
                return manualContent;
            }
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
                        for(int i=0;i<arr.length();i++){
                            JSONObject o=arr.getJSONObject(i);
                            String url=o.optString("media_url",o.optString("url",""));
                            if(url.isEmpty())continue;
                            String title = o.optString("title");
                            String image = o.optString("thumb_square", o.optString("image", ""));
                            String group = o.optString("group", "Genel");
                            if(!groupedChannels.containsKey(group)) { groupedChannels.put(group, new ArrayList<>()); groupNames.add(group); }
                            groupedChannels.get(group).add(new ChannelItem(title, url, image, "{}"));
                        }
                    } catch(Exception e){}
                } 
                if(groupedChannels.isEmpty()) {
                    String[] lines = r.split("\n");
                    String currentTitle="Kanal", currentImage="", currentGroup="Genel";
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
                        } else if(!line.startsWith("#")) {
                            if(!groupedChannels.containsKey(currentGroup)) { groupedChannels.put(currentGroup, new ArrayList<>()); groupNames.add(currentGroup); }
                            groupedChannels.get(currentGroup).add(new ChannelItem(currentTitle, line, currentImage, "{}"));
                            currentTitle="Kanal"; currentImage="";
                        }
                    }
                }
                if (groupNames.size() > 1) showGroups(); 
                else if (groupNames.size() == 1) showChannels(groupNames.get(0));
                else Toast.makeText(ChannelListActivity.this,"Kanal Bulunamadı",Toast.LENGTH_SHORT).show();
            }catch(Exception e){Toast.makeText(ChannelListActivity.this,"Liste Hatası",Toast.LENGTH_SHORT).show();}
        }
    }
}
EOF

# --- 8. PlayerActivity (PLAYER OVERLAY + DEEP RESOLVER) ---
cat > "$TARGET_DIR/PlayerActivity.java" <<EOF
package com.base.app;
import android.app.Activity;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.View;
import android.view.ViewGroup;
import android.view.Gravity;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.TextView;
import android.widget.Toast;
import android.graphics.Color;
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
        
        FrameLayout root = new FrameLayout(this);
        playerView = new PlayerView(this);
        playerView.setShowNextButton(false);
        playerView.setShowPreviousButton(false);
        root.addView(playerView);

        String configStr = getIntent().getStringExtra("PLAYER_CONFIG");
        if(configStr != null) {
            try {
                JSONObject cfg = new JSONObject(configStr);
                if(cfg.optBoolean("enable_overlay", false)) {
                    TextView overlay = new TextView(this);
                    overlay.setText(cfg.optString("watermark_text", ""));
                    overlay.setTextColor(Color.parseColor(cfg.optString("watermark_color", "#FFFFFF")));
                    overlay.setTextSize(18);
                    overlay.setPadding(30, 30, 30, 30);
                    overlay.setBackgroundColor(Color.parseColor("#80000000"));
                    FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(-2, -2);
                    String pos = cfg.optString("watermark_pos", "left");
                    params.gravity = (pos.equals("right") ? Gravity.TOP | Gravity.END : Gravity.TOP | Gravity.START);
                    params.setMargins(20, 20, 20, 20);
                    root.addView(overlay, params);
                }
            } catch(Exception e) {}
        }

        setContentView(root);
        videoUrl = getIntent().getStringExtra("VIDEO_URL");
        headersJson = getIntent().getStringExtra("HEADERS_JSON");
        
        if(videoUrl != null && !videoUrl.isEmpty()) {
            new ResolveUrlTask().execute(videoUrl.trim());
        }
    }

    class UrlInfo { String url; String mimeType; UrlInfo(String u, String m) { url = u; mimeType = m; } }

    private class ResolveUrlTask extends AsyncTask<String, Void, UrlInfo> {
        protected UrlInfo doInBackground(String... params) {
            String currentUrl = params[0];
            String detectedMime = null;
            try {
                if (!currentUrl.startsWith("http")) return new UrlInfo(currentUrl, null);
                for (int i = 0; i < 5; i++) {
                    URL url = new URL(currentUrl);
                    HttpURLConnection con = (HttpURLConnection) url.openConnection();
                    con.setInstanceFollowRedirects(false);
                    con.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
                    con.setConnectTimeout(8000);
                    con.connect();
                    int code = con.getResponseCode();
                    if (code >= 300 && code < 400) {
                        String next = con.getHeaderField("Location");
                        if (next != null) { currentUrl = next; continue; }
                    }
                    detectedMime = con.getContentType();
                    con.disconnect();
                    break;
                }
            } catch (Exception e) {}
            return new UrlInfo(currentUrl, detectedMime);
        }
        protected void onPostExecute(UrlInfo info) { initializePlayer(info); }
    }

    private void initializePlayer(UrlInfo info) {
        if (player != null) return;
        String userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)";
        Map<String, String> requestProps = new HashMap<>();
        if(headersJson != null){ try{ JSONObject h=new JSONObject(headersJson); Iterator<String> k=h.keys(); while(k.hasNext()){ String key=k.next(); requestProps.put(key, h.getString(key)); } }catch(Exception e){} }

        DefaultHttpDataSource.Factory httpFactory = new DefaultHttpDataSource.Factory().setUserAgent(userAgent).setAllowCrossProtocolRedirects(true).setDefaultRequestProperties(requestProps);
        player = new ExoPlayer.Builder(this).setMediaSourceFactory(new DefaultMediaSourceFactory(this).setDataSourceFactory(httpFactory)).build();
        playerView.setPlayer(player);
        
        try {
            MediaItem.Builder item = new MediaItem.Builder().setUri(Uri.parse(info.url));
            if (info.mimeType != null) {
                if (info.mimeType.contains("mpegurl")) item.setMimeType(MimeTypes.APPLICATION_M3U8);
                else if (info.mimeType.contains("dash")) item.setMimeType(MimeTypes.APPLICATION_MPD);
            }
            player.setMediaItem(item.build());
            player.prepare();
            player.setPlayWhenReady(true);
        } catch(Exception e){ Toast.makeText(this, "Hata", Toast.LENGTH_LONG).show(); }
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
import android.util.Base64;
public class WebViewActivity extends Activity {
    protected void onCreate(Bundle s) {
        super.onCreate(s); WebView w=new WebView(this); setContentView(w);
        String u=getIntent().getStringExtra("WEB_URL");
        String html=getIntent().getStringExtra("HTML_DATA");
        w.getSettings().setJavaScriptEnabled(true); w.getSettings().setDomStorageEnabled(true);
        w.setWebViewClient(new WebViewClient()); 
        
        if (html != null && !html.isEmpty()) {
            w.loadData(Base64.encodeToString(html.getBytes(), Base64.NO_PADDING), "text/html", "base64");
        } else {
            w.loadUrl(u);
        }
    }
}
EOF

echo "✅ ULTRA APP V50 - CONVERT PRO EDITION"
