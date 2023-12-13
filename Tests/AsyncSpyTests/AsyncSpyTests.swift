import XCTest
import Combine
@testable import AsyncSpy


final class AsyncSpyNextTests: XCTestCase {
    func test_nextOnSimpleSynchronousPublish() async throws {
        let subject = PassthroughSubject<Int, Never>()
        
        let spy = AsyncSpy(subject: subject)
        
        subject.send(1)
        subject.send(2)
        
        try await spy.next {
            XCTAssertEqual($0, 1)
        }
        
        try await spy.next {
            XCTAssertEqual($0, 2)
        }
    }
    
    func test_lateSubscribeToCurrentValueSubject() async throws {
        let subject = CurrentValueSubject<Int, Never>(1)
        let spy = AsyncSpy(subject: subject)
        await spy.expect(1)
    }
    
    func test_nextOnImmediateDebounce() async throws {
        let subject = PassthroughSubject<Int, Never>()
        let publisher = subject.debounce(for: 0, scheduler: ImmediateScheduler.shared)
        
        let spy = AsyncSpy(subject: publisher)
        
        subject.send(1)
        subject.send(2)

        try await spy.next {
            XCTAssertEqual($0, 1)
        }
        
        try await spy.next {
            XCTAssertEqual($0, 2)
        }
    }
    
    func test_nextOnRunloopMainDebounce() async throws {
        let subject = PassthroughSubject<Int, Never>()
        let publisher = subject.debounce(for: 0, scheduler: RunLoop.main)
        
        let spy = AsyncSpy(subject: publisher)
        
        subject.send(1)
        
        try await spy.next {
            XCTAssertEqual($0, 1)
        }
        
        subject.send(2)
        
        try await spy.next {
            XCTAssertEqual($0, 2)
        }
    }
}
