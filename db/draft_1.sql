CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE EXTENSION IF NOT EXISTS "vector";

-- Enums
CREATE TYPE user_role AS ENUM ('admin', 'moderator', 'member');

CREATE TYPE member_type AS ENUM ('academic', 'syndicate');

CREATE TYPE meeting_type AS ENUM ('syndicate', 'academic');

CREATE TYPE meeting_status AS ENUM ('locked', 'open', 'end');

CREATE TYPE content_type AS ENUM ('agendaItem', 'resolutionItem');

CREATE TYPE member_status AS ENUM ('active', 'onleave', 'past');

CREATE TYPE template_visibility AS ENUM ('public', 'private');

-- tables
CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    bangla_name VARCHAR(255) NOT NULL,
    english_name VARCHAR(255) NOT NULL,
    bangla_alias VARCHAR(255) NOT NULL,
    english_alias VARCHAR(255) NOT NULL,
    faculty_id UUID REFERENCES faculties (id) ON DELETE CASCADE
);

CREATE TABLE faculties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    bangla_name VARCHAR(255) NOT NULL,
    english_name VARCHAR(255) NOT NULL
);

CREATE TABLE designations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    bangla_name VARCHAR(255) NOT NULL,
    english_name VARCHAR(255) NOT NULL
);

CREATE TABLE emails (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    address VARCHAR(255) UNIQUE
);

CREATE TABLE member_emails (
    member_id UUID REFERENCES members (id) ON DELETE CASCADE,
    email_id UUID REFERENCES emails (id) ON DELETE CASCADE,

    PRIMARY KEY (member_id, email_id)
)

CREATE TABLE primary_emails (
    id UUID PRIMARY KEY REFERENCES emails (id) ON DELETE CASCADE
);

CREATE TABLE members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    email VARCHAR(255) UNIQUE,
    english_name VARCHAR(255),
    bangla_name VARCHAR(255),
    status member_status NOT NULL DEFAULT 'active',
    type member_type NOT NULL,
    member_id UUID PRIMARY KEY REFERENCES members (id) ON DELETE CASCADE,
    faculty_id UUID REFERENCES faculties (id) ON DELETE SET NULL,
    department_id UUID REFERENCES departments (id) ON DELETE SET NULL,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES members (id) ON DELETE CASCADE,
    password VARCHAR(255) NOT NULL, -- Store hashed passwords only
    role user_role NOT NULL DEFAULT 'member',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE presentees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    meeting_id UUID REFERENCES meetings (id) ON DELETE CASCADE,
    member_id UUID REFERENCES members (id) ON DELETE CASCADE,
    designation_id UUID REFERENCES designations (id) ON DELETE CASCADE,
    is_present BOOLEAN DEFAULT FALSE, 
    UNIQUE (meeting_id, member_id) -- Prevent duplicate entries for same person in same meeting
);

CREATE TABLE meetings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    serial INTEGER NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL, -- change1: adding description field
    meeting_date TIMESTAMP WITH TIME ZONE NOT NULL,
    type meeting_type NOT NULL,
    meeting_link VARCHAR(255),
    agenda_pdf_link VARCHAR(255),
    transcript VARCHAR(255),
    resolution_pdf_link VARCHAR(255),
    status meeting_status NOT NULL DEFAULT 'open',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

REATE TABLE agenda (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    -- 'vector(1536)' is standard for OpenAI embeddings. 
    -- Change 1536 to your specific model's dimension if different.
    content TEXT,
    embedding vector (1536),
    decision TEXT,
    is_executed BOOLEAN DEFAULT FALSE, 
    is_suppli_agendum BOOLEAN DEFAULT FALSE,
    execution_status TEXT, -- Detailed status description
    serial INTEGER, -- e.g., "Ag-1", "Res-5"
    meeting_id UUID REFERENCES meetings (id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    text_content TEXT NOT NULL,
    visibility template_visibility NOT NULL DEFAULT 'private',
    created_by UUID REFERENCES users (id) ON DELETE SET NULL,
    type template_type NOT NULL,
    used_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);





