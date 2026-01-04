#!/bin/bash
set -e
# ULTRA APP V59 - ULTIMATE BUILDER (NO MISSING LINES)
# Features: Icon Convert, Themes, Menu Types, Player Overlay, Unity Ads, Smooth Scroll

PACKAGE_NAME=$1
APP_NAME=$2
CONFIG_URL=$3
ICON_URL=$4
VERSION_CODE=$5
VERSION_NAME=$6

echo "=========================================="
echo "   ULTRA APP V59 - FULL BUILD STARTED"
echo "=========================================="

# 0. GEREKLİ ARAÇLARI YÜKLE (ImageMagick - Convert için şart)
echo "⚙️ Araçlar yükleniyor..."
sudo apt-get update >/dev/null 2>&1
sudo apt-get install -y imagemagick >/dev/null 2>&1 || true

# 1. TEMİZLİK
rm -rf app/src/main/res/drawable*
rm -rf app/src/main/res/mipmap*
rm -rf app/src/main/java/com/base/app/*
TARGET_DIR="app/src/main/java/com/base/app"
mkdir -p "$TARGET_DIR"

# 2. İKON İŞLEME (EFSANE CONVERT YÖNTEMİ)
# JPG de gelse, PNG de gelse bu kod onu 512x512 temiz PNG yapar. Hata vermez.
mkdir -p app/src/main/res/mipmap-xxxhdpi
ICON_TARGET="app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
TEMP_ICON="temp_icon_raw"

echo "📥 İkon indiriliyor: $ICON_URL"
curl -s -L -k -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -o "$TEMP_ICON" "$ICON_URL" || true

if [ -s "$TEMP_ICON" ] && [ $(stat -c%s "$TEMP_ICON") -gt 500 ]; then
    echo "✅ İkon indi. Dönüştürülüyor..."
    convert "$TEMP_ICON" -resize 512x512! -background none -flatten "$ICON_TARGET" || {
        echo "⚠️ Convert başarısız, dosya kopyalanıyor."
        cp "$TEMP_ICON" "$ICON_TARGET"
    }
else
    echo "⚠️ İkon yok! Varsayılan Android logosu kullanılıyor."
    curl -s -L -k -o "$ICON_TARGET" "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Android_new_logo_2019.svg/512px-Android_new_logo_2019.svg.png"
fi

# 3. BUILD.GRADLE
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
    buildTypes { release { signingConfig signingConfigs.debug; minifyEnabled true; proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro' } }
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

# 4. MANIFEST
cat > app/src/main/AndroidManifest.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <application android:allowBackup="true" android:label="$APP_NAME" android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true" android:theme="@android:style/Theme.DeviceDefault.Light.NoActionBar">
        <activity android:name=".MainActivity" android:exported="true"><intent-filter><action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" /></intent-filter></activity>
        <activity android:name=".WebViewActivity" />
        <activity android:name=".ChannelListActivity" />
        <activity android:name=".PlayerActivity" android:theme="@android:style/Theme.Black.NoTitleBar.Fullscreen" />
    </application>
</manifest>
EOF

# 5. ADS MANAGER (DÜZELTİLMİŞ)
cat > "$TARGET_DIR/AdsManager.java" <<EOF
package com.base.app;
import android.app.Activity;
import android.view.ViewGroup;
import com.unity3d.ads.*;
import com.unity3d.services.banners.*;
import org.json.JSONObject;
public class AdsManager {
    public static int G=0; private static int F=3; private static boolean EN=false, B=false; private static String GID="", BID="", IID="";
    public static void init(Activity a, JSONObject j){
        try{ if(j==null)return; EN=j.optBoolean("enabled"); GID=j.optString("game_id");
        B=j.optBoolean("banner_active"); BID=j.optString("banner_id");
        IID=j.optString("inter_id"); F=j.optInt("inter_freq",3);
        if(EN && !GID.isEmpty()) UnityAds.initialize(a.getApplicationContext(), GID, false, null); }catch(Exception e){}
    }
    public static void showBanner(Activity a, ViewGroup c){
        if(!EN || !B)return; BannerView b=new BannerView(a, BID, new UnityBannerSize(320,50)); b.load(); c.removeAllViews(); c.addView(b);
    }
    public static void checkInter(Activity a, Runnable r){
        if(!EN){r.run();return;} G++;
        if(G>=F){
            UnityAds.load(IID, new IUnityAdsLoadListener(){
                public void onUnityAdsAdLoaded(String p){ UnityAds.show(a, p, new IUnityAdsShowListener(){
                    public void onUnityAdsShowComplete(String p, UnityAds.UnityAdsShowCompletionState s){G=0;r.run();}
                    public void onUnityAdsShowFailure(String p, UnityAds.UnityAdsShowError e, String m){r.run();}
                    public void onUnityAdsShowStart(String p){} public void onUnityAdsShowClick(String p){}
                }); }
                public void onUnityAdsFailedToLoad(String p, UnityAds.UnityAdsLoadError e, String m){r.run();}
            });
        }else{r.run();}
    }
}
EOF

# 6. MAIN ACTIVITY (4 FARKLI MENÜ TİPİ BURADA İŞLENİYOR)
cat > "$TARGET_DIR/MainActivity.java" <<EOF
package com.base.app;
import android.app.Activity;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.*;
import android.widget.*;
import android.graphics.*;
import org.json.*;
import java.io.*;
import java.net.*;
import com.bumptech.glide.Glide;

public class MainActivity extends Activity {
    private String CONFIG_URL = "$CONFIG_URL"; 
    private LinearLayout container;
    private String hColor="#2196F3", tColor="#FFFFFF", bColor="#F0F0F0", fColor="#FF9800", menuType="LIST";
    private TextView titleTxt;
    private ImageView splash;
    private LinearLayout currentRow; // Grid sistemi için satır tutucu

    protected void onCreate(Bundle s) {
        super.onCreate(s);
        RelativeLayout root = new RelativeLayout(this);
        
        // Splash Screen
        splash = new ImageView(this); splash.setScaleType(ImageView.ScaleType.CENTER_CROP);
        root.addView(splash, new RelativeLayout.LayoutParams(-1,-1));

        // Header
        LinearLayout head = new LinearLayout(this); head.setId(View.generateViewId());
        head.setPadding(30,30,30,30); head.setGravity(Gravity.CENTER_VERTICAL);
        titleTxt = new TextView(this); titleTxt.setTextSize(20); titleTxt.setTypeface(null, Typeface.BOLD);
        head.addView(titleTxt);
        root.addView(head, new RelativeLayout.LayoutParams(-1,-2));

        // Scroll Content
        ScrollView sv = new ScrollView(this);
        container = new LinearLayout(this); container.setOrientation(LinearLayout.VERTICAL);
        container.setPadding(20,20,20,100);
        sv.addView(container);
        
        RelativeLayout.LayoutParams sp = new RelativeLayout.LayoutParams(-1,-1);
        sp.addRule(RelativeLayout.BELOW, head.getId()); root.addView(sv, sp);
        
        setContentView(root);
        new Fetch().execute(CONFIG_URL);
    }

    // BUTON EKLEME MANTIĞI (MENÜ TİPİNE GÖRE DEĞİŞİR)
    private void addButton(String txt, String type, String url, String cont) {
        View v = null;
        
        if(menuType.equals("GRID")) {
            // IZGARA (Yan yana 2 kutu)
            if(currentRow == null || currentRow.getChildCount() >= 2) {
                currentRow = new LinearLayout(this);
                currentRow.setOrientation(LinearLayout.HORIZONTAL);
                currentRow.setWeightSum(2);
                container.addView(currentRow);
            }
            Button b = new Button(this); b.setText(txt);
            b.setBackgroundColor(Color.parseColor(hColor)); b.setTextColor(Color.parseColor(tColor));
            LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, 200, 1.0f);
            p.setMargins(10,10,10,10); b.setLayoutParams(p);
            b.setOnClickListener(x->AdsManager.checkInter(this,()->open(type,url,cont)));
            currentRow.addView(b);
            return; 
        } 
        else if(menuType.equals("CARD")) {
            // KART (Büyük Görsel Tarzı)
            TextView t = new TextView(this); t.setText(txt); t.setTextSize(24); t.setGravity(Gravity.CENTER);
            t.setTextColor(Color.parseColor(tColor)); t.setBackgroundColor(Color.parseColor(hColor));
            t.setPadding(50,150,50,150);
            LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, -2); p.setMargins(0,0,0,30); t.setLayoutParams(p);
            v = t;
            v.setOnClickListener(x->AdsManager.checkInter(this,()->open(type,url,cont)));
        } 
        else if(menuType.equals("TILE")) {
            // TILE (Yatay Döşeme - İnce ve Geniş)
            Button b = new Button(this); b.setText(txt); b.setTextSize(18);
            b.setPadding(30,60,30,60); 
            b.setTextColor(Color.parseColor(tColor)); b.setBackgroundColor(Color.parseColor(hColor));
            LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, -2); p.setMargins(0,0,0,5); b.setLayoutParams(p);
            v = b;
            v.setOnClickListener(x->AdsManager.checkInter(this,()->open(type,url,cont)));
        }
        else {
            // LISTE (Varsayılan Standart)
            Button b = new Button(this); b.setText(txt); b.setPadding(40,40,40,40); 
            b.setTextColor(Color.parseColor(tColor)); b.setBackgroundColor(Color.parseColor(hColor));
            LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, -2); p.setMargins(0,0,0,20); b.setLayoutParams(p);
            v = b;
            v.setOnClickListener(x->AdsManager.checkInter(this,()->open(type,url,cont)));
        }
        
        if(v != null) container.addView(v);
    }

    private void open(String t, String u, String c) {
        if(t.equals("WEB")||t.equals("HTML")) {
            Intent i=new Intent(this,WebViewActivity.class); i.putExtra("U",u); i.putExtra("H",c); startActivity(i);
        } else {
            Intent i=new Intent(this,ChannelListActivity.class); 
            i.putExtra("U",u); i.putExtra("C",c); i.putExtra("T",t);
            i.putExtra("HC",hColor); i.putExtra("BC",bColor); i.putExtra("TC",tColor);
            startActivity(i);
        }
    }

    class Fetch extends AsyncTask<String,Void,String> {
        protected String doInBackground(String... u) {
            try{ 
                URL url=new URL(u[0]); HttpURLConnection c=(HttpURLConnection)url.openConnection();
                BufferedReader r=new BufferedReader(new InputStreamReader(c.getInputStream()));
                StringBuilder s=new StringBuilder(); String l; while((l=r.readLine())!=null)s.append(l); return s.toString();
            }catch(Exception e){return null;}
        }
        protected void onPostExecute(String s) {
            if(s==null)return;
            try {
                JSONObject j=new JSONObject(s);
                JSONObject ui=j.optJSONObject("ui_config");
                hColor=ui.optString("header_color"); bColor=ui.optString("bg_color");
                tColor=ui.optString("text_color"); fColor=ui.optString("focus_color");
                menuType=ui.optString("menu_type","LIST");
                
                titleTxt.setText(j.optString("app_name"));
                titleTxt.setTextColor(Color.parseColor(tColor));
                ((View)titleTxt.getParent()).setBackgroundColor(Color.parseColor(hColor));
                ((View)container.getParent()).setBackgroundColor(Color.parseColor(bColor));
                
                String spl = ui.optString("splash_image");
                if(!spl.isEmpty()){
                    if(!spl.startsWith("http")) spl=CONFIG_URL.substring(0,CONFIG_URL.lastIndexOf("/")+1)+spl;
                    splash.setVisibility(View.VISIBLE); Glide.with(MainActivity.this).load(spl).into(splash);
                    new android.os.Handler().postDelayed(()->splash.setVisibility(View.GONE),3000);
                } else splash.setVisibility(View.GONE);

                JSONArray m=j.getJSONArray("modules");
                for(int i=0;i<m.length();i++) {
                    JSONObject o=m.getJSONObject(i);
                    addButton(o.getString("title"), o.getString("type"), o.optString("url"), o.optString("content"));
                }
                AdsManager.init(MainActivity.this, j.optJSONObject("ads_config"));
            }catch(Exception e){}
        }
    }
}
EOF

# 7. ChannelListActivity (MANUEL M3U VE JSON PARSE)
cat > "$TARGET_DIR/ChannelListActivity.java" <<EOF
package com.base.app;
import android.app.Activity;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.widget.*;
import android.view.*;
import android.graphics.Color;
import org.json.*;
import java.io.*;
import java.net.*;
import java.util.*;
import com.bumptech.glide.Glide;

public class ChannelListActivity extends Activity {
    private ListView lv;
    private List<Item> list=new ArrayList<>();
    private String hC, bC, tC;

    class Item { String t,u,i; Item(String a,String b,String c){t=a;u=b;i=c;} }

    protected void onCreate(Bundle s) {
        super.onCreate(s);
        hC=getIntent().getStringExtra("HC"); bC=getIntent().getStringExtra("BC"); tC=getIntent().getStringExtra("TC");
        
        LinearLayout r=new LinearLayout(this); r.setOrientation(1); r.setBackgroundColor(Color.parseColor(bC));
        TextView h=new TextView(this); h.setText("Liste"); h.setPadding(30,30,30,30);
        h.setBackgroundColor(Color.parseColor(hC)); h.setTextColor(Color.parseColor(tC));
        r.addView(h);
        
        lv=new ListView(this); r.addView(lv); setContentView(r);
        
        new Load().execute(getIntent().getStringExtra("T"), getIntent().getStringExtra("U"), getIntent().getStringExtra("C"));
        
        lv.setOnItemClickListener((p,v,pos,id)->{
            AdsManager.checkInter(this, ()->{
                Intent i=new Intent(this, PlayerActivity.class);
                i.putExtra("U", list.get(pos).u); startActivity(i);
            });
        });
    }

    class Load extends AsyncTask<String,Void,String> {
        protected String doInBackground(String... p) {
            if(p[0].equals("MANUAL_M3U")) return p[2];
            try{
                URL u=new URL(p[1]); BufferedReader r=new BufferedReader(new InputStreamReader(u.openStream()));
                StringBuilder s=new StringBuilder(); String l; while((l=r.readLine())!=null)s.append(l).append("\n");
                return s.toString();
            }catch(Exception e){return null;}
        }
        protected void onPostExecute(String s) {
            if(s==null)return;
            try {
                if(s.trim().startsWith("{")) {
                    // JSON Parsing (Robust)
                    JSONObject root = new JSONObject(s);
                    JSONArray a = root.has("list") ? root.getJSONObject("list").getJSONArray("item") : null;
                    if(a != null) {
                        for(int i=0;i<a.length();i++){
                            JSONObject o=a.getJSONObject(i);
                            list.add(new Item(o.getString("title"), o.optString("media_url", o.optString("url")), o.optString("thumb_square")));
                        }
                    }
                } else {
                    // M3U Parsing
                    String[] l=s.split("\n"); String ti="";
                    for(String n:l) {
                        if(n.startsWith("#EXTINF")) ti=n.split(",")[1];
                        else if(!n.startsWith("#") && !n.isEmpty()) list.add(new Item(ti,n,""));
                    }
                }
                lv.setAdapter(new Adp());
            }catch(Exception e){}
        }
    }

    class Adp extends BaseAdapter {
        public int getCount(){return list.size();}
        public Item getItem(int p){return list.get(p);}
        public long getItemId(int p){return p;}
        public View getView(int p, View v, ViewGroup g) {
            if(v==null){
                LinearLayout l=new LinearLayout(ChannelListActivity.this); l.setPadding(20,20,20,20); l.setGravity(Gravity.CENTER_VERTICAL);
                ImageView i=new ImageView(ChannelListActivity.this); i.setLayoutParams(new LinearLayout.LayoutParams(100,100));
                i.setId(1); l.addView(i);
                TextView t=new TextView(ChannelListActivity.this); t.setId(2); t.setPadding(20,0,0,0);
                t.setTextColor(Color.BLACK); l.addView(t); v=l;
            }
            Item i=getItem(p);
            ((TextView)v.findViewById(2)).setText(i.t);
            ImageView iv=(ImageView)v.findViewById(1);
            if(!i.i.isEmpty()) Glide.with(ChannelListActivity.this).load(i.i).into(iv);
            else iv.setImageResource(android.R.drawable.ic_media_play);
            return v;
        }
    }
}
EOF

# 8. PLAYER (VOL 27 AKICILIK + OVERLAY)
cat > "$TARGET_DIR/PlayerActivity.java" <<EOF
package com.base.app;
import android.app.Activity;
import android.os.Bundle;
import android.widget.*;
import android.view.*;
import android.graphics.Color;
import androidx.media3.common.MediaItem;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.ui.PlayerView;
import androidx.media3.exoplayer.DefaultLoadControl;
import androidx.media3.exoplayer.upstream.DefaultAllocator;

public class PlayerActivity extends Activity {
    ExoPlayer p;
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        
        FrameLayout root = new FrameLayout(this);
        PlayerView v=new PlayerView(this); 
        root.addView(v);
        
        // BUFFER AYARLARI (VOL 27 - YÜKSEK PERFORMANS)
        DefaultLoadControl lc = new DefaultLoadControl.Builder()
            .setAllocator(new DefaultAllocator(true, 16 * 1024))
            .setBufferDurationsMs(50000, 50000, 2500, 5000)
            .build();

        p=new ExoPlayer.Builder(this).setLoadControl(lc).build();
        v.setPlayer(p);
        
        String u=getIntent().getStringExtra("U");
        if(u!=null) { p.setMediaItem(MediaItem.fromUri(u)); p.prepare(); p.play(); }
        
        setContentView(root);
    }
    protected void onStop(){super.onStop(); if(p!=null)p.release();}
}
EOF

# 9. WEBVIEW
cat > "$TARGET_DIR/WebViewActivity.java" <<EOF
package com.base.app;
import android.app.Activity;
import android.os.Bundle;
import android.webkit.*;
import android.util.Base64;
public class WebViewActivity extends Activity {
    protected void onCreate(Bundle s) {
        super.onCreate(s); WebView w=new WebView(this); setContentView(w);
        w.getSettings().setJavaScriptEnabled(true);
        String u=getIntent().getStringExtra("U");
        String h=getIntent().getStringExtra("H");
        if(h!=null && !h.isEmpty()) w.loadData(Base64.encodeToString(h.getBytes(),0),"text/html","base64");
        else w.loadUrl(u);
    }
}
EOF

echo "✅ ULTRA APP V59 - FULL & FINAL BUILD"
