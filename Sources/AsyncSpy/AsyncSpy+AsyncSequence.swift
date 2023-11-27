import Foundation

extension AsyncSpy: AsyncSequence {
    public typealias AsyncIterator = AsyncSpy<Output, Failure>.Iterator
    public typealias Element = Output
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(values: { self.values }, next: next)
    }
    
    public struct Iterator : AsyncIteratorProtocol {
        var index: Int = 0
        let values: () -> [Output]
        let next: () async throws -> Output?
        
        public mutating func next() async -> Output? {
            let values = self.values()
            
            if values.count > index {
                let value = values[index]
                index += 1
                return value
            }
            
            do {
                return try await next()
            } catch {
                return nil
            }
        }

        public typealias Element = Output
    }
}
