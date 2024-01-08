import Foundation
import XCTest
@testable import AsyncSpy

class AsyncSpyTests: XCTestCase {
    func testThatIndexing_isAsExpected() async {
        let events = [1, 2, 3].publisher
        let spy = AsyncSpy(subject: events)
        
        XCTAssertEqual(spy.nextIndex, 0)
        
        await spy.expect(1)
        
        XCTAssertEqual(spy.values.count, 3)
        XCTAssertEqual(spy.nextIndex, 1)
        
        await spy.expect(2)
        
        XCTAssertEqual(spy.nextIndex, 2)
        
        await spy.expect(3)
    }
}
