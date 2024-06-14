DROP TABLE IF EXISTS temp_movie_company;

SELECT 
		m.movie_id, 
		m.title, 
		m.budget, 
		m.revenue, 
		m.popularity, 
		m.release_date, 
		m.runtime,m.vote_average, 
		m.vote_count, pc.company_name,
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


CREATE TEMPORARY TABLE temp_movie_company AS
	SELECT 
		m.movie_id, 
		m.title, 
		m.budget, 
		m.revenue, 
		m.popularity, 
		m.release_date, 
		m.runtime,m.vote_average, 
		m.vote_count, pc.company_name,
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
	    DENSE_RANK() OVER(ORDER BY ROUND((f.revenue * (c.current_cpi / f.release_cpi))::NUMERIC, 2) DESC) AS rank
	FROM 
	    FilmCPI AS f,
	    CurrentCPI AS c
	ORDER BY 
	    rank ASC;
-- Conclusion: This analysis shows Bambi and Snow White brought the most revenue, after adjusting for inflation



/*********** 2.Box Office Performance Relative to Budget **************************/

    SELECT DISTINCT
        title,
		release_date,
        TO_CHAR(revenue, '$ FM999,999,999,999') AS revenue,
		TO_CHAR(budget, '$ FM999,999,999,999') AS  budget,        
        ROUND((revenue / budget) * 100)  AS roi_percentage
    FROM 
        temp_movie_company
    WHERE 
        revenue != 0
	AND 
	budget != 0
    ORDER BY 
        roi_percentage DESC;


/************** 3. Most popular movies ***************/
		SELECT DISTINCT
			title, 
			popularity, 
			vote_average, 
			runtime
		FROM temp_movie_company
		ORDER BY popularity DESC;

	--Conclusion: Pirates of the Caribbean: The Curse Of The Black Pearl is the most popular.



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
		TO_CHAR(ROUND((SUM(f.revenue) / COUNT(f.title))), '$ FM999,999,999,999') AS revenue_per_movie,
	        TO_CHAR(ROUND((SUM(f.revenue) - SUM(f.budget)) * 100.0 / NULLIF(SUM(f.budget), 0), 2), '99999.99 %')  AS roi_percentage		
	    FROM 
	        FilmCPI AS f
	    GROUP BY 
	        f.release_year
	    ORDER BY 
	        roi_percentage DESC;

------------------------------------------------------------------------------------------
	WITH CurrentCPI AS (
		    SELECT cpi AS current_cpi
		    FROM InflationData
		    WHERE year = 2024
		),	
	GenreCPI AS (
	    SELECT DISTINCT
	        t.title, 
	        t.revenue, 
	        t.release_date, 
			t.genre_name,
	        i.cpi AS release_cpi
	    FROM temp_movie_company AS t
	    JOIN InflationData AS i ON EXTRACT(YEAR FROM t.release_date) = i.year
	    WHERE t.revenue != 0
		)
	SELECT DISTINCT
	    --g.title,
	    --g.release_date,
	    g.revenue,
		g.genre_name,
	    TO_CHAR(ROUND((g.revenue * (c.current_cpi / g.release_cpi))::NUMERIC, 2), '$ FM999,999,999,999.00') AS adjusted_revenue,
	    DENSE_RANK() OVER(ORDER BY ROUND((g.revenue * (c.current_cpi / g.release_cpi))::NUMERIC, 2) DESC) AS rank
	FROM 
	    GenreCPI AS g,
	    CurrentCPI AS c
	ORDER BY 
	    rank ASC;

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

	-- Family and Adventure are the most profitable.


	-- 2. Most popular genres

			SELECT genre_name, ROUND(AVG(vote_average),2) AS average_vote 
			FROM temp_movie_company
			GROUP BY genre_name
			ORDER BY average_vote DESC

		-- Documentary received the highest vote

			


SELECT *
FROM temp_movie_company;
