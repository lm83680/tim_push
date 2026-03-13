package com.plugin.tim_push.application;

import android.app.Application;
import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.Nullable;

import com.plugin.tim_push.TimPushPlugin;
import com.plugin.tim_push.common.Extras;
import com.tencent.qcloud.tuicore.TUIConstants;
import com.tencent.qcloud.tuicore.TUICore;

import java.util.Timer;
import java.util.TimerTask;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.dart.DartExecutor;

/**
 * TIMPush Android 宿主初始化入口。
 * 通过静态组合方式承载初始化与运行时状态，避免宿主必须继承特定 Application。
 */
public final class TimPushBootstrap {
    private static final String TAG = "TimPushBootstrap";

    private static boolean initialized = false;
    private static boolean useCustomFlutterEngine = false;
    private static boolean hadLaunchedMainActivity = false;
    private static Application application;

    private TimPushBootstrap() {
    }

    public static synchronized void init(Context context) {
        if (initialized) {
            return;
        }
        Application resolvedApplication = resolveApplication(context);
        if (resolvedApplication == null) {
            Log.e(TAG, "Failed to resolve Application from context.");
            return;
        }
        application = resolvedApplication;
        TUICore.callService(TUIConstants.TIMPush.SERVICE_NAME, TUIConstants.TIMPush.METHOD_DISABLE_AUTO_REGISTER_PUSH, null);
        registerOnNotificationClickedEventToTUICore();
        registerOnAppWakeUp();
        initialized = true;
    }

    public static synchronized void markMainActivityLaunched() {
        hadLaunchedMainActivity = true;
    }

    @Nullable
    public static synchronized String getCachedEngineId(@Nullable Intent intent) {
        if (useCustomFlutterEngine) {
            return Extras.FLUTTER_ENGINE;
        }
        if (intent == null) {
            return null;
        }
        try {
            return intent.getStringExtra("cached_engine_id");
        } catch (Exception ignored) {
            return null;
        }
    }

    @Nullable
    private static Application resolveApplication(Context context) {
        Context applicationContext = context.getApplicationContext();
        if (applicationContext instanceof Application) {
            return (Application) applicationContext;
        }
        if (context instanceof Application) {
            return (Application) context;
        }
        return null;
    }

    private static synchronized void generateFlutterEngine() {
        if (application == null) {
            return;
        }
        if (FlutterEngineCache.getInstance().contains(Extras.FLUTTER_ENGINE) || hadLaunchedMainActivity) {
            return;
        }
        new Handler(Looper.getMainLooper()).post(() -> {
            useCustomFlutterEngine = true;
            FlutterEngine engine = new FlutterEngine(application);
            engine.getDartExecutor().executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault());
            FlutterEngineCache.getInstance().put(Extras.FLUTTER_ENGINE, engine);
        });
    }

    private static void launchMainActivity(boolean showInForeground) {
        Application app = application;
        if (app == null) {
            return;
        }
        Intent launchIntent = app.getPackageManager().getLaunchIntentForPackage(app.getPackageName());
        if (launchIntent != null) {
            launchIntent.putExtra(Extras.SHOW_IN_FOREGROUND, showInForeground);
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            app.startActivity(launchIntent);
        } else {
            Log.e(TAG, "Failed to get launch intent for package: " + app.getPackageName());
        }
    }

    private static void scheduleCheckPluginInstanceAndNotify(final String action, final String data) {
        final Handler handler = new Handler(Looper.getMainLooper());
        final Timer timer = new Timer();
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
                        Log.e(TAG, e.toString());
                    }
                });
            }
        }, 100, 500);
    }

    private static void registerOnNotificationClickedEventToTUICore() {
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

    private static void registerOnAppWakeUp() {
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
