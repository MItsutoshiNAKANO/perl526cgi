CREATE ROLE apache PASSWORD 'vagrant' LOGIN;

CREATE TABLE workers (
    account_id VARCHAR(126),
    worker_number INTEGER,
    affiliation VARCHAR(126),
    abbreviation_for_affiliation VARCHAR(126),
    worker_name VARCHAR(126),
    worker_katakana VARCHAR(126),
    phone VARCHAR(31),
    creator VARCHAR(126),
    updater VARCHAR(126),
    create_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (account_id, worker_number)    
);

CREATE UNIQUE INDEX unique_workers
ON workers (worker_name, worker_katakana, phone);

GRANT SELECT ON TABLE workers TO apache;
GRANT INSERT ON TABLE workers TO apache;
GRANT UPDATE ON TABLE workers TO apache;
GRANT DELETE ON TABLE workers TO apache;
