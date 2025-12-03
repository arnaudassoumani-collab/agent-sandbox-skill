-- Supabase Schema for Repository Sync
-- Creates tables for bidirectional sync tracking

-- Main sync table
CREATE TABLE IF NOT EXISTS repo_sync (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_name TEXT NOT NULL,
  repo_path TEXT NOT NULL,
  sync_timestamp TIMESTAMPTZ DEFAULT NOW(),
  sync_type TEXT CHECK (sync_type IN ('github-local', 'supabase', 'full')),
  status TEXT CHECK (status IN ('success', 'failed', 'pending')),
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- File tracking table
CREATE TABLE IF NOT EXISTS repo_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sync_id UUID REFERENCES repo_sync(id) ON DELETE CASCADE,
  file_path TEXT NOT NULL,
  file_hash TEXT,
  content TEXT,
  last_modified TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Commit history table
CREATE TABLE IF NOT EXISTS repo_commits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sync_id UUID REFERENCES repo_sync(id) ON DELETE CASCADE,
  commit_hash TEXT NOT NULL,
  author TEXT,
  commit_date TIMESTAMPTZ,
  message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_repo_sync_project ON repo_sync(project_name);
CREATE INDEX IF NOT EXISTS idx_repo_sync_timestamp ON repo_sync(sync_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_repo_files_path ON repo_files(file_path);
CREATE INDEX IF NOT EXISTS idx_repo_commits_hash ON repo_commits(commit_hash);

-- Real-time subscription trigger
CREATE OR REPLACE FUNCTION notify_sync_change()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM pg_notify('repo_sync_change', row_to_json(NEW)::text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER repo_sync_notify
AFTER INSERT OR UPDATE ON repo_sync
FOR EACH ROW EXECUTE FUNCTION notify_sync_change();

-- Update timestamp function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER repo_sync_updated_at
BEFORE UPDATE ON repo_sync
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Row-level security
ALTER TABLE repo_sync ENABLE ROW LEVEL SECURITY;
ALTER TABLE repo_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE repo_commits ENABLE ROW LEVEL SECURITY;

-- Policies (adjust based on auth requirements)
CREATE POLICY "Enable read access for all users" ON repo_sync
  FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated users" ON repo_sync
  FOR INSERT WITH CHECK (true);
