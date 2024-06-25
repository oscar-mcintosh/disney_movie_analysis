DROP TABLE IF EXISTS temp_movie_company;

CREATE TEMPORARY TABLE temp_movie_company AS
	SELECT 
		m.movie_id, 
		m.title, 
		m.budget, 
		m.revenue, 
		m.popularity, 
		m.release_date, 
		m.runtime,
		m.vote_average, 
		m.vote_count, 
		pc.company_name,
		g.genre_name
	FROM movie_company AS mc
	JOIN movie AS m
	ON m.movie_id = mc.movie_id
	JOIN production_company AS pc
	ON pc.company_id = mc.company_id
	JOIN movie_genres AS mg
	ON mg.movie_id = m.movie_id
	JOIN genre AS g
	ON g.genre_id = mg.genre_id
	WHERE pc.company_name LIKE '%Walt%';

	SELECT *
	FROM temp_movie_company
	ORDER BY release_date;

--1. Analyze the revenue of each film after adjusting for inflation.
	
	WITH CurrentCPI AS (
	    SELECT cpi AS current_cpi
	    FROM InflationData
	    WHERE year = 2024
	),		
	FilmCPI AS (
	    SELECT DISTINCT
	        t.title, 
	        t.revenue, 
	        t.release_date, 
	        i.cpi AS release_cpi
	    FROM temp_movie_company AS t
	    JOIN InflationData AS i ON EXTRACT(YEAR FROM t.release_date) = i.year
	 WHERE t.revenue != 0  
	)
	SELECT 
	    f.title,
	    f.release_date,
	    TO_CHAR(f.revenue,'$ FM999,999,999,999') AS revenue,
	    TO_CHAR(ROUND((f.revenue * (c.current_cpi / f.release_cpi))::NUMERIC, 2), '$ FM999,999,999,999.00') AS adjusted_revenue,
		-- Adjusted Revenue = Original Revenue * (Current CPI / Release year CPI)
	    DENSE_RANK() OVER(ORDER BY ROUND((f.revenue * (c.current_cpi / f.release_cpi))::NUMERIC, 2) DESC) AS rank
		
	FROM 
	    FilmCPI AS f,
	    CurrentCPI AS c
	ORDER BY 
	    rank ASC;


/*********** 2.Box Office Performance Relative to Budget **************************/

    SELECT DISTINCT
	    title,
	    release_date,
	    TO_CHAR(revenue, '$FM999,999,999,999') AS revenue,
	    TO_CHAR(budget, '$FM999,999,999,999') AS budget,
	    TO_CHAR(ROUND(((revenue - budget) / budget) * 100, 2), 'FM999,999,999 %') AS roi_percentage,		
	    DENSE_RANK() OVER (ORDER BY (revenue / budget) DESC) AS rank
	FROM 
	    temp_movie_company
	WHERE 
	    revenue != 0
	    AND budget != 0
		
	ORDER BY 
	    rank 
 --LIMIT  
		10

/************** 3. Most popular movies ***************/
		
	SELECT DISTINCT
		title, 
		popularity, 
		vote_average, 
		runtime
	FROM temp_movie_company
	ORDER BY popularity DESC;

	

/************* 4. Analysis of Total Revenue, Total Budget, and ROI Percentage ************/

	--This query will provide the total revenue and total budget for each year, along with the ROI percentage,

	    WITH FilmCPI AS (
	        SELECT title, revenue, budget, release_date, EXTRACT(YEAR FROM release_date) AS release_year
	        FROM temp_movie_company AS t
	        WHERE revenue != 0
			AND budget != 0
	    )
	    SELECT 
	        f.release_year,
			COUNT(f.title) AS film_count,
	        TO_CHAR(SUM(f.revenue), '$ FM999,999,999,990') AS total_revenue,
	        TO_CHAR(SUM(f.budget), '$ FM999,999,999,990') AS total_budget,        
		TO_CHAR(ROUND((SUM(f.revenue) / COUNT(f.title))), '$ FM999,999,999,999') AS average_revenue_per_movie,
	        TO_CHAR(ROUND((SUM(f.revenue) - SUM(f.budget)) * 100.0 / NULLIF(SUM(f.budget), 0), 2), '99999.99 %')  AS roi_percentage		
	    FROM 
	        FilmCPI AS f
	    GROUP BY 
	        f.release_year
	    ORDER BY 
	        roi_percentage DESC;

/********************* Genre analysis *********************/
	--- 1. Most profitable genre
			WITH p_genre AS (
			    SELECT genre_name, 
			           SUM(revenue - budget) AS total_profit
			    FROM temp_movie_company
			    GROUP BY genre_name
			)
			SELECT genre_name, 
			       TO_CHAR(total_profit, '$ FM999,999,999,999') AS total_profit,
			       DENSE_RANK() OVER (ORDER BY total_profit DESC) AS rank 
			FROM p_genre;

-- 2. Most popular genres

			SELECT genre_name, ROUND(AVG(vote_average),2) AS average_vote 
			FROM temp_movie_company
			GROUP BY genre_name
			ORDER BY average_vote DESC
------------------------------------------------------------------------------------------


