-- `?` marks a parameter to be bound by the app (prepared statements).
-- `User` and `Group` must always be written with backticks.

-- User
-- Create
INSERT INTO `User` (password_hash, email, first_name, last_name)
VALUES (?, ?, ?, ?);

-- Read
SELECT user_id, email, first_name, last_name FROM `User` WHERE user_id = ?;
SELECT user_id, password_hash, first_name, last_name FROM `User` WHERE email = ?;  -- login lookup
SELECT user_id, email, first_name, last_name FROM `User`;

-- Update
UPDATE `User` SET email = ?, first_name = ?, last_name = ? WHERE user_id = ?;
UPDATE `User` SET password_hash = ? WHERE user_id = ?;

-- Delete
DELETE FROM `User` WHERE user_id = ?;

-- ---------------------------------------------------------------------
-- Group
-- ---------------------------------------------------------------------
-- Create
INSERT INTO `Group` (name, created_by) VALUES (?, ?);

-- Read
SELECT * FROM `Group` WHERE group_id = ?;
SELECT * FROM `Group`;

-- Update
UPDATE `Group` SET name = ? WHERE group_id = ?;

-- Delete
DELETE FROM `Group` WHERE group_id = ?;

-- ---------------------------------------------------------------------
-- Task
-- ---------------------------------------------------------------------
-- Create
INSERT INTO Task (name, description, group_id, due_date)
VALUES (?, ?, ?, ?);

-- Read
SELECT * FROM Task WHERE task_id = ?;
SELECT * FROM Task WHERE group_id = ? ORDER BY due_date;

-- Update
UPDATE Task SET name = ?, description = ?, due_date = ? WHERE task_id = ?;
UPDATE Task SET is_complete = ? WHERE task_id = ?;

-- Delete
DELETE FROM Task WHERE task_id = ?;

-- ---------------------------------------------------------------------
-- Cycle
-- ---------------------------------------------------------------------
-- Create
INSERT INTO Cycle (frequency, current_position) VALUES (?, ?);

-- Read
SELECT * FROM Cycle WHERE cycle_id = ?;
SELECT * FROM Cycle;

-- Update
UPDATE Cycle SET frequency = ? WHERE cycle_id = ?;
UPDATE Cycle SET current_position = ? WHERE cycle_id = ?;

-- Delete
DELETE FROM Cycle WHERE cycle_id = ?;

-- ---------------------------------------------------------------------
-- Label
-- ---------------------------------------------------------------------
-- Create
INSERT INTO Label (name, color, group_id) VALUES (?, ?, ?);

-- Read
SELECT * FROM Label WHERE label_id = ?;
SELECT * FROM Label WHERE group_id = ?;

-- Update
UPDATE Label SET name = ?, color = ? WHERE label_id = ?;

-- Delete
DELETE FROM Label WHERE label_id = ?;

-- ---------------------------------------------------------------------
-- Invite
-- ---------------------------------------------------------------------
-- Create
INSERT INTO Invite (invitee, invited_by, group_id) VALUES (?, ?, ?);

-- Read
SELECT * FROM Invite WHERE invite_id = ?;
SELECT * FROM Invite WHERE group_id = ?;
SELECT * FROM Invite
WHERE invitee = ? AND has_accepted = FALSE AND is_cancelled = FALSE;  -- pending invites for an email

-- Update
UPDATE Invite SET sent_at = CURRENT_TIMESTAMP WHERE invite_id = ?;
UPDATE Invite SET has_accepted = TRUE, accepted_at = CURRENT_TIMESTAMP WHERE invite_id = ?;
UPDATE Invite SET is_cancelled = TRUE WHERE invite_id = ?;

-- Delete
DELETE FROM Invite WHERE invite_id = ?;

-- ---------------------------------------------------------------------
-- User_Group
-- ---------------------------------------------------------------------
-- Create
INSERT INTO User_Group (user_id, group_id) VALUES (?, ?);

-- Read
SELECT * FROM User_Group WHERE user_id = ?;
SELECT * FROM User_Group WHERE group_id = ?;

-- Update
UPDATE User_Group SET group_id = ? WHERE user_id = ? AND group_id = ?;

-- Delete
DELETE FROM User_Group WHERE user_id = ? AND group_id = ?;

-- ---------------------------------------------------------------------
-- User_Task
-- ---------------------------------------------------------------------
-- Create
INSERT INTO User_Task (user_id, task_id) VALUES (?, ?);

-- Read
SELECT * FROM User_Task WHERE user_id = ?;
SELECT * FROM User_Task WHERE task_id = ?;

-- Update (reassign a task to a different user)
UPDATE User_Task SET user_id = ? WHERE user_id = ? AND task_id = ?;

-- Delete
DELETE FROM User_Task WHERE user_id = ? AND task_id = ?;

-- ---------------------------------------------------------------------
-- User_Cycle
-- ---------------------------------------------------------------------
-- Create
INSERT INTO User_Cycle (user_id, cycle_id, user_position) VALUES (?, ?, ?);

-- Read
SELECT * FROM User_Cycle WHERE cycle_id = ? ORDER BY user_position;
SELECT * FROM User_Cycle WHERE user_id = ?;

-- Update
UPDATE User_Cycle SET user_position = ? WHERE user_id = ? AND cycle_id = ?;

-- Delete
DELETE FROM User_Cycle WHERE user_id = ? AND cycle_id = ?;

-- ---------------------------------------------------------------------
-- Task_Cycle
-- ---------------------------------------------------------------------
-- Create
INSERT INTO Task_Cycle (task_id, cycle_id) VALUES (?, ?);

-- Read
SELECT * FROM Task_Cycle WHERE task_id = ?;
SELECT * FROM Task_Cycle WHERE cycle_id = ?;

-- Update
UPDATE Task_Cycle SET cycle_id = ? WHERE task_id = ?;

-- Delete
DELETE FROM Task_Cycle WHERE task_id = ?;

-- ---------------------------------------------------------------------
-- Task_Label
-- ---------------------------------------------------------------------
-- Create
INSERT INTO Task_Label (task_id, label_id) VALUES (?, ?);

-- Read
SELECT * FROM Task_Label WHERE task_id = ?;
SELECT * FROM Task_Label WHERE label_id = ?;

-- Update
UPDATE Task_Label SET label_id = ? WHERE task_id = ? AND label_id = ?;

-- Delete
DELETE FROM Task_Label WHERE task_id = ? AND label_id = ?;

-- ---------------------------------------------------------------------
-- User_Phone
-- ---------------------------------------------------------------------
-- Create
INSERT INTO User_Phone (user_id, phone_number) VALUES (?, ?);

-- Read
SELECT * FROM User_Phone WHERE user_id = ?;

-- Update
UPDATE User_Phone SET phone_number = ? WHERE user_id = ? AND phone_number = ?;

-- Delete
DELETE FROM User_Phone WHERE user_id = ? AND phone_number = ?;
