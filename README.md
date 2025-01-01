# inflearn_sql_quest
인프런 강의 "[SQL Quest] 실전 문제 풀이로 SQL 역량 강화 하기 (Basic)"

## Table Description
### raw_register_data (회원가입입)
|COLUMN|TYPE|DESC|
|------|---|---|
|WID|VARCHAR|
|country|VARCHAR|
|log_time|DATETIME|
|os|VARCHAR|
|register_channel|VARCHAR|

### raw_login_data (로그인)
|COLUMN|TYPE|DESC|
|------|---|---|
|WID|VARCHAR|
|log_time|DATETIME|
|country|VARCHAR|
|os|VARCHAR|
|level|INT|로그인 시점 레벨|

### daily_sales (구매이력)
|COLUMN|TYPE|DESC|
|------|---|---|
|date|DATE|
|WID|VARCHAR|
|item_id|VARCHAR|
|buy_count|INT|구매 횟수|
|revenue|INT|총 구매 금액|

### daily_play (플레이이력)
|COLUMN|TYPE|DESC|
|------|---|---|
|date|DATE|
|WID|VARCHAR|
|mode|INT|
|play_count|INT|
|playtime|INT|