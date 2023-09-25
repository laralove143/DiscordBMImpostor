class UsernameTests: BaseTestCase {
    let invalidUsername = "a clyde discord"
    let removeDescription = "invalid username *(username should be a)*"

    func testInvalidSubtringRemoveUsername() async throws {
        var message = try await createMessage(.init(content: removeDescription))
        message.member!.nick = nil
        message.author?.username = invalidUsername
        try await sourceMessage(message: .given(message: message)).create()
    }

    func testInvalidSubtringRemoveNickname() async throws {
        var message = try await createMessage(.init(content: removeDescription))
        message.member!.nick = invalidUsername
        try await sourceMessage(message: .given(message: message)).create()
    }

    func testInvalidSubstringReplace() async throws {
        var message = try await createMessage(.init(content: "only invalid username *(username should be .)*"))
        message.member!.nick = "clyde"
        try await sourceMessage(message: .given(message: message)).create()
    }
}
