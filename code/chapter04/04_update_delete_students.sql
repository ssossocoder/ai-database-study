-- Chapter 04-4: 본문 기준 UPDATE·DELETE
-- 전제: 01_create_students.sql와 02_insert_students.sql만 실행한 초기 6명 상태
--       (5~7절의 가상 학생 실습 결과가 남아 있지 않은 상태)
-- 각 변경문 앞의 SELECT를 먼저 한 문장씩 실행해 대상이 정확히 1행인지 확인한다.

-- 이준호의 현재 상태 확인: 기대 1행, grade = 3
SELECT id, name, email, grade
FROM public.students
WHERE email = 'junho.lee@example.test';

-- 이준호 grade를 4로 변경: 기대 영향 행 수 1
UPDATE public.students
SET grade = 4
WHERE email = 'junho.lee@example.test'
RETURNING id, name, email, grade;

-- 박서연의 현재 상태 확인: 기대 1행
SELECT id, name, email
FROM public.students
WHERE email = 'seoyeon.park@example.test';

-- 박서연 삭제: 기대 영향 행 수 1
DELETE FROM public.students
WHERE email = 'seoyeon.park@example.test'
RETURNING id, name, email;
