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
