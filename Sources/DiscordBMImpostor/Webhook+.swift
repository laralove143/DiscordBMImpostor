import DiscordBM

extension Webhook {
    func address() throws -> WebhookAddress {
        try WebhookAddress.deconstructed(id: id, token: token.requireValue())
    }
}
