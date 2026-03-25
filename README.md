# Mandate Plugin for Claude Code

Spend limits for AI agent wallets. Install the plugin, it scans your project automatically.

## Install

```
/plugin marketplace add SwiftAdviser/claude-mandate-plugin
/plugin install mandate@mandate
```

That's it. Next time Claude starts a session, you'll see:

```
  Mandate Scan

  3 unprotected wallet call(s) found in 42 files:

    src/agents/trader.ts:23  wallet.sendTransaction({ to, data })
    src/agents/payer.ts:45   wallet.transfer(recipient, amount)
    src/tools/swap.ts:12     writeContract(config)

  Run: mandate validate --action <action> --reason <why> before each transaction.
```

If everything is protected:

```
  Mandate Scan

  All 5 wallet call(s) are protected by Mandate. Clean.
```

No wallet calls in the project? The scan stays silent.

## Setup

1. Register: `npx @mandate.md/cli login --name "MyAgent"`
2. Claim your agent at the printed URL
3. Set spend limits at [app.mandate.md](https://app.mandate.md)

## What you control

- **Per-transaction limit**: max USD per single transaction
- **Daily/monthly limit**: spending caps over time
- **Allowlist**: only approved addresses
- **Approval workflow**: require your OK above a threshold
- **Blocked actions**: prevent specific operations entirely

## How enforcement works

Every time Claude tries to send money, the plugin checks for a valid Mandate token:

- Valid token exists (from `mandate validate`) -> transaction proceeds
- No token -> transaction blocked, Claude is told to validate first

No network calls during enforcement. Purely local. Tokens expire after 15 minutes.

## Works with

Any wallet or tool Claude can access: Bankr, MCP payment tools, direct RPC calls, custom CLIs.

## Community

- [Telegram Developer Chat](https://t.me/mandate_md_chat)
- [Docs](https://mandate.md)
- [GitHub](https://github.com/SwiftAdviser/claude-mandate-plugin)
