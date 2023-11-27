import Foundation

#if DEBUG
public func XCTFail(
    _ message: String,
    file: StaticString = #file,
    line: UInt = #line
) {
    handler(nil, true, "\(file)", line, message, nil)
}

private typealias XCTFailureHandler = @convention(c) (
    AnyObject?, Bool, UnsafePointer<CChar>, UInt, String, String?
) -> Void

private let handler = unsafeBitCast(
    dlsym(dlopen(nil, RTLD_LAZY), "_XCTFailureHandler"),
    to: XCTFailureHandler.self
)
#else
public func XCTFail(
    _: String = "",
    file _: StaticString = #file,
    line _: UInt = #line
) {}
#endif
