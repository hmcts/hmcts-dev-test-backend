INSERT INTO
    cases (
        id,
        case_number,
        description,
        status,
        created_date
    )
VALUES (
        UNHEX(REPLACE(UUID(), '-', '')),
        'ABC12345',
        'Case Description 1',
        'Open',
        NOW()
    ),
    (
        UNHEX(REPLACE(UUID(), '-', '')),
        'DEF67890',
        'Case Description 2',
        'Closed',
        NOW()
    ),
    (
        UNHEX(REPLACE(UUID(), '-', '')),
        'GHI11223',
        'Case Description 3',
        'In Progress',
        NOW()
    );