-- Chapter 07. 온라인 강의 수강신청 프로젝트 안내·최종 확인
-- 이 파일은 기존 링크 호환용 읽기 전용 파일입니다.
-- 프로젝트 생성 파일이 아닙니다.
-- 01 → 02 → 03 → 04 실행 후 최종 상태를 확인할 때 사용합니다.

SELECT current_database();
SELECT current_user;
SELECT current_schema();
SHOW search_path;

DO $$
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION '확인 중단: ai_database_book에 연결하세요.';
    END IF;

    IF to_regclass('course_project.students') IS NULL
       OR to_regclass('course_project.instructors') IS NULL
       OR to_regclass('course_project.courses') IS NULL
       OR to_regclass('course_project.enrollments') IS NULL
       OR to_regclass('course_project.uq_course_enrollments_active') IS NULL THEN
        RAISE EXCEPTION '확인 중단: Chapter 07 프로젝트 객체가 모두 존재하지 않습니다.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema='course_project'
          AND table_name='enrollments'
          AND column_name='recorded_amount'
          AND data_type='numeric'
          AND numeric_precision=12
          AND numeric_scale=0
    ) THEN
        RAISE EXCEPTION '확인 중단: enrollments.recorded_amount NUMERIC(12,0) 열을 확인하세요.';
    END IF;
END
$$;

SELECT
    to_regclass('course_project.students') AS students_table,
    to_regclass('course_project.instructors') AS instructors_table,
    to_regclass('course_project.courses') AS courses_table,
    to_regclass('course_project.enrollments') AS enrollments_table,
    to_regclass('course_project.uq_course_enrollments_active') AS active_index;

SELECT 'students' AS object_name, COUNT(*) AS row_count
FROM course_project.students
UNION ALL
SELECT 'instructors', COUNT(*)
FROM course_project.instructors
UNION ALL
SELECT 'courses', COUNT(*)
FROM course_project.courses
UNION ALL
SELECT 'enrollments', COUNT(*)
FROM course_project.enrollments
ORDER BY object_name;

SELECT
    e.id AS enrollment_id,
    s.name AS student_name,
    c.title AS course_title,
    i.name AS instructor_name,
    e.status,
    e.recorded_amount,
    e.enrolled_at
FROM course_project.enrollments AS e
JOIN course_project.students AS s ON e.student_id = s.id
JOIN course_project.courses AS c ON e.course_id = c.id
JOIN course_project.instructors AS i ON c.instructor_id = i.id
ORDER BY e.id;

SELECT
    COUNT(*) AS total_enrollments,
    SUM(recorded_amount) AS total_recorded_amount,
    COUNT(*) FILTER (WHERE status <> '취소') AS non_cancelled_enrollments,
    SUM(recorded_amount) FILTER (WHERE status <> '취소') AS non_cancelled_recorded_amount
FROM course_project.enrollments;

-- 최종 기대 상태
-- students 3 / instructors 2 / courses 3 / enrollments 5
-- 1001 완료 / recorded_amount 100000
-- 1004 취소 / recorded_amount 150000
-- 1005 신청 / recorded_amount 120000
-- 전체 recorded_amount 590000
-- 취소 제외 recorded_amount 440000
-- 자동 완료 판정은 04_course_project_validation.sql을 실행합니다.

