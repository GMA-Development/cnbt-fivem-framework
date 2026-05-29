# CNBT — Lightweight FiveM RP Framework

A custom, performance-first RP framework for FiveM. Built around three
non-negotiables:

1. **Leggerissimo** — minimal resmon. Pure **Lua 5.4**, no build step, no
   per-frame loops in the core.
2. **Zero desync** — replicated **state bags** are the single source of
   truth. The server is authority; clients sync natively with no custom
   net-event spam.
3. **Reusable components** — one job per module, a `require()` loader, and
   **APIs everywhere** (in-resource object + cross-resource exports +
   analytics events).

> Status: **foundation (v0.1.0)**. Core kernel, DB layer, sync, RPC, and
> the player/identity lifecycle. Gameplay features build on top of this.

---

## Why it's fast

| Concern        | Approach                                                                 |
|----------------|--------------------------------------------------------------------------|
| Sync / desync  | State bags (`Player(src).state`, `Entity(e).state`, `GlobalState`) — replicated by the server, no manual events. |
| DB writes      | **Write-behind cache**: data lives in memory, marked dirty on change, and flushed in **one batched transaction** periodically + on disconnect. |
| CPU / resmon   | No `Wait(0)` loops in the core. The only timers are the DB flush (minutes) and a one-shot session-ready wait. |
| Module loading | `require()` compiles + caches each module **once**; zero runtime cost after load. |
| Code size      | Single-responsibility components, no duplicated helpers.                  |

---

## Install

1. Place this resource in your server and **name the folder `cnbt`** (so
   exports are `exports.cnbt:...`).
2. Ensure [`oxmysql`](https://github.com/overextended/oxmysql) is installed
   and started **before** `cnbt`.
3. Import `sql/schema.sql` into your database.
4. In `server.cfg`:
   ```cfg
   set onesync on
   ensure oxmysql
   ensure cnbt
   ```
5. Tune `config/config.lua` (log level, save interval, spawn, starting money).

---

## Architecture

```
cnbt/
├─ fxmanifest.lua          # lua54, oxmysql dep, loads import.lua + main.lua, files{} for client require
├─ config/config.lua       # shared config
├─ shared/                 # runs in BOTH realms
│  ├─ import.lua           # require() module loader + CNBT global   ← loaded first
│  ├─ class.lua            # minimal OOP (single inheritance)
│  ├─ logger.lua           # level-gated colorized logging
│  ├─ eventEmitter.lua     # in-process pub/sub
│  ├─ rpc.lua              # realm-agnostic request/response engine
│  └─ utils/               # table, string, math helpers
├─ server/
│  ├─ main.lua             # bootstrap (requires modules => side effects)
│  ├─ modules/
│  │  ├─ events.lua        # central emitter + analytics bridge
│  │  ├─ database/
│  │  │  ├─ database.lua   # oxmysql wrapper (await-in-coroutine)
│  │  │  └─ writeBehind.lua# batched write-behind cache  ← the DB optimization
│  │  ├─ state/state.lua   # state-bag helpers (authority)
│  │  ├─ callback/callback.lua  # server RPC
│  │  ├─ identity/identity.lua  # account + character data-access
│  │  └─ player/
│  │     ├─ player.lua     # runtime Player object
│  │     └─ manager.lua    # connection lifecycle + character selection
│  └─ api/exports.lua      # CNBT global + cross-resource exports
└─ client/
   ├─ main.lua             # bootstrap + minimal character flow
   ├─ modules/
   │  ├─ state/state.lua   # state-bag reads + change handlers
   │  └─ callback/callback.lua # client RPC
   └─ api/exports.lua      # CNBT global + cross-resource exports
```

---

## Conventions

- **camelCase** for variables, functions, fields, DB columns. PascalCase for
  classes (`Player`) and the `CNBT` global.
- **Reuse, don't duplicate.** Before adding a function, check `shared/utils`,
  the existing components, and the relevant module. New shared behavior goes
  into a component, not copy-pasted.
- **Never write to the DB directly** from gameplay code. Mutate the in-memory
  object, mark it dirty (`writeBehind.markDirty`), and let the cache persist.
- **Sync via state bags**, not custom events. If a value must reach clients,
  put it in a state bag.

---

## Using the API

### Inside this resource

```lua
local player = CNBT.getPlayer(source)
player:addMoney('bank', 250, 'salary')
player:setJob('police', 2)

local row = CNBT.db.single('SELECT * FROM characters WHERE id = ?', { id })
CNBT.state.setGlobal('weather', 'CLEAR')
```

### From another resource (cross-resource exports)

```lua
exports.cnbt:addMoney(source, 'cash', 100, 'reward')
local money = exports.cnbt:getMoney(source, 'bank')
local loaded = exports.cnbt:isPlayerLoaded(source)
local rows  = exports.cnbt:query('SELECT * FROM users')
```

### Await-able callbacks (RPC)

```lua
-- server
exports.cnbt:registerCallback('shop:buy', function(source, itemId)
    return exports.cnbt:removeMoney(source, 'cash', 100, 'shop')
end)

-- client (inside a thread)
local ok = exports.cnbt:triggerServerCallback('shop:buy', itemId)
```

### Analytics / integration events (server)

```lua
AddEventHandler('cnbt:money:changed',    function(source, account, delta, reason) end)
AddEventHandler('cnbt:character:loaded', function(source, charId, citizenid) end)
AddEventHandler('cnbt:job:changed',      function(source, jobName, grade) end)
AddEventHandler('cnbt:player:dropped',   function(source) end)
```

---

## Extending it (read this first)

When building a new feature: **scan the codebase for existing components
before writing anything.** Then:

1. Put data-access in a `modules/<domain>/<domain>.lua` (reuse `CNBT.db`).
2. Persist via the **write-behind cache** — register a domain with a
   `buildSaveQueries` builder; never write per-action.
3. Sync player-facing values through **state bags** (`CNBT.state`).
4. Expose the feature via **exports** (cross-resource) and emit lifecycle
   events through the analytics bridge.
5. Keep it allocation- and loop-free in hot paths.
