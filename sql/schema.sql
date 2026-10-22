-- =====================================================================
-- CS 4750 project schema (MySQL 8 / Cloud SQL)
--
-- WARNING: this script DROPS and recreates every table. Running it on
-- the shared database wipes all data.
--
-- CLI (proxy running): mysql -h 127.0.0.1 -u <user> -p todo-app < sql/schema.sql
--
-- `User` and `Group` must always be written with backticks in queries.
-- GROUP is a reserved word in MySQL.
-- =====================================================================

CREATE TABLE `User` (
  user_id       INT AUTO_INCREMENT PRIMARY KEY,
  password_hash VARCHAR(255) NOT NULL,          
  email         VARCHAR(255) NOT NULL UNIQUE,
  first_name    VARCHAR(100) NOT NULL,
  last_name     VARCHAR(100) NOT NULL
); 

CREATE TABLE `Group` (
  group_id   INT AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(100) NOT NULL,
  created_by INT NULL,                           -- NULL if creator's account is deleted
  FOREIGN KEY (created_by) REFERENCES `User`(user_id) ON DELETE SET NULL
); 

CREATE TABLE Task (
  task_id     INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(255) NOT NULL,
  description TEXT,
  group_id    INT NOT NULL,                      -- every task is_in exactly one group
  due_date    DATETIME NULL,
  is_complete BOOLEAN NOT NULL DEFAULT FALSE,
  FOREIGN KEY (group_id) REFERENCES `Group`(group_id) ON DELETE CASCADE
); 

CREATE TABLE Cycle (
  cycle_id         INT AUTO_INCREMENT PRIMARY KEY,
  frequency        VARCHAR(20) NOT NULL,         -- 'daily', 'weekly', 'monthly', etc. maybe we make an enum for this?
  current_position INT NOT NULL DEFAULT 0       -- whose turn it is (matches User_Cycle.user_position)
); 

CREATE TABLE Label (
  label_id INT AUTO_INCREMENT PRIMARY KEY,
  name     VARCHAR(50) NOT NULL,
  color    CHAR(7) NOT NULL DEFAULT '#888888',   -- hex color
  group_id INT NOT NULL,
  FOREIGN KEY (group_id) REFERENCES `Group`(group_id) ON DELETE CASCADE,
  UNIQUE (group_id, name)                        -- no duplicate label names within a group
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
  FOREIGN KEY (group_id)   REFERENCES `Group`(group_id) ON DELETE CASCADE
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
  UNIQUE (cycle_id, user_position),              -- two users can't share a slot in a rotation
  FOREIGN KEY (user_id)  REFERENCES `User`(user_id) ON DELETE CASCADE,
  FOREIGN KEY (cycle_id) REFERENCES Cycle(cycle_id) ON DELETE CASCADE
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
  FOREIGN KEY (user_id) REFERENCES `User`(user_id) ON DELETE CASCADE
); 