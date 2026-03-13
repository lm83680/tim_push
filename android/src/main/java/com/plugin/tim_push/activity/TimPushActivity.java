package com.plugin.tim_push.activity;

import android.content.Intent;
import android.os.Bundle;

import androidx.annotation.NonNull;

import com.plugin.tim_push.application.TimPushBootstrap;
import com.plugin.tim_push.common.Extras;

import io.flutter.embedding.android.FlutterActivity;

public class TimPushActivity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handleIntent(getIntent());
        TimPushBootstrap.markMainActivityLaunched();
    }

    @Override
    protected void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);
        handleIntent(intent);
    }

    private void handleIntent(Intent intent) {
        boolean showInForeground = intent.getBooleanExtra(Extras.SHOW_IN_FOREGROUND, true);
        if (!showInForeground) {
            moveTaskToBack(true);
        }
    }

    @Override
    public String getCachedEngineId() {
        return TimPushBootstrap.getCachedEngineId(getIntent());
    }
}
