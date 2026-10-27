# Chapter 08 확장 실습 답안

> JOIN과 집계로 서비스 질문에 답하기
>
> 작성 상태: SQL·예상 결과·설명 작성 완료. 본인 DB 실행과 증거 캡처는 미완료다. 아래 수치는 Chapter 07 최종 Seed와 변경 SQL을 바탕으로 계산한 **예상값**이며 실제 실행 결과로 주장하지 않는다. 실제 결과는 실행 후 확인하여 기록한다. 개인 프로젝트는 Chapter 07 설계 단계이므로 SQL 초안과 검산 계획을 제시한다.

```text
GitHub 계정: ssossocoder
과제 작성일: 2026-10-27
사용한 AI 도구: OpenAI Codex
```

공식 자료: [답안 템플릿](https://github.com/GilbertMoon/ai-database-book/blob/main/assignments/chapter08/chapter08_answer_template.md), [실습 SQL](https://github.com/GilbertMoon/ai-database-book/tree/main/code/chapter08).
비밀번호·접속 URL·API Key·실제 개인정보는 기록하지 않는다. 아래 사람 이름은 공식 가상 Seed다.

# 1. Chapter 07 기준 상태 확인

## 1-1. 사전 검사 결과

실행 대상: 공식 `00_check_course_project.sql` 전체.

| 항목 | 기준/예상값 | 실제 결과 |
| --- | ---: | --- |
| students | 3 | 미실행 |
| instructors | 2 | 미실행 |
| courses | 3 | 미실행 |
| enrollments | 5 | 미실행 |
| 전체 신청 건수 / recorded_amount | 5 / 590000 | 미실행 |
| 활성 신청 건수 / recorded_amount | 3 / 340000 | 미실행 |
| 취소 제외 건수 / recorded_amount | 4 / 440000 | 미실행 |

검증 메시지: 미실행. 기대 메시지는 `Chapter 08 prerequisite check passed`다.
활성은 `신청·수강중`, 취소 제외는 `신청·수강중·완료`다.

### 기준값이 다르면 그대로 진행하면 안 되는 이유

Chapter 07 변경 전에는 신청이 4건이고 상태와 금액도 다르다. 기준 상태가 다르면 JOIN 방식의 차이인지 데이터 차이인지 구별하기 어렵다. 사전 검사는 행 수뿐 아니라 제약조건, 고아 관계, 활성 중복, 특정 신청의 상태·기록 금액도 확인한다.

### 증거 화면

미첨부. 사전 검사 통과 메시지와 요약 결과를 본인 DB에서 캡처하여 확인해야 한다.

# 2. 업무 질문을 SQL보다 먼저 정의하기

## 질문 A

```text
업무 질문: 각 신청은 어느 학생이 어느 강사의 어떤 강의에 남긴 이력인가?
결과 한 행: 신청 한 건(enrollments.id).
포함 상태: 신청, 수강중, 완료, 취소 모두.
제외 상태: 없음.
JOIN할 테이블: enrollments, students, courses, instructors.
JOIN 경로: e.student_id → s.id, e.course_id → c.id, c.instructor_id → i.id.
선택: INNER JOIN.
이유: 신청을 기준으로 필수 부모를 연결하며 FK가 보장된 기준 상태다.
예상 행 수: 5행. 학생 수가 아니라 신청 건수다.
```

## 질문 B

```text
업무 질문: 강의별 취소 제외 신청 수, 고유 학생 수, 신청 시 기록 금액은 얼마인가?
결과 한 행: 강의 한 개(courses.id).
포함 상태: 신청, 수강중, 완료.
제외 상태: 취소.
JOIN할 테이블: courses, enrollments.
JOIN 경로: c.id → e.course_id, 취소 제외 조건은 ON.
집계 대상: COUNT(e.id), COUNT(DISTINCT e.student_id), SUM(e.recorded_amount).
예상 결과: 301=2건/2명/200000, 302=2건/2명/240000, 303=0건/0명/0.
```

## 질문 C

```text
업무 질문: 모든 학생을 남겨 취소 제외 신청 수를 확인할 수 있는가?
결과 한 행: 학생 한 명(students.id).
포함 상태: 신청, 수강중, 완료.
제외 상태: 취소.
0건인 부모도 보여야 하는가: 예. students에서 LEFT JOIN한다.
NULL 해석: 연결된 취소 제외 신청이 없다는 뜻이며 학생이 없다는 뜻이 아니다.
예상 결과: 101 김민지=2, 102 이준호=2, 103 박서연=0.
```

# 3. INNER JOIN과 다중 JOIN

## 3-1. 신청 한 건마다 학생 이름과 강의 제목 조회

예상: 신청 한 건이 한 행이며 5행이다. `enrollments → students`, `enrollments → courses`로 연결한다.

```sql
SELECT e.id AS enrollment_id, s.name AS student_name,
       c.title AS course_title, e.status
FROM course_project.enrollments AS e
INNER JOIN course_project.students AS s ON e.student_id = s.id
INNER JOIN course_project.courses AS c ON e.course_id = c.id
ORDER BY e.id;
```

실제 행 수: 미실행. 예상과 일치 여부: 미확인.

학생은 여러 강의를 신청할 수 있다. 학생 이름이 반복되어도 신청 ID가 다르면 다른 사건이다. 이름만 보고 DISTINCT로 제거하면 정상 신청 이력이 사라질 수 있다.

## 3-2. 학생·강의·강사까지 연결

결과 한 행은 여전히 신청 한 건이다. 강사는 `e.course_id → c.id → c.instructor_id → i.id`로 찾는다.

```sql
SELECT e.id AS enrollment_id, s.name AS student_name,
       c.title AS course_title, i.name AS instructor_name,
       e.status, e.recorded_amount, e.enrolled_at
FROM course_project.enrollments AS e
JOIN course_project.students AS s ON e.student_id = s.id
JOIN course_project.courses AS c ON e.course_id = c.id
JOIN course_project.instructors AS i ON c.instructor_id = i.id
ORDER BY e.id;
```

| 신청 ID | 학생 | 강의 | 강사 | 상태 | 기록 금액(예상) |
| --- | --- | --- | --- | --- | ---: |
| 1001 | 김민지 | 데이터베이스 입문 | 문길래 | 완료 | 100000 |
| 1002 | 김민지 | 정규화 실습 | 문길래 | 신청 | 120000 |
| 1003 | 이준호 | 데이터베이스 입문 | 문길래 | 수강중 | 100000 |
| 1004 | 박서연 | 파이썬 데이터 분석 | 홍길동 | 취소 | 150000 |
| 1005 | 이준호 | 정규화 실습 | 문길래 | 신청 | 120000 |

실제 행 수: 미실행(예상 5행). 증거 화면: 미첨부.

# 4. LEFT JOIN과 0건 표현

## 4-1. 강의별 취소 제외 신청 수

한 행은 강의 한 개다. 강의 303의 예상 신청 수·고유 학생 수·기록 금액은 모두 0이다.

```sql
SELECT c.id AS course_id, c.title,
       COUNT(e.id) AS enrollment_count,
       COUNT(DISTINCT e.student_id) AS student_count,
       COALESCE(SUM(e.recorded_amount), 0) AS recorded_amount_total
FROM course_project.courses AS c
LEFT JOIN course_project.enrollments AS e
  ON c.id = e.course_id AND e.status <> '취소'
GROUP BY c.id, c.title
ORDER BY c.id;
```

예상: 301=2건/2명/200000, 302=2건/2명/240000, 303=0건/0명/0. 실제 결과: 미실행.

## 4-2. COUNT 대상 비교

```sql
SELECT c.id, COUNT(*) AS joined_rows, COUNT(e.id) AS enrollment_count,
       COUNT(DISTINCT e.student_id) AS student_count
FROM course_project.courses AS c
LEFT JOIN course_project.enrollments AS e
  ON c.id = e.course_id AND e.status <> '취소'
WHERE c.id = 303
GROUP BY c.id;
```

예상: `COUNT(*)=1`, `COUNT(e.id)=0`, `COUNT(DISTINCT e.student_id)=0`.실제 결과: 미실행.

LEFT JOIN은 연결된 자식이 없어도 오른쪽 열을 NULL로 채운 부모 행을 남긴다. COUNT(*)는 이 행도 센다. 자식 PK인 e.id는 실제 신청에서 NULL이 아니므로 COUNT(e.id)는 실제 신청만 센다. 고유 학생 수는 재신청 이력 수와 다를 수 있으므로 별도로 계산한다.

# 5. LEFT JOIN에서 ON과 WHERE 조건 비교

## 5-1. 조건을 ON에 둔 경우

```sql
SELECT s.id, s.name, COUNT(e.id) AS non_cancelled_count
FROM course_project.students AS s
LEFT JOIN course_project.enrollments AS e
  ON s.id = e.student_id AND e.status <> '취소'
GROUP BY s.id, s.name
ORDER BY s.id;
```

예상: 학생 3명, 박서연 포함(0건). 실제: 미실행.

## 5-2. 조건을 WHERE에 둔 경우

```sql
SELECT s.id, s.name, COUNT(e.id) AS non_cancelled_count
FROM course_project.students AS s
LEFT JOIN course_project.enrollments AS e ON s.id = e.student_id
WHERE e.status <> '취소'
GROUP BY s.id, s.name
ORDER BY s.id;
```

예상: 학생 2명, 박서연 제외. 실제: 미실행.

## 5-3. 차이 설명

ON은 연결할 신청을 취소 제외로 제한하고 모든 학생을 보존한다. WHERE는 JOIN을 마친 뒤 조건을 만족하지 않는 행을 제거한다. 박서연은 취소 신청만 있어 WHERE에서 그 행이 제거된다. 신청 자체가 없는 학생도 e.status가 NULL이므로 `NULL <> '취소'`가 TRUE가 되지 않아 제거된다. 따라서 이 조건에서는 ON=3명, WHERE=2명이다.

# 6. 신청이 없는 학생 찾기 — 두 방법 비교

여기서 ‘없는 신청’은 **취소 제외 신청 이력**이다. 전체 신청이 전혀 없는 학생과 구분한다.

## 방법 1. LEFT JOIN ... IS NULL

```sql
SELECT s.id, s.name
FROM course_project.students AS s
LEFT JOIN course_project.enrollments AS e
  ON s.id = e.student_id AND e.status <> '취소'
WHERE e.id IS NULL
ORDER BY s.id;
```

## 방법 2. NOT EXISTS

```sql
SELECT s.id, s.name
FROM course_project.students AS s
WHERE NOT EXISTS (
  SELECT 1 FROM course_project.enrollments AS e
  WHERE e.student_id = s.id AND e.status <> '취소'
)
ORDER BY s.id;
```

두 방법 모두 예상 결과는 `103 / 박서연` 한 명이다. 실제 결과 및 동일 여부: 미실행.
공통 의미는 학생별로 조건에 맞는 신청이 한 건도 존재하지 않는다는 것이다. 취소 제외 조건을 제거하면 전체 신청이 없는 학생을 찾으며, 현재 Seed의 예상 결과는 0명이다.

# 7. 기본 집계 검산

```sql
SELECT COUNT(*) AS total_count, SUM(recorded_amount) AS total_amount,
       COUNT(*) FILTER (WHERE status IN ('신청', '수강중')) AS active_count,
       SUM(recorded_amount) FILTER (WHERE status IN ('신청', '수강중')) AS active_amount,
       COUNT(*) FILTER (WHERE status <> '취소') AS non_cancelled_count,
       SUM(recorded_amount) FILTER (WHERE status <> '취소') AS non_cancelled_amount,
       COUNT(*) FILTER (WHERE status = '취소') AS cancelled_count,
       SUM(recorded_amount) FILTER (WHERE status = '취소') AS cancelled_amount,
       ROUND(AVG(recorded_amount), 2) AS total_avg,
       ROUND(AVG(recorded_amount) FILTER (WHERE status <> '취소'), 2) AS non_cancelled_avg
FROM course_project.enrollments;
```

| 분석 범위 | 예상 건수 | 실제 건수 | 예상 금액 | 실제 금액 | 일치? |
| --- | ---: | --- | ---: | --- | --- |
| 전체 신청 | 5 | 미실행 | 590000 | 미실행 | 미확인 |
| 활성 신청 | 3 | 미실행 | 340000 | 미실행 | 미확인 |
| 취소 제외 | 4 | 미실행 | 440000 | 미실행 | 미확인 |
| 취소 | 1 | 미실행 | 150000 | 미실행 | 미확인 |

## 7-1. 전체 평균

예상: 590000 / 5 = 118000.00. 실제: 미실행.

## 7-2. 취소 제외 평균

예상: 440000 / 4 = 110000.00. 실제: 미실행.

recorded_amount는 신청 당시 기록한 금액이다. 결제 승인·환불·수수료·정산 이력을 포함하지 않으므로 실제 회계 매출로 부를 수 없다. 현재 courses.price를 합산하면 과거 신청 금액과도 달라질 수 있다.

# 8. GROUP BY, HAVING, FILTER

## 8-1. 상태별 신청 건수

```sql
SELECT status, COUNT(*) AS enrollment_count,
       SUM(recorded_amount) AS recorded_amount_total
FROM course_project.enrollments
GROUP BY status
ORDER BY CASE status WHEN '신청' THEN 1 WHEN '수강중' THEN 2
                    WHEN '완료' THEN 3 WHEN '취소' THEN 4 END;
```

예상: 신청 2건/240000, 수강중 1건/100000, 완료 1건/100000, 취소 1건/150000.
예상 검산: 2+1+1+1=5건, 240000+100000+100000+150000=590000. 실제: 미실행.

## 8-2. 강의별 취소 제외 신청 수와 금액

```sql
SELECT c.id, c.title,
       COUNT(e.id) FILTER (WHERE e.status <> '취소') AS non_cancelled_count,
       COALESCE(SUM(e.recorded_amount) FILTER (WHERE e.status <> '취소'), 0)
         AS non_cancelled_amount
FROM course_project.courses AS c
LEFT JOIN course_project.enrollments AS e ON c.id = e.course_id
GROUP BY c.id, c.title
ORDER BY c.id;
```

예상: 301=2건/200000, 302=2건/240000, 303=0건/0.
FILTER는 각 집계에 적용되므로 강의 행은 유지된다. 예상 합계 4건/440000으로 전체 취소 제외 기준과 같다. 실제: 미실행.

## 8-3. HAVING 사용

```sql
SELECT c.id, c.title, COUNT(e.id) AS non_cancelled_count
FROM course_project.courses AS c
JOIN course_project.enrollments AS e ON c.id = e.course_id
WHERE e.status <> '취소'
GROUP BY c.id, c.title
HAVING COUNT(e.id) >= 2
ORDER BY c.id;
```

예상 강의 수: 2개(301, 302), 각각 2건. 실제: 미실행.
WHERE는 집계할 행을 제한하고 HAVING은 집계가 끝난 그룹을 제한한다.

# 9. 과대 집계 오류 직접 관찰

## 9-1. 신청까지 JOIN해서 잘못 집계한 결과

```sql
SELECT i.id, i.name, SUM(c.price) AS wrong_course_price_sum
FROM course_project.instructors AS i
JOIN course_project.courses AS c ON i.id = c.instructor_id
JOIN course_project.enrollments AS e ON c.id = e.course_id
WHERE i.id = 201
GROUP BY i.id, i.name;
```

예상 잘못된 합계: 440000. 실제: 미실행.

## 9-2. 강의 수준에서 올바르게 집계

```sql
SELECT i.id, i.name, COALESCE(SUM(c.price), 0) AS course_price_sum
FROM course_project.instructors AS i
LEFT JOIN course_project.courses AS c ON i.id = c.instructor_id
WHERE i.id = 201
GROUP BY i.id, i.name;
```

예상 올바른 합계: 220000. 실제: 미실행.

## 9-3. 왜 두 결과가 달라졌나요?

강사 201의 강의는 JOIN 전 2행(301, 302)이다. 두 강의에 신청이 각각 2건 있어 신청 JOIN 후 4행이 된다. SUM(c.price)는 100000과 120000을 각각 두 번 더한다. 강의 가격 합계가 질문이므로 신청을 연결하지 않고 강의 수준에서 합산한다. 신청 지표도 필요하면 강의별로 먼저 신청을 집계한 뒤 연결한다.

SUM(DISTINCT c.price)는 가격 값만 중복 제거한다. 서로 다른 강의 두 개가 모두 100000이면 올바른 합계 200000 대신 100000이 되므로 일반적인 해결책이 아니다.

증거 화면: 미첨부. 잘못된 합계와 올바른 합계를 함께 비교해야 한다.

# 10. 상세 결과 ↔ 집계 결과 교차 검산

선택한 course_id: 302. 강의 제목: 정규화 실습. 상세·집계 모두 취소 제외 범위를 사용한다.

## 10-1. 상세 신청 행 조회

```sql
SELECT e.id, e.student_id, e.status, e.recorded_amount
FROM course_project.enrollments AS e
WHERE e.course_id = 302 AND e.status <> '취소'
ORDER BY e.id;
```

예상 상세: 1002/101/신청/120000, 1005/102/신청/120000.
예상 2행, 금액 직접 합산 120000+120000=240000. 실제: 미실행.

## 10-2. 집계 SQL

```sql
SELECT COUNT(*) AS enrollment_count,
       COALESCE(SUM(recorded_amount), 0) AS recorded_amount_total
FROM course_project.enrollments
WHERE course_id = 302 AND status <> '취소';
```

예상 2건/240000. 실제: 미실행.

## 10-3. 비교

예상에서는 행 수와 COUNT, 직접 합산과 SUM이 각각 같다. 실제 일치 여부는 실행 후 확인한다. 다르면 상태 조건, 강의 ID, JOIN으로 신청 ID가 반복되는지, 실제 데이터가 기준 상태인지 점검한다.

# 11. 자동 완료 게이트

실행 대상: 공식 `03_join_aggregation_validation.sql` 전체.
최종 검증 메시지: **미실행**. 기대 메시지: `Chapter 08 join and aggregation validation passed`.

자동 검증은 정해진 Seed와 기준값의 일치 여부를 확인한다. 다른 데이터에서도 업무 의미가 맞는지, 0건 부모를 보존해야 하는지, 완료를 활성에 넣어도 되는지까지 대신 판단하지는 않는다. 작성한 SQL의 결과 단위와 포함 범위를 사람이 설명하고 상세 행으로 검산해야 한다.

# 12. 개인 프로젝트 업무 질문 3개 만들기

프로젝트: **사주 기록 노트**. Chapter 07의 테이블·키 이름을 계승한다. 개인 프로젝트 테이블은 아직 PostgreSQL로 구현·실행하지 않았다. 아래는 **SQL 초안이며 전부 미실행**이다. author_type 값도 구현 시 확정할 정책으로, 여기서는 사람=`human`, AI=`ai`를 가정한다. 삭제·보관 상태나 출생 시간 필수성 등 미확정 정책은 추가하지 않는다.

| 질문 ID | 업무 질문 | 결과 한 행 | 포함/제외 범위 | JOIN 경로 | 집계 대상 | 검산 방법 |
| --- | --- | --- | --- | --- | --- | --- |
| P08-Q01 | 대상자별 출생 입력 버전과 계산 결과가 몇 건인가? | 대상자 | 모든 입력·계산, 0건 대상자 포함 | subjects → birth_info → calculation_results | 고유 입력 수, 계산 수 | 대상자 A의 입력 2건/계산 3건, B의 입력 1건/계산 0건 확인 |
| P08-Q02 | 각 계산 결과에 사람·AI 해석이 몇 건씩 있는가? | 계산 결과 | 모든 계산, 0건 포함, 사람/AI 외 값은 별도 확인 | calculation_results → interpretations | 해석 ID와 유형별 건수 | C1 해석 I1·I2 직접 조회, 유형 합계 대조 |
| P08-Q03 | 주제별 연결 해석 수와 고유 대상자 수는 얼마인가? | 주제 | 모든 주제, 계산 미연결 해석도 해석 수에는 포함 | topics → interpretation_topics → interpretations → calculation_results → birth_info | 고유 해석·대상자 수 | 진로=2해석/1대상자, 관계=1해석/1대상자 |

기대값은 Chapter 07의 가상 시나리오를 사용한다. A의 입력 A1·A2, B의 입력 B1, A1의 C1·C2와 A2의 C3, C1의 사람 I1·AI I2, I1의 진로·관계 및 I2의 진로 연결이다. 실제 데이터가 아니다.

## 12-1. 질문 1 SQL

```sql
SELECT s.id AS subject_id, s.subject_code,
       COUNT(DISTINCT b.birth_info_id) AS birth_version_count,
       COUNT(c.calculation_id) AS calculation_count
FROM subjects AS s
LEFT JOIN birth_info AS b ON b.subject_id = s.id
LEFT JOIN calculation_results AS c ON c.birth_info_id = b.birth_info_id
GROUP BY s.id, s.subject_code
ORDER BY s.id;
```

예상 결과: A=입력 2건/계산 3건, B=입력 1건/계산 0건.
실제 결과: 미실행. 검산 계획: birth_info와 calculation_results를 각각 조회해 ID별로 센다. A1이 C1·C2 때문에 두 번 연결되므로 입력 수에는 DISTINCT를 쓴다. 다른 자식 테이블을 추가하면 계산 수의 증폭도 다시 검토한다.

## 12-2. 질문 2 SQL

```sql
SELECT c.calculation_id, c.rule_version,
       COUNT(i.interpretation_id) AS interpretation_count,
       COUNT(i.interpretation_id) FILTER (WHERE i.author_type = 'human') AS human_count,
       COUNT(i.interpretation_id) FILTER (WHERE i.author_type = 'ai') AS ai_count,
       COUNT(i.interpretation_id) FILTER (
         WHERE i.author_type IS NULL OR i.author_type NOT IN ('human', 'ai')
       ) AS unclassified_count
FROM calculation_results AS c
LEFT JOIN interpretations AS i ON i.calculation_id = c.calculation_id
GROUP BY c.calculation_id, c.rule_version
ORDER BY c.calculation_id;
```

예상 결과: C1=전체 2/사람 1/AI 1/미분류 0, C2·C3=모두 0.
실제 결과: 미실행. 검산 계획: I1·I2를 직접 조회하여 사람+AI+미분류=전체인지 비교한다. 해석이 없는 계산도 LEFT JOIN으로 보존한다. 계산 미연결 해석은 이 질문의 계산별 집계에 포함되지 않으므로 별도로 조회한다.

## 12-3. 질문 3 SQL

```sql
SELECT t.topic_id, t.topic_name,
       COUNT(DISTINCT i.interpretation_id) AS interpretation_count,
       COUNT(DISTINCT b.subject_id) AS subject_count,
       COUNT(DISTINCT i.interpretation_id) FILTER (
         WHERE i.calculation_id IS NULL
       ) AS without_calculation_count
FROM topics AS t
LEFT JOIN interpretation_topics AS it ON it.topic_id = t.topic_id
LEFT JOIN interpretations AS i ON i.interpretation_id = it.interpretation_id
LEFT JOIN calculation_results AS c ON c.calculation_id = i.calculation_id
LEFT JOIN birth_info AS b ON b.birth_info_id = c.birth_info_id
GROUP BY t.topic_id, t.topic_name
ORDER BY t.topic_id;
```

예상 결과: 진로=해석 2/대상자 1/계산 미연결 0, 관계=해석 1/대상자 1/계산 미연결 0.
실제 결과: 미실행. 검산 계획: 주제별 연결쌍 2개·1개를 직접 나열하고 대상자 A가 반복되어도 한 명으로 세는지 확인한다. 주제별 해석 수 합 3은 고유 해석 수 2와 같지 않다. I1이 두 주제에 속하기 때문이다. 추가 검증 시 연결 없는 주제는 0/0, 계산 없는 해석은 해석 수에만 포함되는지도 확인한다.

# 13. AI를 JOIN·집계 리뷰어로 활용

## 13-1. AI 검토에 사용한 질문

이번 답안 작성 요청을 다음 검토 기준으로 구체화했다.

```text
Chapter 07 최종 course_project 데이터와 사주 기록 노트 설계를 기준으로
JOIN·집계 SQL을 검토한다. 각 결과 한 행의 의미와 상태 범위를 먼저 정하고,
0건 부모 보존, COUNT 대상, ON/WHERE 차이, 1:N·N:M 과대 집계,
상세 행과 집계의 교차 검산을 확인한다.
본인 DB 실행·캡처 사실을 만들지 않고 예상값과 실제 결과를 구분한다.
개인 프로젝트는 기존 키 이름을 쓰고 미확정 정책은 가정으로 명시한다.
```

## 13-2. 작성 SQL과 AI 검토 비교

아래는 AI와 함께 작성한 초안의 검토 기록이다. 별도의 사전 작성 SQL이나 실제 실행이 있었다는 의미는 아니다. 본인 최종 판단은 제출 전에 확인해야 한다.

| 검토 항목 | 작성 초안/검토 대상 | AI 검토·제안 | 최종 초안 선택 | 이유 |
| --- | --- | --- | --- | --- |
| 결과 한 행 | 학생 이름이 반복되는 신청 상세 | 신청 ID 기준 확인 | 상세=신청 한 건 | 정상 이력을 DISTINCT로 없애지 않음 |
| 상태 범위 | 활성과 취소 제외 | 완료 포함 여부 구분 | 활성 3, 취소 제외 4 | 서로 다른 업무 범위 |
| JOIN 경로 | 신청에서 강사 조회 | courses 경유 | e→c→i | 직접 연결할 강사 FK가 신청에 없음 |
| INNER/LEFT 선택 | 0건 강의 집계 | courses 기준 LEFT | LEFT 및 ON 조건 | 강의 303 유지 |
| COUNT 대상 | COUNT(*) | COUNT(e.id) 제안 | 자식 PK COUNT | NULL 확장 행 제외 |
| 과대 집계 위험 | 신청 JOIN 뒤 SUM(c.price) | 강의 수준 합산 | 신청 JOIN 제거 | 반복된 강의 가격 합산 방지 |
| 상세 검산 방법 | 합계 숫자만 확인 | 강의 302 상세 대조 | 1002·1005와 2건/240000 비교 | 같은 조건의 원본에서 재확인 |

### AI가 만든 SQL에서 확인한 위험

SUM(DISTINCT price)는 같은 가격의 다른 강의를 지울 수 있다. 개인 프로젝트에서도 출생 입력에 계산을 연결하면 입력 행이 반복되므로 입력 버전 수는 고유 PK로 센다. 주제별 해석 수를 더하면 여러 주제에 속한 해석이 반복되므로 전체 고유 해석 수와 혼동하지 않는다.

### 실행 성공만으로 정답이라고 할 수 없는 이유

문법이 맞아도 잘못된 상태 범위, 사라진 0건 부모, 반복 합산은 오류 없이 숫자를 반환한다. 업무 질문·결과 단위·포함 범위를 검토하고 상세 ID와 합계를 비교해야 한다.

# 14. 최종 성찰

아래는 본인 검토가 필요한 성찰 초안이다.

1. JOIN SQL을 작성하기 전에 가장 먼저 정해야 하는 것은 업무 질문, 결과 한 행의 의미와 포함할 상태 범위다.
2. LEFT JOIN에서 COUNT(*) 대신 COUNT(child.id)를 검토하는 이유는 자식이 없는 부모의 NULL 확장 행을 실제 사건으로 세지 않기 위해서다.
3. ON과 WHERE 조건 위치가 중요한 이유는 연결할 대상을 제한하는 것과 연결 뒤 행을 제거하는 것이 부모 보존 여부를 다르게 만들기 때문이다.
4. 여러 1:N 관계를 JOIN한 뒤 바로 SUM하면 부모나 자식 행이 반복되어 같은 금액이 여러 번 합산될 수 있다.
5. 집계 결과를 신뢰하기 전에는 같은 조건의 상세 ID·행 수·금액을 직접 나열하여 COUNT·SUM과 대조한다.

# 15. 제출 체크리스트

- [x] 본인 저장소의 지정 경로에 답안 파일을 작성했다.
- [x] 업무 질문마다 결과 한 행과 포함 범위를 정의했다.
- [x] INNER·다중·LEFT JOIN SQL을 작성했다.
- [x] COUNT 대상, ON/WHERE, anti-join 두 방식의 차이를 설명했다.
- [x] 전체·활성·취소 제외 예상값을 계산했다.
- [x] GROUP BY·HAVING·FILTER와 과대 집계 수정 SQL을 작성했다.
- [x] 상세·집계 교차 검산 SQL을 작성했다.
- [x] 개인 프로젝트 업무 질문 3개와 SQL 초안·검산 계획을 작성했다.
- [x] AI 검토 기록을 작성하고 실행 성공과 의미 검증을 구분했다.
- [ ] 본인 DB에서 00 사전 검사 통과를 확인했다.
- [ ] 본인 DB에서 JOIN·COUNT·ON/WHERE·anti-join을 실행했다.
- [ ] 본인 DB에서 기본 집계·그룹 집계·과대 집계·상세 검산을 실행했다.
- [ ] 실제 결과·일치 여부를 답안에 기록했다.
- [ ] 03 자동 완료 게이트 통과를 확인했다.
- [ ] 핵심 증거 화면 3~4장을 확보하고 제출 방식에 맞게 첨부했다.
- [ ] 본인이 개인 프로젝트 가정·AI 검토·성찰을 최종 확인했다.
- [ ] 캡처까지 포함해 비밀번호·개인정보가 없는지 확인했다.
- [ ] GitHub 웹에서 최종 Markdown·증거 표시를 확인했다.
- [ ] 실행·캡처 반영 후 최종 제출본을 commit/push했다.

# 16. LMS 제출 URL

```text
https://github.com/ssossocoder/ai-database-study/blob/main/assignments/chapter08/chapter08_answer.md
```

현재는 작성 초안이다. 본인 DB 실행·캡처·실제 결과 반영과 최종 확인 후 위 파일 화면 URL을 LMS에 제출한다.
