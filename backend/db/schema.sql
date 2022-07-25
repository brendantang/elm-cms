CREATE TABLE IF NOT EXISTS articles (
      id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      slug text UNIQUE,
      title text,
      body text,
      metadata jsonb DEFAULT '{}'::jsonb,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
)