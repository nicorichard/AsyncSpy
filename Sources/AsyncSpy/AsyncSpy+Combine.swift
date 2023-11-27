import Foundation
import Combine

extension AsyncSpy {
    public convenience init<P: Publisher>(subject: P) where P.Output == Output, P.Failure == Failure {
        self.init()
        self.cancellable = subject.sink(receiveCompletion: { [weak self] completion in
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
