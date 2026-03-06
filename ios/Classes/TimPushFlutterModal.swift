import Foundation

public class TimPushFlutterModal: NSObject {
  public static let shared = TimPushFlutterModal()

  public var busId: Int32 = 0
  public var applicationGroupID: String = ""

  private override init() {
    super.init()
  }

  public func offlinePushCertificateID() -> Int32 {
    return busId
  }
}
