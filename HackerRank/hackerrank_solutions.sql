/* 15 Days of Learning SQL */
CREATE TABLE Hackers (
    hacker_id INT,
    name VARCHAR(50) NOT NULL
);

CREATE TABLE Submissions (
    submission_date DATE NOT NULL,
    submission_id INT,
    hacker_id INT,
    score INT
);

INSERT INTO Hackers (hacker_id, name) VALUES
(15758, 'Rose'),
(20703, 'Angela'),
(36396, 'Frank'),
(38289, 'Patrick'),
(44056, 'Lisa'),
(53473, 'Kimbrely'),
(62529, 'Bonnie'),
(79722, 'Michael');

INSERT INTO Submissions (submission_date, submission_id, hacker_id, score) VALUES
('2016-03-01', 8494, 20703, 0),
('2016-03-01', 22403, 53473, 15),
('2016-03-01', 23965, 79722, 60),
('2016-03-01', 30173, 36396, 70),
('2016-03-02', 34928, 20703, 0),
('2016-03-02', 38740, 15758, 60),
('2016-03-02', 42769, 79722, 25),
('2016-03-02', 44364, 79722, 60),
('2016-03-03', 45440, 20703, 0),
('2016-03-03', 49050, 36396, 70),
('2016-03-03', 50273, 79722, 5),
('2016-03-04', 50344, 20703, 0),
('2016-03-04', 51360, 44065, 90),
('2016-03-04', 54404, 53473, 65),
('2016-03-04', 61533, 79722, 45),
('2016-03-05', 72852, 20703, 0),
('2016-03-05', 74546, 38289, 0),
('2016-03-05', 76487, 62529, 0),
('2016-03-05', 82439, 36396, 10),
('2016-03-05', 90006, 36396, 40),
('2016-03-06', 90404, 20703, 0);


   SET @day := '2016-03-01';
   SET @rk := 0;
SELECT q2.submission_date, q2.unik_h_id,  q5.hacker_id, q5.name
  FROM (  SELECT submission_date,
                 (SELECT COUNT(DISTINCT hacker_id)  
                    FROM Submissions s2  
                   WHERE s2.submission_date = s1.submission_date 
                         AND (SELECT COUNT(DISTINCT s3.submission_date) 
                                FROM Submissions s3 
                               WHERE s3.hacker_id = s2.hacker_id 
                                     AND s3.submission_date < s1.submission_date
                             ) = DATEDIFF(s1.submission_date , '2016-03-01')
                 ) AS unik_h_id
            FROM (SELECT DISTINCT submission_date 
                    FROM Submissions
                 ) s1
        GROUP BY submission_date
       ) q2
       INNER JOIN (  SELECT q4.submission_date AS submission_date, q4.hacker_id AS hacker_id, Hackers.name AS name
                       FROM (SELECT q3.submission_date, q3.hacker_id, q3.sub_cnt, 
                                    IF(submission_date = @day, @rk := @rk + 1, @rk := 1 AND @day := submission_date) AS rk
                               FROM (  SELECT submission_date,  hacker_id, COUNT(submission_id) AS sub_cnt
                                         FROM Submissions 
                                     GROUP BY submission_date, hacker_id
                                     ORDER BY submission_date, sub_cnt DESC, hacker_id ASC
                                    ) q3
                            ) q4
                            INNER JOIN Hackers
                            ON Hackers.hacker_id = q4.hacker_id
                      WHERE rk = 1
                   ORDER BY q4.submission_date
                  ) q5
       ON q2.submission_date = q5.submission_date

-- Another solution
  SELECT submission_date,
         (SELECT COUNT(DISTINCT hacker_id)  
            FROM Submissions s2  
           WHERE s2.submission_date = s1.submission_date 
                 AND (SELECT COUNT(DISTINCT s3.submission_date) 
                        FROM Submissions s3 
                       WHERE s3.hacker_id = s2.hacker_id 
                             AND s3.submission_date < s1.submission_date
                     ) = DATEDIFF(s1.submission_date , '2016-03-01')
         ) AS unik_h_id,
         (  SELECT hacker_id 
              FROM Submissions s2 
             WHERE s2.submission_date = s1.submission_date 
          GROUP BY hacker_id 
          ORDER BY COUNT(submission_id) DESC, hacker_id 
             LIMIT 1
         ) AS max_sub_h_id,
         (SELECT name 
            FROM Hackers 
           WHERE hacker_id = max_sub_h_id
         ) AS max_sub_h_name
    FROM (SELECT DISTINCT submission_date 
            FROM Submissions
         ) s1
GROUP BY submission_date

---------------------------------------------------------------------------------------------------
/* Interviews */
CREATE TABLE Contests (
  contest_id INT,  
  hacker_id INT,
  name VARCHAR(30) NOT NULL
);

CREATE TABLE Colleges (
  college_id INT,
  contest_id INT
);

CREATE TABLE Challenges (
  challenge_id INT,
  college_id INT
);

CREATE TABLE View_Stats (
  challenge_id INT,
  total_views INT,
  total_unique_views INT
);

CREATE TABLE Submission_Stats (
  challenge_id INT,
  total_submissions INT,
  total_accepted_submissions INT
);

INSERT INTO Contests (contest_id, hacker_id, name) VALUES
(66406, 17973, 'Rose'),
(66556, 79153, 'Angela'),
(94828, 80275, 'Frank');

INSERT INTO Colleges (college_id, contest_id) VALUES
(11219, 66406),
(32473, 66556),
(56685, 94828);

INSERT INTO Challenges (challenge_id, college_id) VALUES
(18765, 11219),
(47127, 11219),
(60292, 32473),
(72974, 56685);

INSERT INTO View_Stats (challenge_id, total_views,
  total_unique_views) VALUES
(47127, 26, 19),
(47127, 15, 14),
(18765, 43, 10),
(18765, 72, 13),
(75516, 35, 17),
(60292, 11, 10),
(72974, 41, 15),
(75516, 75, 11);

INSERT INTO Submission_Stats (challenge_id, total_submissions, total_accepted_submissions) 
VALUES
(75516, 34, 12),
(47127, 27, 10),
(47127, 56, 18),
(75516, 74, 12),
(75516, 83, 8),
(72974, 68, 24),
(72974, 82, 14),
(47127, 28, 11);


SELECT contest_id, hacker_id, name, t_s, t_a_s, t_v, t_u_v
  FROM (  SELECT contest_id, SUM(t_s) AS t_s, SUM(t_a_s) AS t_a_s, SUM(t_v) AS t_v, SUM(t_u_v) AS t_u_v
            FROM (  SELECT college_id, SUM(t_s) AS t_s, SUM(t_a_s) AS t_a_s, SUM(t_v) AS t_v, SUM(t_u_v) AS t_u_v
                      FROM (  SELECT challenge_id, college_id, COALESCE(SUM(total_views), 0) AS t_v,
                                     COALESCE(SUM(total_unique_views), 0) AS t_u_v
                                FROM Challenges
                                     LEFT JOIN View_Stats
                                     USING(challenge_id)
                            GROUP BY challenge_id, college_id
                           ) CV
                           INNER JOIN (  SELECT challenge_id, college_id, COALESCE(SUM(total_submissions), 0) AS t_s, 
                                                COALESCE(SUM(total_accepted_submissions), 0) AS t_a_s
                                           FROM Challenges
                                                LEFT JOIN Submission_Stats
                                                USING(challenge_id)
                                       GROUP BY challenge_id, college_id
                                      ) CS
                           USING(college_id, challenge_id)
                  GROUP BY college_id
                 ) C_CV_CS
                 INNER JOIN Colleges
                 USING(college_id)
        GROUP BY contest_id
       ) C_C_CV_CS
       INNER JOIN Contests
       USING(contest_id)
 WHERE t_s + t_a_s + t_v + t_u_v > 0

-- Another solution
SELECT q.contest_id, q.hacker_id, q.name, t_s, t_a_s, t_v, t_u_v
  FROM (  SELECT Contests.contest_id, hacker_id, name,
                 COALESCE(SUM(total_submissions), 0) AS t_s,
                 COALESCE(SUM(total_accepted_submissions), 0) AS t_a_s
            FROM Contests
                 INNER JOIN Colleges
                 ON Contests.contest_id = Colleges.contest_id
                 INNER JOIN Challenges
                 ON Colleges.college_id = Challenges.college_id
                 LEFT JOIN Submission_Stats
                 ON Challenges.challenge_id = Submission_Stats.challenge_id
        GROUP BY Contests.contest_id, hacker_id, name
       ) q
       INNER JOIN
       (  SELECT Contests.contest_id, hacker_id, name,
                 COALESCE(SUM(total_views), 0) AS t_v,
                 COALESCE(SUM(total_unique_views), 0) AS t_u_v
            FROM Contests
                 INNER JOIN Colleges
                 ON Contests.contest_id = Colleges.contest_id
                 INNER JOIN Challenges
                 ON Colleges.college_id = Challenges.college_id
                 LEFT JOIN View_Stats
                 ON Challenges.challenge_id = View_Stats.challenge_id
        GROUP BY Contests.contest_id, hacker_id, name
       ) q1
       ON q.contest_id = q1.contest_id
          AND q.hacker_id = q1.hacker_id
          AND q.name = q1.name
 WHERE t_s + t_a_s + t_v + t_u_v > 0

--------------------------------------------------------------------------------------------------
/* Draw The Triangle 1 */
  WITH RECURSIVE asterisk AS
       (SELECT 20 AS num
        
         UNION ALL
        
        SELECT num - 1 AS num
          FROM asterisk
         WHERE num > 1
       )
SELECT REPEAT(' * ', num)
  FROM asterisk

-- Another solution
DELIMITER $$

CREATE PROCEDURE asterisk(IN num INT) 
BEGIN 
  WHILE num > 0 DO
    SELECT REPEAT('* ', num);
       SET num = num - 1;
  END WHILE;
END$$

DELIMITER ;

CALL asterisk(20);


/* Draw The Triangle 2 */
  WITH RECURSIVE asterisk AS
       (SELECT 1 AS num
        
         UNION ALL
        
        SELECT num + 1 AS num
          FROM asterisk
         WHERE num < 20
       )
SELECT REPEAT(' * ', num)
  FROM asterisk

--------------------------------------------------------------------------------------------------
/* Print Prime Numbers */
  WITH RECURSIVE Prime_numbers AS
       (SELECT 2 AS num
        
         UNION ALL
        
        SELECT num + 1 AS num
          FROM Prime_numbers
         WHERE num < 1001
       ),
       Prime_numbers_1 AS
       (SELECT num
          FROM Prime_numbers p_n
         WHERE NOT EXISTS (SELECT 1
                             FROM Prime_numbers p_n1
                            WHERE p_n1.num < p_n.num AND p_n.num % p_n1.num = 0
                          )
       )
       
SELECT GROUP_CONCAT(num SEPARATOR '&') 
  FROM Prime_numbers_1

-- Another solution
  WITH RECURSIVE Prime_numbers AS
       (SELECT 2 AS num
        
         UNION ALL
        
        SELECT num + 1 AS num
          FROM Prime_numbers
         WHERE num < 1000
       )

SELECT GROUP_CONCAT(num SEPARATOR '&') 
  FROM (SELECT num
          FROM Prime_numbers p_n
         WHERE NOT EXISTS (SELECT 1
                             FROM Prime_numbers p_n1
                            WHERE p_n1.num < p_n.num AND p_n.num % p_n1.num = 0
                          )
       ) q

--------------------------------------------------------------------------------------------------
/* The PADS */
  SELECT CONCAT(Name, "(", LEFT(Occupation, 1), ")") 
    FROM OCCUPATIONS
ORDER BY Name;

  SELECT CONCAT("There are a total of ", COUNT(Name), " ", LOWER(Occupation), "s", ".") 
    FROM OCCUPATIONS
GROUP BY Occupation
ORDER BY COUNT(Name), Occupation

---------------------------------------------------------------------------------------------------
/* Occupations */
   WITH RankedOccupations AS 
         (SELECT Name, Occupation, 
                 ROW_NUMBER() OVER (PARTITION BY Occupation ORDER BY Name) AS rn
            FROM OCCUPATIONS
         )
  SELECT MAX(CASE WHEN Occupation = 'Doctor' THEN Name END) AS Doctor,
         MAX(CASE WHEN Occupation = 'Professor' THEN Name END) AS Professor,
         MAX(CASE WHEN Occupation = 'Singer' THEN Name END) AS Singer,
         MAX(CASE WHEN Occupation = 'Actor' THEN Name END) AS Actor
    FROM RankedOccupations
GROUP BY rn
ORDER BY rn

---------------------------------------------------------------------------------------------------