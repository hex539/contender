--  Database schema for "contender"


DROP TYPE IF EXISTS "verdict" CASCADE;
CREATE TYPE "verdict" AS ENUM(
  'WAITING',
  'JUDGING',
  'COMPILE-ERROR',
  'RUNTIME-ERROR',
  'TIME-LIMIT',
  'WRONG-ANSWER',
  'OK'
);


DROP TYPE IF EXISTS "scoring_type" CASCADE;
CREATE TYPE "scoring_type" AS ENUM(
  'binary',
  'partial'
);


DROP TABLE IF EXISTS "series" CASCADE;
CREATE TABLE "series" (
  "id"            serial          NOT NULL PRIMARY KEY,
  "name"          varchar(255)    NOT NULL,
  "shortname"     varchar(255)    NOT NULL UNIQUE
);


DROP TABLE IF EXISTS "contests" CASCADE;
CREATE TABLE "contests" (
  "id"              serial          NOT NULL PRIMARY KEY,
  "shortname"       varchar(255)    NOT NULL,
  "name"            varchar(255)    DEFAULT NULL,
  "series_id"       integer         DEFAULT NULL REFERENCES "series" ("id") ON DELETE CASCADE,
  "start_time"      timestamp       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "duration"        interval        DEFAULT NULL,
  "visible"         boolean         NOT NULL,
  "openbook"        boolean         NOT NULL DEFAULT false,
  "window_duration" interval        DEFAULT NULL,
  "penalty"         integer         NOT NULL DEFAULT 20
);


DROP TABLE IF EXISTS "users" CASCADE;
CREATE TABLE "users" (
  "id" serial         NOT NULL PRIMARY KEY,
  "username" varchar(255) NOT NULL UNIQUE,
  "realname" varchar(255) NOT NULL,
  "administrator" boolean NOT NULL DEFAULT false
);
INSERT INTO "users" VALUES (1,'rl773@bath.ac.uk','Robin Lee',true);


DROP TABLE IF EXISTS "sessions" CASCADE;
CREATE TABLE "sessions" (
  "id"            char(32)      NOT NULL PRIMARY KEY,
  "a_session"     text          NOT NULL,
  "timestamp"     timestamp     NOT NULL DEFAULT CURRENT_TIMESTAMP
);


DROP TABLE IF EXISTS "windows" CASCADE;
CREATE TABLE "windows" (
  "id"            serial        NOT NULL PRIMARY KEY,
  "contest_id"    integer       NOT NULL REFERENCES "contests" ("id") ON DELETE CASCADE,
  "user_id"       integer       NOT NULL REFERENCES "users" ("id") ON DELETE CASCADE,
  "start_time"    timestamp     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "duration"      interval      DEFAULT NULL,

  CONSTRAINT "one_contest_attempt_per_user" UNIQUE ("contest_id", "user_id")
);


DROP TABLE IF EXISTS "problems" CASCADE;
CREATE TABLE "problems" (
  "id"            serial            NOT NULL PRIMARY KEY,
  "contest_id"    integer           NOT NULL REFERENCES "contests" ("id") ON DELETE CASCADE,
  "name"          varchar(255)      NOT NULL,
  "scoring"       "scoring_type"    NOT NULL DEFAULT 'binary',
  "shortname"     varchar(255)      DEFAULT NULL
);


DROP TABLE IF EXISTS "submissions" CASCADE;
CREATE TABLE "submissions" (
  "id"          serial      NOT NULL PRIMARY KEY,
  "user_id"     integer     NOT NULL REFERENCES "users" ("id") ON DELETE CASCADE,
  "problem_id"  integer     NOT NULL REFERENCES "problems" ("id") ON DELETE CASCADE,
  "time"        timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "status"      verdict     NOT NULL DEFAULT 'WAITING'
);


DROP TABLE IF EXISTS "judgements" CASCADE;
CREATE TABLE "judgements" (
  "id"            serial        NOT NULL PRIMARY KEY,
  "submission_id" integer       NOT NULL REFERENCES "submissions" ("id") ON DELETE CASCADE,
  "status"        verdict       NOT NULL DEFAULT 'WAITING',
  "testcase"      varchar(255)  NOT NULL UNIQUE
);
