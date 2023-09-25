import DiscordBM

extension DiscordClient {
    func findOrCreateWebhook(channelID: ChannelSnowflake, name: String) async throws -> Webhook {
        if let foundWebhook = try await self.listChannelWebhooks(channelId: channelID).decode().first(
            where: { $0.token != nil && $0.name == name }
        ) {
            return foundWebhook
        }

        return try await self.createWebhook(
            channelId: channelID,
            payload: Payloads.CreateWebhook(name: name)
        )
        .decode()
    }
}
