-- Chapter 03 DBeaver 실행 순서
-- 반드시 ai_database_book 연결을 선택한 SQL Editor에서 실행한다.
-- 아래 단계는 한꺼번에 전체 실행하지 말고, 각 블록을 따로 실행한다.

-- ============================================================
-- 1. 첫 SQL
-- 예상 결과: 2
-- ============================================================
SELECT 1 + 1 AS result;


-- ============================================================
-- 2. 현재 연결 위치 확인
-- 결과를 chapter03_answer.md의 3-1 표에 기록한다.
-- ============================================================
SELECT version();
SELECT current_database();
SELECT current_user;
SELECT current_schema();
SHOW search_path;
SHOW transaction_read_only;
SHOW TimeZone;


-- ============================================================
-- 3. ai_database_book 연결 여부 재확인
-- 예상 결과: ai_database_book
-- ============================================================
SELECT current_database();


-- ============================================================
-- 4. 실행 범위 실험
-- 4-1: 첫 문장 A에 커서를 두고 한 문장만 실행한다.
-- 4-2: B와 C 두 문장을 드래그로 선택한 뒤 선택 영역만 실행한다.
-- 4-3: 세 문장을 모두 실행한다.
-- ============================================================
SELECT 'A' AS step;
SELECT 'B' AS step;
SELECT 'C' AS step;


-- ============================================================
-- 5. 안전한 문법 오류 관찰
-- 이 한 문장만 실행한다. 데이터는 변경되지 않는다.
-- ============================================================
SELEC 1;


-- ============================================================
-- 6. 오류 수정 뒤 재검증
-- 위 오류를 확인한 뒤 이 두 문장만 실행한다.
-- ============================================================
SELECT 1;
SELECT current_database();


-- ============================================================
-- 7. 공식 환경 확인 SQL
-- 다음 두 파일은 GitHub의 Raw 화면에서 전체를 복사해 각각 실행한다.
--
-- setup_check.sql:
-- https://raw.githubusercontent.com/GilbertMoon/ai-database-book/main/code/chapter03/setup_check.sql
--
-- setup_validate_local.sql:
-- https://raw.githubusercontent.com/GilbertMoon/ai-database-book/main/code/chapter03/setup_validate_local.sql
--
-- setup_check.sql은 조회문만 포함한다.
-- setup_validate_local.sql은 권장 로컬 환경 조건을 검사하고,
-- 통과하면 NOTICE로 validation passed를 표시한다.
-- ============================================================
