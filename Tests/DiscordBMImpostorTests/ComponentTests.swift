import DiscordBM
import DiscordBMImpostor

class ComponentTests: BaseTestCase {
    func testComponent() async throws {
        let message = try await createMessage(
            .init(components: [.init(arrayLiteral: .button(.init(label: "wöæo", url: "https://youtu.be/jPx_ZWKYRCE")))])
        )

        try await sourceMessage(from: message).create()
    }
}
