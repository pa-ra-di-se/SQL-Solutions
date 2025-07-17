/* Second Highest Salary */
SELECT MAX(salary) AS SecondHighestSalary
  FROM Employee
 WHERE salary NOT IN (SELECT MAX(salary) FROM Employee)


/* Department Top Three Salaries */
  WITH employee_rank (emp_name, salary, departmentId, emp_rank) AS
       (SELECT name, salary, departmentId,
               DENSE_RANK() OVER (PARTITION BY departmentId ORDER BY salary DESC, departmentId) AS ASposition
          FROM Employee
       )
SELECT name AS Department, emp_name AS Employee, salary AS Salary
  FROM Department
       INNER JOIN employee_rank
       ON Department.id = employee_rank.departmentId
 WHERE emp_rank <= 3


/* Trips and Users */
  SELECT request_at AS Day,
         ROUND(SUM(IF(status = 'completed', 0, 1)) / COUNT(*), 2) AS 'Cancellation Rate'
    FROM Trips
   WHERE request_at BETWEEN '2013-10-01' AND '2013-10-03' 
         AND
         client_id NOT IN (SELECT users_id
                             FROM Users
                            WHERE banned = 'Yes'
                          ) 
         AND driver_id NOT IN (SELECT users_id
                                 FROM Users
                                WHERE banned = 'Yes'
                              )
GROUP BY request_at


/* Human Traffic of Stadium */
  WITH stadium1 (id, visit_date, people, id_diff) AS
       (SELECT id, visit_date, people,
               id - ROW_NUMBER() OVER () AS id_diff
          FROM Stadium 
         WHERE people > 99
       )
SELECT id, visit_date, people
  FROM stadium1
 WHERE id_diff IN (  SELECT id_diff
                       FROM stadium1
                   GROUP BY id_diff
                     HAVING COUNT(*) > 2
                  )


/* Nth Highest Salary */
CREATE FUNCTION getNthHighestSalary(N INT) RETURNS INT
BEGIN
    SET N = N-1;
    RETURN (
          SELECT DISTINCT(salary) 
            FROM Employee 
        ORDER BY salary DESC
           LIMIT 1 OFFSET N
    );
END


/* Rank Scores */
SELECT score, DENSE_RANK() OVER (ORDER BY score DESC) AS 'rank'
  FROM Scores


/* Consecutive Numbers */
    WITH Logs_with_dr (id, num, diff_id_dr) AS
        (  SELECT id, num, 
                  id - CAST(DENSE_RANK() OVER (PARTITION BY num ORDER BY id) AS SIGNED)
             FROM Logs
         ORDER BY id
        )

  SELECT DISTINCT num AS ConsecutiveNums
    FROM Logs_with_dr
GROUP BY diff_id_dr, num
  HAVING COUNT(*) > 2

-- Another solution
  SELECT DISTINCT a.num AS ConsecutiveNums
    FROM logs a, logs b, logs c
   WHERE a.id = b.id - 1 AND b.id = c.id - 1
         AND a.num = b.num AND b.num = c.num


/* Department Highest Salary */
SELECT Department.name AS Department, Employee.name AS Employee, 
       salary AS Salary
  FROM Department 
       INNER JOIN Employee
       ON Department.id = Employee.departmentId
       
       INNER JOIN (  SELECT MAX(salary) as maxsalary, departmentId
                       FROM Employee 
                   GROUP BY departmentId
                  ) query
       ON Employee.salary = query.maxsalary
          AND Employee.departmentId = query.departmentId

-- Another solution
  WITH employee_with_maxsalary (department, employee, salary, maxsalary) AS
       (SELECT Department.name, Employee.name, salary, 
               MAX(salary) OVER (PARTITION BY departmentId) AS maxsalary
          FROM Employee 
               INNER JOIN Department
               ON Employee.departmentId = Department.id
       )
SELECT department AS Department, employee AS Employee, salary AS Salary 
  FROM employee_with_maxsalary
 WHERE salary = maxsalary


 /* Managers with at Least 5 Direct Reports */
SELECT name
  FROM Employee
 WHERE id IN (   SELECT managerId
                   FROM Employee
               GROUP BY managerId
                 HAVING COUNT(*) > 4
              )


/* Investments in 2016 */
  WITH tiv15 (tiv) AS
       (   SELECT tiv_2015
             FROM Insurance
         GROUP BY tiv_2015
           HAVING COUNT(*) > 1
       ),
       tiv1516 (tiv, tiv1) AS
       (   SELECT tiv_2015, tiv_2016
             FROM Insurance
         GROUP BY lat, lon
           HAVING COUNT(*) = 1
       )

SELECT ROUND(SUM(tiv1), 2) AS tiv_2016 
  FROM tiv15
       INNER JOIN tiv1516
       ON tiv15.tiv = tiv1516.tiv

-- Another solution
SELECT ROUND(SUM(tiv_2016), 2) AS tiv_2016 
  FROM Insurance 
 WHERE tiv_2015 IN (   SELECT tiv_2015
                         FROM Insurance
                     GROUP BY tiv_2015
                       HAVING COUNT(*) > 1
                    )
       AND (lat, lon) IN (   SELECT lat, lon
                               FROM Insurance
                           GROUP BY lat, lon
                             HAVING COUNT(*) = 1
                          )


/* Friend Requests II: Who Has the Most Friends */
    WITH req (req_id, req_count) AS
         (   SELECT requester_id, COUNT(accepter_id)
               FROM RequestAccepted
           GROUP BY requester_id
         ),
         acc (acc_id, acc_count) AS
         (   SELECT accepter_id, COUNT(requester_id)
               FROM RequestAccepted
           GROUP BY accepter_id   
         ),
         ra (req_id, req_count, acc_id, acc_count) AS
         (SELECT *
            FROM req
                 LEFT JOIN acc
                 ON req.req_id = acc.acc_id

           UNION

          SELECT *
            FROM req
                 RIGHT JOIN acc
                 ON req.req_id = acc.acc_id
         ), 
         ra1 (user_id, req_count, acc_count) AS
         (SELECT IF(req_id IS NULL, acc_id, req_id),
                 IF(req_count IS NULL, 0, req_count),
                 IF(acc_count IS NULL, 0, acc_count)
            FROM ra
         )

  SELECT user_id AS id,
         SUM(req_count + acc_count) OVER (PARTITION BY user_id) AS num
    FROM ra1
ORDER BY num DESC
   LIMIT 1

-- Another solution
    WITH CTE AS 
         (SELECT requester_id AS id 
            FROM RequestAccepted
           UNION ALL
          SELECT accepter_id AS id 
            FROM RequestAccepted
         )  

  SELECT id, COUNT(id) AS num
    FROM CTE
GROUP BY id
ORDER BY num DESC
   LIMIT 1


/* Tree Node */
SELECT id, CASE
              WHEN p_id IS NULL THEN "Root"
              WHEN id IN (SELECT DISTINCT t1.id
                            FROM Tree t1
                                 INNER JOIN Tree t2
                                 ON t1.id = t2.p_id
                           WHERE t1.p_id IS NOT NULL
                          ) THEN "Inner"
              ELSE "Leaf"
            END AS type
  FROM Tree

-- Another solution
SELECT id, CASE 
             WHEN p_id IS NULL THEN 'Root'
             WHEN id IN (SELECT DISTINCT p_id FROM Tree) THEN 'Inner'
             ELSE 'Leaf'
           END AS type
  FROM Tree


/* Exchange Seats */
  SELECT CASE
            WHEN (SELECT MAX(id) FROM Seat) % 2 = 1 AND id = (SELECT MAX(id) FROM Seat) THEN id
            WHEN id % 2 = 1 THEN id + 1
            ELSE id - 1
         END AS id, student
    FROM Seat
ORDER BY id

-- Another solution
  SELECT IF (id < (SELECT MAX(id) FROM Seat),
             IF(id % 2 = 0, id - 1, id + 1), 
             IF(id % 2 = 0, id - 1, id)
            ) AS id, student
    FROM Seat
ORDER BY id

-- Another solution
SELECT id, CASE WHEN MOD(id, 2) = 0 THEN (LAG(student) OVER (ORDER BY id))
                ELSE (LEAD(student, 1, student) OVER (ORDER BY id))
           END AS 'student'
  FROM Seat


/* Customers Who Bought All Products */
   SELECT customer_id
     FROM Customer
 GROUP BY customer_id
   HAVING COUNT(DISTINCT product_key) = (SELECT COUNT(product_key) FROM Product) 

/* Product Sales Analysis III */
SELECT product_id, year AS first_year, quantity, price
  FROM Sales
 WHERE (product_id, year) IN (  SELECT product_id, MIN(year)
                                  FROM Sales
                              GROUP BY product_id
                             )

-- Another solution
  WITH min_year (product_id, year, quantity, price, min_y) AS
       (SELECT product_id, year, quantity, price,
               MIN(year) OVER (PARTITION BY product_id)
          FROM Sales
       )

SELECT product_id, year AS first_year, quantity, price 
  FROM min_year
 WHERE year = min_y


/* Game Play Analysis IV */
  WITH activity (player_id, event_date, date_diff, day_rank) AS
       (SELECT player_id, event_date,
               (UNIX_TIMESTAMP(event_date) - 
               LAG(UNIX_TIMESTAMP(event_date), 1, UNIX_TIMESTAMP(event_date)) 
               OVER (PARTITION BY player_id ORDER BY event_date)) / 86400,
               ROW_NUMBER() OVER (PARTITION BY player_id ORDER BY event_date)
          FROM Activity 
       )

SELECT ROUND(COUNT(DISTINCT player_id) / (SELECT COUNT(DISTINCT player_id) FROM Activity), 2) 
       AS fraction 
  FROM activity
 WHERE day_rank = 2 AND date_diff = 1

-- Another solution
SELECT ROUND(SUM(login) / COUNT(DISTINCT player_id), 2) AS fraction
FROM (SELECT player_id,
             DATEDIFF(event_date, MIN(event_date) OVER (PARTITION BY player_id)) = 1 AS login
        FROM Activity
      ) AS t

-- Another solution
SELECT ROUND(COUNT(DISTINCT player_id) / (SELECT COUNT(DISTINCT player_id) FROM Activity), 2) 
       AS fraction
  FROM Activity
 WHERE (player_id, DATE_SUB(event_date, INTERVAL 1 DAY)) 
       IN (  SELECT player_id, MIN(event_date) AS first_login
               FROM Activity
           GROUP BY player_id
          )

-- Another solution
  WITH first_login AS 
       (  SELECT player_id, MIN(event_date) AS first_date
            FROM Activity
        GROUP BY player_id
       )

SELECT ROUND(SUM(DATEDIFF(a.event_date, fl.first_date) = 1) / (COUNT(DISTINCT a.player_id)) , 2) 
       AS fraction
  FROM Activity a 
       INNER JOIN first_login fl
       ON a.player_id = fl.player_id 


/* Market Analysis I */
SELECT user_id AS buyer_id, join_date,
       IFNULL(order_in_2019, 0) AS orders_in_2019 -- Beats98.97%
       -- IF(order_in_2019 IS NULL, 0, order_in_2019) AS orders_in_2019
  FROM Users
       LEFT JOIN (  SELECT buyer_id, COUNT(*) AS order_in_2019
                      FROM Orders
                     WHERE 2019 = YEAR(order_date)
                  GROUP BY buyer_id
                 ) query_in
       ON Users.user_id = query_in.buyer_id

-- Another solution
  SELECT user_id AS buyer_id, join_date, 
         COUNT(order_id) AS orders_in_2019
    FROM Users 
         LEFT JOIN Orders
         ON Users.user_id = Orders.buyer_id AND YEAR(order_Date) = 2019
GROUP BY user_id


/* Product Price at a Given Date */
  WITH products_rank (pr_id, new_price, pr_rank) AS
       (  SELECT product_id, new_price, ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY change_date)
            FROM Products
           WHERE change_date <= '2019-08-16'
       ),
       products_last_rank (pr_id, last_price, pr_rank, last_rank) AS
       (  SELECT pr_id, new_price, pr_rank, MAX(pr_rank) OVER (PARTITION BY pr_id)
            FROM products_rank
       ),
       products_last_price (pr_id, last_price) AS
       (  SELECT pr_id, last_price
            FROM products_last_rank
           WHERE pr_rank = last_rank 
        GROUP BY pr_id
       )  

SELECT DISTINCT Products.product_id, IFNULL(last_price, 10) AS price
  FROM Products 
       LEFT JOIN products_last_price
       ON Products.product_id = products_last_price.pr_id

-- Another solution
  WITH products_rank (pr_id, new_price, pr_rank) AS
       (  SELECT product_id, new_price, ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY change_date DESC)
            FROM Products
           WHERE change_date <= '2019-08-16'
       ),
       products_last_price (pr_id, last_price) AS
       (  SELECT pr_id, new_price
            FROM products_rank
           WHERE pr_rank = 1
        GROUP BY pr_id
       )  

SELECT DISTINCT Products.product_id, IFNULL(last_price, 10) AS price
  FROM Products 
       LEFT JOIN products_last_price
       ON Products.product_id = products_last_price.pr_id

-- Another solution
  WITH products_rank (product_id, new_price, pr_rank) AS
       (SELECT product_id, new_price, ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY change_date DESC)
          FROM Products
         WHERE change_date <= '2019-08-16'
       )

SELECT product_id, new_price AS price 
  FROM products_rank
 WHERE pr_rank = 1

 UNION

SELECT product_id, 10 
  FROM products
 WHERE product_id NOT IN (SELECT product_id FROM products_rank)

-- Another solution
SELECT DISTINCT product_id, 10 AS price 
  FROM Products 
 WHERE product_id NOT IN (SELECT DISTINCT product_id 
                            FROM Products 
                           WHERE change_date <= '2019-08-16'
                         )

UNION

SELECT product_id, new_price AS price 
  FROM Products 
 WHERE (product_id, change_date) IN (  SELECT product_id, MAX(change_date) 
                                         FROM Products 
                                        WHERE change_date <= '2019-08-16' 
                                     GROUP BY product_id
                                    )
                                  

/* Immediate Food Delivery II */
  WITH orders_rank (customer_id, order_date, customer_pref_delivery_date, order_rank) AS
       (SELECT customer_id, order_date, customer_pref_delivery_date, 
               ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date)
          FROM Delivery
       ),
       immediate_orders (im_cost_count) AS
       (  SELECT COUNT(*)
            FROM orders_rank
           WHERE order_rank = 1 AND  order_date = customer_pref_delivery_date
       )
    
SELECT ROUND(immediate_orders.im_cost_count / COUNT(DISTINCT customer_id) * 100, 2) 
       AS immediate_percentage 
  FROM Delivery, immediate_orders

-- Another solution 
SELECT ROUND(AVG(order_date = customer_pref_delivery_date) * 100, 2) AS immediate_percentage
  FROM Delivery
 WHERE (customer_id, order_date) IN (  SELECT customer_id, MIN(order_date)
                                         FROM Delivery
                                     GROUP BY customer_id
                                    )


/* Monthly Transactions I */
    WITH month_trans (month, country, trans_count, trans_total_amount) AS
        (  SELECT DATE_FORMAT(trans_date, '%Y-%m'), country, COUNT(*), SUM(amount)
             FROM Transactions
         GROUP BY country, DATE_FORMAT(trans_date, '%Y-%m')   
        ),
        approved_trans (month, country, approved_count, approved_total_amount) AS
        (  SELECT DATE_FORMAT(trans_date, '%Y-%m'), country, COUNT(*), SUM(amount)
             FROM Transactions
            WHERE state = 'approved'
         GROUP BY country, DATE_FORMAT(trans_date, '%Y-%m')  
        )
  
  SELECT month_trans.month, month_trans.country, trans_count, 
         IFNULL(approved_count, 0) AS approved_count, 
         trans_total_amount, IFNULL(approved_total_amount, 0) AS approved_total_amount
    FROM month_trans
         LEFT JOIN approved_trans
         ON month_trans.month = approved_trans.month
            AND EXISTS (   SELECT month_trans.country
                        INTERSECT
                           SELECT approved_trans.country
                       )
                
-- Another solution
  SELECT DATE_FORMAT(trans_date, '%Y-%m') AS month, country,
         COUNT(*) AS trans_count, 
         COUNT(CASE WHEN state = "approved" THEN 1 ELSE NULL END) AS approved_count,
         SUM(amount) AS trans_total_amount,
         SUM(CASE WHEN state = "approved" THEN amount ELSE 0 END) AS approved_total_amount
    FROM Transactions 
GROUP BY DATE_FORMAT(trans_date, '%Y-%m'), country

-- Another solution
  SELECT DATE_FORMAT(trans_date, '%Y-%m') AS month, country,
         COUNT(*) AS trans_count, 
         COUNT(IF(state = "approved", 1, NULL)) AS approved_count,
         SUM(amount) AS trans_total_amount,
         SUM(IF(state = "approved", amount, 0)) AS approved_total_amount
    FROM Transactions 
GROUP BY DATE_FORMAT(trans_date, '%Y-%m'), country


/* Last Person to Fit in the Bus */
  WITH queue AS
       (SELECT turn, person_id, person_name, weight, 
               SUM(weight) OVER (ORDER BY turn) AS Total_Weight
          FROM Queue 
       )
       
SELECT person_name
  FROM Queue
 WHERE turn = (SELECT MAX(turn)
                 FROM queue
                WHERE Total_Weight <= 1000
              )

--Another solution
  SELECT person_name 
    FROM (SELECT person_name, SUM(weight) OVER (ORDER BY turn) AS total_weight
          FROM Queue 
         ) query_in
   WHERE total_weight <= 1000
ORDER BY total_weight DESC 
   LIMIT 1
  

/* Restaurant Growth */
SELECT DISTINCT visited_on, 
       SUM(amount) OVER (ORDER BY visited_on  
                         RANGE BETWEEN INTERVAL 6 DAY PRECEDING AND CURRENT ROW) AS amount,
       ROUND((SUM(amount) OVER (ORDER BY visited_on  
                                RANGE BETWEEN INTERVAL 6 DAY PRECEDING AND CURRENT ROW) / 7), 2) 
       AS average_amount
  FROM Customer
 LIMIT 1000 OFFSET 6 

 SELECT DISTINCT visited_on, 
        SUM(amount) OVER w AS amount,
        ROUND((SUM(amount) OVER w) / 7, 2) AS average_amount
   FROM Customer
 WINDOW w AS (ORDER BY visited_on  
              RANGE BETWEEN INTERVAL 6 DAY PRECEDING AND CURRENT ROW
             )
  LIMIT 1000 OFFSET 6 

--Another solution
SELECT visited_on, amount, ROUND(amount / 7, 2) AS average_amount
  FROM (SELECT DISTINCT visited_on, 
               SUM(amount) OVER(ORDER BY visited_on 
                                RANGE BETWEEN INTERVAL 6 DAY PRECEDING AND CURRENT ROW) AS amount, 
               MIN(visited_on) OVER() AS 1st_date 
          FROM Customer
        ) q
 WHERE visited_on >= 1st_date + 6


/* Movie Rating */
  WITH us_name (results) AS
       (   SELECT name
             FROM MovieRating
                  INNER JOIN Users
                  ON MovieRating.user_id = Users.user_id
         GROUP BY name
         ORDER BY COUNT(movie_id) DESC, name
            LIMIT 1
        ),
       mov_title (results) AS
       (   SELECT title 
             FROM MovieRating
                  INNER JOIN Movies
                  ON MovieRating.movie_id  = Movies.movie_id
            WHERE DATE_FORMAT(created_at, '%Y-%m') = '2020-02'
         GROUP BY title
         ORDER BY SUM(rating) / COUNT(*) DESC, title
            LIMIT 1
        )

SELECT results FROM us_name
 UNION ALL
SELECT results FROM mov_title

-- Another solution
 (SELECT name AS results
    FROM MovieRating
         INNER JOIN Users
         ON MovieRating.user_id = Users.user_id
GROUP BY name
ORDER BY COUNT(movie_id) DESC, name
   LIMIT 1)
   
   UNION ALL

(SELECT title AS results
    FROM MovieRating
         INNER JOIN Movies
         ON MovieRating.movie_id  = Movies.movie_id
   WHERE DATE_FORMAT(created_at, '%Y-%m') = '2020-02'
GROUP BY title
ORDER BY AVG(rating) DESC, title
   LIMIT 1)


/* Capital Gain/Loss */
-- В общем случае ошибочное решение, т.к может идти подряд Buy, Buy; Sell, Sell и т.д.
  SELECT stock_name, SUM(pruf) AS capital_gain_loss
    FROM (SELECT stock_name, operation, 
                 price - LAG(price, 1, price) 
                         OVER (PARTITION BY stock_name ORDER BY operation_day) AS pruf
            FROM Stocks
         ) q
   WHERE operation = 'Sell'
GROUP BY stock_name

-- Another solution
  SELECT stock_name, SUM(IF(operation = 'Sell', price, -price)) AS capital_gain_loss 
    FROM Stocks
GROUP BY stock_name


/* Count Salary Categories */
SELECT cty.category, IFNULL(accounts_count, 0) AS accounts_count
  FROM (  SELECT category, COUNT(account_id) AS accounts_count
            FROM (SELECT CASE
                           WHEN income < 20000 THEN 'Low Salary'
                           WHEN income BETWEEN 20000 AND 50000 THEN 'Average Salary'
                           ELSE 'High Salary'
                         END AS category, account_id
                    FROM Accounts
                 ) q
        GROUP BY category
       ) q1
       RIGHT JOIN (SELECT 'Low Salary' AS category 
                    UNION ALL 
                   SELECT 'Average Salary' 
                    UNION ALL 
                   SELECT 'High Salary'
                  ) cty
       ON q1.category = cty.category

-- Another solution
(SELECT 'Low Salary' AS category,
        (SELECT COUNT(*) FROM Accounts WHERE income < 20000) AS accounts_count)
  
  UNION ALL

(SELECT 'Average Salary' AS category,
        (SELECT COUNT(*) FROM Accounts WHERE income BETWEEN 20000 AND 50000) 
        AS accounts_count)
  
  UNION ALL

(SELECT 'High Salary' AS category,
        (SELECT COUNT(*) FROM Accounts WHERE income > 50000) AS accounts_count)



/* Confirmation Rate */
  SELECT Signups.user_id, IFNULL(ROUND(AVG(action = 'confirmed'), 2), 0) AS confirmation_rate
    FROM Confirmations
         RIGHT JOIN Signups
         ON Confirmations.user_id = Signups.user_id
GROUP BY user_id   

-- Another solution
  SELECT Signups.user_id, IFNULL(confirmation_rate, 0) AS confirmation_rate
    FROM Signups
         LEFT JOIN (   SELECT user_id, ROUND(AVG(action = 'confirmed'), 2) AS confirmation_rate
                         FROM Confirmations
                     GROUP BY user_id  
                    ) q
         ON Signups.user_id = q.user_id
    

/* Odd and Even Transactions */
    SELECT transaction_date, 
         SUM(IF(amount % 2 <> 0, amount, 0)) AS odd_sum, -- MOD(amount, 2)
         SUM(IF(amount % 2 = 0, amount, 0)) AS even_sum 
    FROM transactions
GROUP BY transaction_date 
ORDER BY transaction_date 


/* Combine Two Tables */
SELECT firstName, lastName, city, state
  FROM Person 
       LEFT JOIN Address
       ON Person.personId = Address.personId


/*  Employees Earning More Than Their Managers */
SELECT e2.name AS Employee
  FROM Employee e1
       INNER JOIN Employee e2
       ON e1.id = e2.managerId
 WHERE e2.salary > e1.salary


/* Duplicate Emails */
  SELECT email AS Email
    FROM Person
GROUP BY email
  HAVING COUNT(1) > 1


/* Customers Who Never Order */
SELECT name AS Customers
  FROM Orders 
       RIGHT JOIN Customers 
       ON Orders.customerId = Customers.id
 WHERE Orders.id IS NULL

-- Another solution
 SELECT name AS Customers
  FROM Customers 
       LEFT JOIN Orders
       ON Customers.id = Orders.customerId
 WHERE Orders.id IS NULL


/* Delete Duplicate Emails */
DELETE FROM Person 
WHERE id IN (SELECT a.id
               FROM (SELECT id, ROW_NUMBER() OVER (PARTITION BY email ORDER BY id) AS rn
                       FROM Person
                    ) a
              WHERE a.rn > 1
            )

-- Another solution
DELETE FROM Person 
 WHERE id NOT IN (SELECT id 
                    FROM (SELECT MIN(id) AS id FROM Person GROUP BY email) q
                 )
            

/* Rising Temperature */
SELECT id
  FROM (SELECT id, recordDate, temperature, 
               LAG(temperature) OVER (ORDER BY recordDate) AS PrevT,
               LAG(recordDate) OVER (ORDER BY recordDate) AS PrevD
          FROM Weather 
        ) q
 WHERE temperature > PrevT AND recordDate = DATE_ADD(PrevD, INTERVAL 1 DAY)

-- Another solution
SELECT W1.id 
  FROM Weather W1 
       INNER JOIN Weather W2 
       ON W1.recordDate = DATE_ADD(W2.recordDate, INTERVAL 1 DAY) 
 WHERE W1.temperature > W2.temperature


/* Employee Bonus */
SELECT name, bonus
  FROM Employee 
       LEFT JOIN Bonus
       ON Employee.empId = Bonus.empId
 WHERE bonus < 1000 OR bonus IS NULL

-- Another solution
SELECT name, bonus
  FROM Employee 
       LEFT JOIN Bonus
       ON Employee.empId = Bonus.empId
 WHERE bonus < 1000

 UNION ALL

 SELECT name, bonus
  FROM Employee 
       LEFT JOIN Bonus
       ON Employee.empId = Bonus.empId
 WHERE bonus IS NULL


 /* Find Customer Referee */
SELECT name
  FROM Customer
 WHERE referee_id <> 2 OR referee_id IS NULL

-- Another solution
SELECT name
  FROM Customer
 WHERE referee_id < 2 

 UNION ALL 

 SELECT name
   FROM Customer
  WHERE referee_id > 2

  UNION ALL
   
 SELECT name
   FROM Customer
  WHERE referee_id IS NULL


/* Customer Placing the Largest Number of Orders */
SELECT customer_number
  FROM (  SELECT customer_number, COUNT(1) AS orders
            FROM Orders
        GROUP BY customer_number
        ORDER BY orders DESC
           LIMIT 1
       ) q

-- Another solution
  SELECT customer_number
    FROM Orders
GROUP BY customer_number
ORDER BY COUNT(1) DESC
   LIMIT 1


/* Big Countries */
SELECT name, population, area
  FROM World
 WHERE population >= 25000000 OR area >= 3000000


/* Classes More Than 5 Students */
  SELECT class
    FROM Courses
GROUP BY class
  HAVING COUNT(1) >= 5


/* Average Selling Price */
  SELECT UnitsSold.product_id, ROUND(SUM(units * price) / SUM(units), 2) AS average_price
    FROM UnitsSold
         INNER JOIN Prices
         ON UnitsSold.product_id = Prices.product_id
            AND purchase_date BETWEEN start_date AND end_date
GROUP BY UnitsSold.product_id

   UNION ALL

  SELECT product_id, 0 AS average_price
    FROM Prices
   WHERE product_id NOT IN (SELECT DISTINCT product_id FROM UnitsSold)

-- Another solution
  SELECT Prices.product_id, IFNULL(ROUND(SUM(units * price) / SUM(units), 2), 0) AS average_price
    FROM UnitsSold
         RIGHT JOIN Prices 
         ON UnitsSold.product_id = Prices.product_id
            AND purchase_date BETWEEN start_date AND end_date
GROUP BY Prices.product_id


/* Patients With a Condition */
SELECT patient_id, patient_name, conditions 
  FROM Patients
 WHERE conditions LIKE "% DIAB1%" OR conditions LIKE "DIAB1%" 


/* Find Users With Valid E-Mails */
SELECT *
  FROM Users
 WHERE mail REGEXP '^[A-Za-z][A-Za-z0-9._-]*@leetcode\\.com$'
                -- '^[A-Za-z]+[A-Za-z0-9\\._-]*@leetcode\\.com$'
        --  REGEXP_LIKE(mail, '^[A-Za-z]+[A-Za-z0-9\_\.\-]*@leetcode\\.com$')


/* Queries Quality and Percentage */
  SELECT query_name, 
         ROUND(SUM(rating / position) / COUNT(*), 2) AS quality, 
         ROUND(AVG(rating < 3) * 100, 2) AS poor_query_percentage
    FROM Queries
   WHERE query_name IS NOT NULL
GROUP BY query_name


/* Sales Analysis III */
  SELECT DISTINCT Sales.product_id, product_name
    FROM Sales
         INNER JOIN Product
         ON Sales.product_id = Product.product_id 
GROUP BY Sales.product_id
  HAVING MIN(sale_date) >= '2019-01-01' AND MAX(sale_date) <= '2019-03-31'


/* Employees Whose Manager Left the Company */
  SELECT e1.employee_id
    FROM Employees e1
         LEFT JOIN Employees e2
         ON e1.manager_id = e2.employee_id
   WHERE e1.salary < 30000 AND e1.manager_id IS NOT NULL AND e2.employee_id IS NULL
ORDER BY e1.employee_id

-- Another solution
  SELECT employee_id
    FROM Employees a
   WHERE salary < 30000 
         AND manager_id IS NOT NULL
         AND NOT EXISTS (SELECT 1 
                           FROM Employees b
                          WHERE b.employee_id = a.manager_id
                        )
ORDER BY employee_id

-- Another solution
  SELECT employee_id
    FROM Employees
   WHERE salary < 30000 
         AND manager_id IS NOT NULL
         AND manager_id  NOT IN (SELECT employee_id FROM Employees)
ORDER BY EMPLOYEE_ID


/* User Activity for the Past 30 Days I */
  SELECT activity_date AS day, COUNT(DISTINCT user_id) AS active_users 
    FROM Activity 
   WHERE activity_date <= '2019-07-27' AND DATEDIFF('2019-07-27', activity_date) < 30
GROUP BY activity_date

-- Another solution
  SELECT activity_date AS day, COUNT(*) AS active_users 
    FROM (  SELECT DISTINCT user_id, activity_date
              FROM Activity 
             WHERE activity_date <= '2019-07-27' AND DATEDIFF('2019-07-27', activity_date) < 30
          GROUP BY user_id, activity_date
         ) q
GROUP BY activity_date


/* The Number of Employees Which Report to Each Employee */
  SELECT e2.employee_id, e2.name, 
         COUNT(e1.employee_id) AS reports_count, 
         ROUND(SUM(e1.age) / COUNT(e1.employee_id)) AS average_age
    FROM Employees e1
         INNER JOIN Employees e2
         ON e1.reports_to = e2.employee_id
GROUP BY e2.employee_id
ORDER BY e2.employee_id


/* Percentage of Users Attended a Contest */
  SELECT contest_id,
         ROUND(COUNT(user_id) / (SELECT COUNT(user_id) FROM Users) * 100, 2) AS percentage
    FROM Register
GROUP BY contest_id
ORDER BY percentage DESC, contest_id


/* Top Travellers */
  SELECT name, IFNULL(SUM(distance), 0) AS travelled_distance
    FROM Rides 
         RIGHT JOIN Users
         ON Rides.user_id = Users.id
GROUP BY user_id
ORDER BY travelled_distance DESC, name


/* Calculate Special Bonus */
  SELECT employee_id, 
         CASE
           WHEN employee_id % 2 <> 0 AND name NOT LIKE 'M%' THEN salary
           ELSE 0
         END AS bonus
    FROM Employees
ORDER BY employee_id

-- Another solution
  SELECT employee_id, 
         IF(employee_id % 2 <> 0 AND name NOT LIKE 'M%', salary, 0) AS bonus
    FROM Employees
ORDER BY employee_id


/* Students and Examinations */
  SELECT Students.student_id, student_name, Subjects.subject_name, 
         IFNULL(COUNT(Examinations.subject_name), 0) AS attended_exams
    FROM Students 
         CROSS JOIN Subjects
         LEFT JOIN Examinations
         ON Students.student_id = Examinations.student_id
            AND Subjects.subject_name = Examinations.subject_name
GROUP BY Students.student_id, Subjects.subject_name 
ORDER BY Students.student_id, Subjects.subject_name 

-- Another solution
  SELECT q.student_id, student_name, q.subject_name, 
         IFNULL(COUNT(Examinations.subject_name), 0) AS attended_exams
    FROM (SELECT student_id, student_name, subject_name
            FROM Students, Subjects
         ) q
         LEFT JOIN Examinations
         ON q.student_id = Examinations.student_id
            AND q.subject_name = Examinations.subject_name
GROUP BY q.student_id, q.subject_name 
ORDER BY q.student_id, q.subject_name 


/* Fix Names in a Table */
  SELECT user_id, CONCAT(UPPER(LEFT(name, 1)), LOWER(SUBSTRING(name, 2))) AS name
    FROM Users
ORDER BY user_id


/*Project Employees I */
  SELECT project_id, ROUND(SUM(experience_years) / COUNT(employee_id), 2) AS average_years
    FROM Project 
         INNER JOIN Employee
         USING (employee_id)
GROUP BY project_id 


/* Primary Department for Each Employee */
  SELECT employee_id, department_id
    FROM Employee
   WHERE primary_flag LIKE 'Y'

   UNION ALL

  SELECT employee_id, department_id
    FROM Employee
GROUP BY employee_id
  HAVING COUNT(department_id) = 1
ORDER BY employee_id


/* Biggest Single Number */
SELECT (   SELECT num
             FROM MyNumbers
         GROUP BY num
           HAVING COUNT(*) < 2
         ORDER BY num DESC
            LIMIT 1 
       ) num


/* Sales Person */
SELECT name
  FROM SalesPerson
 WHERE sales_id NOT IN (SELECT sales_id
                          FROM Orders 
                               INNER JOIN Company
                               USING(com_id)
                         WHERE Company.name LIKE 'RED'
                       )

            
/* Customer Who Visited but Did Not Make Any Transactions */
  SELECT customer_id, COUNT(visit_id) AS count_no_trans
    FROM Visits
   WHERE visit_id NOT IN (SELECT visit_id FROM Transactions)
GROUP BY customer_id


/* Average Time of Process per Machine */
  SELECT machine_id, ROUND(AVG(diff), 3) AS processing_time
    FROM (SELECT machine_id, 
                 ABS(timestamp - LAG(timestamp, 1, timestamp) 
                                 OVER (PARTITION BY machine_id, process_id)) AS diff
            FROM Activity
         ) q
   WHERE diff <> 0 
GROUP BY machine_id


/* Find Followers Count */
  SELECT user_id, COUNT(*) AS followers_count
    FROM Followers
GROUP BY user_id
ORDER BY user_id


/* Actors and Directors Who Cooperated At Least Three Times */
  SELECT actor_id, director_id
    FROM ActorDirector
GROUP BY actor_id, director_id
  HAVING COUNT(*) > 2


/* List the Products Ordered in a Period */
  SELECT product_name, SUM(unit) AS unit  
    FROM Orders
         INNER JOIN Products
         USING(product_id)
   WHERE DATE_FORMAT(order_date, '%Y-%m') = '2020-02'
GROUP BY product_id 
  HAVING SUM(unit) >= 100


/* Triangle Judgement */
SELECT *, IF(x + y > z AND x + z > y AND y + z > x, 'Yes', 'No') AS triangle 
  FROM Triangle


/* Employees With Missing Information */
WITH full_outer_join (employee_id, name, salary) AS
    (SELECT Employees.employee_id, name, salary
       FROM Employees
            LEFT JOIN Salaries
            ON Employees.employee_id = Salaries.employee_id
      
      UNION ALL 
      
      SELECT Salaries.employee_id, name, salary
        FROM Employees
             RIGHT JOIN Salaries
             ON Employees.employee_id = Salaries.employee_id
    )

  SELECT employee_id 
    FROM full_outer_join
GROUP BY employee_id 
  HAVING COUNT(*) = 1
ORDER BY employee_id

-- Another solution
WITH full_outer_join (employee_id, name, salary) AS
    (SELECT Employees.employee_id, name, salary
       FROM Employees
            LEFT JOIN Salaries
            ON Employees.employee_id = Salaries.employee_id
      
      UNION ALL 
      
      SELECT Salaries.employee_id, name, salary
        FROM Employees
             RIGHT JOIN Salaries
             ON Employees.employee_id = Salaries.employee_id
    )

  SELECT DISTINCT employee_id 
    FROM full_outer_join
   WHERE name IS NULL OR salary IS NULL
ORDER BY employee_id

-- Another solution
WITH full_outer_join (employee_id, name, salary) AS
    (SELECT Employees.employee_id, name, salary
       FROM Employees
            LEFT JOIN Salaries
            ON Employees.employee_id = Salaries.employee_id
      
      UNION 
      
      SELECT Salaries.employee_id, name, salary
        FROM Employees
             RIGHT JOIN Salaries
             ON Employees.employee_id = Salaries.employee_id
    )

  SELECT employee_id 
    FROM full_outer_join
   WHERE name IS NULL OR salary IS NULL
ORDER BY employee_id


/* Not Boring Movies */
  SELECT *
    FROM Cinema
   WHERE id % 2 <> 0 AND description NOT LIKE '%boring%'
ORDER BY rating DESC


/* Game Play Analysis I */
SELECT player_id, event_date AS first_login
  FROM (SELECT *, DENSE_RANK() OVER (PARTITION BY player_id ORDER BY event_date) AS ds
          FROM Activity 
       ) q
 WHERE ds = 1

-- Another solution
  SELECT player_id, MIN(event_date) AS first_login
    FROM ACtivity 
GROUP BY player_id


/* Article Views I */
  SELECT DISTINCT author_id AS id
    FROM Views
   WHERE author_id = viewer_id
ORDER BY author_id 


/* Reformat Department Table */
  SELECT id,
         SUM(IF (MONTH = "Jan", revenue, NULL)) AS Jan_Revenue,
         SUM(IF (MONTH = "Feb", revenue, NULL)) AS Feb_Revenue,
         SUM(IF (MONTH = "Mar", revenue, NULL)) AS Mar_Revenue,
         SUM(IF (MONTH = "Apr", revenue, NULL)) AS Apr_Revenue,
         SUM(IF (MONTH = "May", revenue, NULL)) AS May_Revenue,
         SUM(IF (MONTH = "Jun", revenue, NULL)) AS Jun_Revenue,
         SUM(IF (MONTH = "Jul", revenue, NULL)) AS Jul_Revenue,
         SUM(IF (MONTH = "Aug", revenue, NULL)) AS Aug_Revenue,
         SUM(IF (MONTH = "Sep", revenue, NULL)) AS Sep_Revenue,
         SUM(IF (MONTH = "Oct", revenue, NULL)) AS Oct_Revenue,
         SUM(IF (MONTH = "Nov", revenue, NULL)) AS Nov_Revenue,
         SUM(IF (MONTH = "Dec", revenue, NULL)) AS Dec_Revenue
    FROM Department
GROUP BY id

-- Another solution
  SELECT id,
         MAX(CASE WHEN month = 'Jan' THEN revenue END) AS Jan_Revenue,
         MAX(CASE WHEN month = 'Feb' THEN revenue END) AS Feb_Revenue,
         MAX(CASE WHEN month = 'Mar' THEN revenue END) AS Mar_Revenue,
         MAX(CASE WHEN month = 'Apr' THEN revenue END) AS Apr_Revenue,
         MAX(CASE WHEN month = 'May' THEN revenue END) AS May_Revenue,
         MAX(CASE WHEN month = 'Jun' THEN revenue END) AS Jun_Revenue,
         MAX(CASE WHEN month = 'Jul' THEN revenue END) AS Jul_Revenue,
         MAX(CASE WHEN month = 'Aug' THEN revenue END) AS Aug_Revenue,
         MAX(CASE WHEN month = 'Sep' THEN revenue END) AS Sep_Revenue,
         MAX(CASE WHEN month = 'Oct' THEN revenue END) AS Oct_Revenue,
         MAX(CASE WHEN month = 'Nov' THEN revenue END) AS Nov_Revenue,
         MAX(CASE WHEN month = 'Dec' THEN revenue END) AS Dec_Revenue
    FROM Department
GROUP BY id


/* The Latest Login in 2020 */
  SELECT user_id, last_stamp
    FROM (SELECT user_id, time_stamp, 
                 MAX(time_stamp) OVER (PARTITION BY user_id) AS last_stamp  
            FROM Logins 
           WHERE YEAR(time_stamp) = '2020'
         ) AS q
GROUP BY user_id 

-- Another solution
  SELECT user_id, MAX(time_stamp) AS last_stamp 
    FROM Logins
   WHERE YEAR(time_stamp) = 2020 -- EXTRACT(YEAR FROM time_stamp) = '2020';
GROUP BY user_id


/* Group Sold Products By The Date */
  SELECT sell_date, COUNT(DISTINCT product) AS num_sold,
         GROUP_CONCAT(DISTINCT product ORDER BY product ASC) AS products
    FROM Activities
GROUP BY sell_date
ORDER BY sell_date


/* Bank Account Summary II */
  SELECT name, SUM(amount) AS balance
    FROM Transactions 
         INNER JOIN Users
         ON Users.account = Transactions.account
GROUP BY name
  HAVING SUM(amount) > 10000


/* Swap Salary */
UPDATE Salary
   SET sex = IF(sex = 'm', 'f', 'm')

-- Another solution
UPDATE Salary
   SET sex = CASE
               WHEN sex = 'm' THEN 'f'
               WHEN sex = 'f' THEN 'm'
             END
            

/* Replace Employee ID With The Unique Identifier */
SELECT unique_id, name
  FROM Employees
       LEFT JOIN EmployeeUNI
       ON Employees.id = EmployeeUNI.id


/* Product Sales Analysis I */
  SELECT product_name, year, price
    FROM Sales
         INNER JOIN Product
         USING(product_id)
GROUP BY sale_id, year     -- можно и без GROUP BY, но сним время меньше (возможн из-за индекса)


/* Rearrange Products Table */
SELECT product_id, 'store1' AS store, store1 AS price 
  FROM Products 
 WHERE store1 IS NOT NULL

 UNION ALL

SELECT product_id, 'store2' AS store, store2 AS price 
  FROM Products 
 WHERE store2 IS NOT NULL

 UNION ALL

SELECT product_id, 'store3' AS store, store3 AS price 
  FROM Products 
 WHERE store3 IS NOT NULL

-- Another solution
    WITH CTE (product_id, store, price) AS
        (SELECT product_id, 'store1' AS store, store1 AS price 
           FROM Products 
          WHERE store1 IS NOT NULL

          UNION ALL

         SELECT product_id, 'store2' AS store, store2 AS price 
           FROM Products 
          WHERE store2 IS NOT NULL

          UNION ALL

         SELECT product_id, 'store3' AS store, store3 AS price 
           FROM Products 
          WHERE store3 IS NOT NULL
        )
  SELECT * 
    FROM CTE
ORDER BY product_id, store


/* Invalid Tweets */
SELECT tweet_id
  FROM Tweets
 WHERE LENGTH(content) > 15


/* Daily Leads and Partners */
  SELECT date_id, make_name, 
         COUNT(DISTINCT lead_id) AS unique_leads, 
         COUNT(DISTINCT partner_id) AS unique_partners 
    FROM DailySales
GROUP BY date_id, make_name


/* Find Total Time Spent by Each Employee */
  SELECT event_day AS day, emp_id, 
         SUM(out_time - in_time) AS total_time 
    FROM Employees
GROUP BY emp_id, event_day


/* Number of Unique Subjects Taught by Each Teacher */
  SELECT teacher_id, COUNT(DISTINCT subject_id) AS cnt
    FROM Teacher
GROUP BY teacher_id


/* Recyclable and Low Fat Products */
SELECT product_id
  FROM Products
 WHERE low_fats = 'Y' AND recyclable = 'Y'


/* First Letter Capitalization II */

/* PostgreSQL solution */
SELECT content_id, content_text AS original_text, 
       initcap(content_text) AS converted_text 
  FROM user_content

/* MySQL solution */
    WITH RECURSIVE iter (pos) AS 
         (SELECT 1 AS pos
           
           UNION ALL

          SELECT i.pos + 1
            FROM iter i
           WHERE i.pos + 1 <= (SELECT MAX(LENGTH(content_text)) 
                                 FROM user_content
                              )
         ),
         t AS 
         (SELECT content_id, content_text, iter.pos,
                 SUBSTRING(content_text, iter.pos, 1) AS token,
                 LAG(SUBSTRING(content_text, iter.pos, 1)) OVER (PARTITION BY content_id ORDER BY iter.pos) AS prev_token
            FROM user_content, iter
           WHERE SUBSTRING(content_text, iter.pos, 1) IS NOT NULL
         )
  SELECT content_id, content_text AS original_text,
         GROUP_CONCAT(CASE 
                        WHEN prev_token IS NULL OR prev_token IN (' ', '-') THEN UPPER(token)
                        ELSE LOWER(token)
                      END ORDER BY pos SEPARATOR ''
                     ) AS converted_text
    FROM t
GROUP BY content_id, content_text

/* MySQL solution =)))))))))))))))))))))))))))))) */ 
SELECT content_id, content_text AS original_text,
       REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
       CONCAT(
         UPPER(SUBSTRING(content_text, 1, 1)), 
         LOWER(SUBSTRING(content_text, 2, LENGTH(content_text) - 1))),
        " z", " Z"), " y", " Y"), " x", " X"), " w", " W"), " v", " V"), " u", " U"), " t", " T"), " s", " S"), " r", " R"), " q", " Q"), " p", " P"), " o", " O"), " n", " N"), " m", " M"), " l", " L"), " k", " K"), " j", " J"), " i", " I"), " h", " H"), " g", " G"), " f", " F"), " e", " E"), " d", " D"), " c", " C"), " b", " B"), " a", " A") ,"-z", "-Z"),"-y", "-Y"),"-x", "-X"),"-w", "-W"),"-v", "-V"),"-u", "-U"),"-t", "-T"),"-s", "-S"),"-r", "-R"),"-q", "-Q"),"-p", "-P"),"-o", "-O"),"-n", "-N"),"-m", "-M"),"-l", "-L"),"-k", "-K"),"-j", "-J"),"-i", "-I"),"-h", "-H"),"-g", "-G"),"-f", "-F"),"-e", "-E"),"-d", "-D"),"-c", "-C"),"-b", "-B"),"-a", "-A") AS converted_text 
  FROM user_content


/* Find Students Who Improved */
  SELECT student_id, subject, first_score, score AS latest_score
    FROM (SELECT student_id, subject, score,
                 IF(score - LAG(score, 1, score) 
                            OVER (PARTITION BY student_id, subject ORDER BY exam_date) > 0, 1, 0) AS improve,
                 LAG(score, 1, score) 
                 OVER (PARTITION BY student_id, subject ORDER BY exam_date) AS first_score
            FROM (SELECT *, MIN(exam_date) OVER (PARTITION BY student_id, subject) AS first_exam,
                         MAX(exam_date) OVER (PARTITION BY student_id, subject) AS last_exam
                    FROM Scores
                 ) s
           WHERE exam_date = first_exam OR exam_date = last_exam
         )  s1 
   WHERE improve = 1
ORDER BY student_id, subject 

-- Another solution
  WITH CTE1 AS 
       (SELECT *, MIN(exam_date) OVER (PARTITION BY student_id, subject) AS first_exam,
               MAX(exam_date) OVER (PARTITION BY student_id, subject) AS last_exam
          FROM Scores
       ),
       CTE2 AS 
       (  SELECT student_id, subject,
                 MIN(CASE WHEN exam_date = first_exam THEN score END) AS first_score,
                 MAX(CASE WHEN exam_date = last_exam THEN score END) AS latest_score
            FROM CTE1 
        GROUP BY student_id, subject
          HAVING COUNT(*) > 1
       )
       
SELECT student_id, subject, first_score, latest_score
  FROM CTE2
 WHERE latest_score > first_score

-- Another solution
  WITH RankedScores AS 
       (SELECT *, RANK() OVER (PARTITION BY student_id, subject ORDER BY exam_date) AS rn_asc,
               RANK() OVER (PARTITION BY student_id, subject ORDER BY exam_date DESC) AS rn_desc
          FROM Scores
       ),
       FirstLastScores AS 
       (  SELECT student_id, subject,
                 MIN(CASE WHEN rn_asc = 1 THEN score END) AS first_score,
                 MAX(CASE WHEN rn_desc = 1 THEN score END) AS latest_score
            FROM RankedScores 
        GROUP BY student_id, subject
          HAVING COUNT(*) > 1
       )

SELECT student_id, subject, first_score, latest_score
  FROM FirstLastScores
 WHERE latest_score > first_score


/* SQL Squid Game */
SELECT FLOOR(AVG(diff / 365.2425))
  FROM (  SELECT fi.failure_date - e.installation_date diff
            FROM failure_incidents fi
                 JOIN equipment e
                      ON fi.failed_equipment_id = e.id
                 JOIN suppliers s
                      ON e.supplier_id = s.id
        ORDER BY COUNT(fi.failure_type) OVER (PARTITION BY e.game_type) DESC,
	   	         COUNT(fi.failure_type) OVER (PARTITION BY e.game_type, s.name) DESC,
 	             DENSE_RANK() OVER (PARTITION BY e.game_type, s.name, e.id ORDER BY fi.failure_date)
	       LIMIT 3
       )

/* SQL Squid Game */
  SELECT id, first_name, last_name, last_moved_time_seconds
    FROM player
   WHERE game_id = (  SELECT game_id
                        FROM player
                       WHERE death_description ~ '^.*[Pp]ushed.*$'
                    ORDER BY AVG(last_moved_time_seconds) OVER (PARTITION BY game_id) DESC
                       LIMIT 1
                   )
         AND death_description ~ '^.*[Pp]ushed.*$'
ORDER BY last_moved_time_seconds DESC
   LIMIT 1


/* Find Products with Valid Serial Numbers */
  SELECT *
    FROM products
   WHERE description ~ '^.*SN\d{4}-\d{4}\D*$'
ORDER BY product_id

-- Another solution
SELECT *
  FROM products
 WHERE description LIKE '%SN____-____'
       OR description LIKE '%SN____-____ %'


/* Find Valid Emails */
  SELECT user_id, email
    FROM Users
   WHERE email ~ '^\w+@[a-zA-Z]+\.com$'
ORDER BY user_id


/* DNA Pattern Recognition */
  SELECT sample_id, dna_sequence, species,
         CASE WHEN dna_sequence ~ '^ATG.*$' THEN 1 ELSE 0 END has_start,
         CASE WHEN dna_sequence ~ '^.*(TAA|TAG|TGA)$' THEN 1 ELSE 0 END has_stop,
         CASE WHEN dna_sequence ~ '^.*ATAT.*$' THEN 1 ELSE 0 END has_atat,
         CASE WHEN dna_sequence ~ '^.*G{3,}.*$' THEN 1 ELSE 0 END has_ggg
    FROM Samples
ORDER BY sample_id

-- Another solution
  SELECT sample_id, dna_sequence, species,
         dna_sequence LIKE 'ATG%' has_start,
         dna_sequence LIKE ANY(ARRAY['%TAA','%TAG','%TGA']) has_stop,
         dna_sequence LIKE '%ATAT%' has_atat,
         dna_sequence LIKE '%GGG%' has_ggg
    FROM Samples
ORDER BY sample_id


/* Analyze Subscription Conversion */
  SELECT user_id,
         MAX(CASE WHEN activity_type = 'free_trial' THEN avg_duration END) trial_avg_duration,
         MAX(CASE WHEN activity_type = 'paid' THEN avg_duration END) paid_avg_duration
    FROM (SELECT DISTINCT user_id, activity_type,
                 ROUND(AVG(activity_duration) OVER (PARTITION BY user_id, activity_type), 2) avg_duration
            FROM UserActivity us1
           WHERE EXISTS ( SELECT 1
                            FROM UserActivity us2
                           WHERE activity_type = 'paid'
                                 AND us1.user_id = us2.user_id
                        )
         ) q
GROUP BY user_id
ORDER BY user_id

-- Another solution
  SELECT user_id,
         ROUND(AVG(activity_duration) FILTER(WHERE activity_type = 'free_trial'), 2) AS trial_avg_duration,
         ROUND(AVG(activity_duration) FILTER(WHERE activity_type = 'paid'), 2) AS paid_avg_duration
    FROM useractivity
GROUP BY user_id
  HAVING BOOL_OR(activity_type = 'free_trial') AND BOOL_OR(activity_type = 'paid')
ORDER BY user_id

-- Another solution
  SELECT user_id,
         ROUND(AVG(CASE WHEN activity_type = 'free_trial' THEN activity_duration END), 2) AS trial_avg_duration,
         ROUND(AVG(CASE WHEN activity_type = 'paid' THEN activity_duration END), 2) AS paid_avg_duration
    FROM UserActivity
GROUP BY user_id
  HAVING SUM(CASE WHEN activity_type = 'free_trial' THEN 1 ELSE 0 END) > 0
         AND SUM(CASE WHEN activity_type = 'paid' THEN 1 ELSE 0 END) > 0
ORDER BY user_id;


/* Find COVID Recovery Patients */
    WITH maybe_recovered (patient_id) AS
         (   SELECT patient_id
               FROM covid_tests
              WHERE result = 'Positive'
          INTERSECT
             SELECT patient_id
               FROM covid_tests
              WHERE result = 'Negative'
         ),
         first_positive_test (patient_id, fptd) AS
         (  SELECT ct.patient_id, MIN(test_date)
              FROM covid_tests ct
                   JOIN maybe_recovered mr
                   ON ct.patient_id = mr.patient_id
             WHERE result = 'Positive'
          GROUP BY ct.patient_id
         ),
         first_negative_test (patient_id, fntd) AS
         (  SELECT patient_id, MIN(test_date)
              FROM covid_tests ct
             WHERE EXISTS ( SELECT 1
                              FROM first_positive_test fpt
                             WHERE ct.patient_id = fpt.patient_id
                                   AND ct.result = 'Negative'
                                   AND fpt.fptd < ct.test_date
                          )
          GROUP BY patient_id
         )
  SELECT p.patient_id, patient_name, age, fntd-fptd recovery_time
    FROM patients p
         JOIN first_positive_test fpt
         ON p.patient_id = fpt.patient_id
         JOIN first_negative_test fnt
         ON p.patient_id = fnt.patient_id
ORDER BY recovery_time, patient_name

-- Another solution
    WITH first_positive_test (patient_id, fptd) AS
         (  SELECT patient_id, MIN(test_date)
              FROM covid_tests
             WHERE result = 'Positive'
          GROUP BY patient_id
         ),
         first_negative_test (patient_id, fntd) AS
         (  SELECT patient_id, MIN(test_date)
              FROM covid_tests ct
             WHERE EXISTS ( SELECT 1
                              FROM first_positive_test fpt
                             WHERE ct.patient_id = fpt.patient_id
                                   AND ct.result = 'Negative'
                                   AND fpt.fptd < ct.test_date
                          )
          GROUP BY patient_id
         )
  SELECT p.patient_id, patient_name, age, fntd-fptd recovery_time
    FROM patients p
         JOIN first_positive_test fpt
         ON p.patient_id = fpt.patient_id
         JOIN first_negative_test fnt
         ON p.patient_id = fnt.patient_id
ORDER BY recovery_time, patient_name

-- Another solution
    WITH first_positive_test (patient_id, fptd) AS
         (  SELECT patient_id, MIN(test_date)
              FROM covid_tests
             WHERE result = 'Positive'
          GROUP BY patient_id
         ),
         recovered (patient_id, fptd, fntd) AS
         (  SELECT ct.patient_id, fptd, MIN(test_date)
              FROM covid_tests ct
                   JOIN first_positive_test fpt
                   ON ct.patient_id = fpt.patient_id
             WHERE ct.result = 'Negative' AND fpt.fptd < ct.test_date
          GROUP BY ct.patient_id, fptd
         )
  SELECT p.patient_id, patient_name, age, fntd-fptd recovery_time
    FROM patients p
         JOIN recovered r
         ON p.patient_id = r.patient_id
ORDER BY recovery_time, patient_name


/* Find Books with No Available Copies */
  SELECT book_id, title, author, genre, publication_year, total_copies current_borrowers
    FROM library_books lb
   WHERE EXISTS (  SELECT 1
                     FROM borrowing_records br
                    WHERE return_date IS NULL
                 GROUP BY book_id
                   HAVING COUNT(1) = lb.total_copies
                          AND br.book_id = lb.book_id
                )
ORDER BY current_borrowers DESC, title

-- Another solution
  SELECT lb.book_id, title, author, genre, publication_year, current_borrowers
    FROM library_books lb
         JOIN (  SELECT book_id, COUNT(1) current_borrowers
                   FROM borrowing_records br
                  WHERE return_date IS NULL
               GROUP BY book_id
              ) cb
         ON lb.book_id = cb.book_id
   WHERE total_copies = current_borrowers
ORDER BY current_borrowers DESC, title


/* Find Consistently Improving Employees */
    WITH CTE (rev_num, employee_id, improve, improvement_score) AS
         (SELECT ROW_NUMBER() OVER (PARTITION BY employee_id),
                 employee_id,
                 LAG(rating, 1, rating) OVER (PARTITION BY employee_id ORDER BY review_date DESC) - rating,
                 LAG(rating, 2, rating) OVER (PARTITION BY employee_id ORDER BY review_date DESC) - rating
            FROM performance_reviews
         )
  SELECT e.employee_id, e.name, MAX (CASE WHEN rev_num = 3 THEN improvement_score END) improvement_score
    FROM employees e
         JOIN CTE
         ON e.employee_id = CTE.employee_id
   WHERE EXISTS (  SELECT 1
                     FROM CTE
                    WHERE (rev_num = 2 OR rev_num = 3)
                          AND e.employee_id = CTE.employee_id
                 GROUP BY employee_id
                   HAVING SUM(improve) > 1 AND MAX(rev_num) > 2
                )
GROUP BY e.employee_id, e.name
ORDER BY improvement_score DESC, e.name

-- Another solution
    WITH CTE (rev_num, employee_id, improve, improvement_score) AS
         (SELECT ROW_NUMBER() OVER (PARTITION BY employee_id),
                 employee_id,
                 LAG(rating, 1, rating) OVER (PARTITION BY employee_id ORDER BY review_date DESC) - rating,
                 LAG(rating, 2, rating) OVER (PARTITION BY employee_id ORDER BY review_date DESC) - rating
            FROM performance_reviews
         ),
         CTE2 AS
         (  SELECT employee_id
              FROM CTE
             WHERE rev_num = 2 OR rev_num = 3
          GROUP BY employee_id
            HAVING SUM(improve) > 1 AND MAX(rev_num) > 2
         )
  SELECT e.employee_id, e.name, MAX (CASE WHEN rev_num = 3 THEN improvement_score END) improvement_score
    FROM employees e
         JOIN CTE2
         ON e.employee_id = CTE2.employee_id
         JOIN CTE
         ON CTE2.employee_id = CTE.employee_id
GROUP BY e.employee_id, e.name
ORDER BY improvement_score DESC, e.name


/* Seasonal Sales Analysis */
    WITH CTE (season, category, total_quantity, total_revenue) AS
         (  SELECT CASE
                     WHEN EXTRACT(MONTH FROM sale_date) IN (9, 10, 11) THEN 'Fall'
                     WHEN EXTRACT(MONTH FROM sale_date) IN (12, 1, 2) THEN 'Winter'
                     WHEN EXTRACT(MONTH FROM sale_date) IN (3, 4, 5) THEN 'Spring'
                     ELSE 'Summer'
                   END season,
                   category,
                   SUM(quantity),
                   SUM (quantity * price)
              FROM sales s
                   JOIN products p
                   ON s.product_id = p.product_id
          GROUP BY CASE
                     WHEN EXTRACT(MONTH FROM sale_date) IN (9, 10, 11) THEN 'Fall'
                     WHEN EXTRACT(MONTH FROM sale_date) IN (12, 1, 2) THEN 'Winter'
                     WHEN EXTRACT(MONTH FROM sale_date) IN (3, 4, 5) THEN 'Spring'
                     ELSE 'Summer'
                   END,
                   category
         ),
         CTE2 (season, category, total_quantity, total_revenue, rank) AS
         (SELECT *, DENSE_RANK() OVER (PARTITION BY season ORDER BY total_quantity DESC)
            FROM CTE
         ),
         CTE3 (season, max_tr) AS
         (  SELECT season, MAX(total_revenue)
              FROM CTE2
             WHERE rank = 1
          GROUP BY season
         )
  SELECT c1.season, category, total_quantity, total_revenue
    FROM CTE2 c1
         JOIN CTE3 c3
         ON c1.season = c3.season AND c1.total_revenue = c3.max_tr
ORDER BY season


/* Find Drivers with Improved Fuel Efficiency */
    WITH CTE (driver_id, fuel_avg, half_of_the_year) AS
        (  SELECT driver_id, AVG(distance_km / fuel_consumed) avg,
                  CASE
                    WHEN EXTRACT(MONTH FROM trip_date) BETWEEN 1 AND 6 THEN 'first_half'
                    WHEN EXTRACT(MONTH FROM trip_date) BETWEEN 7 AND 12 THEN 'second_half'
                  END half_of_the_year
             FROM trips
         GROUP BY driver_id,
                  CASE
                    WHEN EXTRACT(MONTH FROM trip_date) BETWEEN 1 AND 6 THEN 'first_half'
                    WHEN EXTRACT(MONTH FROM trip_date) BETWEEN 7 AND 12 THEN 'second_half'
                  END
        )
  SELECT d.driver_id, driver_name,
         ROUND(SUM(CASE WHEN half_of_the_year = 'first_half' THEN fuel_avg END), 2) first_half_avg,
         ROUND(SUM(CASE WHEN half_of_the_year = 'second_half' THEN fuel_avg END), 2) second_half_avg,
         ROUND(SUM(CASE WHEN half_of_the_year = 'second_half' THEN fuel_avg END) -
         SUM(CASE WHEN half_of_the_year = 'first_half' THEN fuel_avg END), 2) efficiency_improvement
    FROM CTE cte1
         JOIN drivers d
         ON cte1.driver_id = d.driver_id
   WHERE EXISTS (  SELECT 1
                     FROM CTE cte2
                    WHERE cte1.driver_id = cte2.driver_id
                 GROUP BY cte2.driver_id
                   HAVING COUNT(1) > 1
                )
GROUP BY d.driver_id, driver_name
  HAVING SUM(CASE WHEN half_of_the_year = 'first_half' THEN fuel_avg END) <
         SUM(CASE WHEN half_of_the_year = 'second_half' THEN fuel_avg END)
ORDER BY efficiency_improvement DESC, driver_name

--Another solution
    WITH first_half_avg AS
        (  SELECT driver_id, AVG(distance_km / fuel_consumed) AS fuel_efficiency
             FROM trips
            WHERE EXTRACT(MONTH FROM trip_date) <= 6
         GROUP BY driver_id
        ),
        second_half_avg AS
        (  SELECT driver_id, AVG(distance_km / fuel_consumed) AS fuel_efficiency
             FROM trips
            WHERE EXTRACT(MONTH FROM trip_date) > 6
         GROUP BY driver_id
        )
  SELECT a.driver_id,
         c.driver_name,
         ROUND(a.fuel_efficiency, 2) AS first_half_avg,
         ROUND(b.fuel_efficiency, 2) AS second_half_avg,
         ROUND(b.fuel_efficiency - a.fuel_efficiency, 2) AS efficiency_improvement
    FROM first_half_avg a
         JOIN second_half_avg b ON a.driver_id = b.driver_id
         JOIN drivers c ON a.driver_id = c.driver_id
   WHERE b.fuel_efficiency > a.fuel_efficiency
ORDER BY efficiency_improvement DESC, driver_name

--Another solution
  SELECT trips.driver_id,
         drivers.driver_name,
         ROUND(AVG(CASE WHEN EXTRACT(MONTH FROM trip_date) <= 6 THEN trips.distance_km / fuel_consumed END), 2) AS first_half_avg,
         ROUND(AVG(CASE WHEN EXTRACT(MONTH FROM trip_date) > 6 THEN trips.distance_km / fuel_consumed END), 2) AS second_half_avg,
         ROUND(AVG(CASE WHEN EXTRACT(MONTH FROM trip_date) > 6 THEN trips.distance_km / fuel_consumed END) -
               AVG(CASE WHEN EXTRACT(MONTH FROM trip_date) <= 6 THEN trips.distance_km / fuel_consumed END), 2) AS efficiency_improvement
    FROM trips
         JOIN drivers
         ON trips.driver_id = drivers.driver_id
GROUP BY 1, 2
  HAVING ROUND(AVG(CASE WHEN EXTRACT(MONTH FROM trip_date) > 6 THEN trips.distance_km / fuel_consumed END) -
               AVG(CASE WHEN EXTRACT(MONTH FROM trip_date) <= 6 THEN trips.distance_km / fuel_consumed END), 2) > 0
ORDER BY efficiency_improvement DESC , driver_name


/* Find Overbooked Employees */
  SELECT DISTINCT e.employee_id, employee_name, department, meeting_heavy_weeks
    FROM (  SELECT employee_id,
                   COUNT(1) OVER (PARTITION BY employee_id) meeting_heavy_weeks
              FROM meetings
          GROUP BY employee_id, DATE_TRUNC('week', meeting_date)
            HAVING SUM(duration_hours) > 20
         ) q
         JOIN employees e
         ON q.employee_id = e.employee_id
            AND meeting_heavy_weeks > 1
ORDER BY meeting_heavy_weeks DESC, employee_name


/* Find Product Recommendation Pairs */
  SELECT pp1.product_id product1_id,
         pp2.product_id product2_id,
         pi1.category product1_category,
         pi2.category product2_category,
         COUNT(1) customer_count
    FROM ProductPurchases pp1
         JOIN ProductPurchases pp2
         ON pp1.product_id < pp2.product_id
            AND pp1.user_id = pp2.user_id
         JOIN ProductInfo pi1
         ON pp1.product_id = pi1.product_id
         JOIN ProductInfo pi2
         ON pp2.product_id = pi2.product_id
GROUP BY pp1.product_id, pp2.product_id, pi1.category, pi2.category
  HAVING COUNT(1) > 2
ORDER BY customer_count DESC, pp1.product_id, pp2.product_id

-- Another solution
  SELECT pp1.product_id product1_id,
         pp2.product_id product2_id,
         (SELECT category FROM ProductInfo pi WHERE pi.product_id = pp1.product_id) product1_category,
         (SELECT category FROM ProductInfo pi WHERE pi.product_id = pp2.product_id) product2_category,
         COUNT(1) customer_count
    FROM ProductPurchases pp1
         JOIN ProductPurchases pp2
         ON pp1.product_id < pp2.product_id
            AND pp1.user_id = pp2.user_id
GROUP BY pp1.product_id, pp2.product_id
  HAVING COUNT(1) > 2
ORDER BY customer_count DESC, pp1.product_id, pp2.product_id
