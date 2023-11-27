import Foundation
import Combine

enum AsyncSpyError: Error {
    case timeout
    case completed
    case completedWhileWaiting
}

public class AsyncSpy<Output, Failure: Error> {
    public enum Exhaustivity {
        case all(requireCompletion: Bool)
        case none
    }
    
    public enum Completion {
        case finished
        case failure(Failure)
    }
    
    var cancellable: AnyCancellable?
    
    @Published var index: Int = 0
    @Published var values: [Output] = []
    @Published var completion: Completion?
    
    let file: StaticString
    let line: UInt
    
    // TODO: Expose
    private let timeout: Int = 10
    private let exhaustivity: Exhaustivity = .all(requireCompletion: false)
    
    init(file: StaticString, line: UInt) {
        self.file = file
        self.line = line
    }
    
    deinit {
        switch exhaustivity {
            case .all(let requireCompletion):
                if requireCompletion && completion == nil {
                    XCTFail("Subject did not complete", file: file, line: line)
                }
                if values.count > index {
                    XCTFail("Did not exhaust all values. Values remaining: \(values[index...])", file: file, line: line)
                }
            case .none:
                break
        }
        
    }
    
    @MainActor
    @discardableResult
    func next() async throws -> Output {
        defer { index += 1 }
        
        if completion != nil && values.count <= index {
            throw AsyncSpyError.completed
        }

        var iterator = $values
            .drop(while: { $0.count <= self.index })
            .timeout(.seconds(timeout), scheduler: RunLoop.main)
            .values
            .makeAsyncIterator()
        
        guard let next = await iterator.next() else {
            throw AsyncSpyError.completedWhileWaiting
        }
        
        return next[index]
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
    public func next(_ body: (Output) -> Void) async throws {
        body(try await next())
    }
}
