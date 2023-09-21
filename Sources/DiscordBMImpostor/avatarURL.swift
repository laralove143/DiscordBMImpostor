import DiscordBM

func avatarURL(member: Guild.PartialMember, user: DiscordUser, guildId: GuildSnowflake) -> String {
    if let memberAvatar = member.avatar {
        return CDNEndpoint.guildMemberAvatar(guildId: guildId, userId: user.id, avatar: memberAvatar).url
    }

    if let userAvatar = user.avatar {
        return CDNEndpoint.userAvatar(userId: user.id, avatar: userAvatar).url
    }

    return CDNEndpoint.defaultUserAvatar(discriminator: user.discriminator).url
}
