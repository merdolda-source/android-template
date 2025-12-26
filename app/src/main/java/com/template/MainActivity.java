package com.template;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebSettings;

import com.google.firebase.database.*;

public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        WebView web = new WebView(this);
        setContentView(web);

        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setMediaPlaybackRequiresUserGesture(false);

        String pkg = getPackageName();

        DatabaseReference ref =
                FirebaseDatabase.getInstance()
                        .getReference("apps")
                        .child(pkg);

        ref.addValueEventListener(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot snap) {
                if (!snap.exists()) return;

                Boolean active = snap.child("active").getValue(Boolean.class);
                String url = snap.child("url").getValue(String.class);

                if (active != null && active && url != null) {
                    web.loadUrl(url);
                }
            }

            @Override
            public void onCancelled(DatabaseError error) {}
        });
    }
}
