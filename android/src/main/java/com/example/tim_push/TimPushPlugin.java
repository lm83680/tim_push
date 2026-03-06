package com.example.tim_push;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import com.example.tim_push.common.Extras;
import com.tencent.qcloud.tim.push.TIMPushCallback;
import com.tencent.qcloud.tim.push.TIMPushListener;
import com.tencent.qcloud.tim.push.TIMPushManager;
import com.tencent.qcloud.tim.push.TIMPushMessage;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.Timer;
import java.util.TimerTask;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** TimPushPlugin */
public class TimPushPlugin implements FlutterPlugin, MethodCallHandler {
    public static TimPushPlugin instance;

    private MethodChannel channel;
    private Context context;
    public boolean attachedToEngine = false;
    private final Set<Integer> listenerIdSet = new HashSet<>();
    private boolean nativePushListenerRegistered = false;

    private final TIMPushListener nativePushListener = new TIMPushListener() {
        @Override
        public void onRecvPushMessage(TIMPushMessage message) {
            toFlutterMethod("onRecvPushMessage", convertPushMessage(message));
        }

        @Override
        public void onRevokePushMessage(String messageID) {
            toFlutterMethod("onRevokePushMessage", messageID);
        }

        @Override
        public void onNotificationClicked(String ext) {
            toFlutterMethod("onNotificationClicked", ext);
        }
    };

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        instance = this;
        context = flutterPluginBinding.getApplicationContext();
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "tim_push");
        channel.setMethodCallHandler(this);
        attachedToEngine = true;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "registerPush":
                registerPush(call, result);
                break;
            case "unRegisterPush":
                unRegisterPush(result);
                break;
            case "setRegistrationID":
                setRegistrationID(call, result);
                break;
            case "getRegistrationID":
                getRegistrationID(result);
                break;
            case "addPushListener":
                addPushListener(call, result);
                break;
            case "removePushListener":
                removePushListener(call, result);
                break;
            case "disablePostNotificationInForeground":
                disablePostNotificationInForeground(call, result);
                break;
            case "forceUseFCMPushChannel":
                forceUseFCMPushChannel(call, result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (nativePushListenerRegistered) {
            TIMPushManager.getInstance().removePushListener(nativePushListener);
            nativePushListenerRegistered = false;
        }
        listenerIdSet.clear();
        if (channel != null) {
            channel.setMethodCallHandler(null);
        }
        attachedToEngine = false;
    }

    public void toFlutterMethod(final String methodName, final Object data) {
        final Handler handler = new Handler(Looper.getMainLooper());
        handler.post(() -> {
            if (attachedToEngine) {
                channel.invokeMethod(methodName, data);
            } else {
                final Timer timer = new Timer();
                timer.schedule(new TimerTask() {
                    @Override
                    public void run() {
                        if (attachedToEngine) {
                            channel.invokeMethod(methodName, data);
                            timer.cancel();
                        }
                    }
                }, 0, 500);
            }
        });
    }

    public void tryNotifyDartEvent(final String action, final Object data) {
        if (Extras.ON_NOTIFICATION_CLICKED.equals(action) || Extras.ON_APP_WAKE_UP.equals(action)) {
            toFlutterMethod(action, data);
        }
    }

    private void registerPush(@NonNull MethodCall call, @NonNull Result result) {
        Integer sdkAppId = readIntegerArg(call, "sdk_app_id");
        String appKey = readStringArg(call, "app_key");

        TIMPushManager.getInstance().registerPush(context, sdkAppId, appKey, new TIMPushCallback<Object>() {
            @Override
            public void onSuccess(Object data) {
                result.success("");
            }

            @Override
            public void onError(int code, String desc, Object data) {
                result.error(String.valueOf(code), desc, data);
            }
        });
    }

    private void unRegisterPush(@NonNull Result result) {
        TIMPushManager.getInstance().unRegisterPush(new TIMPushCallback<Object>() {
            @Override
            public void onSuccess(Object data) {
                result.success("");
            }

            @Override
            public void onError(int code, String desc, Object data) {
                result.error(String.valueOf(code), desc, data);
            }
        });
    }

    private void setRegistrationID(@NonNull MethodCall call, @NonNull Result result) {
        String registrationID = readStringArg(call, "registration_id");
        TIMPushManager.getInstance().setRegistrationID(registrationID, new TIMPushCallback<Object>() {
            @Override
            public void onSuccess(Object data) {
                result.success("");
            }

            @Override
            public void onError(int code, String desc, Object data) {
                result.error(String.valueOf(code), desc, data);
            }
        });
    }

    private void getRegistrationID(@NonNull Result result) {
        TIMPushManager.getInstance().getRegistrationID(new TIMPushCallback<Object>() {
            @Override
            public void onSuccess(Object data) {
                result.success(data == null ? "" : data.toString());
            }

            @Override
            public void onError(int code, String desc, Object data) {
                result.error(String.valueOf(code), desc, data);
            }
        });
    }

    private void addPushListener(@NonNull MethodCall call, @NonNull Result result) {
        Integer listenerId = readIntegerArg(call, "listener_id");
        if (listenerId != null) {
            listenerIdSet.add(listenerId);
        }
        if (!nativePushListenerRegistered) {
            TIMPushManager.getInstance().addPushListener(nativePushListener);
            nativePushListenerRegistered = true;
        }
        result.success("");
    }

    private void removePushListener(@NonNull MethodCall call, @NonNull Result result) {
        Integer listenerId = readIntegerArg(call, "listener_id");
        if (listenerId == null) {
            listenerIdSet.clear();
        } else {
            listenerIdSet.remove(listenerId);
        }
        if (listenerIdSet.isEmpty() && nativePushListenerRegistered) {
            TIMPushManager.getInstance().removePushListener(nativePushListener);
            nativePushListenerRegistered = false;
        }
        result.success("");
    }

    private void disablePostNotificationInForeground(@NonNull MethodCall call, @NonNull Result result) {
        boolean disable = readBooleanArg(call, "disable");
        TIMPushManager.getInstance().disablePostNotificationInForeground(disable);
        result.success("");
    }

    private void forceUseFCMPushChannel(@NonNull MethodCall call, @NonNull Result result) {
        boolean enable = readBooleanArg(call, "enable");
        TIMPushManager.getInstance().forceUseFCMPushChannel(enable);
        result.success("");
    }

    private String readStringArg(@NonNull MethodCall call, @NonNull String key) {
        Object value = call.argument(key);
        return value == null ? "" : value.toString();
    }

    private Integer readIntegerArg(@NonNull MethodCall call, @NonNull String key) {
        Object value = call.argument(key);
        if (value instanceof Number) {
            return ((Number) value).intValue();
        }
        if (value == null) {
            return null;
        }
        try {
            return Integer.parseInt(value.toString());
        } catch (Exception ignored) {
            return null;
        }
    }

    private boolean readBooleanArg(@NonNull MethodCall call, @NonNull String key) {
        Object value = call.argument(key);
        if (value instanceof Boolean) {
            return (Boolean) value;
        }
        return value != null && Boolean.parseBoolean(value.toString());
    }

    private Map<String, Object> convertPushMessage(TIMPushMessage message) {
        Map<String, Object> map = new HashMap<>();
        if (message == null) {
            return map;
        }
        map.put("messageID", message.getMessageID());
        map.put("title", message.getTitle());
        map.put("desc", message.getDesc());
        map.put("ext", message.getExt());
        return map;
    }
}
