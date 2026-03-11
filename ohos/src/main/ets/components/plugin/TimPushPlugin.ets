import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';
import { notificationManager } from '@kit.NotificationKit';
import { TIMPushListener, TIMPushManager, TIMPushMessage } from '@tencentcloud/timpush';

/** TimPushPlugin **/
export default class TimPushPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext | null = null;
  private listenerMap: Map<number, TIMPushListener> = new Map<number, TIMPushListener>();

  constructor() {
  }

  getUniqueClassName(): string {
    return "TimPushPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.context = binding.getApplicationContext() as common.UIAbilityContext;
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "tim_push");
    this.channel.setMethodCallHandler(this)
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
    this.listenerMap.clear();
    this.context = null;
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      switch (call.method) {
        case "registerPush":
          await this.registerPush(call, result)
          break
        case "unRegisterPush":
          await this.unRegisterPush(result)
          break
        case "setRegistrationID":
          await this.setRegistrationID(call, result)
          break
        case "getRegistrationID":
          await this.getRegistrationID(result)
          break
        case "addPushListener":
          await this.addPushListener(call, result)
          break
        case "removePushListener":
          this.removePushListener(call, result)
          break
        case "disablePostNotificationInForeground":
          this.disablePostNotificationInForeground(call, result)
          break
        case "forceUseFCMPushChannel":
          // 仅 Android 支持，OHOS 保持空实现。
          result.success(this.ok())
          break
        case "clearAllNotifications":
          this.clearAllNotifications(result)
          break
        default:
          result.notImplemented()
      }
    } catch (error) {
      result.error("-1", this.errorMessage(error), null)
    }
  }

  private async registerPush(call: MethodCall, result: MethodResult): Promise<void> {
    if (this.context == null) {
      result.error("-1", "UIAbilityContext is null", null)
      return
    }
    const sdkAppId = this.readNumberArg(call, "sdk_app_id");
    const appKey = this.readStringArg(call, "app_key");
    const businessId = this.readNumberArg(call, "business_id");
    const pushResult = await TIMPushManager.getInstance().registerPush(this.context, sdkAppId, appKey, businessId);
    result.success(this.normalizeResult(pushResult))
  }

  private async unRegisterPush(result: MethodResult): Promise<void> {
    const pushResult = await TIMPushManager.getInstance().unRegisterPush();
    result.success(this.normalizeResult(pushResult))
  }

  private async setRegistrationID(call: MethodCall, result: MethodResult): Promise<void> {
    const registrationID = this.readStringArg(call, "registration_id");
    const pushResult = await TIMPushManager.getInstance().setRegistrationID(registrationID);
    result.success(this.normalizeResult(pushResult))
  }

  private async getRegistrationID(result: MethodResult): Promise<void> {
    const pushResult = await TIMPushManager.getInstance().getRegistrationID();
    const normalized = this.normalizeResult(pushResult) as Record<string, ESObject>;
    if (Number(normalized["code"] ?? -1) == 0) {
      normalized["data"] = String(normalized["message"] ?? "");
    }
    result.success(normalized)
  }

  private async addPushListener(call: MethodCall, result: MethodResult): Promise<void> {
    const listenerId = this.readNumberArg(call, "listener_id");
    if (this.listenerMap.has(listenerId)) {
      result.success(this.ok())
      return
    }
    const listener: TIMPushListener = {
      onMessageReceived: (message: TIMPushMessage): void => {
        this.channel?.invokeMethod("onMessageReceived", message);
      },
      onRevokePushMessage: (messageID: string): void => {
        this.channel?.invokeMethod("onRevokePushMessage", messageID);
      },
      onNotificationClicked: (ext: string): void => {
        this.channel?.invokeMethod("onNotificationClicked", ext);
      }
    };
    TIMPushManager.getInstance().addPushListener(listener);
    this.listenerMap.set(listenerId, listener);
    result.success(this.ok())
  }

  private removePushListener(call: MethodCall, result: MethodResult): void {
    const listenerId = this.readNumberArg(call, "listener_id");
    const listener = this.listenerMap.get(listenerId);
    if (listener != undefined) {
      TIMPushManager.getInstance().removePushListener(listener);
      this.listenerMap.delete(listenerId);
    }
    result.success(this.ok())
  }

  private disablePostNotificationInForeground(call: MethodCall, result: MethodResult): void {
    const disable = this.readBoolArg(call, "disable");
    TIMPushManager.getInstance().disablePostNotificationInForeground(disable);
    result.success(this.ok())
  }

  private clearAllNotifications(result: MethodResult): void {
    const setBadgeNumberCallback = (error: ESObject): void => {
      if (error != null && error != undefined) {
        result.error("-1", this.errorMessage(error), null)
        return
      }
      result.success(this.ok())
    };
    notificationManager.setBadgeNumber(0, setBadgeNumberCallback);
  }

  private readStringArg(call: MethodCall, key: string): string {
    try {
      return call.args.get(key) as string;
    } catch (error) {
      return "";
    }
  }

  private readNumberArg(call: MethodCall, key: string): number {
    try {
      const value: ESObject = call.args.get(key) as ESObject;
      if (typeof value === "number") {
        return value;
      }
      return Number(value ?? 0);
    } catch (error) {
      return 0;
    }
  }

  private readBoolArg(call: MethodCall, key: string): boolean {
    try {
      const value: ESObject = call.args.get(key) as ESObject;
      if (typeof value === "boolean") {
        return value;
      }
      return String(value).toLowerCase() == "true";
    } catch (error) {
      return false;
    }
  }

  private normalizeResult(source: ESObject): ESObject {
    if (source == null || typeof source != "object") {
      return this.ok();
    }
    const anySource = source as Record<string, ESObject>;
    return {
      code: Number(anySource["code"] ?? 0),
      message: String(anySource["message"] ?? "ok"),
      data: anySource["data"]
    };
  }

  private ok(): ESObject {
    return {
      code: 0,
      message: "ok",
      data: null
    };
  }

  private errorMessage(error: ESObject): string {
    try {
      return (error as Error).message ?? String(error);
    } catch (_) {
      return String(error);
    }
  }
}
