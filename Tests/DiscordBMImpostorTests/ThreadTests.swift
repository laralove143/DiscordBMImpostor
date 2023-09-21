import DiscordBM
import DiscordBMImpostor

class ThreadTests: BaseTestCase {
    func testRegular() async throws {
        let thread = try await bot.client.createThread(
            channelId: channelId, payload: .init(name: "thread", type: .publicThread)
        )
        .decode()

        let message = try await createMessage(.init(content: "thread"), channelId: thread.id)

        try await sourceMessage(message: .fromCache(messageID: message.id, channelID: message.channel_id)).create()
    }

    func testPost() async throws {
        let thread = try await bot.client.startThreadInForumChannel(
            channelId: forumChannelId, payload: .init(name: "post", message: .init(content: "post"))
        )
        .decode()

        try await sourceMessage(
            message: .fromCache(messageID: Snowflake(thread.id), channelID: Snowflake(thread.id))
        )
        .create()
    }
}
