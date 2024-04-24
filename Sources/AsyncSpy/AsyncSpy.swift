import Foundation
import Combine

enum AsyncSpyError: Error {
    case timeout
    case completed
    case completedWhileWaiting
}

public class AsyncSpy<Output, Failure: Error> {
    public enum Exhaustivity {
        case on(requireCompletion: Bool)
        case off
    }
    
    public enum Completion {
        case finished
        case failure(Failure)
    }
    
    var cancellable: AnyCancellable?
    
    @Published var nextIndex: Int = 0
    @Published var values: [Output] = []
    @Published var completion: Completion?
    
    let file: StaticString
    let line: UInt
    let timeout: Int
    let exhaustivity: Exhaustivity
    
    public init(
        file: StaticString,
        line: UInt,
        timeout: Int = 10,
        exhaustivity: Exhaustivity = .on(requireCompletion: false)
    ) {
        self.file = file
        self.line = line
        self.timeout = timeout
        self.exhaustivity = exhaustivity
    }
    
    deinit {
        switch exhaustivity {
            case .on(let requireCompletion):
                if requireCompletion && completion == nil {
                    XCTFail("Subject did not complete", file: file, line: line)
                }
                if values.count > nextIndex {
                    XCTFail("Did not exhaust all values. Values remaining: \(values[nextIndex...])", file: file, line: line)
                }
            case .off:
                break
        }
    }
    
    @MainActor
    @discardableResult
    func next() async throws -> Output {
        defer { nextIndex += 1 }
        
        if completion != nil && values.count <= nextIndex {
            throw AsyncSpyError.completed
        }

        let publisher = $values
            .subscribe(on: RunLoop.main)
            .drop(while: { $0.count <= self.nextIndex })
            .timeout(.seconds(timeout), scheduler: RunLoop.main)
        
        for await value in publisher.values {
            return value[nextIndex]
        }
        
        throw AsyncSpyError.completedWhileWaiting
    }
    
    @MainActor
    @discardableResult
    public func completion() async -> Completion? {
        var iterator = completion.publisher
            .compactMap { $0 }
            .timeout(.seconds(timeout), scheduler: RunLoop.main)
            .values
            .makeAsyncIterator()
        
        return await iterator.next()
    }
}

extension AsyncSpy {
    @MainActor
    public func next(@_implicitSelfCapture _ body: (Output) async throws -> Void) async throws {
        try await body(try await next())
    }
}
