import Foundation
import Combine

extension AsyncSpy {
    public convenience init<P: Publisher>(
        subject: P,
        file: StaticString = #file,
        line: UInt = #line
    ) where P.Output == Output, P.Failure == Failure {
        self.init(file: file, line: line)
        self.cancellable = subject
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
            switch completion {
                case .finished:
                    self?.completion = .finished
                case .failure(let error):
                    self?.completion = .failure(error)
            }
        }, receiveValue: { [weak self] value in
            self?.values.append(value)
        })
    }
}
