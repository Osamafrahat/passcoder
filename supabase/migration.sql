-- PassCoder schema migration: new feature columns
-- Run this in Supabase Dashboard > SQL Editor

-- ============ PASSWORDS ============
ALTER TABLE passwords
  ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS tags TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS two_factor_code TEXT,
  ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 0;

-- ============ NOTES ============
ALTER TABLE notes
  ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- ============ CARDS ============
ALTER TABLE cards
  ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- ============ INDEXES (performance) ============
CREATE INDEX IF NOT EXISTS idx_passwords_user_id ON passwords (user_id);
CREATE INDEX IF NOT EXISTS idx_passwords_user_favorite ON passwords (user_id, is_favorite DESC);
CREATE INDEX IF NOT EXISTS idx_passwords_user_trash ON passwords (user_id, deleted_at);
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes (user_id);
CREATE INDEX IF NOT EXISTS idx_notes_user_trash ON notes (user_id, deleted_at);
CREATE INDEX IF NOT EXISTS idx_cards_user_id ON cards (user_id);
CREATE INDEX IF NOT EXISTS idx_cards_user_trash ON cards (user_id, deleted_at);