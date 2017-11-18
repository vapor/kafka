import Dispatch

/// A future result type.
/// Concretely implemented by `Future<T>`
public protocol FutureType {
    associatedtype Expectation
    func addAwaiter(callback: @escaping ResultCallback)
}

// MARK: Convenience

extension FutureType {
    /// This future's result type.
    public typealias Result = FutureResult<Expectation>

    /// Callback for accepting a result.
    public typealias ResultCallback = ((Result) -> ())

    /// Callback for accepting the expectation.
    public typealias ExpectationCallback = ((Expectation) -> ())

    /// Callback for accepting an error.
    public typealias ErrorCallback = ((Error) -> ())

    /// Callback for accepting the expectation.
    public typealias ExpectationMapCallback<T> = ((Expectation) throws -> (T))

    /// Adds a handler to be asynchronously executed on
    /// completion of this future.
    ///
    /// Will *not* be executed if an error occurs
    ///
    /// http://localhost:8000/async/promise-future-introduction/#on-future-completion
    public func then(callback: @escaping ExpectationCallback) -> Self {
        addAwaiter { result in
            guard let ex = result.expectation else {
                return
            }

            callback(ex)
        }
        
        return self
    }

    /// Adds a handler to be asynchronously executed on
    /// completion of this future.
    ///
    /// Will *only* be executed if an error occurred.
    //// Successful results will not call this handler.
    ///
    /// http://localhost:8000/async/promise-future-introduction/#on-future-completion
    public func `catch`(callback: @escaping ErrorCallback) {
        addAwaiter { result in
            guard let er = result.error else {
                return
            }

            callback(er)
        }
    }

    /// Maps a future to a future of a different type.
    ///
    /// http://localhost:8000/async/promise-future-introduction/#mapping-results
    public func map<T>(to type: T.Type = T.self, callback: @escaping ExpectationMapCallback<T>) -> Future<T> {
        let promise = Promise(T.self)

        then { expectation in
            do {
                let mapped = try callback(expectation)
                promise.complete(mapped)
            } catch {
                promise.fail(error)
            }
        }.catch { error in
            promise.fail(error)
        }

        return promise.future
    }

    /// Waits until the specified time for a result.
    ///
    /// Will return the results when available unless the specified
    /// time has been reached, in which case it will timeout
    ///
    /// http://localhost:8000/async/promise-future-introduction/#synchronous-apis
    public func blockingAwait(deadline time: DispatchTime = .distantFuture) throws -> Expectation {
        let semaphore = DispatchSemaphore(value: 0)
        var awaitedResult: FutureResult<Expectation>?

        addAwaiter { result in
            awaitedResult = result
            semaphore.signal()
        }

        guard semaphore.wait(timeout: time) == .success else {
            throw PromiseTimeout(expecting: Expectation.self)
        }

        return try awaitedResult!.unwrap()
    }

    /// Waits for the specified duration for a result.
    ///
    /// Will return the results when available unless the specified timeout has been reached, in which case it will timeout
    ///
    /// http://localhost:8000/async/promise-future-introduction/#synchronous-apis
    public func blockingAwait(timeout interval: DispatchTimeInterval) throws -> Expectation {
        return try blockingAwait(deadline: DispatchTime.now() + interval)
    }
}

// MARK: Array


extension Array where Element: FutureType {
    /// Flattens an array of future results into one
    /// future array result.
    ///
    /// http://localhost:8000/async/advanced-futures/#combining-multiple-futures
    public func flatten() -> Future<[Element.Expectation]> {
        let promise = Promise<[Element.Expectation]>()

        var elements: [Element.Expectation] = []
        elements.reserveCapacity(self.count)

        var iterator = makeIterator()
        func handle(_ future: Element) {
            future.then { res in
                elements.append(res)
                if let next = iterator.next() {
                    handle(next)
                } else {
                    promise.complete(elements)
                }
            }.catch { error in
                promise.fail(error)
            }
        }

        if let first = iterator.next() {
            handle(first)
        } else {
            promise.complete(elements)
        }

        return promise.future
    }
}
