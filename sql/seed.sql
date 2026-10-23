-- =====================================================================
-- Dummy data
--
-- Run after schema.sql and advanced.sql (the triggers must exist).
-- CLI: mysql -h <host> -u <user> -p todo-app < sql/seed.sql
--
-- Sections marked HAND-WRITTEN list their rows directly; sections marked
-- DERIVED build their rows from earlier sections.
-- Give explicit ids so later sections can reference them.
--
-- Keep the data consistent:
--   * do not insert group creators into User_Group or invite them to their
--     own group: trg_group_add_creator already made them members
--   * accepted invites: invitee matches a User.email exactly,
--     has_accepted = 1, accepted_at set, is_cancelled = 0
--   * invite times: sent_at and accepted_at >= invited_at
--   * tasks in one cycle share a group
--   * current_position < number of members in the group of that cycle
--   * one-off User_Task rows must not include cycle tasks (the derived
--     insert assigns those) and every assignee must be a group member
--     (trg_user_task_member rejects anyone else)
--   * colors '#RRGGBB', frequency in ('daily','weekly','biweekly','monthly')
--
-- Membership (C = creator via trigger, I = accepted invite, M = manual):
--
--                 Apartment  CS 4750  Hiking  Soccer  Office
--   1 Alice          C          M
--   2 Ben                       C                M
--   3 Chloe          M                   I
--   4 Derek                              C       I
--   5 Emma           I                                   M
--   6 Felix                              M       C
--   7 Grace                     I                        M
--   8 Henry                                              C
--   9 Isla           M                                   I
--  10 Jack                      M                M
--
-- Expected row counts after seeding:
--   User 10, User_Phone 9, Group 5, Invite 9, User_Group 19, Label 10,
--   Task 15, Task_Label 13, Cycle 5, Task_Cycle 5, User_Cycle 19, User_Task 14
-- =====================================================================

-- ---------------------------------------------------------------------
-- User (HAND-WRITTEN)
-- ---------------------------------------------------------------------
INSERT INTO `User` (user_id, password_hash, email, first_name, last_name) VALUES
  (1,  '$2b$10$hY9GnYmeJeNtIk6qmqWdsVlqpelY5BZwwW7nPKXzQIKfGHbAVokBS', 'alice.anderson@gmail.com',  'Alice', 'Anderson'),
  (2,  '$2b$10$cSnO0AssuZG/G7/ZwBAil82MQ56mMMsW9wbxGsHCWDO5.ho8ZWyxo', 'ben.brooks@virginia.edu',   'Ben',   'Brooks'),
  (3,  '$2b$10$AUawCyI6eEh5hsWlarnm24sV6mzGGoc7iSMFsOHXTfWkuypzpbYH8', 'chloe.carter@gmail.com',    'Chloe', 'Carter'),
  (4,  '$2b$10$STYdytlN7gOHuNQmhaXE8W2fyqph/irzcsYmYmMfvwS4CG2VoN6hV', 'derek.diaz@outlook.com',    'Derek', 'Diaz'),
  (5,  '$2b$10$qZDyWtiTDmPTMnrLXV/5bDcDAQ5t6TVzK3UAaGOzfVEmMCCX6M.9R', 'emma.evans@gmail.com',      'Emma',  'Evans'),
  (6,  '$2b$10$kJOFrcDDmu0D5v7KPMfD/BdEbdANG/sG/Cj1nddtwVbZEL5kaUneD', 'felix.foster@virginia.edu', 'Felix', 'Foster'),
  (7,  '$2b$10$QeHQ3u3dYXKyy8I2y.YbtdL57xzogbVCerS4NyTFc1h6gv9SLAW.9', 'grace.garcia@virginia.edu', 'Grace', 'Garcia'),
  (8,  '$2b$10$LWJFaRnUHNQN6hr5zvoWtFz1R/KE96hAXTB1hojVGEregqMCheBt6', 'henry.hughes@outlook.com',  'Henry', 'Hughes'),
  (9,  '$2b$10$e/xvFv5hdC1SExyQUQuIgE6BppF3wW3uW.X3B6BvF7lp8oQYzMF1K', 'isla.ingram@gmail.com',     'Isla',  'Ingram'),
  (10, '$2b$10$vxlwMVZ2oAEoVyqZK3O2QAzeDeZtwZPrs6S3izliq6rxJ4XKjTKWs', 'jack.johnson@virginia.edu', 'Jack',  'Johnson');


-- ---------------------------------------------------------------------
-- User_Phone (HAND-WRITTEN; Alice has two numbers, Felix and Isla none)
-- ---------------------------------------------------------------------
INSERT INTO User_Phone (user_id, phone_number) VALUES
  (1,  '(434) 555-0101'),
  (1,  '(434) 555-0199'),
  (2,  '(434) 555-0102'),
  (3,  '(571) 555-0103'),
  (4,  '(804) 555-0104'),
  (5,  '(434) 555-0105'),
  (7,  '(703) 555-0107'),
  (8,  '(434) 555-0108'),
  (10, '(540) 555-0110');


-- ---------------------------------------------------------------------
-- Group (HAND-WRITTEN; trg_group_add_creator adds each creator to User_Group)
-- ---------------------------------------------------------------------
INSERT INTO `Group` (group_id, name, created_by) VALUES
  (1, 'Maple Ave Apartment',   1),
  (2, 'CS 4750 Project Team',  2),
  (3, 'Hiking Club Officers',  4),
  (4, 'Rec League Soccer',     6),
  (5, 'Office Kitchen Crew',   8);


-- ---------------------------------------------------------------------
-- Invite (HAND-WRITTEN; 5 accepted, 2 sent and pending, 1 not yet sent,
-- 1 cancelled. Pending/unsent/cancelled invitees may not have accounts.)
-- ---------------------------------------------------------------------
INSERT INTO Invite (invite_id, invitee, invited_at, invited_by, sent_at, accepted_at, has_accepted, is_cancelled, group_id) VALUES
  (1, 'emma.evans@gmail.com',      '2026-08-20 10:00:00', 1, '2026-08-20 10:00:00', '2026-08-21 09:15:00', 1, 0, 1),
  (2, 'grace.garcia@virginia.edu', '2026-09-02 14:30:00', 2, '2026-09-02 14:30:00', '2026-09-02 18:05:00', 1, 0, 2),
  (3, 'chloe.carter@gmail.com',    '2026-08-28 12:00:00', 4, '2026-08-28 12:00:00', '2026-08-30 08:40:00', 1, 0, 3),
  (4, 'derek.diaz@outlook.com',    '2026-09-05 19:00:00', 6, '2026-09-05 19:00:00', '2026-09-06 11:20:00', 1, 0, 4),
  (5, 'isla.ingram@gmail.com',     '2026-09-15 09:00:00', 8, '2026-09-15 09:00:00', '2026-09-15 13:45:00', 1, 0, 5),
  (6, 'kevin.kim@gmail.com',       '2026-10-18 20:00:00', 6, '2026-10-18 20:01:00', NULL,                  0, 0, 4),
  (7, 'henry.hughes@outlook.com',  '2026-10-20 16:30:00', 4, '2026-10-20 16:30:00', NULL,                  0, 0, 3),
  (8, 'lily.lopez@gmail.com',      '2026-10-22 21:30:00', 1, NULL,                  NULL,                  0, 0, 1),
  (9, 'mike.morris@outlook.com',   '2026-10-01 10:00:00', 8, '2026-10-01 10:00:00', NULL,                  0, 1, 5);


-- ---------------------------------------------------------------------
-- User_Group
-- ---------------------------------------------------------------------
-- DERIVED: members who joined by accepting an invite
INSERT INTO User_Group (user_id, group_id)
SELECT u.user_id, i.group_id
FROM Invite i
JOIN `User` u ON u.email = i.invitee
WHERE i.has_accepted = 1;

-- HAND-WRITTEN: any other members (neither creator nor accepted invitee)
INSERT INTO User_Group (user_id, group_id) VALUES
  (3,  1), (9,  1),   -- Apartment
  (1,  2), (10, 2),   -- CS 4750
  (6,  3),            -- Hiking
  (2,  4), (10, 4),   -- Soccer
  (5,  5), (7,  5);   -- Office


-- ---------------------------------------------------------------------
-- Label (HAND-WRITTEN; two per group)
-- ---------------------------------------------------------------------
INSERT INTO Label (label_id, name, color, group_id) VALUES
  (1,  'Chores',    '#4CAF50', 1),
  (2,  'Bills',     '#F44336', 1),
  (3,  'Milestone', '#3F51B5', 2),
  (4,  'Coding',    '#009688', 2),
  (5,  'Planning',  '#FF9800', 3),
  (6,  'Gear',      '#795548', 3),
  (7,  'Game Day',  '#2196F3', 4),
  (8,  'Equipment', '#9C27B0', 4),
  (9,  'Cleaning',  '#00BCD4', 5),
  (10, 'Supplies',  '#FFC107', 5);


-- ---------------------------------------------------------------------
-- Task (HAND-WRITTEN; three per group, the first of each is recurring)
-- ---------------------------------------------------------------------
INSERT INTO Task (task_id, name, description, group_id, due_date, is_complete) VALUES
  (1,  'Take out trash and recycling',     'Bins go to the curb Sunday night',          1, '2026-10-26 08:00:00', 0),
  (2,  'Pay internet bill',                'Xfinity, $80 split four ways',              1, '2026-10-15 23:59:00', 1),
  (3,  'Deep clean bathroom',              NULL,                                        1, '2026-10-25 18:00:00', 0),
  (4,  'Post daily standup summary',       'What got done, what is next, any blockers', 2, '2026-10-23 21:00:00', 0),
  (5,  'Submit Milestone 2',               'Report PDF and .sql export on Gradescope',  2, '2026-10-23 23:59:00', 0),
  (6,  'Write seed data',                  NULL,                                        2, '2026-10-22 23:59:00', 1),
  (7,  'Lead monthly group hike',          'Pick the trail and post the carpool plan',  3, '2026-11-08 09:00:00', 0),
  (8,  'Book campsite for fall trip',      'Shenandoah, two nights, 12 people',         3, '2026-10-20 17:00:00', 0),
  (9,  'Inventory club gear',              'Count tents, stoves, and first-aid kits',   3, NULL,                  0),
  (10, 'Bring team snacks',                'Orange slices and water for halftime',      4, '2026-10-24 09:00:00', 0),
  (11, 'Pay league registration fee',      '$40 per player',                            4, '2026-09-30 23:59:00', 1),
  (12, 'Wash team jerseys',                NULL,                                        4, '2026-10-26 20:00:00', 0),
  (13, 'Clean out office fridge',          'Toss anything unlabeled or expired',        5, '2026-10-30 17:00:00', 0),
  (14, 'Restock coffee pods',              NULL,                                        5, '2026-10-21 12:00:00', 0),
  (15, 'Organize holiday potluck sign-up', NULL,                                        5, '2026-12-01 12:00:00', 0);


-- ---------------------------------------------------------------------
-- Task_Label (HAND-WRITTEN; tasks 4, 11 and 15 have no label, task 6 has two)
-- ---------------------------------------------------------------------
INSERT INTO Task_Label (task_id, label_id) VALUES
  (1,  1), (2,  2), (3,  1),
  (5,  3), (6,  3), (6,  4),
  (7,  5), (8,  5), (9,  6),
  (10, 7), (12, 8),
  (13, 9), (14, 10);


-- ---------------------------------------------------------------------
-- Cycle (HAND-WRITTEN; one per group, at varying points in the rotation)
-- ---------------------------------------------------------------------
INSERT INTO Cycle (cycle_id, frequency, current_position) VALUES
  (1, 'weekly',   1),
  (2, 'daily',    2),
  (3, 'monthly',  0),
  (4, 'weekly',   2),
  (5, 'biweekly', 1);


-- ---------------------------------------------------------------------
-- Task_Cycle (HAND-WRITTEN; links each recurring task to its cycle)
-- ---------------------------------------------------------------------
INSERT INTO Task_Cycle (task_id, cycle_id) VALUES
  (1,  1),
  (4,  2),
  (7,  3),
  (10, 4),
  (13, 5);


-- ---------------------------------------------------------------------
-- User_Cycle (DERIVED: every member of the group of the cycle, positions 0..n-1)
-- ---------------------------------------------------------------------
INSERT INTO User_Cycle (user_id, cycle_id, user_position)
SELECT ug.user_id, cg.cycle_id,
       ROW_NUMBER() OVER (PARTITION BY cg.cycle_id ORDER BY ug.user_id) - 1
FROM (SELECT DISTINCT tc.cycle_id, t.group_id
      FROM Task_Cycle tc
      JOIN Task t ON t.task_id = tc.task_id) cg
JOIN User_Group ug ON ug.group_id = cg.group_id;


-- ---------------------------------------------------------------------
-- User_Task
-- ---------------------------------------------------------------------
-- DERIVED: each cycle task goes to whoever is at current_position of the cycle
INSERT INTO User_Task (user_id, task_id)
SELECT uc.user_id, tc.task_id
FROM Task_Cycle tc
JOIN Cycle c       ON c.cycle_id = tc.cycle_id
JOIN User_Cycle uc ON uc.cycle_id = c.cycle_id AND uc.user_position = c.current_position;

-- HAND-WRITTEN: one-off task assignments (tasks 9 and 15 stay unassigned,
-- task 3 is shared)
INSERT INTO User_Task (user_id, task_id) VALUES
  (1,  2),
  (5,  3), (9, 3),
  (2,  5),
  (10, 6),
  (4,  8),
  (6,  11),
  (10, 12),
  (5,  14);
