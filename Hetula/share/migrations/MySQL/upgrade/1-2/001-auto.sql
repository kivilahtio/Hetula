-- Convert schema '/home/hetula/Hetula/Hetula/share/migrations/_source/deploy/1/001-auto.yml' to '/home/hetula/Hetula/Hetula/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE log CHANGE COLUMN request request varchar(255) NOT NULL,
                CHANGE COLUMN description description varchar(255) NOT NULL;

;

COMMIT;

