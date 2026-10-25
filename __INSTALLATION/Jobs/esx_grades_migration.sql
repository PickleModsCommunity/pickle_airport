-- Run once on an existing installation after backing up job_grades.
UPDATE job_grades SET grade=CASE name WHEN 'recruit' THEN 0 WHEN 'employee' THEN 1 WHEN 'manager' THEN 2 WHEN 'boss' THEN 3 ELSE grade END
WHERE job_name='airport' AND name IN ('recruit','employee','manager','boss');
