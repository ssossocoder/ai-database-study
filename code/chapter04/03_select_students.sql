-- Chapter 04-3: SELECT 복습
-- 각 블록은 실행 전에 chapter04_answer.md에 예상 행 수를 적고, 한 블록씩 실행한다.

-- 1. 전체 학생: 기대 6행
SELECT id, name, email, major, grade, created_at
FROM public.students
ORDER BY id;

-- 2. 이름·이메일만 조회: 기대 6행
SELECT name, email
FROM public.students
ORDER BY id;

-- 3. 특정 전공(컴퓨터공학): 기대 2행
SELECT id, name, major
FROM public.students
WHERE major = '컴퓨터공학'
ORDER BY id;

-- 4. 특정 학년 이상(3학년 이상): 기대 2행
SELECT id, name, grade
FROM public.students
WHERE grade >= 3
ORDER BY grade DESC, id;

-- 5. 두 전공 중 하나(컴퓨터공학 또는 데이터사이언스): 기대 3행
SELECT id, name, major
FROM public.students
WHERE major IN ('컴퓨터공학', '데이터사이언스')
ORDER BY id;

-- 6. grade가 NULL: 기대 1행
SELECT id, name, grade
FROM public.students
WHERE grade IS NULL
ORDER BY id;

-- 7. 전공 DISTINCT: NULL도 하나의 서로 다른 결과값으로 포함되어 기대 5행
SELECT DISTINCT major
FROM public.students
ORDER BY major NULLS LAST;

-- 8. id순 정렬 후 상위 3명: 기대 3행
SELECT id, name, grade
FROM public.students
ORDER BY id
LIMIT 3;
