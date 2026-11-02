-- Chapter 09 캡처·기록용 SQL: 각 구역을 안내된 시점에 선택 실행한다.
-- 공식 01~06을 대체하지 않는다. 연결 DB: ai_database_book.
-- 아래 조회 구역은 데이터를 수정하지 않는다. Lock 구역만 별도 트랜잭션이다.

-- [A] 01 전에: 환경 및 원본 기준값 (1절 기록)
SELECT current_database(), current_user, current_schema();
SHOW search_path;
SHOW transaction_read_only;
SELECT 'students' AS object_name, COUNT(*) AS row_count FROM course_project.students
UNION ALL SELECT 'instructors', COUNT(*) FROM course_project.instructors
UNION ALL SELECT 'courses', COUNT(*) FROM course_project.courses
UNION ALL SELECT 'enrollments', COUNT(*) FROM course_project.enrollments;
SELECT COUNT(*) AS total_count, SUM(recorded_amount) AS total_amount,
       COUNT(*) FILTER (WHERE status IN ('신청', '수강중')) AS active_count,
       SUM(recorded_amount) FILTER (WHERE status IN ('신청', '수강중')) AS active_amount,
       COUNT(*) FILTER (WHERE status <> '취소') AS non_cancelled_count,
       SUM(recorded_amount) FILTER (WHERE status <> '취소') AS non_cancelled_amount
FROM course_project.enrollments;

-- [B] 02 직후: 초기 좌석 2/1/1, 신청·결제 각각 0. 캡처 1
SELECT ci.course_id, ci.capacity, ci.remaining_seats,
       (SELECT COUNT(*) FROM transaction_lab.enrollments) AS lab_enrollments,
       (SELECT COUNT(*) FROM transaction_lab.payments) AS payments
FROM transaction_lab.course_inventory AS ci ORDER BY ci.course_id;

-- [C] 03 전 / 내부 / COMMIT 후: 같은 연결에서 각 시점에 이 SELECT만 실행.
-- 각 결과를 답안 4-2에 기록. 마지막 결과는 캡처 2.
SELECT '301 seat / 9001 enrollment / 9901 payment' AS observation,
       ci.course_id, ci.remaining_seats,
       e.id AS enrollment_id, e.student_id, e.status, e.recorded_amount,
       p.id AS payment_id, p.amount
FROM transaction_lab.course_inventory AS ci
LEFT JOIN transaction_lab.enrollments AS e ON e.course_id = ci.course_id AND e.id = 9001
LEFT JOIN transaction_lab.payments AS p ON p.enrollment_id = e.id
WHERE ci.course_id = 301;

-- [D] 04 전 / 内部 / ROLLBACK 후: 같은 SELECT로 302 좌석 1→0→1,
-- 9002/9902 없음→존재→없음과 이전 COMMIT 9001/9901 보존을 기록.
SELECT ci.course_id, ci.remaining_seats,
       e.id AS enrollment_id, e.student_id, e.recorded_amount,
       p.id AS payment_id, p.amount
FROM transaction_lab.course_inventory AS ci
LEFT JOIN transaction_lab.enrollments AS e
  ON e.course_id = ci.course_id AND e.id IN (9001, 9002)
LEFT JOIN transaction_lab.payments AS p ON p.enrollment_id = e.id
WHERE ci.course_id IN (301, 302)
ORDER BY ci.course_id;

-- [E] 05 완료 직후: 좌석 부족 시 9003·9903 0건 확인. 캡처 3
SELECT ci.course_id, ci.remaining_seats,
       (SELECT COUNT(*) FROM transaction_lab.enrollments WHERE id = 9003) AS enrollment_9003,
       (SELECT COUNT(*) FROM transaction_lab.payments WHERE id = 9903) AS payment_9903,
       (SELECT COUNT(*) FROM transaction_lab.enrollments) AS total_enrollments,
       (SELECT COUNT(*) FROM transaction_lab.payments) AS total_payments
FROM transaction_lab.course_inventory AS ci WHERE ci.course_id = 302;

-- [F] 06 완료 직후: 최종 정합성. 캡처 4는 공식 06 통과 메시지도 함께 담는다.
SELECT ci.course_id, ci.capacity, ci.remaining_seats,
       COUNT(e.id) AS active_enrollments,
       ci.capacity - ci.remaining_seats = COUNT(e.id) AS seats_match
FROM transaction_lab.course_inventory AS ci
LEFT JOIN transaction_lab.enrollments AS e
  ON e.course_id = ci.course_id AND e.status = '수강중'
GROUP BY ci.course_id, ci.capacity, ci.remaining_seats ORDER BY ci.course_id;
SELECT e.id AS enrollment_id, e.student_id, e.course_id, e.status,
       e.recorded_amount, p.id AS payment_id, p.amount,
       e.recorded_amount = p.amount AS amount_match
FROM transaction_lab.enrollments AS e
LEFT JOIN transaction_lab.payments AS p ON p.enrollment_id = e.id ORDER BY e.id;
-- 原본 집계는 A의 마지막 SELECT를 다시 실행한다.

-- [G] 선택 Lock 실습: 이 구역 전체를 한 번에 실행하지 않는다.
-- 두 에디터에서 먼저 각각 실행: 서로 다른 PID인지 확인.
SELECT pg_backend_pid();
SHOW transaction_isolation;

-- G-1: Session A에서 이 블록만 실행. 종료하지 않은 채 Session B로 이동.
BEGIN;
SELECT * FROM transaction_lab.course_inventory WHERE course_id = 303 FOR UPDATE;

-- G-2: Session B에서 이 블록만 실행. 5초 뒤 timeout 또는 A 종료 뒤 잠금 획득.
BEGIN;
SET LOCAL lock_timeout = '5s';
SHOW lock_timeout;
SELECT * FROM transaction_lab.course_inventory WHERE course_id = 303 FOR UPDATE;

-- G-3: Session A로 돌아가 실행.
ROLLBACK;
-- G-4: Session B로 돌아가 실행. timeout 오류 상태여도 반드시 종료.
ROLLBACK;
