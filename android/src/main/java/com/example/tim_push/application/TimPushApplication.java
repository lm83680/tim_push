package com.example.tim_push.application;

import android.content.Intent;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import com.example.tim_push.TimPushPlugin;
import com.example.tim_push.common.Extras;
import com.tencent.qcloud.tuicore.TUIConstants;
import com.tencent.qcloud.tuicore.TUICore;

import java.util.Timer;
import java.util.TimerTask;

import io.flutter.app.FlutterApplication;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.dart.DartExecutor;

public class TimPushApplication extends FlutterApplication {
    private final String tag = "TimPushApplication";

    public static boolean useCustomFlutterEngine = false;
    public static boolean hadLaunchedMainActivity = false;

    @Override
    public void onCreate() {
        super.onCreate();
        TUICore.callService(TUIConstants.TIMPush.SERVICE_NAME, TUIConstants.TIMPush.METHOD_DISABLE_AUTO_REGISTER_PUSH, null);
        registerOnNotificationClickedEventToTUICore();
        registerOnAppWakeUp();
    }

    private void generateFlutterEngine() {
        if (FlutterEngineCache.getInstance().contains(Extras.FLUTTER_ENGINE) || hadLaunchedMainActivity) {
            return;
        }
        new Handler(Looper.getMainLooper()).post(() -> {
            useCustomFlutterEngine = true;
            FlutterEngine engine = new FlutterEngine(this);
            engine.getDartExecutor().executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault());
            FlutterEngineCache.getInstance().put(Extras.FLUTTER_ENGINE, engine);
        });
    }

    private void launchMainActivity(boolean showInForeground) {
        Intent launchIntent = getPackageManager().getLaunchIntentForPackage(getPackageName());
        if (launchIntent != null) {
            launchIntent.putExtra(Extras.SHOW_IN_FOREGROUND, showInForeground);
            startActivity(launchIntent);
        } else {
            Log.e(tag, "Failed to get launch intent for package: " + getPackageName());
        }
    }

    private void scheduleCheckPluginInstanceAndNotify(final String action, final String data) {
        final Handler handler = new Handler(Looper.getMainLooper());
        Timer timer = new Timer();
        timer.scheduleAtFixedRate(new TimerTask() {
            @Override
            public void run() {
                handler.post(() -> {
                    try {
                        if (TimPushPlugin.instance != null && TimPushPlugin.instance.attachedToEngine) {
                            TimPushPlugin.instance.tryNotifyDartEvent(action, data);
                            timer.cancel();
                        }
                    } catch (Exception e) {
                        Log.e(tag, e.toString());
                    }
                });
            }
        }, 100, 500);
    }

    private void registerOnNotificationClickedEventToTUICore() {
        TUICore.registerEvent(
                TUIConstants.TIMPush.EVENT_NOTIFY,
                TUIConstants.TIMPush.EVENT_NOTIFY_NOTIFICATION,
                (key, subKey, param) -> {
                    launchMainActivity(true);
                    if (TUIConstants.TIMPush.EVENT_NOTIFY.equals(key)
                            && TUIConstants.TIMPush.EVENT_NOTIFY_NOTIFICATION.equals(subKey)
                            && param != null) {
                        String extString = (String) param.get(TUIConstants.TUIOfflinePush.NOTIFICATION_EXT_KEY);
                        scheduleCheckPluginInstanceAndNotify(Extras.ON_NOTIFICATION_CLICKED, extString);
                    }
                }
        );
    }

    private void registerOnAppWakeUp() {
        TUICore.registerEvent(
                TUIConstants.TIMPush.EVENT_IM_LOGIN_AFTER_APP_WAKEUP_KEY,
                TUIConstants.TIMPush.EVENT_IM_LOGIN_AFTER_APP_WAKEUP_SUB_KEY,
                (key, subKey, param) -> {
                    if (TUIConstants.TIMPush.EVENT_IM_LOGIN_AFTER_APP_WAKEUP_KEY.equals(key)
                            && TUIConstants.TIMPush.EVENT_IM_LOGIN_AFTER_APP_WAKEUP_SUB_KEY.equals(subKey)) {
                        generateFlutterEngine();
                        scheduleCheckPluginInstanceAndNotify(Extras.ON_APP_WAKE_UP, "");
                    }
                }
        );
    }
}
