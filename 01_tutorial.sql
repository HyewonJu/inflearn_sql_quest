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