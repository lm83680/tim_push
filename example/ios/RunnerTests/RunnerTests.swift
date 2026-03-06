import Flutter
import UIKit
import XCTest


@testable import tim_push

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testUnknownMethod() {
    let plugin = TimPushPlugin()

    let call = FlutterMethodCall(methodName: "unknown_method", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertTrue((result as AnyObject) === (FlutterMethodNotImplemented as AnyObject))
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
