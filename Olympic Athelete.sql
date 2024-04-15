SELECT * FROM OLYMPICS_HISTORY;
SELECT * FROM OLYMPICS_HISTORY_NOC_REGIONS;

--  1. How many olympics games have been held?
	SELECT COUNT(total_olympic_games) as Games FROM (
	SELECT COUNT(games) as total_olympic_games FROM OLYMPICS_HISTORY GROUP BY games
		);

-- 2. List down all Olympics games held so far.
	SELECT DISTINCT OLYMPICS_HISTORY.year, OLYMPICS_HISTORY.season, OLYMPICS_HISTORY.city
	FROM OLYMPICS_HISTORY 
	ORDER BY OLYMPICS_HISTORY.year;

-- 3. Mention the total no of nations who participated in each olympics game?


-- 4. Which year saw the highest and lowest no of countries participating in olympics

      with all_countries as
              (select games, nr.region as countries
              from olympics_history oh
              join olympics_history_noc_regions nr ON nr.noc=oh.noc
              group by games, nr.region),
          tot_countries as
              (select games, count(countries) as total_countries
              from all_countries
              group by games order by total_countries)
	select distinct
      concat(first_value(games) over(order by total_countries)
      , ' - '
      , first_value(total_countries) over(order by total_countries)) as Lowest_Countries,
      concat(first_value(games) over(order by total_countries desc)
      , ' - '
      , first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
      from tot_countries
      order by 1;
-- 5. Which nation has participated in all of the olympic games
     with total_games as(
	  select COUNT(DISTINCT oh.games) AS all_games FROM OLYMPICS_HISTORY oh
	 ),
	 cte2 AS (
	 select oh1.NOC,oh1.games from OLYMPICS_HISTORY oh1
		 GROUP BY oh1.games, oh1.NOC ORDER BY oh1.NOC
	 ),
	 cte3 AS (
	 SELECT cte2.NOC,COUNT(cte2.NOC) AS total_games FROM cte2 GROUP BY cte2.NOC
	 ),
	 cte4 AS(
	 SELECT cte3.NOC,cte3.total_games FROM cte3 
		 WHERE cte3.total_games = (select COUNT(DISTINCT oh.games) AS all_games FROM OLYMPICS_HISTORY oh)
	 ),
	 cte5 AS(
	  SELECT no.region,cte4.total_games FROM OLYMPICS_HISTORY_NOC_REGIONS no
		 JOIN cte4 ON cte4.NOC = no.NOC ORDER BY no.region
	 )
	 SELECT * FROM cte5;
	 
-- 6. Identify the sport which was played in all summer olympics.
     with cte1 AS(
	  SELECT COUNT(DISTINCT oh1.games) as total_summer_games FROM olympics_history oh1 
		 WHERE season='Summer' GROUP BY season
	 ),
	 cte2 AS(
	  SELECT DISTINCT oh1.games,oh1.sport FROM olympics_history oh1 WHERE oh1.season = 'Summer'
	 ),
	 cte3 AS(
	  SELECT cte2.sport,COUNT(cte2.sport) AS cnt FROM cte2
		 GROUP BY cte2.sport 
	 ),
	 cte4 AS (
	  SELECT cte3.sport,cte3.cnt AS total_games FROM cte3 where cnt = (select * from cte1)
	 )
	 SELECT * from cte4;

-- 7. Which Sports were just played only once in the olympics.
     WITH cte1 AS (
	  SELECT DISTINCT oh.games, oh.sport FROM olympics_history oh ORDER BY oh.sport,oh.games
	 ),
	 cte2 AS (
	  SELECT cte1.sport,COUNT(cte1.sport) AS cnt FROM cte1 GROUP BY cte1.sport
	 ),
	 cte3 AS (
	  SELECT cte2.sport,cte2.cnt FROM cte2 WHERE cte2.cnt = 1
	 )
	 SELECT DISTINCT cte3.*,oh.games FROM cte3
	 JOIN olympics_history oh ON oh.sport = cte3.sport
	 order by cte3.sport;
	 
-- 	 8. Fetch the total no of sports played in each olympic games.
	WITH cte1 AS (
	 SELECT oh.games, oh.sport FROM olympics_history oh GROUP BY oh.games,oh.sport
	  ORDER BY oh.games 
	),
	cte2 AS (
	 SELECT cte1.games,COUNT(cte1.games) AS no_of_sports FROM cte1 
		GROUP BY cte1.games ORDER BY no_of_sports DESC
	)
	SELECT * FROM cte2;
	
-- 9. Fetch oldest athletes to win a gold medal
	WITH cte AS (
	 SELECT oh1.*,Dense_rank() over(order by oh1.age DESC) AS rnk from olympics_history oh1 WHERE oh1.Medal = 'Gold' AND oh1.Age != 'NA'
		ORDER BY oh1.Age DESC
	)
	SELECT * FROM cte WHERE rnk = 1;

-- 10. Find the Ratio of male and female athletes participated in all olympic games.
    WITH t1 AS (
	 SELECT COUNT(sex) AS cnt FROM olympics_history GROUP BY sex
	)
    select concat('1 : ', round((SELECT MAX(cnt) AS MAX_COUNT FROM t1)::decimal/(SELECT MIN(cnt) AS MAX_COUNT FROM t1), 2))
	as ratio;

-- 11. Fetch the top 5 athletes who have won the most gold medals.
	WITH cte1 AS (
	 SELECT oh1.name,oh1.team,oh1.Medal FROM olympics_history oh1 
		WHERE oh1.Medal = 'Gold' 
	),
	cte2 As (
	 SELECT cte1.name,cte1.team,COUNT(cte1.name) AS total_no_medal FROM cte1 GROUP BY cte1.name,cte1.team ORDER BY total_no_medal DESC
	),
	cte3 AS (
	 SELECT * , DENSE_RANK() OVER (ORDER BY total_no_medal DESC) AS rnk FROM cte2
	)
	SELECT cte3.name,cte3.team,cte3.total_no_medal AS total_medals FROM cte3 WHERE rnk <= 5;
	
-- 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
	WITH cte1 AS (
	 SELECT oh1.name,oh1.team,oh1.Medal FROM olympics_history oh1 
		WHERE oh1.Medal != 'NA' 
	),
	cte2 As (
	 SELECT cte1.name,cte1.team,COUNT(cte1.name) AS total_no_medal FROM cte1 GROUP BY cte1.name,cte1.team ORDER BY total_no_medal DESC
	),
	cte3 AS (
	 SELECT * , DENSE_RANK() OVER (ORDER BY total_no_medal DESC) AS rnk FROM cte2
	)
	SELECT cte3.name,cte3.team,cte3.total_no_medal AS total_medals FROM cte3 WHERE rnk <= 5;
	
	
-- 13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
	with t1 as
            (select nr.region,oh.medal
            from olympics_history oh
            join olympics_history_noc_regions nr on nr.noc = oh.noc
            where medal <> 'NA'
            ),
	t2 AS 
			(SELECT cte.region,COUNT(cte.region) AS total_medals 
			 FROM t1 cte GROUP BY cte.region
			 ORDER BY total_medals DESC
			),
	t3 AS 
			(SELECT * , ROW_NUMBER() OVER (ORDER BY total_medals DESC) AS rnk
			 FROM t2
			)
        
    select * from t3 WHERE rnk<=5;
	
-- 14. List down total gold, silver and bronze medals won by each country.
	with t1 as
            (select nr.region,oh.medal
            from olympics_history oh
            join olympics_history_noc_regions nr on nr.noc = oh.noc
            where medal <> 'NA'
            ),
	t2 AS 
	 		( SELECT *,COUNT(1) AS total_cnt FROM t1 
			 GROUP BY region,medal ORDER BY total_cnt DESC 
			)
	SELECT region,
	(SUM (CASE WHEN medal = 'Gold' THEN total_cnt ELSE 0 END)) AS Gold,
	(SUM (CASE WHEN medal = 'Silver' THEN total_cnt ELSE 0 END)) AS Silver,
	(SUM (CASE WHEN medal = 'Bronze' THEN total_cnt ELSE 0 END)) AS Bronze
	FROM t2 GROUP BY region ORDER BY Gold DESC;
	
-- 15. List down total gold, silver and bronze medals won by each country 
-- corresponding to each olympic games.
	with t1 as
            (select nr.region,oh.medal,oh.games
            from olympics_history oh
            join olympics_history_noc_regions nr on nr.noc = oh.noc
            where medal <> 'NA'
            ),
	t2 AS 
	 		( SELECT *,COUNT(1) AS total_cnt FROM t1 
			 GROUP BY games,region,medal ORDER BY total_cnt DESC 
			)
	SELECT games,region,
	(SUM (CASE WHEN medal = 'Gold' THEN total_cnt ELSE 0 END)) AS Gold,
	(SUM (CASE WHEN medal = 'Silver' THEN total_cnt ELSE 0 END)) AS Silver,
	(SUM (CASE WHEN medal = 'Bronze' THEN total_cnt ELSE 0 END)) AS Bronze
	FROM t2 GROUP BY games,region ORDER BY games,region ASC;
   
-- 16. Identify which country won the most gold, most silver 
-- and most bronze medals in each olympic games.
	with t1 as
            (select nr.region,oh.medal,oh.games
            from olympics_history oh
            join olympics_history_noc_regions nr on nr.noc = oh.noc
            where medal <> 'NA'
            ),
	t2 AS 
	 		( SELECT *,COUNT(1) AS total_cnt FROM t1 
			 GROUP BY games,region,medal ORDER BY total_cnt DESC 
			),
	t3 AS 
		(SELECT games,region,
		(SUM (CASE WHEN medal = 'Gold' THEN total_cnt ELSE 0 END)) AS Gold,
		(SUM (CASE WHEN medal = 'Silver' THEN total_cnt ELSE 0 END)) AS Silver,
		(SUM (CASE WHEN medal = 'Bronze' THEN total_cnt ELSE 0 END)) AS Bronze
		FROM t2 GROUP BY games,region ORDER BY games,region ASC),
	t4 AS
		(SELECT games,MAX(Gold) AS gold, MAX(Silver) AS silver, MAX(Bronze) AS bronze 
		 FROM t3 GROUP BY games
		)
	SELECT * FROM t4;

-- 19. In which Sport/event, India has won highest medals.
	WITH cte AS (
	 SELECT oh.sport,oh.noc,oh.medal 
		from olympics_history oh
        WHERE oh.noc = 'IND' AND oh.medal != 'NA'
	),
	cte2 AS (
		SELECT COUNT(1) AS cnt, oh.sport,oh.noc FROM cte oh 
		GROUP BY oh.sport,oh.noc ORDER BY cnt DESC limit 1
	),cte3 AS (
	  SELECT cte2.sport,cte2.cnt,nr.region FROM cte2
		JOIN OLYMPICS_HISTORY_NOC_REGIONS nr ON nr.noc = cte2.noc
	)
	SELECT * FROM cte3;

-- 20. Break down all olympic games where India won medal 
-- for Hockey and how many medals in each olympic games
   
   WITH cte AS (
	 SELECT oh.games,oh.sport,oh.noc,oh.medal 
		from olympics_history oh
        WHERE oh.noc = 'IND' AND oh.medal != 'NA'AND oh.sport = 'Hockey'
	),
	cte2 AS (
		SELECT oh.games,COUNT(1) AS cnt, oh.sport,oh.noc FROM cte oh 
		GROUP BY oh.noc,oh.sport,oh.medal,oh.games ORDER BY cnt DESC
	),cte3 AS (
	  SELECT cte2.games,cte2.sport,cte2.cnt,nr.region FROM cte2
		JOIN OLYMPICS_HISTORY_NOC_REGIONS nr ON nr.noc = cte2.noc ORDER BY cte2.cnt DESC
	)
	SELECT * FROM cte3;
