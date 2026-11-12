# Chapter 10 확장 실습 답안

> **과제:** 실행 계획으로 인덱스 효과 검증하기  
> **작성 상태:** 환경과 초기 데이터 규모·분포 확인, SQL·인덱스 설계 작성. 실행 계획·반복 측정값·최종 검증 결과는 측정 대기.

- GitHub 계정: ssossocoder
- 작성일: 2026-11-12
- 사용한 AI 도구: Codex

# 1. PostgreSQL 버전과 시작 환경 확인

| 확인 항목 | 실제 결과 | 의미 |
| --- | --- | --- |
| PostgreSQL 버전 | PostgreSQL 18.6 / aarch64-apple-darwin24.6.0 / 64-bit | 과제의 기준 버전 16과 구별하여 해석 |
| `current_database()` | ai_database_book | 수강신청 실습 DB |
| `current_user` | postgres | 실행 역할 |
| `current_schema()` | public | 기본 스키마 |
| `search_path` | `"$user", public` | 이름을 해석하는 탐색 순서 |

확인 SQL:

```sql
SELECT version();
SELECT current_database();
SELECT current_user;
SELECT current_schema();
SHOW search_path;
```

환경 확인 시점에는 `performance_lab`이 없었다. 이후 실습 객체는 모두 `performance_lab.`으로 한정해 사용하도록 준비했다.

PostgreSQL 버전을 기록하는 이유는 같은 SQL·인덱스라도 최적화 기능과 비용 판단에 따라 계획이 달라질 수 있기 때문이다. 특히 PostgreSQL 18의 B-tree Skip Scan을 고려하면 후행 컬럼 조건을 항상 사용할 수 없다고 단정할 수 없다. 다만 기능이 있다는 사실만으로 실제 선택을 보장하지는 않는다. [PostgreSQL 18 복합 인덱스 문서](https://www.postgresql.org/docs/18/indexes-multicolumn.html)

# 2. Chapter 07·08 기준 상태 확인

직전 Chapter 09 답안의 검증 기록은 아래 기준과 일치했다. 이번 Chapter 10 시작·종료 시점의 재확인은 아직 대기 상태이므로 이전 기록과 현재 측정값을 구분한다.

| 항목 | 이전 답안 기록 / 이번 기대값 | 이번 실제 확인 |
| --- | ---: | --- |
| students | 3 | 확인 대기 |
| instructors | 2 | 확인 대기 |
| courses | 3 | 확인 대기 |
| enrollments | 5 | 확인 대기 |
| 전체 recorded_amount | 590000 | 확인 대기 |
| 활성 신청 건수 / 금액 | 3 / 340000 | 확인 대기 |
| 취소 제외 건수 / 금액 | 4 / 440000 | 확인 대기 |
| 신청 1001 | 완료 / 100000 | 확인 대기 |
| 신청 1004 | 취소 / 150000 | 확인 대기 |
| 신청 1005 | 신청 / 120000 | 확인 대기 |

`course_project`에 대량 데이터를 넣으면 이전 장에서 검증한 건수·분포·금액과 무결성 실험 기준이 바뀐다. 별도 스키마에서 실험하면 원본을 유지하며 성능 실험용 데이터와 인덱스를 구분할 수 있다. 스키마 분리만으로 오수정이 자동 차단되는 것은 아니므로 모든 변경 대상을 한정하고 최종 검증에서도 원본 상태를 확인한다.

# 3. performance_lab 생성과 대량 데이터 확인

실행 순서:

```text
01_performance_lab_schema.sql
02_performance_lab_seed.sql
```

## 3-1. 생성 후 행 수

| 테이블 | 기대 행 수 | 실제 행 수 | 일치 여부 |
| --- | ---: | --- | --- |
| performance_lab.students | 10003 | 10003 | 일치 |
| performance_lab.instructors | 2 | 2 | 일치 |
| performance_lab.courses | 2003 | 2003 | 일치 |
| performance_lab.enrollments | 100005 | 100005 | 일치 |

## 3-2. 데이터 분포와 선택도

2026-11-12 11:28:18 DBeaver에서 실행한 규모·분포 요약의 expected와 actual을 비교했다. 네 테이블의 행 수와 여섯 조회 조건의 건수가 모두 일치했다. 아래 비율은 확인된 건수로 계산한 근삿값이다.

| 조건 | 기대 행 수 | 실제 행 수 | 해당 테이블 대비 기대 반환 비율 |
| --- | ---: | --- | ---: |
| email = performance5000@example.com | 1 | 1 | 약 0.010% |
| title = 성능 테스트 강의 00500 | 1 | 1 | 약 0.050% |
| student_id = 5000 | 10 | 10 | 약 0.010% |
| course_id = 1500 | 50 | 50 | 약 0.050% |
| course_id = 1500 AND status = 수강중 | 15 | 15 | 약 0.015% |
| status = 수강중 | 30001 | 30001 | 약 30.0% |

여기서는 용어의 혼동을 피하려고 반환 비율로 비교한다. 전체에서 소수 행만 찾는 조건은 인덱스로 불필요한 페이지 접근을 줄일 가능성이 크다. 많은 행이 테이블 전반에 흩어져 있으면 인덱스와 테이블을 번갈아 방문하는 비용 때문에 순차 조회가 유리할 수 있다. 비율 외에 테이블 크기, 행의 물리적 배치, 필요한 컬럼, 정렬과 LIMIT도 함께 확인한다.

**증거 화면 확인:** 2026-11-12 오전 11:28:26에 촬영한 DBeaver 결과표에서 10개 항목의 expected와 actual 일치를 확인했다. 캡처 이미지의 저장소 첨부는 남아 있다.

# 4. 인덱스 생성 전 기준 계획 기록

`03_baseline_explain.sql`을 후보 인덱스가 없는 상태에서 먼저 실행한다. 자동 인덱스 6개만 있는지 확인하고, 아래 세 SQL을 포함한 8개 조회의 계획을 확보한다.

## Query A — 강의 제목 정확 일치

- 업무 질문: 제목이 정확히 일치하는 강의의 ID·제목·등급·가격은 무엇인가?
- WHERE: title 정확 일치
- JOIN / ORDER BY / LIMIT: 없음
- 예상 반환 행 수: seed 기준 1행
- 실제 반환 행 수: 측정 대기

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, title, level, price
FROM performance_lab.courses
WHERE title = '성능 테스트 강의 00500';
```

## Query B — 학생별 신청과 학생·강의 정보

- 업무 질문: 학생 5000의 신청 내역과 학생명·강의명·상태·신청 금액은 무엇인가?
- WHERE: e.student_id = 5000
- JOIN: students PK, courses PK
- ORDER BY / LIMIT: 없음
- 예상 반환 행 수: seed 기준 10행
- 실제 반환 행 수: 측정 대기

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT e.id, s.name AS student_name, c.title AS course_title,
       e.status, e.recorded_amount
FROM performance_lab.enrollments AS e
JOIN performance_lab.students AS s ON s.id = e.student_id
JOIN performance_lab.courses AS c ON c.id = e.course_id
WHERE e.student_id = 5000;
```

## Query C — 특정 강의의 수강중 신청

- 업무 질문: 강의 1500에서 수강중인 신청 내역은 무엇인가?
- WHERE: course_id = 1500 AND status = 수강중
- JOIN / ORDER BY / LIMIT: 없음
- 예상 반환 행 수: seed 기준 15행
- 실제 반환 행 수: 측정 대기

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_id, course_id, status, recorded_amount
FROM performance_lab.enrollments
WHERE course_id = 1500 AND status = '수강중';
```

## 기준 계획 기록표

| 관찰 항목 | Query A | Query B | Query C |
| --- | --- | --- | --- |
| 주요 Scan / 계획 노드 | 측정 대기 | 측정 대기 | 측정 대기 |
| estimated rows | 측정 대기 | 측정 대기 | 측정 대기 |
| actual rows / loops | 측정 대기 | 측정 대기 | 측정 대기 |
| Filter / Rows Removed by Filter | 측정 대기 | 측정 대기 | 측정 대기 |
| Index Cond / 사용 인덱스 | 측정 대기 | 측정 대기 | 측정 대기 |
| 실행 Buffers shared hit / read | 측정 대기 | 측정 대기 | 측정 대기 |
| Planning Time | 측정 대기 | 측정 대기 | 측정 대기 |
| Execution Time | 측정 대기 | 측정 대기 | 측정 대기 |

`cost`는 비용 매개변수로 계산한 상대적인 추정값이고, 실제 실행 시간의 ms 값이 아니다. estimated rows는 노드가 출력할 행 수의 추정치이며 actual rows와 구분한다. loops가 여러 번이면 표시된 actual rows·time이 반복당 평균이라는 점도 확인한다. [EXPLAIN 공식 문서](https://www.postgresql.org/docs/18/using-explain.html)

`EXPLAIN ANALYZE`는 SQL을 실제 실행하므로 변경문에 붙이면 데이터도 변경할 수 있다. 이번 비교는 SELECT에만 적용한다. 결과 데이터 대신 계획을 출력하므로 반환 데이터의 정합성은 별도 조회와 최종 Validation으로 확인한다.

**증거 화면:** 기준 계획 확보 후 대표 Query B 계획을 추가할 예정.

# 5. 후보 인덱스를 만들기 전에 이유 작성

| 후보 인덱스 | 대응 조회 패턴 | 예상 이점 | 컬럼 순서 이유 | 예상 비용 / 단점 |
| --- | --- | --- | --- | --- |
| idx_performance_courses_title | 제목 정확 일치, ORDER BY title, LIMIT 20 | 제목 검색과 정렬 순서 활용 | 단일 검색·정렬 키 title | 추가 공간, 강의 INSERT 및 title 변경 시 유지 비용 |
| idx_performance_enrollments_student_id | 학생별 신청 조회와 JOIN | 전체 신청 중 학생 1명의 신청을 먼저 축소 | 필터 대상인 student_id | 신청 INSERT 및 student_id 변경 시 유지 비용 |
| idx_performance_enrollments_course_status | 강의별 신청, 특정 강의의 상태별 신청 | course_id와 두 조건을 모두 지원 | course_id 단독 조회도 있으므로 앞에 배치 | 추가 공간, 신청 INSERT와 status 변경 시 유지 비용 |

“중요한 컬럼”이라는 이유만으로는 검색 빈도, 조건별 반환 비율, 기존 인덱스 중복, 정렬과 쓰기 비용을 설명하지 못한다. 실제 SQL의 필터와 접근 순서에 맞춰 판단해야 한다.

두 컬럼 모두 동등 조건이면 `(course_id, status)`와 `(status, course_id)`가 모두 유용할 수 있다. 그러나 course_id만 사용하는 조회까지 함께 지원하려는 목적에서는 전자가 자연스럽다. 후행 컬럼만 사용하는 조회는 선행 컬럼의 고유값 수와 Skip Scan의 비용에 따라서도 달라지므로 두 순서를 항상 동등하다고 보지 않는다.

# 6. 후보 인덱스 생성

기준 계획을 저장한 다음에만 다음 DDL을 실행한다.

```sql
CREATE INDEX idx_performance_courses_title
ON performance_lab.courses(title);

CREATE INDEX idx_performance_enrollments_student_id
ON performance_lab.enrollments(student_id);

CREATE INDEX idx_performance_enrollments_course_status
ON performance_lab.enrollments(course_id, status);
```

| 구분 | 생성 후 기대값 | 실제 확인 |
| --- | ---: | --- |
| PK·UNIQUE 자동 인덱스 | 6 | 확인 대기 |
| 후보 인덱스 | 3 | 확인 대기 |
| 전체 인덱스 | 9 | 확인 대기 |
| 후보 중 invalid / not ready | 0 | 확인 대기 |

PK·UNIQUE가 제공하는 인덱스와 같은 목적의 인덱스를 추가하면 조회 이점은 중복되고 공간과 쓰기 유지 비용이 늘 수 있다. 예를 들어 학생 email은 UNIQUE 인덱스가 있으므로 같은 email 단일 인덱스를 추가할 이유부터 다시 확인한다.

# 7. 같은 SQL로 인덱스 후 재측정

03과 05에 포함된 8개 SELECT의 일치를 확인했다. 전후 측정 사이에 데이터와 테이블 통계를 바꾸지 않고, 같은 연결·설정에서 각각 3회 기록한다. 첫 회의 캐시 영향도 기록하며 반복값의 범위와 중앙값을 비교한다.

## Query A 전후 비교

| 항목 | Before | After | 해석 기준 |
| --- | --- | --- | --- |
| 주요 계획 노드 | 측정 대기 | 측정 대기 | 제목 후보 인덱스 사용 여부 |
| actual rows | 측정 대기 | 측정 대기 | 1행 기대, 실제 결과 확인 |
| 실행 Buffers hit / read | 측정 대기 | 측정 대기 | 접근한 버퍼 수와 캐시 상태 |
| Execution Time 1 / 2 / 3회 | 측정 대기 | 측정 대기 | 한 회의 최솟값으로 판단하지 않음 |
| Execution Time 중앙값 | 측정 대기 | 측정 대기 | 반복값과 함께 비교 |
| Index Cond | 측정 대기 | 측정 대기 | title 조건 반영 여부 |

## Query B 전후 비교

| 항목 | Before | After | 해석 기준 |
| --- | --- | --- | --- |
| 주요 계획 노드 | 측정 대기 | 측정 대기 | enrollments 접근 및 JOIN 전체 |
| actual rows / loops | 측정 대기 | 측정 대기 | 최상위 10행 기대, 하위 반복 구분 |
| 실행 Buffers hit / read | 측정 대기 | 측정 대기 | JOIN을 포함한 최상위 노드 기준 |
| Execution Time 1 / 2 / 3회 | 측정 대기 | 측정 대기 | 동일 SELECT로 반복 |
| Execution Time 중앙값 | 측정 대기 | 측정 대기 | 편차와 함께 비교 |
| Index Cond | 측정 대기 | 측정 대기 | student_id 및 PK 탐색 조건 |

## Query C 전후 비교

| 항목 | Before | After | 해석 기준 |
| --- | --- | --- | --- |
| 주요 계획 노드 | 측정 대기 | 측정 대기 | 일반 Index / Bitmap / Seq Scan 구분 |
| actual rows | 측정 대기 | 측정 대기 | 15행 기대, 실제 결과 확인 |
| 실행 Buffers hit / read | 측정 대기 | 측정 대기 | 두 조건으로 접근량이 줄었는지 |
| Execution Time 1 / 2 / 3회 | 측정 대기 | 측정 대기 | 조건을 바꾸지 않고 반복 |
| Execution Time 중앙값 | 측정 대기 | 측정 대기 | 편차와 함께 비교 |
| Index Cond | 측정 대기 | 측정 대기 | course_id와 status 반영 여부 |

현재는 세 SQL 모두 결과 동일성·버퍼 감소·계획 변경·성능 개선을 확정하지 않았다.

Index Scan으로 바뀌어도 실제 버퍼 접근과 시간이 줄었다고 단정할 수 없다. Bitmap 계획이 선택될 수도 있으며 노드 이름 자체가 성공 기준은 아니다. 상위 노드의 Buffers에는 하위 작업이 포함될 수 있으므로 모든 노드의 수치를 단순 합산하지 않는다. shared read도 OS 캐시를 거칠 수 있어 디스크 장치의 물리 읽기 횟수와 동일시하지 않는다.

**증거 화면:** 사후 Query B 계획을 기준 계획과 비교하여 추가할 예정.

# 8. status 단독 조회와 Seq Scan 해석

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_id, course_id, status
FROM performance_lab.enrollments
WHERE status = '수강중';
```

| 항목 | 기록 |
| --- | --- |
| seed 기준 기대 행 수 | 30001 |
| 실제 반환 행 수 | 측정 대기 |
| 주요 계획 노드 | 측정 대기 |
| Buffers / Execution Time | 측정 대기 |

수강중 조건은 약 30%를 반환하도록 설계되어 있다. 행들이 넓게 분포하면 인덱스를 찾은 뒤 많은 테이블 페이지를 방문하기보다 테이블을 순차적으로 읽는 편이 쌀 수 있다. 따라서 인덱스가 있어도 Seq Scan을 선택하는 것은 합리적일 수 있다.

PostgreSQL 16과 18은 후행 조건의 최적화 가능성이 다르다. 18에서도 선행 course_id의 고유값이 많거나 반환 범위가 넓으면 Skip Scan보다 다른 접근이 유리할 수 있다. 이번 서버의 실제 계획으로 판단해야 하며, 현재 Seq Scan이나 Skip Scan이 관찰되었다고 기록하지 않는다.

# 9. ORDER BY와 LIMIT에서 인덱스 관찰

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, title, level, price
FROM performance_lab.courses
ORDER BY title;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, title, level, price
FROM performance_lab.courses
ORDER BY title
LIMIT 20;
```

| 조건 | Before | After |
| --- | --- | --- |
| ORDER BY title | 측정 대기 | 측정 대기 |
| ORDER BY title LIMIT 20 | 측정 대기 | 측정 대기 |

title B-tree가 정렬 순서를 제공하면 별도 Sort를 생략하고 LIMIT에 필요한 행에서 멈출 수 있다. 전체 반환에서는 순차 읽기 후 정렬이 더 저렴할 수도 있다. 실제 계획의 Sort 유무, Sort Method, 사용 인덱스, Limit 하위 노드의 actual rows·Buffers를 비교한다. [인덱스와 정렬 공식 문서](https://www.postgresql.org/docs/18/indexes-ordering.html)

# 10. 인덱스 검토

## 10-1. 인덱스별 판단

| 인덱스 | 크기 / 사용 관찰 | 현재 판단 | 확정에 필요한 근거 |
| --- | --- | --- | --- |
| idx_performance_courses_title | 측정 대기 | 실험 후보, 운영 채택 보류 | 제목 검색·LIMIT 계획, 반복 시간, 크기 |
| idx_performance_enrollments_student_id | 측정 대기 | 실험 후보, 운영 채택 보류 | 학생별 JOIN의 접근량 감소 |
| idx_performance_enrollments_course_status | 측정 대기 | 실험 후보, 운영 채택 보류 | 강의 단독·복합 조건과 status 갱신 부담 |

`idx_scan = 0`만으로 삭제하면 안 된다. 통계 초기화 시점과 관찰 기간이 짧을 수 있고 드물지만 중요한 조회·부모 키 변경에서 사용될 수 있다. PK·UNIQUE 인덱스는 제약조건 역할도 있으므로 사용 통계와 분리해서 본다.

FK 자식 컬럼 인덱스는 FK 무결성 성립 자체의 필수 조건은 아니다. 다만 부모 삭제·키 변경 시 참조 자식을 찾거나 자식 조회·JOIN을 수행할 때 전체 스캔을 줄일 수 있다. FK라는 이유만으로 일괄 생성하지 않고 실제 조건과 기존 인덱스의 선두 컬럼을 확인한다.

인덱스는 저장 공간·생성 시간과 관련 DML의 유지 비용을 추가한다. status를 키로 포함한 인덱스는 상태 변경 시에도 관리가 필요하다. 쓰기 지연·WAL·백업 공간 등도 운영 판단 대상이다. 현재 저장 크기와 쓰기 비용은 측정하지 않았으므로 개선율이나 비용 수치를 제시하지 않는다.

# 11. 자동 완료 게이트

공식 `07_result_validation.sql`의 최종 검증 결과: **실행 확인 대기**.

| 검증 대상 | 통과 기준 | 현재 상태 |
| --- | --- | --- |
| lab 행 수 | 10003 / 2 / 2003 / 100005 | 대기 |
| 주요 조회 결과 수 | 1 / 1 / 10 / 50 / 15 / 30001 | 대기 |
| 신청 상태 분포 | 30002 / 30001 / 20001 / 20001 | 대기 |
| 활성 신청 중복 | 0건 | 대기 |
| 신청 금액과 강의 가격 불일치 | 0건 | 대기 |
| 학생별·강의별 생성 분포 | 학생당 10건, 강의당 50건 | 대기 |
| 인덱스 | 전체 9개, 후보 3개, 후보 valid / ready | 대기 |
| 원본 보존 | 기준 행·금액·상태·제약조건 유지 | 대기 |

기대 통과 메시지는 다음과 같다. 아직 관찰한 메시지는 아니다.

```text
Chapter 10 performance result validation passed
```

실행 계획이 빨라져도 조건 누락이나 JOIN 변경으로 결과가 달라졌다면 올바른 최적화가 아니다. 동일 SQL을 유지하고 결과 건수·무결성을 별도로 확인한다. 건수만 같은 서로 다른 데이터도 가능하므로 의심되는 변경이 있으면 키·값이나 양방향 EXCEPT로도 대조한다.

**증거 화면:** 최종 검증 요약과 서버 출력의 통과 메시지를 직접 캡처한 뒤 추가할 예정.

# 12. 인덱스 만능론 반박

## 주장 1 — “인덱스를 만들었는데 Seq Scan이면 실패다.”

반환 비율이 크고 테이블 페이지를 많이 읽어야 하면 Seq Scan이 더 저렴할 수 있다. 이번 status 단독 조건은 30001 / 100005행을 반환하도록 설계되어 있어 이 주장을 검토하기에 적절하다.

실제 계획 근거: 측정 대기. status 단독 계획이 확보되면 Scan·Buffers·반복 시간을 기록하고 그 결과에 맞춰 결론을 보완한다.

## 주장 2 — “실행 시간이 한 번이라도 빨라졌으면 효과가 입증됐다.”

한 번의 시간은 캐시·동시 부하·계획 준비 비용 등의 영향을 받는다. A·B·C를 전후 각각 3회 측정하고 시간 범위·중앙값, 버퍼 접근, 실제 행 수와 Index Cond를 함께 비교해야 한다.

실제 계획 근거: 측정 대기. 현재는 반복 측정값이 없으므로 성능 개선이 입증됐다고 결론내리지 않는다.

# 13. 개인 프로젝트 조회 패턴과 인덱스 후보

Chapter 08·09의 **청약 의사결정 노트**를 이어서 설계한다. [개인 프로젝트 기획안](https://github.com/ssossocoder/database-project/blob/main/database-project/01_proposal/proposal.md)의 회원·관심 공고·노트 관계를 기준으로 검토했다.

기획안은 구현 전 설계이므로 아래 SQL의 `created_at` 등은 확정 DDL의 컬럼명이 아닌 설계 후보이다. 실제 저장 구조와 기존 인덱스를 확인한 뒤 적용한다.

| ID | 반복 조회 질문 | WHERE | JOIN | ORDER BY / LIMIT | 예상 반환 비율 | 후보 인덱스 |
| --- | --- | --- | --- | --- | --- | --- |
| P10-Q01 | 로그인 회원이 최근 저장한 관심 공고 20개는? | w.app_user_id = 인증 회원 | announcement PK | w.created_at DESC, w.id DESC / 20 | 회원별 편차에 따라 측정 필요 | watchlist(app_user_id, created_at DESC, id DESC) |
| P10-Q02 | 내 관심 공고 하나에 최근 작성한 노트 20개는? | w.id = 대상 관심 ID, w.app_user_id = 인증 회원 | user_note.watchlist_id = w.id | n.created_at DESC, n.id DESC / 20 | 관심 공고별 노트 수에 따라 측정 필요 | user_note(watchlist_id, created_at DESC, id DESC) |

## 후보 1 — 회원별 최근 관심 목록

```sql
-- 구현 전 설계 SQL: 실제 프로젝트 DB에서 실행한 결과가 아님
SELECT w.id, w.announcement_id, w.created_at
FROM watchlist AS w
JOIN announcement AS a ON a.id = w.announcement_id
WHERE w.app_user_id = :authenticated_user_id
ORDER BY w.created_at DESC, w.id DESC
LIMIT 20;

CREATE INDEX idx_watchlist_user_created_id
ON watchlist(app_user_id, created_at DESC, id DESC);
```

회원 ID 동등 조건을 선두에 두고 그 범위에서 최신순으로 읽도록 설계했다. id는 생성 시각이 같은 행의 순서를 일정하게 만든다. 계획된 UNIQUE(app_user_id, announcement_id)도 회원별 필터를 지원할 수 있지만 created_at 정렬을 그대로 제공하지는 않는다. 기존 고유 인덱스와 비교하여 정렬 생략 효과가 실제로 필요한지 확인한다.

추가 공간과 관심 등록·삭제 시 유지 비용이 발생한다. **현재 판단은 후보로 보류**이다. 회원별 관심 목록이 매우 작다면 기존 고유 인덱스와 소규모 정렬로 충분할 수 있다.

## 후보 2 — 관심 공고별 최근 노트

```sql
-- 구현 전 설계 SQL: 실제 프로젝트 DB에서 실행한 결과가 아님
SELECT n.id, n.watchlist_id, n.content, n.created_at
FROM watchlist AS w
JOIN user_note AS n ON n.watchlist_id = w.id
WHERE w.id = :watchlist_id
  AND w.app_user_id = :authenticated_user_id
ORDER BY n.created_at DESC, n.id DESC
LIMIT 20;

CREATE INDEX idx_user_note_watchlist_created_id
ON user_note(watchlist_id, created_at DESC, id DESC);
```

watchlist_id 동등 조건 다음에 최신순 키를 배치했다. watchlist PK 조회와 회원 소유 조건은 유지한다. 인덱스가 권한 검사를 대신하지는 않는다. 긴 content는 정렬 키나 INCLUDE에 넣지 않고 테이블에서 필요한 행의 내용을 읽는 안을 우선 검토한다.

추가 공간과 노트 INSERT·삭제·키 컬럼 변경 시 유지 비용이 발생한다. **현재 판단은 후보로 보류**이다. 실제 노트 수와 정렬 비용을 먼저 측정한다.

## 데이터가 적을 때의 검증 계획

- 규모 후보: watchlist 10만 건, user_note 30만 건에서 시작하고 실제 예상 운영 규모도 함께 비교한다. 이는 적재 완료 건수가 아닌 실험 계획이다.
- 분포: 관심 목록이 적은 회원과 많은 회원, 노트가 0·1·수십·수천 건인 관심 공고, 동일 생성 시각을 가진 행을 포함한다.
- 비교 SQL: 위 P10-Q01·Q02를 동일한 바인드 값과 SELECT로 전후 비교한다.
- 지표: 실제 결과·정렬 순서, Scan·Sort·Index Cond, estimated/actual rows, Buffers, 반복 시간, 인덱스 크기, 필요한 경우 대표 쓰기 비용.
- 현재 상태: DDL 확정과 데이터 적재·실행 계획 확보 전이므로 두 후보 모두 성능 채택 보류. 계획을 유도하려고 enable_seqscan을 끄지 않는다.

# 14. AI를 실행 계획 리뷰어로 활용

## 14-1. 검토에 사용한 정보

| 항목 | 내용 |
| --- | --- |
| 업무 질문 | 제목 검색, 학생별 신청 JOIN, 강의·상태별 신청, 정렬·LIMIT |
| PostgreSQL 버전 | 실제 환경 확인: 18.6 |
| 테이블 행 수 | 실제 확인: 10003 / 2 / 2003 / 100005 |
| 데이터 분포 | COUNT 조회로 확인: student 10건, course 50건, 복합 15건, 수강중 30001건 |
| 기존 인덱스 | 제공 스키마 기준 PK·UNIQUE 6개, 실제 목록 확인 대기 |
| SQL | 4·8·9절의 SELECT 및 개인 프로젝트 설계 SQL |
| EXPLAIN 핵심 결과 | 아직 미확보. 실제 성능에 대한 채택 판단은 보류 |

## 14-2. 제안 검토

| AI 제안 | 판단 | 현재 확보한 근거 | 최종 판단 조건 |
| --- | --- | --- | --- |
| courses(title) | 실험 후보 수용, 성능 채택 보류 | 제목 동등 검색과 정렬·LIMIT SQL 존재 | 실제 계획과 반복 측정에서 이점 확인 |
| enrollments(student_id) | 실험 후보 수용, 성능 채택 보류 | 학생별 JOIN, seed 기준 소수 행 | JOIN 전체 버퍼·시간과 쓰기 비용 비교 |
| enrollments(course_id, status) | 실험 후보 수용, 성능 채택 보류 | course_id 단독 및 복합 조건을 함께 사용 | 두 조회 계획과 상태 변경 비용 확인 |
| students(email) 인덱스 추가 | 보류 | 제공 스키마의 email UNIQUE와 중복 가능 | 실제 인덱스 정의 확인 후 중복이면 추가하지 않음 |
| status 단독 인덱스 추가 | 보류 | seed에서 약 30% 반환, 추가 유지 비용 | 기존 복합 인덱스 후 계획과 실제 워크로드부터 확인 |
| 개인 프로젝트 복합 인덱스 2개 | 후보 보류 | 조회·정렬 조건과 설계상 대응 | 확정 DDL·기존 인덱스·실제 분포에서 전후 검증 |

현재 만들지 않기로 보류한 것은 중복 가능성이 있는 email 단일 인덱스와 status 단독 인덱스이다. 인덱스가 존재한다거나 반환 비율이 작다는 이유만으로 항상 Index Scan이 선택된다는 주장은 채택하지 않는다.

버전·분포를 무시한 단정은 근거로 사용하지 않았다. 특히 18.6 환경에서 후행 컬럼을 절대 사용할 수 없다고 설명하지 않고, Skip Scan 가능성과 실제 비용 판단을 구분한다.

실제 계획 없이 제안을 채택하면 중복 인덱스, 불필요한 쓰기 부담, 정렬 키 순서 불일치 등을 놓칠 수 있다. 현재 표는 SQL·스키마에 대한 설계 검토이며 실제 실행 계획과의 비교 검증은 남아 있다.

# 15. 최종 성찰

1. 인덱스 필요성을 판단할 때 먼저 확인할 것은 실제 반복 조회의 조건과 반환 비율, 기존 실행 계획이다.
2. 같은 SQL의 전후를 비교할 때 통제할 것은 데이터·바인드 값·SELECT·통계·플래너 설정이며 캐시와 부하의 영향도 기록해야 한다.
3. Seq Scan은 많은 행과 페이지를 읽는 작업에서 합리적일 수 있으므로 노드 이름만으로 나쁜 계획이라고 할 수 없다.
4. 한 번의 시간보다 계획·Buffers·행 수를 함께 봐야 실제 접근량 변화와 측정 편차를 구분할 수 있다.
5. 개인 프로젝트 후보는 조회 조건과 정렬에는 대응하지만 실제 DDL·분포·실행 계획이 없으므로 운영 적용을 보류했다.

# 16. 제출 체크리스트

- [x] 본인 저장소에 작성할 chapter10_answer.md를 준비했다.
- [x] PostgreSQL 버전과 시작 환경을 확인했다.
- [ ] Chapter 07·08 기준 상태를 이번 실행에서 재확인했다.
- [x] performance_lab의 10003 / 2 / 2003 / 100005를 실제 확인했다.
- [ ] 후보 인덱스 생성 전에 기준 실행 계획을 저장했다.
- [ ] 최소 3개 SQL의 기준 계획과 반복 측정값을 기록했다.
- [x] 후보 인덱스 3개의 이유와 컬럼 순서를 작성했다.
- [x] 전후 비교용 8개 SELECT의 일치를 확인했다.
- [ ] 동일 SQL의 전후 계획·actual rows·Buffers·Index Cond·시간을 비교했다.
- [ ] status 단독 조건의 실제 계획을 해석했다.
- [ ] ORDER BY와 LIMIT의 실제 계획을 확인했다.
- [x] 인덱스 만능론 주장 2개의 반박 논리를 작성했다.
- [ ] 반박에 실제 실행 계획 근거를 추가했다.
- [ ] 공식 07_result_validation.sql의 최종 통과를 확인했다.
- [x] 개인 프로젝트의 반복 조회 2개와 후보를 설계했다.
- [ ] AI 제안을 실제 실행 계획과 비교하여 최종 판정했다.
- [ ] 직접 촬영한 핵심 캡처 3~4장을 추가했다.
- [ ] 캡처의 개인정보와 GitHub 이미지 표시를 확인했다.
- [ ] 측정값과 증거를 모두 반영한 제출 최종본을 확정했다.

# 17. LMS 제출 URL

답안 파일 URL:

[chapter10_answer.md](https://github.com/ssossocoder/ai-database-study/blob/main/assignments/chapter10/chapter10_answer.md)

현재는 실행 결과와 캡처를 보완하기 전 상태이다. 체크리스트의 미완료 항목을 확인한 뒤 최종 제출한다.
