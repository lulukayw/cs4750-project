-- =====================================================================
-- Triggers
--
-- Run after schema.sql and before seed.sql, so seed data goes through them.
-- Written for Cloud SQL Studio: no DELIMITER commands. If the editor
-- rejects the whole file, run the DROP lines, then each CREATE TRIGGER
-- block on its own.
-- Dropping a table drops its triggers, so schema.sql removes these too.
-- Cloud SQL with binary logging needs the instance flag
-- log_bin_trust_function_creators=on to create these without SUPER
-- (error 1419 otherwise).
-- =====================================================================

DROP TRIGGER IF EXISTS trg_group_add_creator;
DROP TRIGGER IF EXISTS trg_user_task_member;

-- The creator of a group is always one of its members.
-- Single-statement body, so it has no inner semicolons to split on.
CREATE TRIGGER trg_group_add_creator
AFTER INSERT ON `Group`
FOR EACH ROW
INSERT INTO User_Group (user_id, group_id)
SELECT NEW.created_by, NEW.group_id
FROM DUAL
WHERE NEW.created_by IS NOT NULL;

-- A task can only be assigned to members of the group that owns the task
CREATE TRIGGER trg_user_task_member
BEFORE INSERT ON User_Task
FOR EACH ROW
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM Task t
    JOIN User_Group ug ON ug.group_id = t.group_id
    WHERE t.task_id = NEW.task_id AND ug.user_id = NEW.user_id
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'User must be a member of the group that owns the task';
  END IF;
END;
