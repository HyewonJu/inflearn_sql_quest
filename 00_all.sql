/*
 SELECT문 실행 순서
 FROM / JOIN -> WHERE -> GROUP BY -> HAVING -> SELECT -> ORDER BY / Window Func -> LIMIT
 */

/*
------------------------------------------------------------------------------------------------
TUTORIAL
------------------------------------------------------------------------------------------------
*/
-- 1. 가입 유저 중 최근에 가입한 5명의 유저
SELECT *
  FROM `data-whiz`.project.raw_register_data
 ORDER BY log_time DESC
 LIMIT 5;

-->>> Window Function 사용
SELECT *
  FROM (SELECT *, ROW_NUMBER() OVER(ORDER BY log_time DESC) row_num
		  FROM `data-whiz`.project.raw_register_data)
 where row_num <= 5;


-- 2. 한국 유저, 일본 유저의 로그인 기록 조회
SELECT *
  FROM `data-whiz`.project.raw_login_data
 WHERE country IN ('KR', 'JP');


-- 3. DAU(Daily Active User) 구하기
SELECT DATE(log_time) log_date, 
	   COUNT(DISTINCT WID) DAU
  FROM `data-whiz`.project.raw_login_data
 GROUP BY 1; -- GROUP BY log_date


-- 4. 아이템별 매출, 아이템별 구매 유저 수(PU, Paying User), ARPPU(Average Revenue Per Paying User = Revenue / PU) 구하기
SELECT item_id, 
	   SUM(revenue) TOTAL_REVENUE, 
	   COUNT(DISTINCT WID) PU, 
	   ROUND(SUM(revenue) / COUNT(DISTINCT WID), 2) ARPPU
  FROM `data-whiz`.project.daily_sales
 GROUP BY item_id;


-- 5. 게임 모드 별 총 플레이 시간, 총 게임 횟수
SELECT mode, 
	   SUM(playtime) TOTAL_PLAY_TIME, 
	   SUM(play_count) TOTAL_PLAY_COUNT
  FROM `data-whiz`.project.daily_play
 GROUP BY 1 -- GROUP BY mode
 ORDER BY 1;

/*
------------------------------------------------------------------------------------------------
QUEST #1 : 기초 SQL 문제풀이
------------------------------------------------------------------------------------------------
*/
-- 1. 로그인 데이터 중 레벨 60 이상인 것을 찾으세요.
SELECT *
  FROM `data-whiz`.project.raw_login_data
 WHERE level >= 60;

-- 1-1. 로그인 데이터에서 현재 기준으로 레벨을 정의하고, 각 유저의 최종레벨을 기준으로 60 이상을 추출해라
SELECT WID, MAX(level) current_level
  FROM `data-whiz`.project.raw_login_data
 GROUP BY 1
HAVING current_level >= 60;

-- 2. 2023년 3번 모드를 플레이했거나, 2022년에 4번 모드를 플레이한 기록을 조회하세요.
/* 2022년 데이터 가져오는 방법
	1) date BETWEEN '2022-01-01' AND '2022-12-31'
	2) EXTRACT(YEAR FROM date) = 2022
	3) FORMAT_DATE('%Y', date) = 2022
*/
SELECT *
  FROM `data-whiz`.project.daily_play
 WHERE (EXTRACT(YEAR FROM date) = 2023 AND mode = 3) 
	OR (EXTRACT(YEAR FROM date) = 2022 AND mode = 4);

-- 3. 한국의 facebook으로 가입한 유저, 일본의 guest로 가입한 유저가 몇 명인지 구하세요. 
	-- A. country| register_channel | 유저 수
	-- B. facebook_kr | jp_guest
SELECT country, register_channel, COUNT(DISTINCT WID) user_cnt
  FROM `data-whiz`.project.raw_register_data
 WHERE (country = 'KR' AND register_channel = 'facebook') 
 	OR (country = 'JP' AND register_channel = 'guest')
 GROUP BY 1, 2;

-- COUNT() 사용 시, NULL 값은 셀 수 없으므로 0을 리턴함 --> ELSE NULL 생략 가능
-- 유저 당 하나의 데이터만 있으므로 COUNT() 대신 SUM() 이용 가능
SELECT COUNT(CASE WHEN country = 'KR' AND register_channel = 'facebook' THEN WID ELSE NULL END) facebook_kr,
	   SUM(CASE WHEN country = 'JP' AND register_channel = 'guest' THEN 1 ELSE 0 END) jp_guest
  FROM `data-whiz`.project.raw_register_data;

-- 4. 우리 프로젝트의 총 매출, 구매 유저 수를 구하세요.
SELECT SUM(revenue) TOTAL_REVENUE,
	   COUNT(DISTINCT WID) PU,
	   ROUND(SUM(revenue) / COUNT(DISTINCT WID), 2) ARPPU
  FROM `data-whiz`.project.daily_sales;

-- 4-1. 일일 총 매출, 구매 유저 수
SELECT date,
	   SUM(revenue) TOTAL_REVENUE,
	   COUNT(DISTINCT WID) PU,
	   ROUND(SUM(revenue) / COUNT(DISTINCT WID), 2) ARPPU
  FROM `data-whiz`.project.daily_sales
 GROUP by 1;

-- 5. 각 유저의 현재 레벨(최고), 최근 로그인 시간, 로그인 횟수, 로그인 일수를 구하세요.
-- COUNT()에 특정 칼럼 지정 시, 해당 칼럼 값이 NULL인 경우에는 카운트하지 않음
SELECT WID, 
	   MAX(level) current_level, 
	   MAX(log_time) last_login_time, 
	   COUNT(*) num_of_login, -- NULL 값을 가진 데이터도 카운트하기 위해 와일드카드(*) 사용
	   COUNT(DISTINCT date(log_time)) login_days 
  FROM `data-whiz`.project.raw_login_data
 GROUP BY WID;

/*
------------------------------------------------------------------------------------------------
QUEST #2
------------------------------------------------------------------------------------------------
*/
-- 1. 국가별 DAU(Daily Active User)를 구하시오
SELECT country, date(log_time) log_date, COUNT(DISTINCT WID) DAU 
  FROM `data-whiz`.project.raw_login_data
 GROUP BY 1, 2
 ORDER BY 1, 2;

-- 1-1. MAU(Monthly Active User)를 구하시오
SELECT FORMAT_DATE('%Y-%m', log_time) yyyy_mm, COUNT(DISTINCT WID) MAU
  FROM `data-whiz`.project.raw_login_data
 GROUP BY 1
 ORDER BY 1;

-- 2. guest 계정과 guest 계정이 아닌 경우를 SNS로 정의하여 가입한 유저 수를 집계하시오 (단, country가 null인 경우 undefined로 구분)
SELECT CASE 
		   WHEN country IS NULL THEN 'UNDEFINED'
		   WHEN register_channel = 'guest' THEN 'GUEST'
	       ELSE 'SNS' 
	   END channel_group, COUNT(DISTINCT WID) register_users 
  FROM `data-whiz`.project.raw_register_data
 GROUP BY 1;

SELECT COUNT(CASE WHEN register_channel = 'guest' AND country IS NOT NULL THEN WID END) GUEST,
	   COUNT(CASE WHEN register_channel <> 'guest' AND country IS NOT NULL THEN WID END) SNS,
	   COUNT(CASE WHEN country IS NULL THEN WID END) UNDEFINED
  FROM `data-whiz`.project.raw_register_data;

-- 3. 월별 아이템별 매출, 구매유저 수, ARPPU, 판매일수, 총 판매 양을 집계하시오
-- Average Revenue Per Paying User(ARPPU) = Revenue / PU
-- cf) DATE_TRUNC 함수 리턴값의 데이터형 : DATE
SELECT FORMAT_DATE('%Y-%m', date) month, 
	   item_id, 
	   SUM(revenue) total_revenue,
	   COUNT(DISTINCT WID) PU,
	   ROUND(SUM(revenue) / COUNT(DISTINCT WID), 2) ARPPU,
	   COUNT(DISTINCT date) sales_days,
	   SUM(buy_count) total_buy_count
 FROM `data-whiz`.project.daily_sales
GROUP BY 1, 2
ORDER BY 1, 2;


-- 4. 가입 유저 중 WID가 W10500 ~ W11000이며, 국적이 KR인 유저들의 가입 정보를 추출하시오
-- [참고] 칼럼명 NOT BETWEEN 조건1 AND 조건2 (조건1~조건2 사이에 있지 않은 것들 추출)
SELECT *
  FROM `data-whiz`.project.raw_register_data
 WHERE country = 'KR'
   AND (WID BETWEEN 'W10500' AND 'W11000')
 ORDER BY WID;

-- 5. 구매 수량이 5개 이상이면 regular, 10개 이상이면 large, 5개 미만인 경우 small로 정의한 buy_size 별로 구매 건수와 매출 총액, 구매 유저수 구하시오
SELECT CASE
	       WHEN buy_count >= 10 THEN 'LARGE'
	       WHEN buy_count >= 5 THEN 'REGULAR'
	       WHEN buy_count < 5 THEN 'SMALL'
	       ELSE 'ERROR'
	   END BUY_SIZE, SUM(buy_count) buy_count, SUM(revenue) total_revenue, COUNT(WID) user_count 
  FROM `data-whiz`.project.daily_sales
 GROUP BY 1
 ORDER BY (CASE WHEN BUY_SIZE = 'SMALL' THEN 1
			   	WHEN BUY_SIZE = 'REGULAR' THEN 2
			   	WHEN BUY_SIZE = 'LARGE' THEN 3
			   	ELSE 4 END);

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

