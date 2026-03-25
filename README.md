# Mandate Plugin for Claude Code

Policy guardrails for AI agent wallets. Every financial transaction requires Mandate validation first, no exceptions.

## Install

**Step 1.** Add the marketplace:

```
/plugin marketplace add SwiftAdviser/claude-mandate-plugin
```

**Step 2.** Install the plugin:

```
/plugin install mandate@mandate
```

**Step 3.** Register your agent:

```bash
npx @mandate.md/cli login --name "MyAgent"
```

Claim the agent at the printed URL, set policies at [app.mandate.md](https://app.mandate.md).

## How it works

```
Claude: mandate validate --action transfer --amount 50 --reason "Invoice #42"
Plugin: [records token, 15-min TTL]

Claude: bankr prompt "send 50 USDC to 0xAlice"
Plugin: [token valid -> allows]
```

Without prior validation:

```
Claude: bankr prompt "send 50 USDC to 0xAlice"
Plugin: BLOCKED. Run mandate validate first.
```

The plugin enforces a two-phase loop: **validate, then execute**. No network calls during enforcement, purely local state file.

## What gets blocked

| Pattern | Examples |
|---------|----------|
| Wallet CLIs with write keywords | `bankr prompt "swap..."`, `bankr submit`, `bankr sign` |
| Generic transfers | Any command with `transfer`/`send` + `0x` address |
| MCP financial tools | `*__transfer`, `*__send`, `*__pay`, `*__swap`, `*__sign_tx`, `*__broadcast`, `*__withdraw`, `*__deposit` |

Write keywords: swap, send, transfer, buy, sell, deploy, stake, bridge, approve, withdraw, deposit, execute, sign, mint.

## What always passes

| Pattern | Examples |
|---------|----------|
| Read-only shell | `ls`, `git status`, `cat`, `grep`, `curl GET` |
| Mandate commands | `mandate validate`, `mandate status`, `mandate login` |
| MCP read tools | `*__get_*`, `*__list_*`, `*__balance`, `*__read_*`, `*__query_*` |
| Bankr read-only | `bankr whoami`, `bankr status`, `bankr login` |

## Validation sources

The plugin records a token when any of these return `allowed: true`:

```bash
# CLI
mandate validate --action transfer --amount 50 --reason "..."
npx @mandate.md/cli validate --action transfer --reason "..."

# REST
curl -X POST https://app.mandate.md/api/validate \
  -H "Authorization: Bearer $MANDATE_RUNTIME_KEY" \
  -d '{"action":"transfer","amount":"50","reason":"..."}'

# MCP
mcp__mandate__validate / mcp__mandate__preflight
```

Tokens expire after 15 minutes. Auto-pruned on each check.

## Included skill

The plugin ships with `mandate-api`, a full API reference skill. Claude Code loads it automatically and knows how to call validation endpoints, handle errors, and display results.

## Scan your codebase

Find unprotected wallet calls before they ship:

```bash
npx @mandate.md/cli scan
```

## Testing

23 built-in tests:

```bash
bash scripts/test-gate.sh
```

## Requirements

- `jq` (JSON parsing in hooks)
- `bash` 4.0+

## Community

- [Telegram Developer Chat](https://t.me/mandate_md_chat)
- [Docs](https://mandate.md)
- [GitHub](https://github.com/SwiftAdviser/claude-mandate-plugin)
