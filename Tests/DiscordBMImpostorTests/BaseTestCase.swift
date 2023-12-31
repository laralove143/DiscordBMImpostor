import AsyncHTTPClient
import DiscordBM
import DiscordBMImpostor
@testable import DiscordModels
import DotEnv
import XCTest

// swiftlint:disable test_case_accessibility
class BaseTestCase: XCTestCase {
    var token: String!
    var channelId: ChannelSnowflake!
    var forumChannelId: ChannelSnowflake!

    var bot: BotGatewayManager!
    var cache: DiscordCache!

    var events: AsyncStream<Gateway.Event>!

    override func setUp() async throws {
        if token == nil || channelId == nil || forumChannelId == nil {
            let dotEnvFileURL = URL(filePath: #file)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appending(path: ".env")

            do {
                try DotEnv.load(path: dotEnvFileURL.path())
            } catch {
                print("not using .env file: \(error)")
            }

            token = ProcessInfo.processInfo.environment["TOKEN"]!
            channelId = ChannelSnowflake(ProcessInfo.processInfo.environment["CHANNEL_ID"]!)
            forumChannelId = ChannelSnowflake(ProcessInfo.processInfo.environment["FORUM_CHANNEL_ID"]!)
        }

        let http = HTTPClient(eventLoopGroupProvider: .singleton)
        bot = await BotGatewayManager(
            eventLoopGroup: http.eventLoopGroup,
            httpClient: http,
            token: token,
            intents: [.guildMessages, .messageContent, .guilds]
        )

        await bot.connect()

        cache = await DiscordCache(gatewayManager: bot, intents: .all, requestAllMembers: .disabled)
        events = await bot.makeEventsStream()

        for await event in events {
            if case .ready? = event.data {
                break
            }
        }
    }

    override func tearDown() {
        bot = nil
        cache = nil
    }

    func createMessage(
        _ messagePayload: Payloads.CreateMessage, channelId: ChannelSnowflake? = nil
    ) async throws -> Gateway.MessageCreate {
        let finalChannelId = channelId ?? self.channelId!

        let message = try await bot.client.createMessage(channelId: finalChannelId, payload: messagePayload).decode()

        for await event in events {
            if case let .messageCreate(messageCreate) = event.data, messageCreate.id == message.id {
                return messageCreate
            }
        }

        fatalError("events exhausted")
    }

    func sourceMessage(message: SourceMessage.MessageProvider) async throws -> SourceMessage {
        try await SourceMessage(message: message, bot: bot, cache: cache)
    }
}
// swiftlint:enable test_case_accessibility
