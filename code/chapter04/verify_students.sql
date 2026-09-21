-- Chapter 04 최종 검증
-- 04_update_delete_students.sql을 초기 6명 상태에서 실행한 뒤 사용한다.
-- 기대값: total_students = 5, grade_null_count = 1,
--         junho_grade = 4, park_seoyeon_count = 0

SELECT
    COUNT(*) AS total_students,
    COUNT(*) FILTER (WHERE grade IS NULL) AS grade_null_count,
    COUNT(*) FILTER (WHERE major IS NULL) AS major_null_count,
    MAX(grade) FILTER (WHERE email = 'junho.lee@example.test') AS junho_grade,
    COUNT(*) FILTER (WHERE email = 'seoyeon.park@example.test') AS park_seoyeon_count
FROM public.students;

-- 숫자 검증 뒤에는 상세 행도 확인한다.
SELECT id, name, email, major, grade, created_at
FROM public.students
ORDER BY id;
