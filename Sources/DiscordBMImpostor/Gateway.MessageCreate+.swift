import DiscordBM
import Foundation

extension Gateway.MessageCreate {
    func getGuildId() throws -> GuildSnowflake {
        try guild_id.requireValue()
    }

    func getAuthor() throws -> DiscordUser {
        try author.requireValue()
    }

    func getMember() throws -> Guild.PartialMember {
        try member.requireValue()
    }

    func sanitizedNameForWebhook() throws -> String {
        let invalidSubstrings = ["clyde", "discord"]

        var name = try getMember().nick ?? getAuthor().username

        for invalidSubstring in invalidSubstrings {
            name = name.replacingOccurrences(of: invalidSubstring, with: "")
        }

        if name.isEmpty {
            name += "."
        }

        return name
    }

    func componentsAreOnlyURL() -> Bool {
        if let actionRows = components {
            for actionRow in actionRows {
                for component in actionRow.components {
                    if case let .button(button) = component {
                        if button.url == nil {
                            return false
                        }
                    } else {
                        return false
                    }
                }
            }
        }

        return true
    }

    func avatarURL() throws -> String {
        let author = try getAuthor()

        if let memberAvatar = try getMember().avatar {
            return try CDNEndpoint.guildMemberAvatar(guildId: getGuildId(), userId: author.id, avatar: memberAvatar).url
        }

        if let userAvatar = author.avatar {
            return CDNEndpoint.userAvatar(userId: author.id, avatar: userAvatar).url
        }

        return CDNEndpoint.defaultUserAvatar(discriminator: author.discriminator).url
    }

    func threadParentId(cache: DiscordCache) async throws -> ChannelSnowflake? {
        guard let thread = try await cache.guilds[getGuildId()]
            .requireValue()
            .threads.first(where: { $0.id == channel_id }) else {
            return nil
        }

        return Snowflake(try thread.parent_id.requireValue())
    }

    mutating func addReferencedMessageEmbed(cache: DiscordCache) async throws {
        let contentTruncateCount = 20
        let maxEmbedCount = 10
        let title = "Reply to"

        guard
            let referencedMessageBox = referenced_message,
            embeds.count < maxEmbedCount,
            let referencedMessage = try await cache.messages[referencedMessageBox.value.channel_id]
                .requireValue()
                .first(where: { $0.id == referencedMessageBox.value.id }) else {
            return
        }

        var content = String(referencedMessage.content.prefix(contentTruncateCount))
        if referencedMessage.content.count > contentTruncateCount {
            content += "..."
        }

        let avatarURL = try referencedMessage.avatarURL()

        let messageURL = URL(string: "https://discord.com/channels")?
            .appendingPathComponent(try referencedMessage.getGuildId().rawValue)
            .appendingPathComponent(referencedMessage.channel_id.rawValue)
            .appendingPathComponent(referencedMessage.id.rawValue)
            .absoluteString

        let embed = Embed(
            title: title,
            description: content,
            url: messageURL,
            author: .init(name: try sanitizedNameForWebhook(), icon_url: .exact(avatarURL))
        )

        embeds.append(embed)
    }
}
