package com.kodhocasi.template;

import android.app.Activity;
import android.os.Bundle;
import android.view.Window;
import android.view.WindowManager;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.ui.StyledPlayerView;

public class MainActivity extends Activity { // AppCompatActivity yerine düz Activity

    private ExoPlayer player;
    private StyledPlayerView playerView;
    
    // PHP Panelden gelecek olan URL
    private String M3U_URL = "CONFIG_URL_PLACEHOLDER"; 

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Fullscreen Modu (Tam Ekran)
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, 
                            WindowManager.LayoutParams.FLAG_FULLSCREEN);
        
        setContentView(R.layout.activity_main);

        playerView = findViewById(R.id.player_view);
        setupPlayer();
    }

    private void setupPlayer() {
        player = new ExoPlayer.Builder(this).build();
        playerView.setPlayer(player);

        // Dinamik link değişimi burada yapılacak
        MediaItem mediaItem = MediaItem.fromUri("http://panelinden-gelen-link.m3u8");
        player.setMediaItem(mediaItem);
        player.prepare();
        player.play();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (player != null) player.release();
    }
}
