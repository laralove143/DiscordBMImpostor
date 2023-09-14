import Collections
import DiscordBM
import DiscordBMImpostor
import XCTest

class SourceMessageTests: BaseTestCase {
    func testBasic() async throws {
        let message = try await createMessage(.init(content: "basic message"))

        try await sourceMessage(from: message).create()
    }

    func testDefaultAvatar() async throws {
        var message = try await createMessage(.init(content: "default avatar"))

        message.member?.avatar = nil
        message.author?.avatar = nil

        try await sourceMessage(from: message).create()
    }

    func testAvatar() async throws {
        let message = try await createMessage(.init(content: "avatar"))

        try await sourceMessage(from: message).create()
    }

    func testAnimatedAvatar() async throws {
        let owner = try await bot.client.getOwnApplication().decode().owner!

        guard let avatar = owner.avatar, avatar.starts(with: "a_") else {
            XCTFail("can't test animated avatar: bot's owner doesn't have an animated avatar")
            return
        }

        var message = try await createMessage(
            .init(content: "animated avatar *(should be bot owner's avatar but not animated)*")
        )
        message.member!.avatar = nil
        message.author!.id = owner.id
        message.author!.avatar = avatar

        try await sourceMessage(from: message).create()
    }

    func testGuildAvatar() async throws {
        for await event in events {
            if case let .guildCreate(guild)? = event.data, guild.channels.contains(where: { $0.id == channelId }) {
                break
            }
        }

        let guild = await cache.guilds.values.first { $0.channels.contains { $0.id == channelId } }!
        let owner = try await bot.client.getOwnApplication().decode().owner!
        let ownerMember = try await bot.client.getGuildMember(guildId: guild.id, userId: owner.id).decode()

        guard let avatar = ownerMember.avatar else {
            XCTFail("can't test guild avatar: bot's owner doesn't have a guild avatar")
            return
        }

        var message = try await createMessage(.init(content: "guild avatar *(should be bot owner's guild avatar)*"))
        message.author!.id = owner.id
        message.member!.avatar = avatar

        try await sourceMessage(from: message).create()
    }

    func testComponent() async throws {
        let message = try await createMessage(
            .init(components: [.init(arrayLiteral: .button(.init(label: "wöæo", url: "https://youtu.be/jPx_ZWKYRCE")))])
        )

        try await sourceMessage(from: message).create()
    }
}
