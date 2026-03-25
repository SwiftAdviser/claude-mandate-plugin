# Mandate Plugin for Claude Code

Spend limits for AI agent wallets. Your agent validates every transaction before executing it.

## Install

```
/plugin marketplace add SwiftAdviser/claude-mandate-plugin
/plugin install mandate@mandate
```

## Setup

1. Register: `npx @mandate.md/cli login --name "MyAgent"`
2. Claim your agent at the printed URL
3. Set spend limits at [app.mandate.md](https://app.mandate.md)

## What happens

Every time Claude tries to send money, the plugin checks with Mandate first:

```
Claude: "Sending 50 USDC to 0xAlice for Invoice #42"
Mandate: allowed (within $100/tx limit)
Claude: [executes transaction]
```

If the transaction breaks your rules:

```
Claude: "Sending 5000 USDC to 0xUnknown"
Mandate: BLOCKED (exceeds daily limit)
Claude: [stops, shows you why]
```

No validation = no transaction. The plugin blocks it automatically.

## What you control

Set these in the Mandate dashboard:

- **Per-transaction limit**: max USD per single transaction
- **Daily/monthly limit**: spending caps over time
- **Allowlist**: only approved addresses
- **Approval workflow**: require your OK above a threshold
- **Blocked actions**: prevent specific operations entirely

## Scan your codebase

Find unprotected wallet calls:

```bash
npx @mandate.md/cli scan
```

## Works with

Any wallet or tool Claude can access: Bankr, MCP payment tools, direct RPC calls, custom CLIs. The plugin intercepts all of them.

## Community

- [Telegram Developer Chat](https://t.me/mandate_md_chat)
- [Docs](https://mandate.md)
- [GitHub](https://github.com/SwiftAdviser/claude-mandate-plugin)
