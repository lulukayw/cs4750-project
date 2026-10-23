-- =====================================================================
-- CS 4750 project schema (MySQL 8.0.16+ / Cloud SQL)
--
-- WARNING: this script DROPS and recreates every table. Running it on
-- the shared database wipes all data.
--
-- CLI: mysql -h <host> -u <user> -p todo-app < sql/schema.sql
--
-- `User` and `Group` must always be written with backticks in queries.
-- GROUP is a reserved word in MySQL.
-- =====================================================================

-- Children first so foreign keys never block a drop
DROP TABLE IF EXISTS User_Phone;
DROP TABLE IF EXISTS Task_Label;
DROP TABLE IF EXISTS Task_Cycle;
DROP TABLE IF EXISTS User_Cycle;
DROP TABLE IF EXISTS User_Task;
DROP TABLE IF EXISTS User_Group;
DROP TABLE IF EXISTS Invite;
DROP TABLE IF EXISTS Label;
DROP TABLE IF EXISTS Cycle;
DROP TABLE IF EXISTS Task;
DROP TABLE IF EXISTS `Group`;
DROP TABLE IF EXISTS `User`;

CREATE TABLE `User` (
  user_id       INT AUTO_INCREMENT PRIMARY KEY,
  password_hash VARCHAR(255) NOT NULL,
  email         VARCHAR(255) NOT NULL UNIQUE,
  first_name    VARCHAR(100) NOT NULL,
  last_name     VARCHAR(100) NOT NULL,
  CONSTRAINT chk_user_email      CHECK (email REGEXP '^[^@ ]+@[^@ ]+[.][^@ ]+$'),
  CONSTRAINT chk_user_first_name CHECK (CHAR_LENGTH(TRIM(first_name)) > 0),
  CONSTRAINT chk_user_last_name  CHECK (CHAR_LENGTH(TRIM(last_name)) > 0)
);

CREATE TABLE `Group` (
  group_id   INT AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(100) NOT NULL,
  created_by INT NULL,                           -- NULL if the creator account is deleted
  FOREIGN KEY (created_by) REFERENCES `User`(user_id) ON DELETE SET NULL,
  CONSTRAINT chk_group_name CHECK (CHAR_LENGTH(TRIM(name)) > 0)
);

CREATE TABLE Task (
  task_id     INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(255) NOT NULL,
  description TEXT,
  group_id    INT NOT NULL,                      -- every task is_in exactly one group
  due_date    DATETIME NULL,
  is_complete BOOLEAN NOT NULL DEFAULT FALSE,
  FOREIGN KEY (group_id) REFERENCES `Group`(group_id) ON DELETE CASCADE,
  CONSTRAINT chk_task_name        CHECK (CHAR_LENGTH(TRIM(name)) > 0),
  CONSTRAINT chk_task_is_complete CHECK (is_complete IN (0, 1))
);

-- A cycle rotates who performs a recurring task; its group is reached via Task_Cycle -> Task
CREATE TABLE Cycle (
  cycle_id         INT AUTO_INCREMENT PRIMARY KEY,
  frequency        VARCHAR(20) NOT NULL,
  current_position INT NOT NULL DEFAULT 0,       -- whose turn it is (matches User_Cycle.user_position)
  CONSTRAINT chk_cycle_frequency CHECK (frequency IN ('daily', 'weekly', 'biweekly', 'monthly')),
  CONSTRAINT chk_cycle_position  CHECK (current_position >= 0)
);

CREATE TABLE Label (
  label_id INT AUTO_INCREMENT PRIMARY KEY,
  name     VARCHAR(50) NOT NULL,
  color    CHAR(7) NOT NULL DEFAULT '#888888',   -- hex color
  group_id INT NOT NULL,
  FOREIGN KEY (group_id) REFERENCES `Group`(group_id) ON DELETE CASCADE,
  UNIQUE (group_id, name),                       -- no duplicate label names within a group
  CONSTRAINT chk_label_name  CHECK (CHAR_LENGTH(TRIM(name)) > 0),
  CONSTRAINT chk_label_color CHECK (color REGEXP '^#[0-9A-Fa-f]{6}$')
);

CREATE TABLE Invite (
  invite_id    INT AUTO_INCREMENT PRIMARY KEY,
  invitee      VARCHAR(255) NOT NULL,            -- email; invitee may not have an account yet
  invited_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  invited_by   INT NULL,
  sent_at      DATETIME NULL,
  accepted_at  DATETIME NULL,
  has_accepted BOOLEAN NOT NULL DEFAULT FALSE,
  is_cancelled BOOLEAN NOT NULL DEFAULT FALSE,
  group_id     INT NOT NULL,
  FOREIGN KEY (invited_by) REFERENCES `User`(user_id) ON DELETE SET NULL,
  FOREIGN KEY (group_id)   REFERENCES `Group`(group_id) ON DELETE CASCADE,
  CONSTRAINT chk_invite_invitee      CHECK (invitee REGEXP '^[^@ ]+@[^@ ]+[.][^@ ]+$'),
  CONSTRAINT chk_invite_flags        CHECK (has_accepted IN (0, 1) AND is_cancelled IN (0, 1)),
  CONSTRAINT chk_invite_not_both     CHECK (NOT (has_accepted = 1 AND is_cancelled = 1)),  -- cannot be accepted and cancelled
  CONSTRAINT chk_invite_accepted_at  CHECK ((has_accepted = 1) = (accepted_at IS NOT NULL)), -- flag and timestamp agree
  CONSTRAINT chk_invite_sent_order   CHECK (sent_at IS NULL OR sent_at >= invited_at),
  CONSTRAINT chk_invite_accept_order CHECK (accepted_at IS NULL OR accepted_at >= invited_at)
);

CREATE TABLE User_Group (
  user_id  INT NOT NULL,
  group_id INT NOT NULL,
  PRIMARY KEY (user_id, group_id),
  FOREIGN KEY (user_id)  REFERENCES `User`(user_id)   ON DELETE CASCADE,
  FOREIGN KEY (group_id) REFERENCES `Group`(group_id) ON DELETE CASCADE
);

CREATE TABLE User_Task (
  user_id INT NOT NULL,
  task_id INT NOT NULL,
  PRIMARY KEY (user_id, task_id),
  FOREIGN KEY (user_id) REFERENCES `User`(user_id) ON DELETE CASCADE,
  FOREIGN KEY (task_id) REFERENCES Task(task_id)   ON DELETE CASCADE
);

CREATE TABLE User_Cycle (
  user_id       INT NOT NULL,
  cycle_id      INT NOT NULL,
  user_position INT NOT NULL,
  PRIMARY KEY (user_id, cycle_id),
  UNIQUE (cycle_id, user_position),              -- two users cannot share a slot in a rotation
  FOREIGN KEY (user_id)  REFERENCES `User`(user_id) ON DELETE CASCADE,
  FOREIGN KEY (cycle_id) REFERENCES Cycle(cycle_id) ON DELETE CASCADE,
  CONSTRAINT chk_user_cycle_position CHECK (user_position >= 0)
);

CREATE TABLE Task_Cycle (
  task_id  INT PRIMARY KEY,                      -- a task belongs to at most one cycle
  cycle_id INT NOT NULL,
  FOREIGN KEY (task_id)  REFERENCES Task(task_id)   ON DELETE CASCADE,
  FOREIGN KEY (cycle_id) REFERENCES Cycle(cycle_id) ON DELETE CASCADE
);

CREATE TABLE Task_Label (
  task_id  INT NOT NULL,
  label_id INT NOT NULL,
  PRIMARY KEY (task_id, label_id),
  FOREIGN KEY (task_id)  REFERENCES Task(task_id)   ON DELETE CASCADE,
  FOREIGN KEY (label_id) REFERENCES Label(label_id) ON DELETE CASCADE
);

-- Multivalued attribute user_phone
CREATE TABLE User_Phone (
  user_id      INT NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  PRIMARY KEY (user_id, phone_number),
  FOREIGN KEY (user_id) REFERENCES `User`(user_id) ON DELETE CASCADE,
  CONSTRAINT chk_user_phone_format CHECK (phone_number REGEXP '^[+]?[0-9 ().-]{7,20}$')
);
