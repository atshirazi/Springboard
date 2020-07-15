/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT * FROM Facilities WHERE membercost>0


/* Q2: How many facilities do not charge a fee to members? */

SELECT count(*) FROM Facilities WHERE membercost=0

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid,name, membercost, monthlymaintenance FROM `Facilities` WHERE membercost>0 and membercost<monthlymaintenance*0.2

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT * FROM `Facilities` WHERE faced in (1,5)

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance,
   case when monthlymaintenance>100 then 'expensive'
        else 'cheap' end as 'cheap/expensive'
from Facilities

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT firstname, surname FROM `Members` where joindate in ( select max(joindate) from Members)

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT  
CASE WHEN b.facid =0
THEN CONCAT( m.firstname,  ' ', m.surname,  ', ',  'Tennis Court 1' ) 
WHEN b.facid =1
THEN CONCAT( m.firstname,  ' ', m.surname,  ', ',  'Tennis Court 2' ) 
END AS Name_and_court
FROM Bookings AS b, Members AS m
WHERE b.facid IN ( 0, 1 ) 
GROUP BY Name_and_court
order by m.surname

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */



SELECT concat(m.firstname, ' ', m.surname, ', ', f.name) as Name_and_court, 
CASE 
WHEN m.memid =0
THEN b.slots * f.guestcost
ELSE b.slots * f.membercost
END AS cost
FROM Members AS m
INNER JOIN Bookings AS b
USING ( memid ) 
INNER JOIN Facilities AS f
USING ( facid ) 
WHERE b.starttime like  '2012-09-14%'

AND (
(m.memid =0
AND b.slots * f.guestcost >=30)
OR (m.memid !=0 AND b.slots * f.membercost >=30))

ORDER BY cost DESC 

/* Q9: This time, produce the same result as in Q8, but using a subquery. */

Solution 1)
SELECT CONCAT( sub.name,  ', ', sub.firstname,  ' ', sub.surname ) AS Name_and_court, sub.bookid, sub.slots * ( 
CASE WHEN sub.memid =0
THEN sub.guestcost
ELSE sub.membercost
END ) AS cost

FROM (SELECT b.bookid, b.facid, b.slots, b.memid, f.membercost, f.guestcost, m.firstname, m.surname, f.name
FROM Bookings AS b
INNER JOIN Facilities AS f
USING ( facid ) 
INNER JOIN Members AS m
USING ( memid ) 
WHERE b.starttime LIKE  '2012-09-14%') AS sub

WHERE (sub.memid =0
AND sub.slots * sub.guestcost >=30)
OR (sub.memid !=0
AND sub.slots * sub.membercost >=30)
ORDER BY cost DESC


Solution 2) 

SELECT sub2.bookid, concat(sub2.name,', ', sub2.firstname,' ', sub2.surname) as Name_and_court, cost
from (SELECT sub.name, sub.firstname, sub.surname, sub.memid, sub.bookid, sub.slots*(case when sub.memid=0 then sub.guestcost
                  else sub.membercost end) as cost 
	      			From (SELECT b.bookid, b.facid, b.slots, b.memid, f.membercost, f.guestcost, m.firstname, m.surname,f.name
					FROM Bookings AS b
					INNER JOIN Facilities AS f USING (facid) 
                    inner join Members as m using(memid)     
                    where b.starttime like '2012-09-14%')as sub)as sub2

where cost>30
order by cost desc





/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

SELECT s1.facid, s1.sum_slots_guests, s2.sum_slots_members, (s1.sum_slots_guests*f.guestcost+s2.sum_slots_members*f.membercost) as gross_income, (s1.sum_slots_guests*f.guestcost+s2.sum_slots_members*f.membercost-f.initialoutlay-f.monthlymaintenance*3) as revenue
FROM (

SELECT facid, SUM( slots ) AS sum_slots_guests
FROM Bookings
WHERE memid =0
GROUP BY facid) as s1 
inner join (SELECT facid, SUM( slots ) AS sum_slots_members
FROM Bookings
WHERE memid >0
GROUP BY facid) as s2
using(facid)
inner join Facilities as f
using (facid)
where (s1.sum_slots_guests*f.guestcost+s2.sum_slots_members*f.membercost-f.initialoutlay-f.monthlymaintenance*3)<1000



/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

SELECT concat(m.surname, ', ', m.firstname) as name, m.recommendedby FROM `Members`as m order by name

/* Q12: Find the facilities with their usage by member, but not guests */

SELECT facid, memid , SUM( slots ) 
FROM Bookings
WHERE memid>0
GROUP BY facid, memid
order by facid, memid

#the following code is not relevant
#SELECT DISTINCT memid, facid
#FROM Bookings
#where memid>0
#ORDER BY memid, facid

#the following code is not relevant
#select distinct b.facid
#from Bookings as b
#left join (select s.facid from Bookings as s where memid=0) as s1
#using (facid) where s1.facid is null

/* Q13: Find the facilities usage by month, but not guests */

SELECT facid, EXTRACT( 
MONTH FROM starttime ) AS 
MONTH , SUM( slots ) 
FROM Bookings
WHERE memid>0
GROUP BY facid, MONTH
order by facid, MONTH
