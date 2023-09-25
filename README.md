# 🥸 DiscordBMImpostor

A third party package for [DiscordBM](https://github.com/DiscordBM/DiscordBM) to execute Discord webhooks that clone an existing message

## ✨ Features

> If any feature is expensive or opinionated, it is opt-in or configurable 

- Replicate the author's user or member avatar, embeds, anything possible
- Change any info about the new message, for example to clone to another channel 
- [ ] Widely tested with integration tests _(Almost 1:1 LOC for source and tests)_
- [ ] Clone attachments or stickers by linking to them or re-uploading them
- Clone URL components
- [ ] Clone messages sent after the original message, even combining them to reduce webhook executions
- [ ] Clone reactions
- Clone references by putting an embed
- Clone messages in a thread/forum post or messages used to start a thread/forum post
- Sanitize invalid usernames
- [ ] Delete the original message and messages sent after

## 😋 A Taste of DiscordBMImpostor

> This also serves as the example, since it includes most of the API surface

```swift
fatalError("stay tuned")
```

## 🙏 Feedback

Although widely tested, there may still be bugs, or you might have feature suggestions, please create issues for these!

## 🧪 Testing

The crate uses integration tests as opposed to unit tests to test real-world usage. It creates a message and clones it, then the tester checks if the message is cloned as expected.

> Because tests are real-world examples, they take a long time to finish, and are checked mostly manually

Before starting, set these environment variables, you can also put them in a `.env` file:

- `TOKEN`: The token of the bot to use for testing
- `CHANNEL_ID`: The channel in which the messages and webhooks will be crated
- `FORUM_CHANNEL_ID`: The forum channel in which forum channels will be tested

Additional required permissions for testing:

- `SEND_MESSAGES`
