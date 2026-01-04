#!/bin/bash
set -e
# ULTRA APP V120 - ANDROID TV & MOBILE HYBRID SYSTEM
# 1. Hybrid UI (Mobile + TV Remote Support)
# 2. Flat JSON Parser (No Categories)
# 3. Smart Header Injection (Referer/Origin/User-Agent)
# 4. Extensionless Stream Optimizer
# 5. Zero-Buffer Config

PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3
ICON_URL=$4
VERSION_CODE=$5
VERSION_NAME=$6

echo "=========================================="
echo "   ULTRA APP V120 - TV/MOBILE DEPLOY"
echo "=========================================="

# 1. PREPARE ENVIRONMENT
sudo apt-get update >/dev/null 2>&1
sudo apt-get install -y imagemagick >/dev/null 2>&1 || true

rm -rf app/src/main/res/drawable* app/src/main/res/mipmap* app/src/main/java/com/base/app/*
TARGET_DIR="app/src/main/java/com/base/app"
mkdir -p "$TARGET_DIR" app/src/main/res/mipmap-xxxhdpi

# 2. ICON PROCESSING
ICON_TARGET="app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
TEMP="dl_icon"
curl -s -L -k -A "Mozilla/5.0" -o "$TEMP" "$ICON_URL" || true
if [ -s "$TEMP" ]; then convert "$TEMP" -resize 512x512! -background none -flatten "$ICON_TARGET" || cp "$TEMP" "$ICON_TARGET"; else curl -s -L -k -o "$ICON_TARGET" "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Android_new_logo_2019.svg/512px-Android_new_logo_2019.svg.png"; fi

# Banner for TV (Reuse icon if no banner provided, resized)
convert "$ICON_TARGET" -resize 320x180! -background none -gravity center -extent 320x180 app/src/main/res/drawable/banner.png || cp "$ICON_TARGET" app/src/main/res/drawable/banner.png

# 3. SETTINGS.GRADLE
cat > settings.gradle <<EOF
pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement { repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS); repositories { google(); mavenCentral(); maven { url 'https://jitpack.io' } } }
rootProject.name = "UltraTVApp"
include ':app'
EOF

# 4. APP GRADLE
cat > app/build.gradle <<EOF
plugins { id 'com.android.application' }
android {
    namespace 'com.base.app'
    compileSdkVersion 34
    defaultConfig { 
        applicationId "$PACKAGE_NAME"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode $VERSION_CODE
        versionName "$VERSION_NAME"
    }
    buildTypes { 
        release { 
            signingConfig signingConfigs.debug
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro' 
        } 
    }
    compileOptions { sourceCompatibility 1.8; targetCompatibility 1.8; }
}
dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.leanback:leanback:1.0.0'
    implementation 'androidx.media3:media3-exoplayer:1.2.0'
    implementation 'androidx.media3:media3-exoplayer-hls:1.2.0'
    implementation 'androidx.media3:media3-exoplayer-dash:1.2.0'
    implementation 'androidx.media3:media3-ui:1.2.0'
    implementation 'androidx.media3:media3-datasource-okhttp:1.2.0'
    implementation 'com.unity3d.ads:unity-ads:4.9.2'
    implementation 'com.github.bumptech.glide:glide:4.16.0'
}
EOF

# 5. MANIFEST (TV SUPPORT ADDED)
cat > app/src/main/AndroidManifest.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-feature android:name="android.software.leanback" android:required="false" />
    <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
    
    <application 
        android:allowBackup="true" 
        android:label="$APP_NAME" 
        android:icon="@mipmap/ic_launcher" 
        android:banner="@drawable/banner"
        android:usesCleartextTraffic="true" 
        android:theme="@android:style/Theme.DeviceDefault.NoActionBar">
        
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
            android:theme="@android:style/Theme.Black.NoTitleBar.Fullscreen" 
            android:launchMode="singleTask" />
    </application>
</manifest>
EOF

# 6. ADS MANAGER
cat > "$TARGET_DIR/AdsManager.java" <<EOF
package com.base.app; import android.app.Activity; import android.view.ViewGroup; import com.unity3d.ads.*; import com.unity3d.services.banners.*; import org.json.JSONObject;
public class AdsManager {
    public static int G=0; private static int F=3; private static boolean EN=false, B=false; private static String GID="", BID="", IID="";
    public static void init(Activity a, JSONObject j){ try{ if(j==null)return; EN=j.optBoolean("enabled"); GID=j.optString("game_id"); B=j.optBoolean("banner_active"); BID=j.optString("banner_id"); IID=j.optString("inter_id"); F=j.optInt("inter_freq",3); if(EN && !GID.isEmpty()) UnityAds.initialize(a.getApplicationContext(), GID, false, null); }catch(Exception e){} }
    public static void showBanner(Activity a, ViewGroup c){ if(!EN || !B)return; BannerView b=new BannerView(a, BID, new UnityBannerSize(320,50)); b.load(); c.removeAllViews(); c.addView(b); }
    public static void checkInter(Activity a, Runnable r){ if(!EN){r.run();return;} G++; if(G>=F){ UnityAds.load(IID, new IUnityAdsLoadListener(){ public void onUnityAdsAdLoaded(String p){ UnityAds.show(a, p, new IUnityAdsShowListener(){ public void onUnityAdsShowComplete(String p, UnityAds.UnityAdsShowCompletionState s){G=0;r.run();} public void onUnityAdsShowFailure(String p, UnityAds.UnityAdsShowError e, String m){r.run();} public void onUnityAdsShowStart(String p){} public void onUnityAdsShowClick(String p){} }); } public void onUnityAdsFailedToLoad(String p, UnityAds.UnityAdsLoadError e, String m){r.run();} }); }else{r.run();} }
}
EOF

# 7. MAIN ACTIVITY (TV DESIGN & FOCUS)
cat > "$TARGET_DIR/MainActivity.java" <<EOF
package com.base.app;
import android.app.Activity; import android.content.Intent; import android.os.AsyncTask; import android.os.Bundle; import android.view.*; import android.widget.*; import android.graphics.*; import android.graphics.drawable.*; import org.json.*; import java.io.*; import java.net.*; import com.bumptech.glide.Glide;

public class MainActivity extends Activity {
    private String CONFIG_URL = "$CONFIG_URL"; 
    private LinearLayout container;
    private String hColor="#1A1A1A", tColor="#FFFFFF", bColor="#101010", fColor="#FFD700";
    private TextView titleTxt; private ImageView splash; private LinearLayout headerLayout, currentRow;
    private String playerConfigStr="";

    protected void onCreate(Bundle s) {
        super.onCreate(s); 
        RelativeLayout root = new RelativeLayout(this); root.setBackgroundColor(Color.parseColor(bColor));
        
        splash = new ImageView(this); splash.setScaleType(ImageView.ScaleType.CENTER_CROP); 
        root.addView(splash, new RelativeLayout.LayoutParams(-1,-1));
        
        headerLayout = new LinearLayout(this); headerLayout.setId(View.generateViewId()); 
        headerLayout.setPadding(40,40,40,40); headerLayout.setGravity(Gravity.CENTER_VERTICAL); headerLayout.setElevation(10f);
        
        titleTxt = new TextView(this); titleTxt.setTextSize(24); titleTxt.setTypeface(null, Typeface.BOLD); 
        headerLayout.addView(titleTxt, new LinearLayout.LayoutParams(0, -2, 1.0f));
        
        ImageView rf = new ImageView(this); rf.setImageResource(android.R.drawable.ic_popup_sync); rf.setColorFilter(Color.WHITE);
        rf.setOnClickListener(v->new Fetch().execute(CONFIG_URL)); rf.setFocusable(true); setFocusBg(rf, false);
        headerLayout.addView(rf, new LinearLayout.LayoutParams(60,60));
        
        RelativeLayout.LayoutParams hp = new RelativeLayout.LayoutParams(-1,-2); hp.addRule(RelativeLayout.ALIGN_PARENT_TOP); root.addView(headerLayout, hp);
        
        ScrollView sv = new ScrollView(this); sv.setSmoothScrollingEnabled(true);
        container = new LinearLayout(this); container.setOrientation(LinearLayout.VERTICAL); container.setPadding(50,20,50,100); 
        sv.addView(container);
        
        RelativeLayout.LayoutParams sp = new RelativeLayout.LayoutParams(-1,-1); sp.addRule(RelativeLayout.BELOW, headerLayout.getId()); 
        root.addView(sv, sp);
        setContentView(root); 
        new Fetch().execute(CONFIG_URL);
    }

    private void addBtn(String txt, String type, String url, String cont, String ua, String ref, String org) {
        JSONObject h = new JSONObject(); try { 
            if(!ua.isEmpty()) h.put("User-Agent", ua); 
            if(!ref.isEmpty()) h.put("Referer", ref); 
            if(!org.isEmpty()) h.put("Origin", org); 
        } catch(Exception e){}
        String hStr = h.toString();

        Button b = new Button(this); 
        b.setText(txt); b.setTextSize(18); b.setTextColor(Color.parseColor(tColor)); 
        b.setPadding(40,40,40,40); b.setAllCaps(false);
        setFocusBg(b, true);

        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, -2); 
        p.setMargins(0,0,0,25); b.setLayoutParams(p);
        
        b.setOnClickListener(x->AdsManager.checkInter(this,()->open(type,url,cont,hStr)));
        container.addView(b);
    }

    private void setFocusBg(View v, boolean isBtn) {
        v.setFocusable(true); v.setClickable(true);
        GradientDrawable def = new GradientDrawable(); 
        if(isBtn) def.setColor(Color.parseColor("#2A2A2A")); else def.setColor(Color.TRANSPARENT);
        def.setCornerRadius(12);
        
        GradientDrawable foc = new GradientDrawable(); 
        foc.setColor(Color.parseColor(fColor)); foc.setCornerRadius(12); foc.setStroke(4, Color.WHITE);
        
        StateListDrawable sld = new StateListDrawable(); 
        sld.addState(new int[]{android.R.attr.state_focused}, foc); 
        sld.addState(new int[]{android.R.attr.state_pressed}, foc); 
        sld.addState(new int[]{}, def);
        v.setBackground(sld);
    }

    private void open(String t, String u, String c, String h) {
        if(t.equals("WEB") || t.equals("HTML")) { Intent i=new Intent(this,WebViewActivity.class); i.putExtra("WEB_URL",u); i.putExtra("HTML_DATA",c); startActivity(i); }
        else if(t.equals("SINGLE_STREAM")) { Intent i=new Intent(this,PlayerActivity.class); i.putExtra("VIDEO_URL",u); i.putExtra("HEADERS_JSON",h); i.putExtra("PLAYER_CONFIG",playerConfigStr); startActivity(i); }
        else { 
            Intent i=new Intent(this,ChannelListActivity.class); 
            i.putExtra("LIST_URL",u); i.putExtra("LIST_CONTENT",c); i.putExtra("TYPE",t);
            i.putExtra("HEADER_COLOR",hColor); i.putExtra("BG_COLOR",bColor); i.putExtra("TEXT_COLOR",tColor); i.putExtra("FOCUS_COLOR", fColor);
            i.putExtra("PLAYER_CONFIG",playerConfigStr);
            startActivity(i);
        }
    }

    class Fetch extends AsyncTask<String,Void,String> {
        protected String doInBackground(String... u) { try{ URL url=new URL(u[0]); HttpURLConnection c=(HttpURLConnection)url.openConnection(); BufferedReader r=new BufferedReader(new InputStreamReader(c.getInputStream())); StringBuilder s=new StringBuilder(); String l; while((l=r.readLine())!=null)s.append(l); return s.toString(); }catch(Exception e){return null;} }
        protected void onPostExecute(String s) {
            if(s==null)return;
            try {
                JSONObject j=new JSONObject(s); JSONObject ui=j.optJSONObject("ui_config");
                hColor=ui.optString("header_color","#1A1A1A"); bColor=ui.optString("bg_color","#101010"); tColor=ui.optString("text_color","#FFFFFF"); fColor=ui.optString("focus_color","#FFD700");
                playerConfigStr=j.optString("player_config","{}");
                
                titleTxt.setText(j.optString("app_name")); titleTxt.setTextColor(Color.parseColor(tColor)); 
                headerLayout.setBackgroundColor(Color.parseColor(hColor)); ((View)container.getParent()).setBackgroundColor(Color.parseColor(bColor));
                
                if(!ui.optBoolean("show_header",true)) headerLayout.setVisibility(View.GONE);
                
                String spl = ui.optString("splash_image");
                if(!spl.isEmpty()){ if(!spl.startsWith("http")) spl=CONFIG_URL.substring(0,CONFIG_URL.lastIndexOf("/")+1)+spl; splash.setVisibility(View.VISIBLE); Glide.with(MainActivity.this).load(spl).into(splash); new android.os.Handler().postDelayed(()->splash.setVisibility(View.GONE),3000); }
                
                container.removeAllViews(); JSONArray m=j.getJSONArray("modules");
                for(int i=0;i<m.length();i++) { JSONObject o=m.getJSONObject(i); addBtn(o.getString("title"), o.getString("type"), o.optString("url"), o.optString("content"), o.optString("ua"), o.optString("ref"), o.optString("org")); }
                AdsManager.init(MainActivity.this, j.optJSONObject("ads_config"));
            }catch(Exception e){}
        }
    }
}
EOF

# 8. CHANNEL LIST (FLAT JSON PARSER + M3U SUPPORT)
cat > "$TARGET_DIR/ChannelListActivity.java" <<EOF
package com.base.app;
import android.app.Activity; import android.content.Intent; import android.os.AsyncTask; import android.os.Bundle; import android.widget.*; import android.view.*; import android.graphics.drawable.*; import android.graphics.Color; import org.json.*; import java.io.*; import java.net.*; import java.util.*; import com.bumptech.glide.Glide; import com.bumptech.glide.request.RequestOptions;

public class ChannelListActivity extends Activity {
    private ListView lv;
    private List<Item> curList=new ArrayList<>();
    private String hC, bC, tC, pCfg, fC;
    private TextView title;

    class Item { String n,u,i,h; Item(String name,String url,String img,String head){n=name;u=url;i=img;h=head;} }

    protected void onCreate(Bundle s) {
        super.onCreate(s);
        hC=getIntent().getStringExtra("HEADER_COLOR"); bC=getIntent().getStringExtra("BG_COLOR"); tC=getIntent().getStringExtra("TEXT_COLOR"); pCfg=getIntent().getStringExtra("PLAYER_CONFIG"); fC=getIntent().getStringExtra("FOCUS_COLOR");
        
        LinearLayout r=new LinearLayout(this); r.setOrientation(1); r.setBackgroundColor(Color.parseColor(bC));
        LinearLayout h=new LinearLayout(this); h.setBackgroundColor(Color.parseColor(hC)); h.setPadding(30,30,30,30); h.setElevation(8f);
        title=new TextView(this); title.setText("Yükleniyor..."); title.setTextColor(Color.parseColor(tC)); title.setTextSize(20);
        h.addView(title); r.addView(h);
        
        lv=new ListView(this); lv.setDivider(null); lv.setPadding(20,20,20,20); lv.setClipToPadding(false); lv.setSelector(new ColorDrawable(Color.TRANSPARENT));
        r.addView(lv); setContentView(r);
        
        new Load(getIntent().getStringExtra("TYPE"), getIntent().getStringExtra("LIST_CONTENT")).execute(getIntent().getStringExtra("LIST_URL"));
        
        lv.setOnItemClickListener((p,v,pos,id)->{
            AdsManager.checkInter(this, ()->{
                Intent i=new Intent(this, PlayerActivity.class);
                i.putExtra("VIDEO_URL", curList.get(pos).u);
                i.putExtra("HEADERS_JSON", curList.get(pos).h);
                i.putExtra("PLAYER_CONFIG", pCfg);
                startActivity(i);
            });
        });
    }

    class Load extends AsyncTask<String,Void,String> {
        String t,c; Load(String ty,String co){t=ty;c=co;}
        protected String doInBackground(String... u) {
            if("MANUAL_M3U".equals(t) && c!=null && !c.isEmpty()) return c;
            try{ URL url=new URL(u[0]); HttpURLConnection cn=(HttpURLConnection)url.openConnection(); cn.setRequestProperty("User-Agent","Mozilla/5.0"); BufferedReader r=new BufferedReader(new InputStreamReader(cn.getInputStream())); StringBuilder s=new StringBuilder(); String l; while((l=r.readLine())!=null)s.append(l).append("\n"); return s.toString(); }catch(Exception e){return null;}
        }
        protected void onPostExecute(String r) {
            if(r==null)return;
            try {
                curList.clear();
                
                // --- NEW FLAT JSON PARSER (NO CATEGORIES) ---
                if(r.trim().startsWith("{")) {
                    JSONObject root=new JSONObject(r); 
                    JSONArray arr = null;
                    if(root.has("list")) arr = root.getJSONArray("list");
                    else if(root.has("channels")) arr = root.getJSONArray("channels");
                    
                    if(arr != null) {
                        for(int i=0;i<arr.length();i++){
                            JSONObject o=arr.getJSONObject(i);
                            String u=o.optString("url", o.optString("stream_url")); 
                            if(u.isEmpty()) continue;
                            
                            // Extract headers specifically
                            JSONObject head=new JSONObject();
                            if(o.has("ua")) head.put("User-Agent", o.getString("ua"));
                            if(o.has("ref")) head.put("Referer", o.getString("ref"));
                            if(o.has("org")) head.put("Origin", o.getString("org"));
                            
                            curList.add(new Item(o.optString("title", "Kanal "+i), u, o.optString("icon", ""), head.toString()));
                        }
                    }
                } 
                // --- M3U PARSER ---
                else {
                    String[] lines=r.split("\n"); String curT="Kanal", curI=""; JSONObject curH=new JSONObject();
                    for(String l:lines) {
                        l=l.trim(); if(l.isEmpty())continue;
                        if(l.startsWith("#EXTINF")) {
                            if(l.contains(",")) curT=l.substring(l.lastIndexOf(",")+1).trim();
                            if(l.contains("tvg-logo=\"")) { int start=l.indexOf("tvg-logo=\"")+10; int end=l.indexOf("\"",start); curI=l.substring(start,end); }
                        } else if(l.startsWith("#EXTVLCOPT:")) {
                            String opt=l.substring(11);
                            if(opt.startsWith("http-referrer=")) curH.put("Referer",opt.substring(14));
                            if(opt.startsWith("http-user-agent=")) curH.put("User-Agent",opt.substring(16));
                        } else if(!l.startsWith("#")) {
                            curList.add(new Item(curT,l,curI,curH.toString()));
                            curT="Kanal"; curI=""; curH=new JSONObject();
                        }
                    }
                }
                title.setText("Kanal Listesi (" + curList.size() + ")");
                lv.setAdapter(new Adp(curList));
            }catch(Exception e){ title.setText("Hata: " + e.getMessage()); }
        }
    }

    class Adp extends BaseAdapter {
        List<Item> d; Adp(List<Item> l){d=l;}
        public int getCount(){return d.size();} public Object getItem(int p){return d.get(p);} public long getItemId(int p){return p;}
        public View getView(int p, View v, ViewGroup gr) {
            if(v==null){
                LinearLayout l=new LinearLayout(ChannelListActivity.this); l.setOrientation(0); l.setGravity(Gravity.CENTER_VERTICAL);
                l.setPadding(20,20,20,20);
                ImageView i=new ImageView(ChannelListActivity.this); i.setId(1); l.addView(i);
                TextView t=new TextView(ChannelListActivity.this); t.setId(2); t.setTextColor(Color.parseColor(tC)); l.addView(t); v=l;
            }
            LinearLayout l = (LinearLayout)v;
            
            // TV FOCUS STYLING
            GradientDrawable norm = new GradientDrawable(); norm.setColor(Color.parseColor("#2A2A2A")); norm.setCornerRadius(10);
            GradientDrawable foc = new GradientDrawable(); foc.setColor(Color.parseColor(fC)); foc.setCornerRadius(10); foc.setStroke(3, Color.WHITE);
            StateListDrawable sld = new StateListDrawable();
            sld.addState(new int[]{android.R.attr.state_focused}, foc); sld.addState(new int[]{android.R.attr.state_pressed}, foc); sld.addState(new int[]{}, norm);
            l.setBackground(sld); 
            
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(-1,-2);
            params.setMargins(0,0,0,15); l.setLayoutParams(params);

            ImageView img=v.findViewById(1); TextView txt=v.findViewById(2);
            img.setLayoutParams(new LinearLayout.LayoutParams(100,100)); ((LinearLayout.LayoutParams)img.getLayoutParams()).setMargins(0,0,30,0);
            
            Item i=d.get(p); txt.setText(i.n); txt.setTextSize(16);
            if(!i.i.isEmpty()) Glide.with(ChannelListActivity.this).load(i.i).circleCrop().into(img); 
            else img.setImageResource(android.R.drawable.ic_menu_slideshow);
            
            return v;
        }
    }
}
EOF

# 9. PLAYER (EXTENSIONLESS OPTIMIZER + SMOOTH BUFFER)
cat > "$TARGET_DIR/PlayerActivity.java" <<EOF
package com.base.app;
import android.app.Activity;
import android.net.Uri;
import android.os.Bundle;
import android.view.*;
import android.widget.*;
import android.graphics.Color;
import androidx.media3.common.*;
import androidx.media3.datasource.DefaultHttpDataSource;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory;
import androidx.media3.ui.PlayerView;
import androidx.media3.exoplayer.DefaultLoadControl;
import androidx.media3.exoplayer.upstream.DefaultAllocator;
import org.json.JSONObject;
import java.util.*;

public class PlayerActivity extends Activity {
    private ExoPlayer player;
    private PlayerView playerView;
    private ProgressBar loadingSpinner;
    private String videoUrl, headersJson;

    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
        
        FrameLayout root = new FrameLayout(this); root.setBackgroundColor(Color.BLACK);
        playerView = new PlayerView(this); 
        playerView.setShowNextButton(false); playerView.setShowPreviousButton(false);
        playerView.setControllerShowTimeoutMs(3000); // Hide controls faster on TV
        root.addView(playerView);

        loadingSpinner = new ProgressBar(this);
        FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(-2, -2);
        lp.gravity = Gravity.CENTER;
        root.addView(loadingSpinner, lp);

        setContentView(root);
        videoUrl = getIntent().getStringExtra("VIDEO_URL");
        headersJson = getIntent().getStringExtra("HEADERS_JSON");
        
        initializePlayer();
    }

    private void initializePlayer() {
        if (player != null || videoUrl == null) return;
        
        // 1. HEADER INJECTION
        String userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)";
        Map<String, String> requestProps = new HashMap<>();
        if(headersJson != null){ 
            try{ JSONObject h=new JSONObject(headersJson); Iterator<String> k=h.keys(); 
            while(k.hasNext()){ String key=k.next(); String val = h.getString(key); 
                if(key.equalsIgnoreCase("User-Agent")) userAgent = val; 
                else requestProps.put(key, val); 
            } 
            }catch(Exception e){} 
        }

        // 2. DATA SOURCE FACTORY
        DefaultHttpDataSource.Factory httpFactory = new DefaultHttpDataSource.Factory()
            .setUserAgent(userAgent)
            .setAllowCrossProtocolRedirects(true)
            .setDefaultRequestProperties(requestProps);

        // 3. BUFFER OPTIMIZATION (FASTER STARTUP)
        DefaultLoadControl lc = new DefaultLoadControl.Builder()
            .setAllocator(new DefaultAllocator(true, 16 * 1024))
            .setBufferDurationsMs(3000, 30000, 1000, 1000) // Lower start buffer for instant play
            .build();

        player = new ExoPlayer.Builder(this)
            .setLoadControl(lc)
            .setMediaSourceFactory(new DefaultMediaSourceFactory(this).setDataSourceFactory(httpFactory))
            .build();
            
        playerView.setPlayer(player);
        player.setPlayWhenReady(true);
        
        player.addListener(new Player.Listener() {
            public void onPlaybackStateChanged(int state) { if (state == Player.STATE_BUFFERING) loadingSpinner.setVisibility(View.VISIBLE); else loadingSpinner.setVisibility(View.GONE); }
            public void onPlayerError(PlaybackException e) { Toast.makeText(PlayerActivity.this, "Error: " + e.getMessage(), Toast.LENGTH_LONG).show(); finish(); }
        });

        // 4. EXTENSIONLESS LINK HANDLING
        MediaItem.Builder item = new MediaItem.Builder().setUri(Uri.parse(videoUrl));
        
        // If no extension, try to guess or force HLS if it looks like a stream
        if(!videoUrl.contains(".")) {
            // Default to HLS for extensionless IPTV links as they are most common
             item.setMimeType(MimeTypes.APPLICATION_M3U8);
        } else if (videoUrl.endsWith(".m3u8")) {
            item.setMimeType(MimeTypes.APPLICATION_M3U8);
        } else if (videoUrl.endsWith(".mpd")) {
            item.setMimeType(MimeTypes.APPLICATION_MPD);
        }

        player.setMediaItem(item.build());
        player.prepare();
    }

    protected void onStop(){ super.onStop(); if(player!=null){player.release(); player=null;} }
    // TV Remote Back Button Handling
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK) { finish(); return true; }
        return super.onKeyDown(keyCode, event);
    }
}
EOF

# 10. WEBVIEW
cat > "$TARGET_DIR/WebViewActivity.java" <<EOF
package com.base.app; import android.app.Activity; import android.os.Bundle; import android.webkit.*; import android.util.Base64;
public class WebViewActivity extends Activity { protected void onCreate(Bundle s) { super.onCreate(s); WebView w=new WebView(this); setContentView(w); w.getSettings().setJavaScriptEnabled(true); w.getSettings().setDomStorageEnabled(true); String u=getIntent().getStringExtra("WEB_URL"); String h=getIntent().getStringExtra("HTML_DATA"); if(h!=null&&!h.isEmpty())w.loadData(Base64.encodeToString(h.getBytes(),0),"text/html","base64"); else w.loadUrl(u); } }
EOF

echo "✅ ULTRA APP V120 - TV/MOBILE HYBRID SYSTEM DEPLOYED"
