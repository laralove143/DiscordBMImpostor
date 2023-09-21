import AsyncHTTPClient
import DiscordBM
import Foundation

// TODO: Change Id to ID

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
    var threadId: ChannelSnowflake?
    let author: DiscordUser
    let member: Guild.PartialMember
    let guildId: GuildSnowflake

    var username: String {
        member.nick ?? author.username
    }

    /// Use the provided message and to initialize this.
    ///
    /// If a webhook called the given name in the channel doesn't exist, creates it.
    ///
    /// ## Message References
    ///
    /// If `ignoreReferencedMessage` is `false` and the message has less than 20 embeds, an embed showing the referenced
    /// message is added to the cloned message.
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
        self.message = try await messageProvider.resolve(cache: cache)
        self.author = try message.author.requireValue()
        self.member = try message.member.requireValue()
        self.guildId = try message.guild_id.requireValue()

        var channelId = message.channel_id
        if let thread = try await cache.guilds[guildId].requireValue().threads.first(where: { $0.id == channelId }) {
            self.threadId = thread.id
            channelId = try Snowflake(thread.parent_id.requireValue())
        }

        if let foundWebhook = try await bot.client.listChannelWebhooks(channelId: message.channel_id).decode().first(
            where: { $0.token != nil && $0.name == webhookName }
        ) {
            webhook = try foundWebhook.address()
        } else {
            webhook = try await bot.client.createWebhook(
                channelId: message.channel_id,
                payload: Payloads.CreateWebhook(name: webhookName)
            )
            .decode()
            .address()
        }

        if !ignoreReferencedMessage {
            try addReferencedMessageEmbed()
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
        guard !containsInvalidComponent() else {
            throw DiscordBMImpostorError.invalidComponent
        }

        try await bot.client.executeWebhook(
            address: webhook,
            threadId: threadId,
            payload: Payloads.ExecuteWebhook(
                content: message.content,
                username: username,
                avatar_url: avatarURL(),
                tts: message.tts,
                embeds: message.embeds,
                components: message.components,
                flags: message.flags
            )
        )
        .guardSuccess()
    }

    func avatarURL() -> String {
        DiscordBMImpostor.avatarURL(member: member, user: author, guildId: guildId)
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

    mutating func addReferencedMessageEmbed() throws {
        let contentTruncateCount = 20

        guard let referencedMessageBox = message.referenced_message else {
            return
        }
        let referencedMessage = referencedMessageBox.value

        var content = String(referencedMessage.content.prefix(contentTruncateCount))
        if referencedMessage.content.count > contentTruncateCount {
            content += "..."
        }

        let avatarURL = DiscordBMImpostor.avatarURL(
            member: try message.member.requireValue(), user: try message.author.requireValue(), guildId: guildId
        )

        let messageURL = URL(string: "https://discord.com/channels")?
            .appendingPathComponent(guildId.rawValue)
            .appendingPathComponent(referencedMessage.channel_id.rawValue)
            .appendingPathComponent(referencedMessage.id.rawValue)
            .absoluteString

        let embed = Embed(
            title: "Reply to",
            description: content,
            url: messageURL,
            author: .init(name: username, icon_url: .exact(avatarURL))
        )

        message.embeds.append(embed)
    }
}
