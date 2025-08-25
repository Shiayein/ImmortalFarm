-- ImmortalFarm - Key store (ASCII only)
-- Declare developer keys, whitelist user IDs, and per-key bindings.
-- IMPORTANT: Keep ASCII only (no fancy dashes/quotes).

local KeyStore = {}

-- Developer keys: work for ANY account
KeyStore.DEV_KEYS = {
  "IMMORTAL-DEV-2025"
}

-- Optional: user IDs allowed to run without a key
KeyStore.WHITELIST_USER_IDS = {
  -- 7849930474
}

-- Normal keys
--   ["KEY"] = { users = {123, 456} }  -- bound to specific accounts
--   ["KEY"] = { users = {} }          -- universal (not bound)
KeyStore.KEYS = {
  ["IMMORTAL-TEAM"]    = { users = {123456, 654321} },
  ["IMMORTAL-SOLO"]    = { users = {5604790652} },
  ["JTXG-BHAF-4U5O-DDZV"] = { users = {} }
}

return KeyStore


