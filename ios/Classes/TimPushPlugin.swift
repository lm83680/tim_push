import Flutter
import UIKit
import UserNotifications
import TIMPush

public class TimPushPlugin: NSObject, FlutterPlugin {
  public static let shared = TimPushPlugin()
  public var attachedToEngine = false
  public var channel: FlutterMethodChannel?

  private let nativePushListener = TimPushNativePushListener()
  private var nativePushListenerRegistered = false
  private var listenerIDs: Set<Int> = []

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = shared
    instance.channel = FlutterMethodChannel(name: "tim_push", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: instance.channel!)
    instance.attachedToEngine = true
    instance.nativePushListener.plugin = instance
    disableAutoRegisterPush()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "registerPush":
      registerPush(call: call, result: result)
    case "unRegisterPush":
      unRegisterPush(result: result)
    case "setRegistrationID":
      setRegistrationID(call: call, result: result)
    case "getRegistrationID":
      getRegistrationID(result: result)
    case "addPushListener":
      addPushListener(call: call, result: result)
    case "removePushListener":
      removePushListener(call: call, result: result)
    case "disablePostNotificationInForeground":
      disablePostNotificationInForeground(call: call, result: result)
    case "forceUseFCMPushChannel":
      // 仅 Android 支持，iOS 保持空实现。
      result(nil)
    case "clearAllNotifications":
      clearAllNotifications(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func toFlutterMethod(_ methodName: String, data: Any?) {
    if attachedToEngine {
      channel?.invokeMethod(methodName, arguments: data)
    } else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
        self?.toFlutterMethod(methodName, data: data)
      }
    }
  }

  func invokeListener(method: String, data: Any?) {
    toFlutterMethod(method, data: data)
  }

  private func registerPush(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let sdkAppId: Int32 = Int32(readInt(call: call, key: "sdk_app_id") ?? 0)
    let appKey: String = readString(call: call, key: "app_key") ?? ""
    TIMPushManager.registerPush(
      sdkAppId,
      appKey: appKey,
      succ: { _ in
        result(nil)
      },
      fail: { code, message in
        result(FlutterError(code: String(code), message: message, details: nil))
      }
    )
  }

  private func unRegisterPush(result: @escaping FlutterResult) {
    TIMPushManager.unRegisterPush(
      {
        result(nil)
      },
      fail: { code, message in
        result(FlutterError(code: String(code), message: message, details: nil))
      }
    )
  }

  private func setRegistrationID(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let registrationID: String = readString(call: call, key: "registration_id") ?? ""
    TIMPushManager.setRegistrationID(registrationID) {
      result(nil)
    }
  }

  private func getRegistrationID(result: @escaping FlutterResult) {
    TIMPushManager.getRegistrationID { registrationID in
      result(registrationID)
    }
  }

  private func addPushListener(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let listenerID: Int = readInt(call: call, key: "listener_id") ?? 0
    listenerIDs.insert(listenerID)
    if !nativePushListenerRegistered {
      TIMPushManager.addPushListener(listener: nativePushListener)
      nativePushListenerRegistered = true
    }
    result(nil)
  }

  private func removePushListener(call: FlutterMethodCall, result: @escaping FlutterResult) {
    if let listenerID = readInt(call: call, key: "listener_id") {
      listenerIDs.remove(listenerID)
    } else {
      listenerIDs.removeAll()
    }
    if listenerIDs.isEmpty && nativePushListenerRegistered {
      TIMPushManager.removePushListener(listener: nativePushListener)
      nativePushListenerRegistered = false
    }
    result(nil)
  }

  private func disablePostNotificationInForeground(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let disable: Bool = readBool(call: call, key: "disable") ?? false
    TIMPushManager.disablePostNotificationInForeground(disable: disable)
    result(nil)
  }

  private func clearAllNotifications(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    UIApplication.shared.applicationIconBadgeNumber = 0
    result(nil)
  }

  private static func disableAutoRegisterPush() {
    TIMPushManager.callExperimentalAPI(
      "disableAutoRegisterPush",
      param: NSNull(),
      succ: { _ in },
      fail: { _, _ in }
    )
  }

  private func readString(call: FlutterMethodCall, key: String) -> String? {
    guard let args = call.arguments as? [String: Any], let value = args[key] else {
      return nil
    }
    return value as? String ?? String(describing: value)
  }

  private func readInt(call: FlutterMethodCall, key: String) -> Int? {
    guard let args = call.arguments as? [String: Any], let value = args[key] else {
      return nil
    }
    if let intValue = value as? Int {
      return intValue
    }
    if let int32Value = value as? Int32 {
      return Int(int32Value)
    }
    if let stringValue = value as? String {
      return Int(stringValue)
    }
    return nil
  }

  private func readBool(call: FlutterMethodCall, key: String) -> Bool? {
    guard let args = call.arguments as? [String: Any], let value = args[key] else {
      return nil
    }
    if let boolValue = value as? Bool {
      return boolValue
    }
    if let stringValue = value as? String {
      return NSString(string: stringValue).boolValue
    }
    return nil
  }
}

private final class TimPushNativePushListener: NSObject, TIMPushListener {
  weak var plugin: TimPushPlugin?

  func onRecvPushMessage(_ message: TIMPushMessage) {
    var payload: [String: Any] = [:]
    payload["messageID"] = message.messageID
    payload["title"] = message.title
    payload["desc"] = message.desc
    payload["ext"] = message.ext
    plugin?.invokeListener(method: "onRecvPushMessage", data: payload)
  }

  func onRevokePushMessage(_ messageID: String) {
    plugin?.invokeListener(method: "onRevokePushMessage", data: messageID)
  }

  func onNotificationClicked(_ ext: String) {
    plugin?.invokeListener(method: "onNotificationClicked", data: ext)
  }
}
