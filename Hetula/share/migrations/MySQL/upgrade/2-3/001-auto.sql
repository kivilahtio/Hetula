-- Convert schema '/opt/Hetula/Hetula/share/migrations/_source/deploy/2/001-auto.yml' to '/opt/Hetula/Hetula/share/migrations/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE log CHANGE COLUMN request request text NOT NULL,
                CHANGE COLUMN description description text NOT NULL;

;

COMMIT;

