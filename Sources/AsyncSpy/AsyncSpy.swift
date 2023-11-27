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
    
    private(set) var index: Int = 0
    @Published internal(set) public var values: [Output] = []
    @Published internal(set) public var completion: Completion?
    
    // TODO: Expose
    private let timeout: Int = 10
    private let exhaustivity: Exhaustivity = .all(requireCompletion: false)
    
    deinit {
        switch exhaustivity {
            case .all(let requireCompletion):
                if requireCompletion && completion == nil {
                    XCTFail("Subject did not complete")
                }
                if values.count > index {
                    XCTFail("Did not exhaust all values. Values remaining: \(values[index...])")
                }
            case .none:
                break
        }
        
    }
    
    @MainActor
    @discardableResult
    public func next() async throws -> Output {
        defer { index += 1 }
        
        if values.count > index {
            return values[index]
        }
        
        if completion != nil {
            throw AsyncSpyError.completed
        }
        
        var iterator = $values
            .dropFirst()
            .timeout(.seconds(timeout), scheduler: RunLoop.main)
            .values
            .makeAsyncIterator()
        
        guard let next = await iterator.next() else {
            throw AsyncSpyError.completedWhileWaiting
        }
        
        return next.last!
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
