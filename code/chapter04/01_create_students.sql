-- Chapter 04-1: public.students 구조 생성
-- 실행 전 00_preflight.sql에서 public.students가 없는지 먼저 확인한다.
-- 이미 존재하면 이 파일은 오류를 내며, 그 오류는 기존 데이터를 보호하기 위한 신호다.

CREATE TABLE public.students (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    major TEXT,
    grade SMALLINT CHECK (grade BETWEEN 1 AND 4),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 생성 직후에는 0행인지 확인한다.
SELECT COUNT(*) AS student_count
FROM public.students;

-- DBeaver에서 테이블을 새로고침한 뒤, Columns와 Constraints도 확인한다.
