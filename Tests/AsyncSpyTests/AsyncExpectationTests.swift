import Foundation
import XCTest
import Combine
@testable import AsyncSpy

class AsyncExpectationTests: XCTestCase {
    func test_valueExpectationForSimplePublisher() async throws {
        let subject = PassthroughSubject<Int, Never>()
        
        let spy = AsyncSpy(subject: subject)
        
        subject.send(1)
        subject.send(2)
        
        await spy.expect(1)
        await spy.expect(2)
    }
    
    func testExample_3() async throws {
        struct State: Equatable {
            var title: String
        }
        
        let subject = PassthroughSubject<State, Never>()
        
        let spy = AsyncSpy(subject: subject)
        
        subject.send(State(title: "1"))
        subject.send(State(title: "2"))
        
        await spy.expectAny()
        await spy.expectMutation {
            $0.title = "2"
        }
    }
    
    func testExample_4() async throws {
        struct TestError: Error {}
        let subject = PassthroughSubject<Int, TestError>()
        
        let spy = AsyncSpy(subject: subject)
        
        subject.send(completion: .failure(TestError()))
        
        await spy.expectError()
    }
    
    func testExample_5() async throws {
        let subject = [1, 2, 3].publisher
        
        let spy = AsyncSpy(subject: subject.values)
        
        await spy.expect(1)
        await spy.expect(2)
        await spy.expect(3)
    }
}
