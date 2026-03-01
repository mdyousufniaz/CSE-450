-- 1. Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE EXTENSION IF NOT EXISTS "vector";

-- 2. Define Enum Types
CREATE TYPE user_role AS ENUM ('admin', 'moderator', 'member');

CREATE TYPE member_type_enum AS ENUM ('academic', 'syndicate', 'none');

CREATE TYPE meeting_type AS ENUM ('syndicate', 'academic');

CREATE TYPE meeting_status AS ENUM ('locked', 'open', 'end');

CREATE TYPE annexure_type AS ENUM ('agendaItem', 'resolution');

-- CREATE TYPE execution_bool AS ENUM ('yes', 'no'); change3.a: using 'built-in' boolean instead of custom ENUM

CREATE TYPE member_status AS ENUM ('active', 'onleave', 'past');

CREATE TYPE template_visibility AS ENUM ('public', 'private');

CREATE TYPE template_type AS ENUM ('agendaItem', 'resolutionItem');

CREATE TYPE content_type AS ENUM ('agendaItem', 'resolutionItem');

-- CREATE TYPE presentee_status AS ENUM ('yes', 'no'); change5.a: using 'built-in' boolean instead of custom ENUM

CREATE TYPE account_status AS ENUM ('active', 'inactive');

-- 3. Create Tables

-- Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    fullname VARCHAR(255) NOT NULL UNIQUE, -- change0: 'fullname' -> 'username'
    email VARCHAR(255) UNIQUE,
    password VARCHAR(255) NOT NULL, -- Store hashed passwords only
    role user_role NOT NULL DEFAULT 'member',
    member_type member_type_enum NOT NULL DEFAULT 'none',
    status account_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Members Table (Base table for people attending meetings)
CREATE TABLE members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    english_name VARCHAR(255) NOT NULL, -- change2: added english_ prefix
    bangla_name VARCHAR(255) NOT NULL, --change6: added bangla name
    status member_status NOT NULL DEFAULT 'active',
    user_id UUID REFERENCES users (id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Syndicate Members (Extension of members)
CREATE TABLE syndicate_members (
    member_id UUID PRIMARY KEY REFERENCES members (id) ON DELETE CASCADE,
    designation VARCHAR(255),
    address VARCHAR(255)
);

-- Academic Members (Extension of members)
CREATE TABLE academic_members (
    member_id UUID PRIMARY KEY REFERENCES members (id) ON DELETE CASCADE,
    designation VARCHAR(255),
    faculty VARCHAR(255),
    department VARCHAR(255),
    -- seniority_order INTEGER
);

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

-- Meetings Table
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

-- Content Table (Stores the core text data and embeddings)
CREATE TABLE agenda (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    -- 'vector(1536)' is standard for OpenAI embeddings. 
    -- Change 1536 to your specific model's dimension if different.
    embedding vector (1536),
    decision TEXT,
    is_executed BOOLEAN DEFAULT FALSE, -- change3.b: reflected changes as mentined 3.a
    is_suppli_agendum BOOLEAN DEFAULT FALSE, --change4: adding a new field
    execution_status TEXT, -- Detailed status description
    agenda_serial INTEGER, -- e.g., "Ag-1", "Res-5"
    meeting_id UUID REFERENCES meetings (id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Templates Table
CREATE TABLE templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    text_content TEXT NOT NULL,
    visibility template_visibility NOT NULL DEFAULT 'private',
    created_by UUID REFERENCES users (id) ON DELETE SET NULL,
    type template_type NOT NULL,
    used_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Presentees Table (Linking table for attendance)
CREATE TABLE presentees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    meeting_id UUID REFERENCES meetings (id) ON DELETE CASCADE,
    member_id UUID REFERENCES members (id) ON DELETE CASCADE,
    is_present BOOLEAN DEFAULT FALSE, -- -- change5.b: reflected changes as mentined 5.a
    UNIQUE (meeting_id, member_id) -- Prevent duplicate entries for same person in same meeting
);

-- Revisions Table (Version control for content)
CREATE TABLE revisions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    text_content TEXT NOT NULL,
    content_id UUID REFERENCES agenda (id) ON DELETE CASCADE,
    content_type content_type,
    modified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    modified_by UUID REFERENCES users (id) ON DELETE SET NULL
);

-- Annexures Table (Attachments/Appendices)
CREATE TABLE annexures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    content_id UUID REFERENCES agenda (id) ON DELETE CASCADE,
    annexure_type annexure_type,
    file_name VARCHAR(255),
    file_path VARCHAR(255),
    summary TEXT,
    embedding vector (1536), -- Vector embedding for the annexure summary/content
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    name VARCHAR(255) NOT NULL,
    embedding vector (1536),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE content_tags (
    content_id UUID REFERENCES agenda (id) ON DELETE CASCADE,
    tag_id UUID REFERENCES tags (id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (content_id, tag_id)
);

/* 
    External members can be keep as like this:
    - id
    - name
    - designation (raw)
    - department (raw)
    - institute (raw)
    - location (raw)
    - user id (fk, users) 

*/


/*
Also need to make tables for
file-management, notifications, logs

need to integrate logic like how to relationally design
- head
- dean
- other designation member
- how to handle external
- how to update db when new members are emerged
- how should he update that
- UX feature ( support for Bangla )
- which fields can be null at first insertion and
    which are mandatory...
*/