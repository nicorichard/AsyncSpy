import Foundation
import Combine

extension AsyncSpy where Output: Equatable {
    public func expectAny(file: StaticString = #file, line: UInt = #line) async {
        do {
            try await next()
        } catch {
            handleError(error, file: file, line: line)
        }
    }
    
    public func expect(file: StaticString = #file, line: UInt = #line, _ expected: Output) async {
        await expect(file: file, line: line, { expected })
    }
    
    public func expect(file: StaticString = #file, line: UInt = #line, _ expected: () -> Output) async {
        do {
            let value = try await next()
            
            if value != expected() {
                XCTFail("(\"\(value)\") is not equal to (\"\(expected())\")", file: file, line: line)
            }
        } catch {
            handleError(error, file: file, line: line)
        }
    }
    
    public func expectError(file: StaticString = #file, line: UInt = #line) async {
        switch await completion() {
            case .failure:
                break
            case .finished:
                XCTFail("Subject completed without any error", file: file, line: line)
            case .none:
                XCTFail("Subject did not produce an error", file: file, line: line)
        }
    }
    
    public func expectMutation(file: StaticString = #file, line: UInt = #line, _ mutate: (inout Output) -> Void) async {
        do {
            if values.count <= index {
                XCTFail("Subject has not produced a value yet.", file: file, line: line)
            }
            
            var current = values[index]
            let next = try await next()
            
            mutate(&current)
            
            if next != current {
                XCTFail("(\"\(next)\") is not equal to (\"\(current)\")", file: file, line: line)
            }
        } catch {
            handleError(error, file: file, line: line)
        }
    }
    
    private func handleError(_ error: Error, file: StaticString, line: UInt) {
        switch error {
            case AsyncSpyError.completed:
                XCTFail("Subject has already completed", file: file, line: line)
            case AsyncSpyError.completedWhileWaiting:
                XCTFail("Subject completed before producing a value", file: file, line: line)
            default:
                XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }
}
