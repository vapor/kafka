/// A promise is a variable that can be completed when it's ready
///
/// It can be transformed into a future which can only be read
///
/// http://localhost:8000/async/promise-future-introduction/#creating-a-promise
public final class Promise<T> {
    /// This promise's future.
    public let future: Future<T>

    /// Create a new promise.
    public init(_ expectation: T.Type = T.self) {
        future = .init()
    }

    /// Fail to fulfill the promise.
    /// If the promise has already been fulfilled,
    /// it will quiety ignore the input.
    ///
    /// http://localhost:8000/async/promise-future-introduction/#creating-a-promise
    public func fail(_ error: Error) {
        future.complete(with: .error(error))
    }

    /// Fulfills the promise.
    /// If the promise has already been fulfilled,
    /// it will quiety ignore the input.
    ///
    /// http://localhost:8000/async/promise-future-introduction/#creating-a-promise
    public func complete(_ expectation: T) {
        future.complete(with: .expectation(expectation))
    }
}
