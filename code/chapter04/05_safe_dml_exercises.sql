-- Chapter 04-5~9: 가상 학생·안전한 변경·제약조건 관찰
-- 중요: 이 파일 전체를 한 번에 실행하지 않는다. 필요한 블록만 선택하여 실행한다.
-- 값은 모두 가상 데이터이며, example.test는 예시 전용 도메인이다.

-- [5] 가상 학생 2명 추가
-- 초기 6명 기준 실행 후에는 전체 8명이 예상된다.
INSERT INTO public.students (name, email, major, grade)
VALUES
    ('가상하린', 'virtual.harin@example.test', 'UX디자인', 2),
    ('가상민준', 'virtual.minjun@example.test', NULL, NULL)
RETURNING id, name, email, major, grade;

SELECT COUNT(*) AS total_students_after_insert
FROM public.students;

-- [6] 가상하린만 수정하기 전 대상 확인: 기대 1행
SELECT id, name, email, major, grade
FROM public.students
WHERE email = 'virtual.harin@example.test';

-- [6] 가상하린의 학년만 3으로 수정: 기대 영향 행 수 1
UPDATE public.students
SET grade = 3
WHERE email = 'virtual.harin@example.test'
RETURNING id, name, email, major, grade;

-- [6] 수정 후 재조회
SELECT id, name, email, major, grade
FROM public.students
WHERE email = 'virtual.harin@example.test';

-- [7] 가상민준 삭제 전 대상 확인: 기대 1행
SELECT id, name, email
FROM public.students
WHERE email = 'virtual.minjun@example.test';

-- [7] 가상민준만 삭제: 기대 영향 행 수 1
DELETE FROM public.students
WHERE email = 'virtual.minjun@example.test'
RETURNING id, name, email;

-- [7] 삭제 후 재조회: 기대 0행
SELECT id, name, email
FROM public.students
WHERE email = 'virtual.minjun@example.test';

-- [9-1] UNIQUE 오류 관찰: 기존 이메일을 일부러 중복한다.
-- 이 한 문장은 실패해야 정상이다. 실패해도 기존 행은 유지된다.
INSERT INTO public.students (name, email, major, grade)
VALUES ('중복테스트', 'minji.kim@example.test', '테스트전공', 1);

-- [9-2] NOT NULL 오류 관찰: name에 NULL을 일부러 입력한다.
-- 이 한 문장은 실패해야 정상이다. 실패해도 새 행은 생기지 않는다.
INSERT INTO public.students (name, email, major, grade)
VALUES (NULL, 'null-name-test@example.test', '테스트전공', 1);
