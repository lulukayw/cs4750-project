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
--   * Task_Label pairs a task only with labels of its own group
--   * colors '#RRGGBB', frequency in ('daily','weekly','biweekly','monthly')
--
-- Membership (C = creator via trigger, I = accepted invite, M = manual):
--
--                 Apt  CS4750  Hike  Soccer  Office  Book  House  Volley  Garden  Chem
--                  1     2      3      4       5      6     7       8       9      10
--   1 Alice        C     M
--   2 Ben                C             M
--   3 Chloe        M            I                     I
--   4 Derek                     C      I
--   5 Emma         I                           M
--   6 Felix                     M      C                            M
--   7 Grace              I                     M                                    M
--   8 Henry                                    C                            I
--   9 Isla         M                           I      M
--  10 Jack               M             M                             I
--  11 Nora                                            C             M
--  12 Owen                             I                    I
--  13 Priya                                                 C               M
--  14 Quentin            I                                  M                      I
--  15 Rosa                                            M             C
--  16 Sam                       M                           M
--  17 Tara                                     M                            C
--  18 Umar                      I                                   M              M
--  19 Violet                                                        I              C
--  20 Will                             M              I                     M
--
-- Expected row counts after seeding:
--   User 20, User_Phone 18, Group 10, Invite 23, User_Group 48, Label 20,
--   Task 50, Task_Label 41, Cycle 13, Task_Cycle 14, User_Cycle 60, User_Task 56
-- =====================================================================

-- ---------------------------------------------------------------------
-- User (HAND-WRITTEN)
-- ---------------------------------------------------------------------
INSERT INTO `User` (user_id, password_hash, email, first_name, last_name) VALUES
  (1,  '$2b$10$hY9GnYmeJeNtIk6qmqWdsVlqpelY5BZwwW7nPKXzQIKfGHbAVokBS', 'alice.anderson@gmail.com',  'Alice',   'Anderson'),
  (2,  '$2b$10$cSnO0AssuZG/G7/ZwBAil82MQ56mMMsW9wbxGsHCWDO5.ho8ZWyxo', 'ben.brooks@virginia.edu',   'Ben',     'Brooks'),
  (3,  '$2b$10$AUawCyI6eEh5hsWlarnm24sV6mzGGoc7iSMFsOHXTfWkuypzpbYH8', 'chloe.carter@gmail.com',    'Chloe',   'Carter'),
  (4,  '$2b$10$STYdytlN7gOHuNQmhaXE8W2fyqph/irzcsYmYmMfvwS4CG2VoN6hV', 'derek.diaz@outlook.com',    'Derek',   'Diaz'),
  (5,  '$2b$10$qZDyWtiTDmPTMnrLXV/5bDcDAQ5t6TVzK3UAaGOzfVEmMCCX6M.9R', 'emma.evans@gmail.com',      'Emma',    'Evans'),
  (6,  '$2b$10$kJOFrcDDmu0D5v7KPMfD/BdEbdANG/sG/Cj1nddtwVbZEL5kaUneD', 'felix.foster@virginia.edu', 'Felix',   'Foster'),
  (7,  '$2b$10$QeHQ3u3dYXKyy8I2y.YbtdL57xzogbVCerS4NyTFc1h6gv9SLAW.9', 'grace.garcia@virginia.edu', 'Grace',   'Garcia'),
  (8,  '$2b$10$LWJFaRnUHNQN6hr5zvoWtFz1R/KE96hAXTB1hojVGEregqMCheBt6', 'henry.hughes@outlook.com',  'Henry',   'Hughes'),
  (9,  '$2b$10$e/xvFv5hdC1SExyQUQuIgE6BppF3wW3uW.X3B6BvF7lp8oQYzMF1K', 'isla.ingram@gmail.com',     'Isla',    'Ingram'),
  (10, '$2b$10$vxlwMVZ2oAEoVyqZK3O2QAzeDeZtwZPrs6S3izliq6rxJ4XKjTKWs', 'jack.johnson@virginia.edu', 'Jack',    'Johnson'),
  (11, '$2b$10$24QL3fLbO4SswQtqJtUHfYmilWPH/pjOYFXzAEzPpY4NQdvnz1cxQ', 'nora.nguyen@gmail.com',     'Nora',    'Nguyen'),
  (12, '$2b$10$yqJ7J7egus.mb1pSIalw/t/tJKEyWVQcTLDaGb6mnaWsnmNxvjnnK', 'owen.ortiz@virginia.edu',   'Owen',    'Ortiz'),
  (13, '$2b$10$VnwuhTvxDJpzkBAdhWIx5o50I3uwKcTTWOKBo1H/Boyuz02wV0F8N', 'priya.patel@virginia.edu',  'Priya',   'Patel'),
  (14, '$2b$10$1B/vxq9AW.VbNBXXLGY98.vwSHhnmN7NSolJHplK4WhmVaNRf0pQ.', 'quentin.quinn@outlook.com', 'Quentin', 'Quinn'),
  (15, '$2b$10$JvdQ9SJOtZMAB8eWHaRxCcE3VlhL6cvEgTb6GMYC/mxnEia4Q/2M8', 'rosa.ramirez@gmail.com',    'Rosa',    'Ramirez'),
  (16, '$2b$10$qZnGUSRRPTmD6OZV2joFuTyc2DhUM1mJYi/gmbBGl90FFMiJxpVaY', 'sam.shah@virginia.edu',     'Sam',     'Shah'),
  (17, '$2b$10$Wl51V4tKElF27sZzU8ExFUVA1JXQhtfgHunszzaba2W6IvhKIan5I', 'tara.thompson@gmail.com',   'Tara',    'Thompson'),
  (18, '$2b$10$vs4XI.XlEHv1DfJ6mOt9LM.M1qu3O7kA68TmrEechx413wy5k8RJR', 'umar.usman@virginia.edu',   'Umar',    'Usman'),
  (19, '$2b$10$M1btovMOaZXs7lz3tHGrmF1XrKdzzQKXA8PGiFFCScsYU.ReZsh1B', 'violet.vance@outlook.com',  'Violet',  'Vance'),
  (20, '$2b$10$xecBJMU5GbheI6rVkA/MhYzGHoKqpmnvgrL7/Pxcn031qsxRK1TPX', 'will.walker@virginia.edu',  'Will',    'Walker');


-- ---------------------------------------------------------------------
-- User_Phone (HAND-WRITTEN; Alice and Priya have two numbers,
-- Felix, Isla, Quentin and Umar none)
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
  (10, '(540) 555-0110'),
  (11, '(434) 555-0111'),
  (12, '(757) 555-0112'),
  (13, '(434) 555-0113'),
  (13, '(202) 555-0187'),
  (15, '(434) 555-0115'),
  (16, '(571) 555-0116'),
  (17, '(434) 555-0117'),
  (19, '(804) 555-0119'),
  (20, '+1 434 555 0120');


-- ---------------------------------------------------------------------
-- Group (HAND-WRITTEN; trg_group_add_creator adds each creator to User_Group)
-- ---------------------------------------------------------------------
INSERT INTO `Group` (group_id, name, created_by) VALUES
  (1,  'Maple Ave Apartment',    1),
  (2,  'CS 4750 Project Team',   2),
  (3,  'Hiking Club Officers',   4),
  (4,  'Rec League Soccer',      6),
  (5,  'Office Kitchen Crew',    8),
  (6,  'Monday Night Book Club', 11),
  (7,  'Rugby Road House',       13),
  (8,  'Intramural Volleyball',  15),
  (9,  'Community Garden Plot',  17),
  (10, 'CHEM 1410 Lab Partners', 19);


-- ---------------------------------------------------------------------
-- Invite (HAND-WRITTEN; 15 accepted, 4 sent and pending, 2 not yet sent,
-- 2 cancelled. Pending/unsent/cancelled invitees may not have accounts.)
-- ---------------------------------------------------------------------
INSERT INTO Invite (invite_id, invitee, invited_at, invited_by, sent_at, accepted_at, has_accepted, is_cancelled, group_id) VALUES
  (1,  'emma.evans@gmail.com',      '2026-08-20 10:00:00', 1,  '2026-08-20 10:00:00', '2026-08-21 09:15:00', 1, 0, 1),
  (2,  'grace.garcia@virginia.edu', '2026-09-02 14:30:00', 2,  '2026-09-02 14:30:00', '2026-09-02 18:05:00', 1, 0, 2),
  (3,  'quentin.quinn@outlook.com', '2026-09-03 11:00:00', 1,  '2026-09-03 11:00:00', '2026-09-04 10:30:00', 1, 0, 2),
  (4,  'chloe.carter@gmail.com',    '2026-08-28 12:00:00', 4,  '2026-08-28 12:00:00', '2026-08-30 08:40:00', 1, 0, 3),
  (5,  'umar.usman@virginia.edu',   '2026-09-10 15:00:00', 4,  '2026-09-10 15:00:00', '2026-09-11 07:50:00', 1, 0, 3),
  (6,  'derek.diaz@outlook.com',    '2026-09-05 19:00:00', 6,  '2026-09-05 19:00:00', '2026-09-06 11:20:00', 1, 0, 4),
  (7,  'owen.ortiz@virginia.edu',   '2026-09-08 20:15:00', 2,  '2026-09-08 20:15:00', '2026-09-09 12:00:00', 1, 0, 4),
  (8,  'isla.ingram@gmail.com',     '2026-09-15 09:00:00', 8,  '2026-09-15 09:00:00', '2026-09-15 13:45:00', 1, 0, 5),
  (9,  'chloe.carter@gmail.com',    '2026-09-01 18:00:00', 11, '2026-09-01 18:00:00', '2026-09-01 19:30:00', 1, 0, 6),
  (10, 'will.walker@virginia.edu',  '2026-09-12 08:45:00', 11, '2026-09-12 08:45:00', '2026-09-13 21:10:00', 1, 0, 6),
  (11, 'owen.ortiz@virginia.edu',   '2026-08-15 12:00:00', 13, '2026-08-15 12:00:00', '2026-08-15 12:30:00', 1, 0, 7),
  (12, 'jack.johnson@virginia.edu', '2026-09-18 17:00:00', 15, '2026-09-18 17:00:00', '2026-09-19 09:00:00', 1, 0, 8),
  (13, 'violet.vance@outlook.com',  '2026-09-18 17:05:00', 15, '2026-09-18 17:05:00', '2026-09-20 14:25:00', 1, 0, 8),
  (14, 'henry.hughes@outlook.com',  '2026-08-25 07:30:00', 17, '2026-08-25 07:30:00', '2026-08-26 18:00:00', 1, 0, 9),
  (15, 'quentin.quinn@outlook.com', '2026-09-24 13:00:00', 19, '2026-09-24 13:00:00', '2026-09-24 13:20:00', 1, 0, 10),
  (16, 'kevin.kim@gmail.com',       '2026-10-18 20:00:00', 6,  '2026-10-18 20:01:00', NULL,                  0, 0, 4),
  (17, 'henry.hughes@outlook.com',  '2026-10-20 16:30:00', 4,  '2026-10-20 16:30:00', NULL,                  0, 0, 3),
  (18, 'alice.anderson@gmail.com',  '2026-10-19 19:00:00', 9,  '2026-10-19 19:00:00', NULL,                  0, 0, 6),
  (19, 'ryan.reed@outlook.com',     '2026-10-21 10:15:00', 15, '2026-10-21 10:15:00', NULL,                  0, 0, 8),
  (20, 'lily.lopez@gmail.com',      '2026-10-22 21:30:00', 1,  NULL,                  NULL,                  0, 0, 1),
  (21, 'tara.thompson@gmail.com',   '2026-10-22 22:10:00', 14, NULL,                  NULL,                  0, 0, 7),
  (22, 'mike.morris@outlook.com',   '2026-10-01 10:00:00', 8,  '2026-10-01 10:00:00', NULL,                  0, 1, 5),
  (23, 'zoe.zhang@virginia.edu',    '2026-09-25 09:00:00', 19, '2026-09-25 09:00:00', NULL,                  0, 1, 10);


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
  (3,  1), (9,  1),            -- Apartment
  (1,  2), (10, 2),            -- CS 4750
  (6,  3), (16, 3),            -- Hiking
  (2,  4), (10, 4), (20, 4),   -- Soccer
  (5,  5), (7,  5), (17, 5),   -- Office
  (9,  6), (15, 6),            -- Book Club
  (14, 7), (16, 7),            -- House
  (6,  8), (11, 8), (18, 8),   -- Volleyball
  (13, 9), (20, 9),            -- Garden
  (7, 10), (18, 10);           -- Chem


-- ---------------------------------------------------------------------
-- Label (HAND-WRITTEN; two per group, groups 1 and 7 both use 'Chores')
-- ---------------------------------------------------------------------
INSERT INTO Label (label_id, name, color, group_id) VALUES
  (1,  'Chores',     '#4CAF50', 1),
  (2,  'Bills',      '#F44336', 1),
  (3,  'Milestone',  '#3F51B5', 2),
  (4,  'Coding',     '#009688', 2),
  (5,  'Planning',   '#FF9800', 3),
  (6,  'Gear',       '#795548', 3),
  (7,  'Game Day',   '#2196F3', 4),
  (8,  'Equipment',  '#9C27B0', 4),
  (9,  'Cleaning',   '#00BCD4', 5),
  (10, 'Supplies',   '#FFC107', 5),
  (11, 'Reading',    '#8BC34A', 6),
  (12, 'Hosting',    '#E91E63', 6),
  (13, 'Chores',     '#4CAF50', 7),
  (14, 'Rent',       '#F44336', 7),
  (15, 'Match Day',  '#1E88E5', 8),
  (16, 'Fees',       '#607D8B', 8),
  (17, 'Upkeep',     '#03A9F4', 9),
  (18, 'Harvest',    '#CDDC39', 9),
  (19, 'Lab Report', '#673AB7', 10),
  (20, 'Prelab',     '#FF5722', 10);


-- ---------------------------------------------------------------------
-- Task (HAND-WRITTEN; five per group, the first of each is recurring.
-- Groups 1, 7 and 9 have a second recurring task with its own cycle;
-- in group 5 the first two tasks share one cycle.)
-- ---------------------------------------------------------------------
INSERT INTO Task (task_id, name, description, group_id, due_date, is_complete) VALUES
  (1,  'Take out trash and recycling',      'Bins go to the curb Sunday night',           1,  '2026-10-26 08:00:00', 0),
  (2,  'Pay internet bill',                 'Xfinity, $80 split four ways',               1,  '2026-10-15 23:59:00', 1),
  (3,  'Deep clean bathroom',               NULL,                                         1,  '2026-10-25 18:00:00', 0),
  (4,  'Vacuum living room and hallway',    NULL,                                         1,  '2026-10-27 20:00:00', 0),
  (5,  'Buy paper towels and dish soap',    'Split the Costco receipt on Venmo',          1,  NULL,                  0),
  (6,  'Post daily standup summary',        'What got done, what is next, any blockers',  2,  '2026-10-23 21:00:00', 0),
  (7,  'Submit Milestone 2',                'Report PDF and .sql export on Gradescope',   2,  '2026-10-23 23:59:00', 0),
  (8,  'Write seed data',                   NULL,                                         2,  '2026-10-22 23:59:00', 1),
  (9,  'Set up Cloud SQL instance',         'MySQL 8 in us-east4, share connection name', 2,  '2026-10-05 23:59:00', 1),
  (10, 'Build login page',                  'React form that calls POST /api/login',      2,  '2026-11-06 23:59:00', 0),
  (11, 'Lead monthly group hike',           'Pick the trail and post the carpool plan',   3,  '2026-11-08 09:00:00', 0),
  (12, 'Book campsite for fall trip',       'Shenandoah, two nights, 12 people',          3,  '2026-10-20 17:00:00', 0),
  (13, 'Inventory club gear',               'Count tents, stoves, and first-aid kits',    3,  NULL,                  0),
  (14, 'Renew club insurance',              'File through the club council portal',       3,  '2026-09-15 17:00:00', 1),
  (15, 'Plan spring break backpacking trip', NULL,                                        3,  '2027-01-31 23:59:00', 0),
  (16, 'Bring team snacks',                 'Orange slices and water for halftime',       4,  '2026-10-24 09:00:00', 0),
  (17, 'Pay league registration fee',       '$40 per player',                             4,  '2026-09-30 23:59:00', 1),
  (18, 'Wash team jerseys',                 NULL,                                         4,  '2026-10-26 20:00:00', 0),
  (19, 'Pump up game balls',                NULL,                                         4,  '2026-10-24 08:30:00', 0),
  (20, 'Reserve field for practice',        'Request the Mad Bowl through IM-Rec',        4,  '2026-11-02 12:00:00', 0),
  (21, 'Clean out office fridge',           'Toss anything unlabeled or expired',         5,  '2026-10-30 17:00:00', 0),
  (22, 'Wipe down microwave',               NULL,                                         5,  '2026-10-30 17:00:00', 0),
  (23, 'Restock coffee pods',               NULL,                                         5,  '2026-10-21 12:00:00', 0),
  (24, 'Organize holiday potluck sign-up',  NULL,                                         5,  '2026-12-01 12:00:00', 0),
  (25, 'Order birthday cake for Isla',      'Chocolate, enough for 15 people',            5,  '2026-10-14 15:00:00', 1),
  (26, 'Host book club meeting',            'Snacks and seating for six',                 6,  '2026-10-27 19:00:00', 0),
  (27, 'Pick November book',                'Shortlist three and run a poll',             6,  '2026-10-31 23:59:00', 0),
  (28, 'Finish reading October book',       NULL,                                         6,  '2026-10-26 19:00:00', 0),
  (29, 'Return library copies',             NULL,                                         6,  '2026-10-02 17:00:00', 1),
  (30, 'Make reading schedule spreadsheet', NULL,                                         6,  NULL,                  0),
  (31, 'Wash dishes',                       'Empty the sink before bed',                  7,  '2026-10-23 23:00:00', 0),
  (32, 'Pay rent',                          '$2,400 through the landlord portal',         7,  '2026-11-01 23:59:00', 0),
  (33, 'Mow the lawn',                      NULL,                                         7,  '2026-10-25 12:00:00', 0),
  (34, 'Schedule furnace inspection',       NULL,                                         7,  '2026-10-10 17:00:00', 1),
  (35, 'Buy new shower curtain',            NULL,                                         7,  NULL,                  0),
  (36, 'Bring the net and ball cart',       'Pick up from the equipment desk',            8,  '2026-10-28 18:30:00', 0),
  (37, 'Pay IM team fee',                   '$60 split six ways',                         8,  '2026-09-25 23:59:00', 1),
  (38, 'Order team shirts',                 NULL,                                         8,  '2026-11-04 23:59:00', 0),
  (39, 'Sign up for winter tournament',     NULL,                                         8,  '2026-11-15 23:59:00', 0),
  (40, 'Submit sportsmanship rating',       NULL,                                         8,  '2026-10-22 23:59:00', 1),
  (41, 'Water the plot',                    'Skip it if it rained',                       9,  '2026-10-24 07:00:00', 0),
  (42, 'Turn the compost bin',              NULL,                                         9,  '2026-10-25 10:00:00', 0),
  (43, 'Harvest fall squash',               NULL,                                         9,  '2026-10-29 10:00:00', 0),
  (44, 'Pay plot rental fee',               '$25 for the season',                         9,  '2026-09-01 23:59:00', 1),
  (45, 'Plant garlic for spring',           NULL,                                         9,  '2026-11-10 12:00:00', 0),
  (46, 'Write lab report section',          'Intro, methods, results, discussion',        10, '2026-10-28 23:59:00', 0),
  (47, 'Complete prelab for Experiment 6',  NULL,                                         10, '2026-10-26 08:00:00', 0),
  (48, 'Submit Experiment 5 report',        NULL,                                         10, '2026-10-21 23:59:00', 1),
  (49, 'Review titration data',             NULL,                                         10, '2026-10-27 20:00:00', 0),
  (50, 'Study for lab practical',           NULL,                                         10, '2026-12-04 09:00:00', 0);


-- ---------------------------------------------------------------------
-- Task_Label (HAND-WRITTEN; tasks 5, 6, 14, 17, 24, 25, 30, 34, 40, 44
-- and 50 have no label, tasks 8 and 26 have two)
-- ---------------------------------------------------------------------
INSERT INTO Task_Label (task_id, label_id) VALUES
  (1,  1),  (2,  2),  (3,  1),  (4,  1),
  (7,  3),  (8,  3),  (8,  4),  (9,  4),  (10, 4),
  (11, 5),  (12, 5),  (13, 6),  (15, 5),
  (16, 7),  (18, 8),  (19, 8),  (20, 7),
  (21, 9),  (22, 9),  (23, 10),
  (26, 11), (26, 12), (27, 11), (28, 11), (29, 11),
  (31, 13), (32, 14), (33, 13), (35, 13),
  (36, 15), (37, 16), (38, 16), (39, 15),
  (41, 17), (42, 17), (43, 18), (45, 17),
  (46, 19), (47, 20), (48, 19), (49, 19);


-- ---------------------------------------------------------------------
-- Cycle (HAND-WRITTEN; at least one per group, at varying points in the rotation)
-- ---------------------------------------------------------------------
INSERT INTO Cycle (cycle_id, frequency, current_position) VALUES
  (1,  'weekly',   1),   -- group 1
  (2,  'biweekly', 3),   -- group 1
  (3,  'daily',    2),   -- group 2
  (4,  'monthly',  0),   -- group 3
  (5,  'weekly',   2),   -- group 4
  (6,  'biweekly', 1),   -- group 5
  (7,  'monthly',  3),   -- group 6
  (8,  'daily',    0),   -- group 7
  (9,  'weekly',   2),   -- group 7
  (10, 'weekly',   4),   -- group 8
  (11, 'daily',    1),   -- group 9
  (12, 'weekly',   3),   -- group 9
  (13, 'weekly',   1);   -- group 10


-- ---------------------------------------------------------------------
-- Task_Cycle (HAND-WRITTEN; links each recurring task to its cycle)
-- ---------------------------------------------------------------------
INSERT INTO Task_Cycle (task_id, cycle_id) VALUES
  (1,  1),
  (4,  2),
  (6,  3),
  (11, 4),
  (16, 5),
  (21, 6), (22, 6),
  (26, 7),
  (31, 8),
  (33, 9),
  (36, 10),
  (41, 11),
  (42, 12),
  (46, 13);


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

-- HAND-WRITTEN: one-off task assignments (tasks 13, 24, 30 and 50 stay
-- unassigned; tasks 3, 10, 28, 43 and 47 are shared)
INSERT INTO User_Task (user_id, task_id) VALUES
  (1,  2),  (5,  3),  (9,  3),  (3,  5),
  (2,  7),  (10, 8),  (1,  9),  (7, 10),  (14, 10),
  (4,  12), (6,  14), (16, 15),
  (6,  17), (10, 18), (20, 19), (12, 20),
  (5,  23), (17, 25),
  (11, 27), (3,  28), (9,  28), (11, 28), (15, 28), (20, 28), (15, 29),
  (13, 32), (12, 34), (16, 35),
  (15, 37), (19, 38), (11, 39), (15, 40),
  (17, 43), (20, 43), (8,  44), (13, 45),
  (7,  47), (14, 47), (18, 47), (19, 47), (19, 48), (18, 49);
