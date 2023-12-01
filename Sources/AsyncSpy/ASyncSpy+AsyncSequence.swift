import Foundation
import Combine

extension AsyncSpy where Failure == Error {
    public convenience init<S: AsyncSequence>(
        subject: S,
        file: StaticString = #file,
        line: UInt = #line
    ) where S.Element == Output {
        self.init(file: file, line: line)
        
        let task = Task {
            do {
                for try await value in subject {
                    values.append(value)
                }
                
                completion = .finished
            } catch {
                completion = .failure(error)
            }
        }
        
        self.cancellable = AnyCancellable { task.cancel() }
    }
}
