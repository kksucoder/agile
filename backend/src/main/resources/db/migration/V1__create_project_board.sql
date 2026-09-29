CREATE TABLE project (
    id UUID PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    version BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT project_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT project_version_nonnegative CHECK (version >= 0)
);

CREATE TABLE board_column (
    id UUID PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES project(id),
    name VARCHAR(50) NOT NULL,
    position INTEGER NOT NULL,
    CONSTRAINT board_column_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT board_column_position_nonnegative CHECK (position >= 0),
    CONSTRAINT board_column_project_position_unique UNIQUE (project_id, position),
    CONSTRAINT board_column_project_id_unique UNIQUE (project_id, id)
);

CREATE TABLE task (
    id UUID PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES project(id),
    column_id UUID NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    position INTEGER NOT NULL,
    version BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    archived_at TIMESTAMPTZ,
    CONSTRAINT task_column_same_project FOREIGN KEY (project_id, column_id)
        REFERENCES board_column(project_id, id),
    CONSTRAINT task_title_not_blank CHECK (length(btrim(title)) > 0),
    CONSTRAINT task_position_nonnegative CHECK (position >= 0),
    CONSTRAINT task_version_nonnegative CHECK (version >= 0)
);

CREATE INDEX task_active_by_column_position
    ON task (project_id, column_id, position)
    WHERE archived_at IS NULL;
