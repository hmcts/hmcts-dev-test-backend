CREATE TABLE IF NOT EXISTS cases (
    id BINARY(16) PRIMARY KEY,
    case_number VARCHAR(255) NOT NULL,
    description VARCHAR(255) NOT NULL,
    status VARCHAR(100) NOT NULL,
    created_date DATETIME(6) NOT NULL
);