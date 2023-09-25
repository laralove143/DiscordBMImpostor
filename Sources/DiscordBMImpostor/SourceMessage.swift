import AsyncHTTPClient
import DiscordBM
import Foundation

// TODO: Change ID to Id
// TODO: Check for unnecessary self.

/// A message that can be cloned.
///
/// ## Caching
///
/// In an opinionated way, this library uses caching wherever possible, this is because supporting both would greatly
/// increase this library's API complexity.
///
/// Messages also require the `member` property for this library to function properly, which is only sent over the
/// gateway.
///
/// ## Required Permissions/Intents
///
/// Required permissions in all channels:
/// - `VIEW_CHANNEL`
/// - `MANAGE_WEBHOOKS`
/// - `MANAGE_THREADS`
///
/// Required intents:
/// - `GUILDS`
/// - `GUILD_MESSAGES`
/// - `MESSAGE_CONTENT`
///
/// ## Warnings
///
/// Many of the fields here are stateful, there are no guarantees on validity since this doesn't have access to the
/// gateway, this means you should use and drop this struct as fast as you can.
public struct SourceMessage {
    /// Defines how to get the message
    public enum MessageProvider {
        /// Get the message from the cache
        case fromCache(messageID: MessageSnowflake, channelID: ChannelSnowflake)
        /// Use the provided message
        case given(message: Gateway.MessageCreate)

        func resolve(cache: DiscordCache) async throws -> Gateway.MessageCreate {
            switch self {
            case let .fromCache(messageID, channelID):
                return try await cache.messages[channelID].requireValue().first { $0.id == messageID }.requireValue()

            case .given(let message):
                return message
            }
        }
    }

    /// The message that will be cloned.
    ///
    /// ## Mutation
    ///
    /// Can be mutated to override some fields, for example to clone it to another channel.
    ///
    /// Since most methods mutate the source, you should mutate the message right before calling
    /// ``SourceMessage/create()``.
    public var message: Gateway.MessageCreate

    let bot: BotGatewayManager
    let webhook: WebhookAddress
    let cache: DiscordCache

    /// Use the provided message and to initialize this.
    ///
    /// If a webhook called the given name in the channel doesn't exist, creates it.
    ///
    /// ## Message References
    ///
    /// If `ignoreReferencedMessage` is `false`, the message has less than 10 embeds and the message is cached, an
    /// embed showing the referenced message is added to the cloned message.
    ///
    /// The content of the embed is as follows:
    /// - Title: Reply to
    /// - Description: First 20 characters of the message, "..." is added if it was truncated
    /// - URL: The referenced message's URL
    /// - Author: The name and avatar of the referenced message's author
    ///
    /// You can mutate the last embed in the message to adjust it to your specific needs.
    public init(
        message messageProvider: MessageProvider,
        bot: BotGatewayManager,
        cache: DiscordCache,
        webhookName: String = "Message Cloner",
        ignoreReferencedMessage: Bool = false
    ) async throws {
        self.bot = bot
        self.cache = cache

        message = try await messageProvider.resolve(cache: cache)

        webhook = try await bot.client.findOrCreateWebhook(
            channelID: try await message.threadParentId(cache: cache) ?? message.channel_id, name: webhookName
        )
        .address()

        if !ignoreReferencedMessage {
            try await message.addReferencedMessageEmbed(cache: cache)
        }
    }

    /// Execute a webhook using the given source.
    ///
    /// ## Rate-limits
    ///
    /// Because rate-limits for webhook executions can't be handled beforehand, retries each execution up to 5 times,
    /// if all of these are rate-limited, throws an error.
    ///
    /// - Throws: ``DiscordBMImpostorError/invalidComponent`` if the message has a non-link component
    public func create() async throws {
        guard message.componentsAreOnlyURL() else {
            throw DiscordBMImpostorError.invalidComponent
        }

        try await bot.client.executeWebhook(
            address: webhook,
            threadId: message.threadParentId(cache: cache) != nil ? message.channel_id : nil,
            payload: Payloads.ExecuteWebhook(
                content: message.content,
                username: message.sanitizedNameForWebhook(),
                avatar_url: message.avatarURL(),
                tts: message.tts,
                embeds: message.embeds,
                components: message.components,
                flags: message.flags
            )
        )
        .guardSuccess()
    }
}
