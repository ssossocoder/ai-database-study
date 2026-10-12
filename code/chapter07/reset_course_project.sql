-- Chapter 07. 온라인 강의 프로젝트 초기화
-- 주의: course_project 스키마와 프로젝트 데이터를 삭제합니다.
-- 처음부터 다시 시작해야 할 때만 사용합니다.
-- DROP SCHEMA ... CASCADE는 사용하지 않습니다.
-- 예상하지 않은 객체가 있으면 전체 초기화를 롤백합니다.

SELECT current_database();
SELECT current_user;
SELECT current_schema();
SHOW search_path;

SELECT
    to_regclass('course_project.students') AS students_before_reset,
    to_regclass('course_project.instructors') AS instructors_before_reset,
    to_regclass('course_project.courses') AS courses_before_reset,
    to_regclass('course_project.enrollments') AS enrollments_before_reset,
    to_regclass('course_project.uq_course_enrollments_active') AS active_index_before_reset;

BEGIN;

DO $$
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '초기화 중단: 현재 데이터베이스는 %입니다. ai_database_book에 연결하세요.',
            current_database();
    END IF;

    IF current_setting('transaction_read_only')::boolean THEN
        RAISE EXCEPTION
            '초기화 중단: 현재 연결이 읽기 전용입니다.';
    END IF;
END
$$;

DO $$
BEGIN
    IF to_regnamespace('course_project') IS NULL THEN
        RAISE NOTICE '초기화할 course_project 스키마가 존재하지 않습니다.';
        RETURN;
    END IF;

    -- 외래키를 가진 자식에서 부모 순서로 알려진 테이블만 삭제합니다.
    DROP TABLE IF EXISTS course_project.enrollments;
    DROP TABLE IF EXISTS course_project.courses;
    DROP TABLE IF EXISTS course_project.instructors;
    DROP TABLE IF EXISTS course_project.students;

    -- 예상하지 않은 객체가 남아 있으면 CASCADE 없이 실패하며 BEGIN 전체가 롤백됩니다.
    DROP SCHEMA course_project;
END
$$;

COMMIT;

DO $$
BEGIN
    IF to_regnamespace('course_project') IS NOT NULL THEN
        RAISE EXCEPTION '초기화 검증 실패: course_project 스키마가 남아 있습니다.';
    END IF;

    RAISE NOTICE 'Chapter 07 course project reset passed';
END
$$;

SELECT
    to_regnamespace('course_project') AS schema_after_reset,
    to_regclass('course_project.students') AS students_after_reset,
    to_regclass('course_project.instructors') AS instructors_after_reset,
    to_regclass('course_project.courses') AS courses_after_reset,
    to_regclass('course_project.enrollments') AS enrollments_after_reset;

-- 다시 시작하는 순서
-- 1. 01_course_project_schema.sql
-- 2. 02_course_project_seed.sql
-- 3. 03_course_project_changes.sql
-- 4. 04_course_project_validation.sql
-- 5. 05_course_project_integrity_tests.sql에서 핵심 테스트 선택 실행
-- 6. 06_course_project_optional_tests.sql에서 선택 테스트 실행

