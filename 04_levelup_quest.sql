/*
------------------------------------------------------------------------------------------------
LEVEL UP QUEST

* 서브쿼리 기능
  - 임시 테이블 제작
  - 조건 값으로 활용
  
* RANK() OVER (PARTITION BY 기준 ORDER BY 조건)
  - 기준 별로 나누어 조건에 따라 순위를 매김
  - 별도 기준 없이 전체를 대상으로 한다면 PARTITION BY 생략 가능
  
* CROSS JOIN
  - 조건 없이 두 테이블의 모든 행을 조합
  - 두 테이블의 행의 곱과 같은 결과 집합 생성
  - ON 절을 사용하지 않음
  - 데이터가 너무 커지지 않도록 테이블 형태에 주의!!!
  
* LEFT OUTER JOIN
  - 누락된 데이터(NULL)의 유무를 확인해야할 때 사용
  - LEFT JOIN의 좌측 테이블(FROM절에 오는)은 기준이므로 JOIN 후에 NULL이 담긴 테이블이 우측에 위치해야 함
  - 양쪽의 NULL이 모두 필요한 경우에는 FULL OUTER JOIN을 사용
  
* COALESCE(칼럼1, 칼럼2, NULL일 때 값)
  - 칼럼1 값이 NULL인 경우 칼럼2 값 표시, 칼럼2 값이 NULL인 경우 NULL일 때 지정한 값이 출력됨
------------------------------------------------------------------------------------------------
*/
-- 1. 매출이 가장 높은 유저의 로그인 기록을 조회하시오
-->>> 1-1) ORDER BY, LIMIT 이용
SELECT *
  FROM `data-whiz`.project.raw_login_data
 WHERE WID = (SELECT WID
				FROM (SELECT WID, SUM(revenue) 
				        FROM `data-whiz`.project.daily_sales
				       GROUP BY 1 
				       ORDER BY 2 DESC
				       LIMIT 1))
 ORDER BY log_time;

-->>> 1-2) RANK() 함수 사용 --> 위의 방법보다 추천
SELECT *
  FROM `data-whiz`.project.raw_login_data
 WHERE WID = (SELECT WID
			    FROM (SELECT WID, RANK() OVER(ORDER BY SUM(revenue) DESC) AS RANK
				  	    FROM `data-whiz`.project.daily_sales
					   GROUP BY 1)
			   WHERE RANK = 1)
 ORDER BY log_time;

-->>> 1-3) WITH절 이용
WITH VIP_USER AS (
	SELECT WID
	FROM (SELECT WID, RANK() OVER(ORDER BY SUM(revenue) DESC) AS RANK
		    FROM `data-whiz`.project.daily_sales
		   GROUP BY 1)
	   WHERE RANK = 1
)
SELECT *
  FROM `data-whiz`.project.raw_login_data AS LOGIN JOIN VIP_USER
    ON LOGIN.WID = VIP_USER.WID
 ORDER BY LOGIN.log_time;

-- 2. 유저들의 각 레벨별 유저 수(단, 현재 레벨 기준으로)
SELECT CURRENT_LEVEL, COUNT(WID) USER_CNT
  FROM (SELECT WID, MAX(LEVEL) AS CURRENT_LEVEL
		  FROM `data-whiz`.project.raw_login_data
		 GROUP BY 1)
 GROUP BY 1
 ORDER BY 1;

-- CROSS JOIN으로 연관 관계가 없는 두 테이블을 합칠 수 있음
SELECT CURRENT_LEVEL, USER_CNT, ROUND(USER_CNT / TOTAL_USERS * 100, 2) AS RATIO
  FROM (SELECT CURRENT_LEVEL, COUNT(WID) USER_CNT
	      FROM (SELECT WID, MAX(LEVEL) AS CURRENT_LEVEL
  	  		      FROM `data-whiz`.project.raw_login_data
			     GROUP BY 1)
	     GROUP BY 1
	     ORDER BY 1)
 CROSS JOIN 
 	   (SELECT COUNT(DISTINCT WID) TOTAL_USERS 
 		  FROM `data-whiz`.project.raw_login_data)
 ORDER BY 1;

-- 3. 일별 ARPDAU와 PUR(Paying User Rate)를 구하시오
/*
	- ARPPU : Average Revenue Per Paying User => 구매력
	- PU : Paying User (=BU)
	- APRDAU : Average Revenue Per Daily Actice User => 고객 단가
	- PUR : Paying User Rate = PU / DAU(혹은 AU) => 구매 전환율

Daily 기준 매출 KPI 공식
	- PUR = PU / DAU
	- ARPPU = Revenue / PU
	- ARPDAU = Revenue / DAU
*/
-->>> WITH AS, LEFT OUTER JOIN, CASE문 이용
WITH 
	LOGIN AS (
		SELECT DATE(log_time) DATE, 
			   COUNT(DISTINCT WID) DAU
		  FROM `data-whiz`.project.raw_login_data
		 GROUP BY 1
	),
	SALES AS (
		SELECT date AS DATE, 
			   COUNT(DISTINCT WID) AS PU, 
			   SUM(revenue) AS REVENUE
		  FROM `data-whiz`.project.daily_sales
		 GROUP BY 1
	)
SELECT LOGIN.DATE AS DATE,
	   CASE 
	   	   WHEN SALES.REVENUE IS NULL THEN 0
	       ELSE ROUND(SALES.REVENUE / LOGIN.DAU, 2)
	   END AS ARPDAU,
	   CASE
	       WHEN SALES.PU IS NULL THEN 0
	   	   ELSE ROUND(SALES.PU / LOGIN.DAU, 3)
	   END AS PUR
  FROM LOGIN
  LEFT OUTER JOIN SALES
    ON LOGIN.DATE = SALES.DATE
 ORDER BY 1;

-->>> LEFT OUTER JOIN, COALESCE 함수 이용
SELECT LOGIN.DATE AS DATE,
	   COALESCE(ROUND(SALES.REVENUE / LOGIN.DAU, 2), 0) AS ARPDAU,
	   COALESCE(ROUND(SALES.PU / LOGIN.DAU, 3), 0) AS PUR
  FROM (SELECT DATE(log_time) DATE, 
			   COUNT(DISTINCT WID) DAU
		  FROM `data-whiz`.project.raw_login_data
		 GROUP BY 1) AS LOGIN
  LEFT OUTER JOIN
  	   (SELECT date AS DATE, 
			   COUNT(DISTINCT WID) AS PU, 
			   SUM(revenue) AS REVENUE
		  FROM `data-whiz`.project.daily_sales
		 GROUP BY 1) AS SALES
	ON LOGIN.DATE = SALES.DATE
 ORDER BY 1;


-- 4. 국가별, OS별 가입채널에 따른 구매 유저 수와 비구매유저 수를 구하시오
SELECT REGISTER.country,
	   REGISTER.os,
	   REGISTER.register_channel,
	   COUNT(DISTINCT REGISTER.WID) AS TOTAL_USER,
	   COUNT(DISTINCT REGISTER.WID) - COUNT(DISTINCT SALES.WID) AS NON_PU,
	   COUNT(DISTINCT SALES.WID) AS PU,
	   COUNT(DISTINCT CASE WHEN SALES.WID IS NULL THEN REGISTER.WID ELSE NULL END) AS NON_PU_2, -- ELSE NULL 생략 가능
	   COUNT(DISTINCT CASE WHEN SALES.WID IS NOT NULL THEN SALES.WID ELSE NULL END) AS PU_2
  FROM `data-whiz`.project.raw_register_data AS REGISTER
  LEFT OUTER JOIN
       `data-whiz`.project.daily_sales AS SALES
    ON REGISTER.WID = SALES.WID
 GROUP BY 1, 2, 3;

SELECT REGISTER.country,
	   REGISTER.os,
	   REGISTER.register_channel,
	   CASE
	       WHEN SALES.WID IS NOT NULL THEN 'PU' ELSE 'NON_PU'
	   END AS IS_PU,
	   COUNT(DISTINCT REGISTER.WID) USERS
  FROM `data-whiz`.project.raw_register_data AS REGISTER
  LEFT OUTER JOIN
       `data-whiz`.project.daily_sales AS SALES
    ON REGISTER.WID = SALES.WID
 GROUP BY 1, 2, 3, 4
 ORDER BY 1, 2, 3, 4;

-- 5. 레벨 30 이상과 미만의 DAU와 당일 플레이 유저 수 비중을 일별로 구하시오 (단, 한 유저의 레벨은 당일 최고 기준으로 하며 비중은 소수점 두자리로 나타낼 것)
SELECT LOGIN.DATE AS DATE,
	   CASE
	   	   WHEN LEVEL >= 30 THEN 'OVER'
	   	   WHEN LEVEL < 30 THEN 'BELOW'
	   END AS LEVEL_GROUP,
	   COUNT(DISTINCT LOGIN.WID) DAU,
	   COUNT(DISTINCT PLAY.WID) GAU,
	   ROUND(COUNT(DISTINCT PLAY.WID) / COUNT(DISTINCT LOGIN.WID), 2) GAU_RATIO
  FROM (SELECT DATE(log_time) DATE, WID, MAX(LEVEL) LEVEL
		  FROM `data-whiz`.project.raw_login_data
		 GROUP BY 1, 2) AS LOGIN
  LEFT OUTER JOIN 
	   `data-whiz`.project.daily_play AS PLAY
    ON LOGIN.WID = PLAY.WID
   AND LOGIN.DATE = PLAY.DATE
 GROUP BY 1, 2
 ORDER BY 1, (CASE WHEN LEVEL_GROUP = 'BELOW' THEN 1
			   	WHEN LEVEL_GROUP = 'OVER' THEN 2 END);

