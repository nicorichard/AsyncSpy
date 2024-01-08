import Foundation
import XCTest
import AsyncSpy

private class State: ObservableObject {
    @Published var username: String = ""
    
    func login() {
        Task {
            try await Task.sleep(nanoseconds: 10)
            username = "Nico"
        }
    }
}

class ObservableObjectTests: XCTestCase {
    func testViewModelStyleLogin() async throws {
        let state = State()
        
        let spy = AsyncSpy(subject: state.$username)
        
        await spy.expect("")
        
        state.login()
        
        await spy.expect("Nico")
    }
}
