# Mandate Plugin for Claude Code

Policy guardrails for AI agent wallets. Blocks financial transactions unless validated by Mandate first.

## Install

```bash
/plugin marketplace add SwiftAdviser/claude-mandate-plugin
```

Or from local path:

```bash
claude --plugin-dir ./packages/claude-mandate-plugin
```

## What it does

Two-phase enforcement: **track**, then **gate**.

1. Agent calls `mandate validate` (or REST/MCP equivalent)
2. Plugin records the validation token (15-minute TTL)
3. When agent tries a financial call (`wallet.transfer`, `bankr prompt`, MCP `send`, etc.), the plugin checks for a valid token
4. No token? Blocked. Valid token? Allowed.

```
Agent: mandate validate --action transfer --amount 50 --reason "Invoice"
Plugin: [records validation token]

Agent: bankr prompt "send 50 USDC to 0xAlice"
Plugin: [checks token -> valid -> allows]
```

Without prior validation:

```
Agent: bankr prompt "send 50 USDC to 0xAlice"
Plugin: DENIED. Run mandate validate first.
```

## What gets blocked

- Wallet CLI calls: `bankr prompt/submit/sign` with write keywords (swap, send, transfer, buy, sell, deploy, stake, bridge, etc.)
- Generic transfers: any command with `transfer`/`send` + `0x` address patterns
- MCP financial tools: `transfer`, `send`, `pay`, `swap`, `trade`, `sign_tx`, `broadcast`, `withdraw`, `deposit`, `bridge`, `execute`, `approve_tx`

## What always passes

- Read-only commands: `ls`, `git status`, `cat`, `grep`, etc.
- Mandate's own commands: `mandate validate`, `mandate status`, `mandate login`
- MCP read tools: `get_*`, `list_*`, `balance`, `read_*`, `fetch_*`, `query_*`
- Bankr read-only: `bankr whoami`, `bankr status`, `bankr login`

## How validation works

The plugin uses a local JSON state file (no network calls during enforcement):

```json
{
  "validations": [
    { "intentId": "abc123", "timestamp": 1711360000, "allowed": true }
  ]
}
```

Entries expire after 15 minutes. Auto-pruned on each check.

Validation is recorded when any of these succeed:
- CLI: `mandate validate`, `mandate preflight`, `mandate transfer`
- REST: `curl`/`fetch` to `/api/validate`
- MCP: `mcp__mandate__preflight`, `mcp__mandate__validate`

## Setup

1. Install the plugin (see above)
2. Register your agent: `npx @mandate.md/cli login --name "MyAgent"`
3. Claim the agent at the URL printed
4. Set policies in the Mandate dashboard at app.mandate.md

## Skills

The plugin includes a `mandate-api` skill with full API reference. Claude Code loads it automatically and knows how to call Mandate's validation endpoints.

## Testing

Built-in test suite (23 tests):

```bash
bash packages/claude-mandate-plugin/scripts/test-gate.sh
```

## Requirements

- `jq` (for JSON parsing in hook scripts)
- `bash` (4.0+)

## Community

- [Telegram Developer Chat](https://t.me/mandate_md_chat)
- [Documentation](https://mandate.md)
- [GitHub](https://github.com/AIMandateProject/mandate)
