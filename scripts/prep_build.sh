#!/bin/bash
set -e
# ULTRA APP V90 - TITANIUM BUILDER (FULL FEATURES + REPAIR)
# - Icon Convert (ImageMagick)
# - List Styling (Radius, Colors, Shapes)
# - Player (Vol 27, Headers, Watermark)
# - Gradle System Repair

PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3
ICON_URL=$4
VERSION_CODE=$5
VERSION_NAME=$6

echo "=========================================="
echo "   ULTRA APP V90 - TITANIUM STARTED"
echo "=========================================="

# 0. SİSTEM
sudo apt-get update >/dev/null 2>&1
sudo apt-get install -y imagemagick >/dev/null 2>&1 || true

# 1. TEMİZLİK
rm -rf app/src/main/res/drawable* app/src/main/res/mipmap* app/src/main/java/com/base/app/*
TARGET_DIR="app/src/main/java/com/base/app"
mkdir -p "$TARGET_DIR" app/src/main/res/mipmap-xxxhdpi

# 2. İKON
ICON_TARGET="app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
TEMP="dl_icon"
curl -s -L -k -A "Mozilla/5.0" -o "$TEMP" "$ICON_URL" || true
if [ -s "$TEMP" ]; then convert "$TEMP" -resize 512x512! -background none -flatten "$ICON_TARGET" || cp "$TEMP" "$ICON_TARGET"; else curl -s -L -k -o "$ICON_TARGET" "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Android_new_logo_2019.svg/512px-Android_new_logo_2019.svg.png"; fi
if [ ! -s "$ICON_TARGET" ]; then convert -size 512x512 xc:blue "$ICON_TARGET"; fi

# 3. GRADLE SETTINGS (FIX)
cat > settings.gradle <<EOF
pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement { repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS); repositories { google(); mavenCentral(); maven { url 'https://jitpack.io' } } }
rootProject.name = "AppBuilderTemplate"
include ':app'
EOF

# 4. APP GRADLE
cat > app/build.gradle <<EOF
plugins { id 'com.android.application' }
android {
    namespace 'com.base.app'
    compileSdkVersion 34
    defaultConfig { applicationId "$PACKAGE_NAME"; minSdkVersion 24; targetSdkVersion 34; versionCode $VERSION_CODE; versionName "$VERSION_NAME" }
    buildTypes { release { signingConfig signingConfigs.debug; minifyEnabled true; proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro' } }
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

# 5. MANIFEST
cat > app/src/main/AndroidManifest.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <application android:allowBackup="true" android:label="$APP_NAME" android:icon="@mipmap/ic_launcher" android:usesCleartextTraffic="true" android:theme="@android:style/Theme.DeviceDefault.Light.NoActionBar">
        <activity android:name=".MainActivity" android:exported="true"><intent-filter><action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" /></intent-filter></activity>
        <activity android:name=".WebViewActivity" />
        <activity android:name=".ChannelListActivity" />
        <activity android:name=".PlayerActivity" android:configChanges="orientation|screenSize|keyboardHidden|smallestScreenSize|screenLayout" android:theme="@android:style/Theme.Black.NoTitleBar.Fullscreen" />
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

# 7. MAIN ACTIVITY
cat > "$TARGET_DIR/MainActivity.java" <<EOF
package com.base.app;
import android.app.Activity; import android.content.Intent; import android.os.AsyncTask; import android.os.Bundle; import android.view.*; import android.widget.*; import android.graphics.*; import org.json.*; import java.io.*; import java.net.*; import com.bumptech.glide.Glide;
public class MainActivity extends Activity {
    private String CONFIG_URL = "$CONFIG_URL"; 
    private LinearLayout container;
    private String hColor="#2196F3", tColor="#FFFFFF", bColor="#F0F0F0", fColor="#FF9800", menuType="LIST";
    // LISTE TASARIM
    private String listType="CLASSIC", listItemBg="#FFFFFF", listIconShape="SQUARE"; private int listRadius=0;
    private TextView titleTxt; private ImageView splash; private LinearLayout headerLayout, currentRow;
    private String playerConfigStr="";

    protected void onCreate(Bundle s) {
        super.onCreate(s); RelativeLayout root = new RelativeLayout(this);
        splash = new ImageView(this); splash.setScaleType(ImageView.ScaleType.CENTER_CROP); root.addView(splash, new RelativeLayout.LayoutParams(-1,-1));
        headerLayout = new LinearLayout(this); headerLayout.setId(View.generateViewId()); headerLayout.setPadding(30,30,30,30); headerLayout.setGravity(Gravity.CENTER_VERTICAL); headerLayout.setElevation(10f);
        titleTxt = new TextView(this); titleTxt.setTextSize(20); titleTxt.setTypeface(null, Typeface.BOLD); headerLayout.addView(titleTxt, new LinearLayout.LayoutParams(0, -2, 1.0f));
        ImageView rf = new ImageView(this); rf.setImageResource(android.R.drawable.ic_popup_sync); rf.setOnClickListener(v->new Fetch().execute(CONFIG_URL)); headerLayout.addView(rf);
        RelativeLayout.LayoutParams hp = new RelativeLayout.LayoutParams(-1,-2); hp.addRule(RelativeLayout.ALIGN_PARENT_TOP); root.addView(headerLayout, hp);
        ScrollView sv = new ScrollView(this); container = new LinearLayout(this); container.setOrientation(LinearLayout.VERTICAL); container.setPadding(20,20,20,100); sv.addView(container);
        RelativeLayout.LayoutParams sp = new RelativeLayout.LayoutParams(-1,-1); sp.addRule(RelativeLayout.BELOW, headerLayout.getId()); root.addView(sv, sp);
        setContentView(root); new Fetch().execute(CONFIG_URL);
    }
    private void addBtn(String txt, String type, String url, String cont) {
        View v = null;
        if(menuType.equals("GRID")) {
            if(currentRow == null || currentRow.getChildCount() >= 2) { currentRow = new LinearLayout(this); currentRow.setOrientation(0); currentRow.setWeightSum(2); container.addView(currentRow); }
            Button b = new Button(this); b.setText(txt); b.setBackgroundColor(Color.parseColor(hColor)); b.setTextColor(Color.parseColor(tColor));
            LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, 200, 1.0f); p.setMargins(10,10,10,10); b.setLayoutParams(p);
            b.setOnClickListener(x->AdsManager.checkInter(this,()->open(type,url,cont))); currentRow.addView(b); return;
        } else if(menuType.equals("CARD")) {
            TextView t = new TextView(this); t.setText(txt); t.setTextSize(24); t.setGravity(Gravity.CENTER); t.setTextColor(Color.parseColor(tColor)); t.setBackgroundColor(Color.parseColor(hColor)); t.setPadding(50,150,50,150);
            LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, -2); p.setMargins(0,0,0,30); t.setLayoutParams(p); v = t;
            v.setOnClickListener(x->AdsManager.checkInter(this,()->open(type,url,cont)));
        } else {
            Button b = new Button(this); b.setText(txt); b.setPadding(40,40,40,40); b.setTextColor(Color.parseColor(tColor)); b.setBackgroundColor(Color.parseColor(hColor));
            LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, -2); p.setMargins(0,0,0,20); b.setLayoutParams(p); v=b;
            v.setOnClickListener(x->AdsManager.checkInter(this,()->open(type,url,cont)));
        }
        if(v!=null) container.addView(v);
    }
    private void open(String t, String u, String c) {
        if(t.equals("WEB")) { Intent i=new Intent(this,WebViewActivity.class); i.putExtra("WEB_URL",u); startActivity(i); }
        else if(t.equals("SINGLE_STREAM")) { Intent i=new Intent(this,PlayerActivity.class); i.putExtra("VIDEO_URL",u); i.putExtra("PLAYER_CONFIG",playerConfigStr); startActivity(i); }
        else { 
            Intent i=new Intent(this,ChannelListActivity.class); 
            i.putExtra("LIST_URL",u); i.putExtra("LIST_CONTENT",c); i.putExtra("TYPE",t);
            i.putExtra("HEADER_COLOR",hColor); i.putExtra("BG_COLOR",bColor); i.putExtra("TEXT_COLOR",tColor);
            i.putExtra("PLAYER_CONFIG",playerConfigStr);
            i.putExtra("L_TYPE", listType); i.putExtra("L_BG", listItemBg); i.putExtra("L_RAD", listRadius); i.putExtra("L_ICON", listIconShape);
            startActivity(i);
        }
    }
    class Fetch extends AsyncTask<String,Void,String> {
        protected String doInBackground(String... u) { try{ URL url=new URL(u[0]); HttpURLConnection c=(HttpURLConnection)url.openConnection(); BufferedReader r=new BufferedReader(new InputStreamReader(c.getInputStream())); StringBuilder s=new StringBuilder(); String l; while((l=r.readLine())!=null)s.append(l); return s.toString(); }catch(Exception e){return null;} }
        protected void onPostExecute(String s) {
            if(s==null)return;
            try {
                JSONObject j=new JSONObject(s); JSONObject ui=j.optJSONObject("ui_config");
                hColor=ui.optString("header_color"); bColor=ui.optString("bg_color"); tColor=ui.optString("text_color"); fColor=ui.optString("focus_color");
                menuType=ui.optString("menu_type","LIST");
                listType=ui.optString("list_type","CLASSIC"); listItemBg=ui.optString("list_item_bg","#FFFFFF"); 
                listRadius=ui.optInt("list_item_radius",0); listIconShape=ui.optString("list_icon_shape","SQUARE");
                playerConfigStr=j.optString("player_config","{}");
                titleTxt.setText(j.optString("app_name")); titleTxt.setTextColor(Color.parseColor(tColor)); headerLayout.setBackgroundColor(Color.parseColor(hColor)); ((View)container.getParent()).setBackgroundColor(Color.parseColor(bColor));
                if(!ui.optBoolean("show_header",true)) headerLayout.setVisibility(View.GONE);
                String spl = ui.optString("splash_image");
                if(!spl.isEmpty()){ if(!spl.startsWith("http")) spl=CONFIG_URL.substring(0,CONFIG_URL.lastIndexOf("/")+1)+spl; splash.setVisibility(View.VISIBLE); Glide.with(MainActivity.this).load(spl).into(splash); new android.os.Handler().postDelayed(()->splash.setVisibility(View.GONE),3000); }
                container.removeAllViews(); JSONArray m=j.getJSONArray("modules");
                for(int i=0;i<m.length();i++) { JSONObject o=m.getJSONObject(i); addBtn(o.getString("title"), o.getString("type"), o.optString("url"), o.optString("content")); }
                AdsManager.init(MainActivity.this, j.optJSONObject("ads_config"));
            }catch(Exception e){}
        }
    }
}
EOF

# 8. CHANNEL LIST (TASARIM MOTORU ENTEGRE)
cat > "$TARGET_DIR/ChannelListActivity.java" <<EOF
package com.base.app;
import android.app.Activity; import android.content.Intent; import android.os.AsyncTask; import android.os.Bundle; import android.widget.*; import android.view.*; import android.graphics.drawable.GradientDrawable; import android.graphics.Color; import org.json.*; import java.io.*; import java.net.*; import java.util.*; import java.util.regex.*; import com.bumptech.glide.Glide; import com.bumptech.glide.request.RequestOptions;
public class ChannelListActivity extends Activity {
    private ListView lv; private Map<String,List<Item>> groups=new LinkedHashMap<>(); private List<String> gNames=new ArrayList<>(); private List<Item> curList=new ArrayList<>(); private boolean isGroup=false;
    private String hC, bC, tC, pCfg; 
    private String lType, lBg, lIcon; private int lRad;

    class Item { String n,u,i,h; Item(String name,String url,String img,String head){n=name;u=url;i=img;h=head;} }
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        hC=getIntent().getStringExtra("HEADER_COLOR"); bC=getIntent().getStringExtra("BG_COLOR"); tC=getIntent().getStringExtra("TEXT_COLOR"); pCfg=getIntent().getStringExtra("PLAYER_CONFIG");
        lType=getIntent().getStringExtra("L_TYPE"); lBg=getIntent().getStringExtra("L_BG"); lRad=getIntent().getIntExtra("L_RAD",0); lIcon=getIntent().getStringExtra("L_ICON");

        LinearLayout r=new LinearLayout(this); r.setOrientation(1); r.setBackgroundColor(Color.parseColor(bC));
        LinearLayout h=new LinearLayout(this); h.setBackgroundColor(Color.parseColor(hC)); h.setPadding(30,30,30,30);
        TextView t=new TextView(this); t.setText("Liste"); t.setTextColor(Color.parseColor(tC)); t.setTextSize(18); h.addView(t); r.addView(h);
        lv=new ListView(this); lv.setDivider(null); lv.setPadding(20,20,20,20); lv.setClipToPadding(false); r.addView(lv); setContentView(r);
        new Load(getIntent().getStringExtra("TYPE"), getIntent().getStringExtra("LIST_CONTENT")).execute(getIntent().getStringExtra("LIST_URL"));
        lv.setOnItemClickListener((p,v,pos,id)->{ if(isGroup) showCh(gNames.get(pos)); else AdsManager.checkInter(this, ()->{ Intent i=new Intent(this, PlayerActivity.class); i.putExtra("VIDEO_URL", curList.get(pos).u); i.putExtra("HEADERS_JSON", curList.get(pos).h); i.putExtra("PLAYER_CONFIG", pCfg); startActivity(i); }); });
    }
    public void onBackPressed(){ if(!isGroup && gNames.size()>1) showGr(); else super.onBackPressed(); }
    private void showGr(){ isGroup=true; lv.setAdapter(new Adp(gNames, true)); }
    private void showCh(String g){ isGroup=false; curList=groups.get(g); lv.setAdapter(new Adp(curList, false)); }

    class Load extends AsyncTask<String,Void,String> {
        String t,c; Load(String ty,String co){t=ty;c=co;}
        protected String doInBackground(String... u) { if("MANUAL_M3U".equals(t))return c; try{ URL url=new URL(u[0]); HttpURLConnection cn=(HttpURLConnection)url.openConnection(); BufferedReader r=new BufferedReader(new InputStreamReader(cn.getInputStream())); StringBuilder s=new StringBuilder(); String l; while((l=r.readLine())!=null)s.append(l).append("\n"); return s.toString(); }catch(Exception e){return null;} }
        protected void onPostExecute(String r) {
            if(r==null)return; try{ groups.clear(); gNames.clear();
                if("JSON_LIST".equals(t)||r.trim().startsWith("{")) { JSONObject root=new JSONObject(r); JSONArray arr=root.getJSONObject("list").getJSONArray("item"); for(int i=0;i<arr.length();i++){ JSONObject o=arr.getJSONObject(i); String u=o.optString("media_url",o.optString("url")); if(u.isEmpty())continue; String g=o.optString("group","Genel"); JSONObject head=new JSONObject(); for(int k=1;k<=5;k++){ String kn=o.optString("h"+k+"Key"), kv=o.optString("h"+k+"Val"); if(!kn.isEmpty()) head.put(kn,kv); } if(!groups.containsKey(g)){groups.put(g,new ArrayList<>()); gNames.add(g);} groups.get(g).add(new Item(o.optString("title"), u, o.optString("thumb_square"), head.toString())); } }
                if(groups.isEmpty()) { String[] lines=r.split("\n"); String curT="Kanal", curI="", curG="Genel"; JSONObject curH=new JSONObject(); Pattern pG=Pattern.compile("group-title=\"([^\"]*)\""), pL=Pattern.compile("tvg-logo=\"([^\"]*)\""); for(String l:lines) { l=l.trim(); if(l.startsWith("#EXTINF")) { if(l.contains(",")) curT=l.substring(l.lastIndexOf(",")+1).trim(); Matcher mG=pG.matcher(l); if(mG.find()) curG=mG.group(1); Matcher mL=pL.matcher(l); if(mL.find()) curI=mL.group(1); } else if(l.startsWith("#EXTVLCOPT:")) { String opt=l.substring(11); if(opt.startsWith("http-referrer=")) curH.put("Referer",opt.substring(14)); if(opt.startsWith("http-user-agent=")) curH.put("User-Agent",opt.substring(16)); } else if(!l.startsWith("#") && !l.isEmpty()) { if(!groups.containsKey(curG)){groups.put(curG,new ArrayList<>()); gNames.add(curG);} groups.get(curG).add(new Item(curT,l,curI,curH.toString())); curT="Kanal"; curI=""; curH=new JSONObject(); } } }
                if(gNames.size()>1) showGr(); else if(gNames.size()==1) showCh(gNames.get(0));
            }catch(Exception e){}
        }
    }

    class Adp extends BaseAdapter {
        List<?> d; boolean isG; Adp(List<?> l, boolean g){d=l;isG=g;}
        public int getCount(){return d.size();} public Object getItem(int p){return d.get(p);} public long getItemId(int p){return p;}
        public View getView(int p, View v, ViewGroup gr) {
            if(v==null){
                LinearLayout l=new LinearLayout(ChannelListActivity.this); l.setOrientation(0); l.setGravity(Gravity.CENTER_VERTICAL);
                ImageView i=new ImageView(ChannelListActivity.this); i.setId(1); l.addView(i);
                TextView t=new TextView(ChannelListActivity.this); t.setId(2); t.setTextColor(Color.BLACK); l.addView(t); v=l;
            }
            LinearLayout l = (LinearLayout)v;
            GradientDrawable bg = new GradientDrawable(); bg.setColor(Color.parseColor(lBg)); bg.setCornerRadius(lRad);
            l.setBackground(bg);
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(-1,-2);
            if(lType.equals("CARD")) { params.setMargins(0,0,0,25); l.setPadding(30,30,30,30); l.setElevation(5f); }
            else if(lType.equals("MODERN")) { params.setMargins(0,0,0,15); l.setPadding(20,50,20,50); }
            else { params.setMargins(0,0,0,5); l.setPadding(20,20,20,20); }
            l.setLayoutParams(params);
            ImageView img=v.findViewById(1); TextView txt=v.findViewById(2);
            img.setLayoutParams(new LinearLayout.LayoutParams(120,120)); ((LinearLayout.LayoutParams)img.getLayoutParams()).setMargins(0,0,30,0);
            RequestOptions opts = new RequestOptions(); if(lIcon.equals("CIRCLE")) opts = opts.circleCrop();
            if(isG) { txt.setText(d.get(p).toString()); img.setImageResource(android.R.drawable.ic_menu_sort_by_size); img.setColorFilter(Color.parseColor(hC)); }
            else { Item i=(Item)d.get(p); txt.setText(i.n); if(!i.i.isEmpty()) Glide.with(ChannelListActivity.this).load(i.i).apply(opts).into(img); else img.setImageResource(android.R.drawable.ic_menu_slideshow); img.clearColorFilter(); }
            return v;
        }
    }
}
EOF

# 9. PLAYER (AYNI - DEĞİŞMEDİ)
cat > "$TARGET_DIR/PlayerActivity.java" <<EOF
package com.base.app;
import android.app.Activity; import android.os.Bundle; import android.widget.*; import android.view.*; import android.graphics.Color; import androidx.media3.common.MediaItem; import androidx.media3.exoplayer.ExoPlayer; import androidx.media3.ui.PlayerView; import androidx.media3.exoplayer.DefaultLoadControl; import androidx.media3.exoplayer.upstream.DefaultAllocator; import androidx.media3.datasource.DefaultHttpDataSource; import androidx.media3.exoplayer.source.DefaultMediaSourceFactory; import org.json.JSONObject; import java.util.*;
public class PlayerActivity extends Activity {
    ExoPlayer p;
    protected void onCreate(Bundle s) {
        super.onCreate(s); getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON); getWindow().setFlags(1024,1024);
        FrameLayout root = new FrameLayout(this); root.setBackgroundColor(Color.BLACK); PlayerView v=new PlayerView(this); v.setShowNextButton(false); v.setShowPreviousButton(false); root.addView(v);
        try { JSONObject cfg = new JSONObject(getIntent().getStringExtra("PLAYER_CONFIG")); if(cfg.optBoolean("enable_overlay", false)) { TextView ov = new TextView(this); ov.setText(cfg.optString("watermark_text")); ov.setTextColor(Color.parseColor(cfg.optString("watermark_color", "#FFFFFF"))); ov.setTextSize(18); ov.setPadding(30,30,30,30); ov.setBackgroundColor(Color.parseColor("#80000000")); FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(-2,-2); String pos = cfg.optString("watermark_pos", "left"); lp.gravity = (pos.equals("right") ? Gravity.TOP|Gravity.END : Gravity.TOP|Gravity.START); lp.setMargins(40,40,40,40); root.addView(ov, lp); } } catch(Exception e){}
        String ua="Mozilla/5.0"; Map<String,String> pr=new HashMap<>(); String hj=getIntent().getStringExtra("HEADERS_JSON"); if(hj!=null)try{JSONObject h=new JSONObject(hj);Iterator<String> k=h.keys();while(k.hasNext()){String ky=k.next();if(ky.equalsIgnoreCase("User-Agent"))ua=h.getString(ky);else pr.put(ky,h.getString(ky));}}catch(Exception e){}
        DefaultLoadControl lc=new DefaultLoadControl.Builder().setAllocator(new DefaultAllocator(true,16*1024)).setBufferDurationsMs(50000,50000,2500,5000).build();
        DefaultHttpDataSource.Factory hf=new DefaultHttpDataSource.Factory().setUserAgent(ua).setAllowCrossProtocolRedirects(true).setDefaultRequestProperties(pr);
        p=new ExoPlayer.Builder(this).setLoadControl(lc).setMediaSourceFactory(new DefaultMediaSourceFactory(hf)).build(); v.setPlayer(p);
        String u=getIntent().getStringExtra("VIDEO_URL"); if(u!=null){p.setMediaItem(MediaItem.fromUri(u));p.prepare();p.play();} setContentView(root);
    }
    protected void onStop(){super.onStop();if(p!=null)p.release();}
}
EOF

# 10. WEBVIEW
cat > "$TARGET_DIR/WebViewActivity.java" <<EOF
package com.base.app; import android.app.Activity; import android.os.Bundle; import android.webkit.*; import android.util.Base64;
public class WebViewActivity extends Activity { protected void onCreate(Bundle s) { super.onCreate(s); WebView w=new WebView(this); setContentView(w); w.getSettings().setJavaScriptEnabled(true); String u=getIntent().getStringExtra("WEB_URL"); String h=getIntent().getStringExtra("HTML_DATA"); if(h!=null&&!h.isEmpty())w.loadData(Base64.encodeToString(h.getBytes(),0),"text/html","base64"); else w.loadUrl(u); } }
EOF

echo "✅ ULTRA APP V90 - TITANIUM EDITION DEPLOYED"
