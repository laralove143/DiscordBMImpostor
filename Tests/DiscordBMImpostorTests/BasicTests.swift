import DiscordBM
import DiscordBMImpostor
import XCTest

class BasicTests: BaseTestCase {
    func testBasic() async throws {
        let message = try await createMessage(.init(content: "basic message"))

        try await sourceMessage(message: .given(message: message)).create()
    }
}
