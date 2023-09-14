import AsyncHTTPClient
import DiscordBM
import DotEnv

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
///
/// Required intents:
/// - `GUILD_MESSAGES`
/// - `MESSAGE_CONTENT`
///
/// ## Warnings
///
/// Many of the fields here are stateful, there are no guarantees on validity since this doesn't have access to the
/// gateway, this means you should use and drop this struct as fast as you can.
public struct SourceMessage {
    /// The message that will be cloned.
    ///
    /// ## Mutation
    ///
    /// Can be mutated to override some fields, for example to clone it to another channel.
    ///
    /// Since most methods mutate the source, you should mutate the message right before calling
    /// ``SourceMessage/create()``.
    public let message: Gateway.MessageCreate
    let bot: BotGatewayManager
    let webhook: WebhookAddress
    let cache: DiscordCache
    let author: DiscordUser
    let member: Guild.PartialMember
    let guildId: GuildSnowflake

    /// Use the provided message and to initialize this.
    ///
    /// If a webhook called the given name in the channel doesn't exist, creates it.
    public init(
        message: Gateway.MessageCreate,
        bot: BotGatewayManager,
        cache: DiscordCache,
        webhookName: String = "Message Cloner"
    ) async throws {
        self.bot = bot
        self.cache = cache
        self.message = message
        self.author = try message.author.requireValue()
        self.member = try message.member.requireValue()
        self.guildId = try message.guild_id.requireValue()

        let webhook = try await {
            if let webhook = try await bot.client.listChannelWebhooks(channelId: message.channel_id).decode().first(
                where: { $0.token != nil && $0.name == webhookName }
            ) {
                return webhook
            }

            return try await bot.client.createWebhook(
                channelId: message.channel_id,
                payload: Payloads.CreateWebhook(name: webhookName)
            )
            .decode()
        }()

        self.webhook = try WebhookAddress.deconstructed(id: webhook.id, token: webhook.token.requireValue())
    }

    /// Get the message from the cache and initialize this.
    ///
    /// If a webhook called the given name in the channel doesn't exist, creates it.
    public init(
        messageId: MessageSnowflake,
        channelId: ChannelSnowflake,
        bot: BotGatewayManager,
        cache: DiscordCache,
        webhookName: String = "Message Cloner"
    ) async throws {
        let message = try await cache.messages[channelId].requireValue().first { $0.id == messageId }.requireValue()

        try await self.init(message: message, bot: bot, cache: cache, webhookName: webhookName)
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
        guard !containsInvalidComponent() else {
            throw DiscordBMImpostorError.invalidComponent
        }

        try await bot.client.executeWebhook(
            address: webhook,
            payload: Payloads.ExecuteWebhook(
                content: message.content,
                username: message.member?.nick ?? author.username,
                avatar_url: avatarURL(),
                tts: message.tts,
                embeds: message.embeds,
                components: message.components,
                flags: message.flags
            )
        )
        .guardSuccess()
    }

    func containsInvalidComponent() -> Bool {
        if let actionRows = message.components {
            for actionRow in actionRows {
                for component in actionRow.components {
                    if case let .button(button) = component {
                        if button.url == nil {
                            return true
                        }
                    } else {
                        return true
                    }
                }
            }
        }

        return false
    }

    func avatarURL() throws -> String {
        if let memberAvatar = member.avatar {
            return CDNEndpoint.guildMemberAvatar(guildId: guildId, userId: author.id, avatar: memberAvatar).url
        }

        if let userAvatar = author.avatar {
            return CDNEndpoint.userAvatar(userId: author.id, avatar: userAvatar).url
        }

        return CDNEndpoint.defaultUserAvatar(discriminator: author.discriminator).url
    }
}
