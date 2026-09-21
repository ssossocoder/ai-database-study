-- Chapter 04-2: 샘플 학생 6명 입력
-- example.test는 예시 전용 도메인이다. 실제 이메일을 쓰지 않는다.
-- 이 파일은 한 번만 실행한다. 다시 실행하면 email UNIQUE 제약조건 오류가 나는 것이 정상이다.

INSERT INTO public.students (name, email, major, grade)
VALUES
    ('김민지', 'minji.kim@example.test', '컴퓨터공학', 2),
    ('이준호', 'junho.lee@example.test', '데이터사이언스', 3),
    ('박서연', 'seoyeon.park@example.test', '컴퓨터공학', 1),
    ('최유진', 'yujin.choi@example.test', '경영학', 4),
    ('윤서진', 'seojin.yoon@example.test', NULL, NULL),
    ('한도윤', 'doyoon.han@example.test', '인공지능', 2)
RETURNING id, name, email, major, grade, created_at;

SELECT COUNT(*) AS student_count
FROM public.students;
