import XCTest
import AsyncSpy

private class State: ObservableObject {
    @Published var username: String = ""

    func login() {
        Task {
            username = "Nico"
        }
    }
}

class OrderingProblemTests: XCTestCase {
    func test_fails_withSimpleStateAccess() {
        let state = State()

        state.login()

        // This assertion will fail 1% of the time
        XCTAssertEqual(state.username, "")
    }

    func test_fails_withCombineSinkAccess() async {
        let state = State()
        state.login()

        let expectation = self.expectation(description: "Login Result")

        let cancellable = state.$username
            .dropFirst()
            .sink {
                expectation.fulfill()

                // This assertion will fail 33% of the time
                XCTAssertEqual($0, "Nico")
            }

        await fulfillment(of: [expectation], timeout: 1)
    }

    func test_fails_withAsyncPublisherAccess() async {
        let state = State()

        let expectation = self.expectation(description: "Login Result")
        Task {
            defer { expectation.fulfill() }

            var first: String?
            for await value in state.$username.values {
                first = value
                break
            }

            // This assertion will fail 33% of the time
            XCTAssertEqual(first, "Nico")
        }

        await fulfillment(of: [expectation], timeout: 1)
    }
}

class OrderingSolutionTests: XCTestCase {
    func test_usingAsyncSpy_isConsistentEvenWithOddOrdering() async {
        let state = State()
        let spy = AsyncSpy(subject: state.$username)

        state.login()
        await spy.expect("")
        await spy.expect("Nico")
    }

    func test_usingAsyncSpy_isConsistentWithBestOrdering() async {
        let state = State()
        let spy = AsyncSpy(subject: state.$username)

        await spy.expect("")
        state.login()
        await spy.expect("Nico")
    }
}
