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