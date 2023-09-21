class MessageReferenceTests: BaseTestCase {
    func testTruncated() async throws {
        let referencedMessage = try await createMessage(.init(content: "012345678901234567890"))
        let message = try await createMessage(
            .init(
                content: "message reference truncated",
                message_reference: .init(
                    message_id: referencedMessage.id,
                    channel_id: referencedMessage.channel_id,
                    guild_id: referencedMessage.guild_id!
                )
            )
        )

        try await sourceMessage(message: .given(message: message)).create()
    }

    func testNotTruncated() async throws {
        let referencedMessage = try await createMessage(.init(content: "01234567890123456789"))
        let message = try await createMessage(
            .init(
                content: "message reference not truncated",
                message_reference: .init(
                    message_id: referencedMessage.id,
                    channel_id: referencedMessage.channel_id,
                    guild_id: referencedMessage.guild_id!
                )
            )
        )

        try await sourceMessage(message: .given(message: message)).create()
    }
}
