-- Chapter 04 시작 전 확인
-- 변경문 없이 현재 연결과 public.students 상태만 조회한다.

SELECT current_database();
SELECT current_user;
SELECT current_schema();
SHOW search_path;
SHOW transaction_read_only;

-- NULL이면 public.students가 아직 없다는 뜻이다.
SELECT to_regclass('public.students') AS students_table;

-- 테이블이 이미 있을 때만 아래 조회를 별도로 실행한다.
-- SELECT COUNT(*) AS current_students FROM public.students;
