# Chapter 07 실제 실행 결과 — 복사·교체용

아래 각 코드 블록을 복사하여 답안의 같은 제목 부분을 교체한다. DB 실행용 SQL이 아닌 Markdown 답안이다. 실행 결과는 사용자 캡처와 Codex의 DBeaver 재검증에 근거한다.

````markdown
## 5-2. 실행 결과

| 항목 | 기대값 | 실제 결과 |
| --- | --- | --- |
| 테이블 수 | 4 | 4 (네 테이블의 to_regclass 결과 확인) |
| 명명 제약조건 수 | 15 | 15 (공식 생성 SQL의 PASS 검사로 확인) |
| NOT NULL 열 수 | 20 | 20 (공식 생성 SQL의 PASS 검사로 확인) |
| 활성 신청 인덱스 | uq_course_enrollments_active 존재 | 존재 (active_index 결과와 PASS 검사로 확인) |
| students/instructors/courses/enrollments 행 수 | 0/0/0/0 | 0/0/0/0 (공식 생성 SQL의 PASS 검사로 확인) |
| 통과 메시지 | Chapter 07 course project schema creation passed | Chapter 07 course project schema creation passed |

### 예상과 실제 비교

2026-10-12 11:31 캡처에서 공식 생성 SQL의 통과 메시지와 네 테이블·활성 인덱스 조회 결과를 확인했다. 제약조건 15개, NOT NULL 20개, 각 테이블 0행은 해당 SQL이 PASS 전에 검사하는 기준이므로 예상과 일치한다. 캡처에는 별도 숫자 조회 표가 없으며 PASS 검사에 근거해 기록했다. 같은 실행 탭에서 COMMIT 뒤 객체 조회 결과가 표시된다.

### 증거 화면

![스키마 생성 PASS와 테이블·활성 인덱스 확인](./images/step05_schema.png)
````

````markdown
## 6-1. 실행 전 예상 / 6-2. 실제 결과

| 항목 | 실행 전 예상 | 실제 결과 |
| --- | --- | --- |
| students | 3 | 3 |
| instructors | 2 | 2 |
| courses | 3 | 3 |
| enrollments | 4 | 4 (변경 전 상태) |
| recorded_amount 합계 | 470000 | 470000 (변경 전 상태) |
| 학생 101 신청 건수 | 2 | 2 |
| 강의 301 신청 건수 | 2 | 2 |
| 강사 201 담당 강의 수 | 2 | 2 |
| 활성 중복 신청 | 0 | 0 |
| 1001 상태 | 수강중 | 수강중 (변경 전 상태) |
| 1004 상태 | 신청 | 신청 (변경 전 상태) |
| 1005 존재 여부 | 없음, 0행 | 없음, 0행 (변경 전 상태) |
| 통과 메시지 | Chapter 07 course project seed passed | 간소화 Seed 입력 SQL을 사용하여 해당 NOTICE는 출력하지 않음 |

합계 근거: 100000 + 120000 + 100000 + 150000 = 470000.

Seed 입력은 채팅에서 제공한 BEGIN·빈 테이블 검사·INSERT·identity 조정·COMMIT SQL로 수행했다. 변경 전 행 수·합계·1001·1004 상태·1005 없음은 공식 변경 SQL의 시작 상태 검사 통과로 확인했다. 학생 101·강의 301·강사 201의 관계 개수와 활성 중복 없음은 Seed 입력문 및 후속 공식 Validation으로 확인했다. 이후 변경으로 신청은 5건, 전체 금액은 590000이 되었으므로 현재 상태와 Seed 직후 상태를 구분한다.

### Seed 데이터를 검증 데이터라고 볼 수 있는 이유

학생 101의 여러 신청, 강의 301의 여러 학생, 강사 201의 여러 강의를 포함해 관계를 확인한다. 특정 ID의 이전 상태와 금액도 정해 두어 변경 시나리오의 시작 조건을 자동 검사할 수 있다. 명시적 ID 입력 후 identity의 다음 값도 조정한다.
````

````markdown
## 7-2. 실제 결과

```text
1001 상태 / recorded_amount: 완료 / 100000
1004 상태 / recorded_amount: 취소 / 150000
1005 상태 / recorded_amount: 신청 / 120000
최종 enrollments 행 수: 5
전체 recorded_amount 합계: 590000
취소 제외 건수: 4
취소 제외 recorded_amount 합계: 440000
활성 중복 신청: 0
통과 메시지: Chapter 07 course project changes passed
```

2026-10-12 12:03 캡처에서 세 신청의 상태·금액과 changes passed를 확인했다. 전체 행 수·합계·취소 제외 집계·활성 중복 수는 공식 변경 SQL의 PASS 검사에 근거한다.

### 조건부 UPDATE에서 예상 이전 상태를 확인해야 하는 이유

id만 검사하면 이미 취소되거나 완료된 행을 의도와 다르게 바꿀 수 있다. `WHERE id = 1001 AND status = '수강중'`으로 예상 상태를 함께 검사하고 RETURNING과 최종 검증을 확인한다. 영향 행 수가 0이면 성공으로 넘기지 않고 시작 상태를 조사한다.

### 증거 화면

![신청 변경 후 상태·금액과 변경 검증 PASS](./images/step07_changes.png)
````

````markdown
## 8-1. 최종 검증 결과

| 검증 항목 | 기대값 | 실제 결과 |
| --- | --- | --- |
| 최종 students/instructors/courses/enrollments | 3/2/3/5 | 3/2/3/5 |
| 서비스 JOIN 결과 행 수 | 5 | 5 |
| 학생 101 신청 수 | 2 | 2 |
| 강의 301 신청 수 | 2 | 2 |
| 강사 201 강의 수 | 2 | 2 |
| 고아 관계 수 (학생/강의/강사) | 0/0/0 | 0/0/0 |
| 공백·허용값·금액 범위 오류 | 각 0 | 각 0 |
| 활성 중복 신청 수 | 0 | 0 |
| 전체 recorded_amount | 590000 | 590000 |
| 취소 제외 건수 / recorded_amount | 4 / 440000 | 4 / 440000 |
| 통과 메시지 | Chapter 07 course project validation passed | Chapter 07 course project validation passed |

2026-10-12 12:04 캡처에서 공식 Validation PASS와 전체 5건·590000, 취소 제외 4건·440000을 확인했다. 나머지 관계·무결성 수치는 공식 Validation의 PASS 검사에 근거한다. 이 캡처는 실패 테스트 전 최종 검증이다. 이후 Codex가 같은 공식 검증 DO 블록을 재실행하여 실패 테스트 후에도 PASS를 확인했다.

### SQL 파일 4개 실행과 프로젝트 검증 PASS가 다른 이유

파일 실행만으로 전체 문장이 성공했거나 올바른 DB에 반영됐다고 단정할 수 없다. Validation은 구조·관계·상태·금액을 기대값과 비교한다. 다만 이 PASS도 정해진 예제 기준을 만족한다는 뜻이며 제외 기능까지 구현됐다는 의미는 아니다.

### 증거 화면

![최종 Validation PASS와 전체·취소 제외 집계](./images/step08_validation.png)
````

````markdown
## 9-1. 허용되어야 하는 경계값 1개

무료 강의·무료 신청·선택 설명 NULL을 함께 확인한다. 임시 행은 롤백하여 기준 상태를 유지한다.

```sql
BEGIN;
INSERT INTO course_project.courses
    (id, instructor_id, title, description, level, price, opened_at)
VALUES (1801, 202, '무료 체험 강의', NULL, 'basic', 0, '2026-05-01');
INSERT INTO course_project.enrollments
    (id, student_id, course_id, enrolled_at, status, recorded_amount)
VALUES (1802, 103, 1801, '2026-05-02', '신청', 0);
SELECT c.price, c.description, e.recorded_amount
FROM course_project.courses c
JOIN course_project.enrollments e ON e.course_id = c.id
WHERE e.id = 1802;
ROLLBACK;
```

```text
기대 결과: INSERT 각각 1행 성공, SELECT 1행 (0 / NULL / 0)
실제 결과: SELECT 1행 (0 / NULL / 0) 성공. 이후 ROLLBACK과 조회로 임시 강의·신청 각각 0건 확인.
허용 이유: 무료는 확정된 0원이며 price·recorded_amount의 >= 0 경계값이다.
          description은 선택 열이므로 NULL을 허용한다.
```

## 9-2. 실패해야 하는 테스트 1 — 잘못된 참조

```sql
INSERT INTO course_project.enrollments
    (id, student_id, course_id, enrolled_at, status, recorded_amount)
VALUES (1908, 999, 303, '2026-05-02', '신청', 150000);
```

```text
기대 결과: 존재하지 않는 학생 999의 신청을 FK 오류로 거절
실제 오류 핵심: SQL Error [23503], violates foreign key constraint "fk_course_enrollments_student"
예상 단서: violates foreign key constraint "fk_course_enrollments_student"
동작할 규칙: fk_course_enrollments_student
실패 이유: 부모 학생이 없는 고아 신청을 저장하면 신청 주체를 추적할 수 없다.
```

## 9-3. 실패해야 하는 테스트 2 — 활성 중복 신청

```sql
INSERT INTO course_project.enrollments
    (id, student_id, course_id, enrolled_at, status, recorded_amount)
VALUES (1910, 101, 302, '2026-05-03', '수강중', 120000);
```

```text
기대 결과: 이미 신청 상태인 1002와 학생·강의 조합이 같아서 거절
실제 오류 핵심: SQL Error [23505], duplicate key value violates unique constraint "uq_course_enrollments_active"; Key (student_id, course_id)=(101, 302) already exists.
예상 단서: duplicate key value violates unique constraint "uq_course_enrollments_active"
동작할 규칙: uq_course_enrollments_active 부분 고유 인덱스
실패 이유: 신청·수강중 상태를 묶어 같은 조합의 활성 신청을 최대 한 건으로 제한한다.
```

## 9-4. 실패 후 기준 상태 재검증

```sql
SELECT COUNT(*) AS temporary_rows
FROM course_project.enrollments
WHERE id IN (1802, 1908, 1910);
SELECT COUNT(*) AS temporary_courses
FROM course_project.courses WHERE id = 1801;
```

```text
임시 행 조회: 임시 신청 0건, 임시 강의 0건
04 validation 재실행 결과: Chapter 07 course project validation passed
기준 데이터 유지 여부: 유지됨. 3/2/3/5행, 전체 5건·590000, 취소 제외 4건·440000
```

### 실패 테스트가 프로젝트 품질 검증에 필요한 이유

정상 입력의 성공만으로 잘못된 참조·활성 중복을 거절하는지 알 수 없다. 의도한 제약조건 때문에 실패했는지 확인해야 한다. PK 충돌 등 다른 오류가 발생하면 원하는 규칙을 검증한 것으로 보지 않는다.

### 증거 화면

![활성 중복 신청 INSERT와 부분 고유 인덱스 오류](./images/step09_integrity.png)

첫 번째 FK 오류는 12:08 화면에서 확인했고 대표 실패 캡처는 12:10의 활성 중복 오류를 첨부했다. 실패 후 Codex가 DBeaver의 Script-41에서 공식 04 SQL의 검증 DO 블록을 재실행하여 validation passed를 확인했다. 이어 임시 신청·강의 0건도 직접 조회했다. 전체 과제 캡처는 5·7·8·9절의 4장으로 정리한다.
````

````markdown
# 10. 재현성 실험

본인의 실습 DB에서 course_project에 보존할 데이터가 없음을 확인한 경우에만 수행한다. reset은 프로젝트 데이터를 삭제한다.

```text
reset_course_project.sql
→ 01_course_project_schema.sql
→ 02_course_project_seed.sql
→ 03_course_project_changes.sql
→ 04_course_project_validation.sql
```

```text
처음 실행의 최종 결과: 3/2/3/5행, 1001 완료·1004 취소·1005 신청,
                       전체 590000·취소 제외 440000, validation passed
재실행의 최종 결과: 초기화 후 재구성 실험은 수행하지 않음
두 결과 일치 여부: 비교하지 않음
중간 수동 수정 필요 여부: 재구성 실험을 하지 않아 해당 없음
주의: 실패 테스트 후 Validation 재실행 PASS는 확인했으나,
      reset → 생성 → Seed → 변경의 재현성 실험과는 구분한다.
```

### 같은 순서로 같은 결과를 얻는 것이 중요한 이유

수동 수정에 의존하면 다른 사람이 DB를 재구성하기 어렵다. 시작 상태, 실행 순서, Seed와 검증을 함께 제공하면 오류가 발생한 단계를 구분하고 동일 기준으로 개선 여부를 확인할 수 있다.
````

````markdown
# 17. LMS 제출 URL

push 후 아래 **작성 답안 파일 화면 URL**을 LMS에 제출한다. 현재 원격 반영과 LMS 제출은 확인하지 않았다.

```text
https://github.com/ssossocoder/ai-database-study/blob/main/assignments/chapter07/chapter07_answer.md
```
````
