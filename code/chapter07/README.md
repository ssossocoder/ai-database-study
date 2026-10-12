# Chapter 07 프로젝트 코드

## 실전 프로젝트 1: 온라인 강의 수강신청 DB 완성하기

이 폴더는 Chapter 07 프로젝트를 전용 PostgreSQL 스키마에서 단계별로 생성·변경·검증하는 파일을 관리합니다.

## 프로젝트 객체

```text
course_project.students
course_project.instructors
course_project.courses
course_project.enrollments
```

모든 SQL은 스키마 한정 이름을 사용하므로 `current_schema()`가 `course_project`일 필요는 없습니다.

## 파일 목록

| 파일 | 시작 상태 | 완료 상태 | 반복 실행 |
| --- | --- | --- | --- |
| `01_course_project_schema.sql` | course_project 없음 | 스키마·네 테이블·규칙·0행 | 한 번 |
| `02_course_project_seed.sql` | 네 테이블 비어 있음 | 기본 3/2/3/4행·관계 기준 | 한 번 |
| `03_course_project_changes.sql` | 기본 샘플 상태 | 최종 3/2/3/5행 | 한 번 |
| `04_course_project_validation.sql` | 최종 상태 | 구조·관계·데이터 자동 완료 검증 | 가능 |
| `05_course_project_integrity_tests.sql` | 최종 상태 | 핵심 경계·오류 테스트 | 한 구간씩 |
| `06_course_project_optional_tests.sql` | 최종 상태 | 선택 경계·공백 테스트 | 한 구간씩 |
| `reset_course_project.sql` | 어떤 프로젝트 상태 | 프로젝트 객체 원자적 삭제 | 필요할 때만 |
| `PROJECT_DECISIONS.md` | 프로젝트 진행 중 | 설계·검증 기록 | 계속 갱신 |
| `online_course_project.sql` | 최종 상태 | 보호된 읽기 전용 호환 확인 | 가능 |

## 최소 완료 경로

```text
01_course_project_schema.sql
→ 02_course_project_seed.sql
→ 03_course_project_changes.sql
→ 04_course_project_validation.sql
```

처음부터 다시 시작할 때:

```text
reset_course_project.sql
→ 01
→ 02
→ 03
→ 04
```

## 공통 안전 원칙

```text
1. ai_database_book 연결인지 확인한다.
2. 현재 사용자와 search_path를 확인한다.
3. 쓰기 가능한 연결인지 확인한다.
4. 파일의 시작 상태를 자동 검사한다.
5. 생성·입력·변경·초기화 작업은 트랜잭션으로 묶는다.
6. 오류 테스트는 하나의 구간만 실행한다.
7. 완료 후 04 검증 파일을 다시 실행한다.
8. 01에서 스키마를 생성한 역할과 같은 PostgreSQL 역할로 02~06·reset을 실행한다.
```

`01`, `02`, `03`은 시작 상태와 완료 상태를 자동으로 검사합니다. 중간 문장에서 오류가 발생하면 전체 작업이 `COMMIT`되지 않도록 구성합니다.

## 금액 열의 의미

```text
course_project.courses.price
→ 현재 강의 기준 가격

course_project.enrollments.recorded_amount
→ 신청 시점에 신청 행에 기록한 금액
```

두 열은 `NUMERIC(12,0)`을 사용합니다. 현재 범위에는 할인·쿠폰이 없으므로 신규 신청은 해당 시점의 `courses.price`를 조회해 `recorded_amount`로 복사합니다. 이 복사는 `CHECK`가 자동 수행하는 것이 아니라 신청 생성 SQL의 책임이며, 과거 행은 이후 가격 변경과 분리해 보존합니다. `recorded_amount`는 실제 결제 승인액이나 환불 후 순수 금액, 회계 매출이 아닙니다. 실제 결제·환불 이력은 현재 프로젝트 범위 밖입니다.

## 핵심 프로젝트 결정

| ID | 결정 | 구현 |
| --- | --- | --- |
| P07-D01 | 무료 금액은 0, NULL·음수 금지 | NOT NULL·CHECK |
| P07-D02 | 신청 생성 시 현재 가격 복사·보존 | INSERT ... SELECT → recorded_amount |
| P07-D03 | 진행 중 중복 신청 금지 | 부분 고유 인덱스 |
| P07-D04 | 예상 이전 상태 확인 | 사전 검사·조건부 UPDATE |
| P07-D05 | 학생·강사 별도 역할 | 별도 테이블 |
| P07-D06 | 참조 중 부모 삭제 제한 | RESTRICT |

```sql
CREATE UNIQUE INDEX uq_course_enrollments_active
ON course_project.enrollments (student_id, course_id)
WHERE status IN ('신청', '수강중');
```

## 상태별 자동 검증

### 01 구조 생성 완료

```text
현재 역할에 ai_database_book의 CREATE 권한 존재
course_project 존재
네 테이블 존재
명명 제약조건 15개
NOT NULL 열 20개
uq_course_enrollments_active 존재
네 테이블 모두 0행
```

통과 메시지:

```text
Chapter 07 course project schema creation passed
```

### 02 기본 샘플 완료

```text
students 3
instructors 2
courses 3
enrollments 4
recorded_amount 합계 470000
학생 101 신청 2
강의 301 신청 2
강사 201 강의 2
활성 중복 0
1001 수강중 / 1004 신청 / 1005 없음
```

통과 메시지:

```text
Chapter 07 course project seed passed
```

### 03 변경 완료

```text
students 3
instructors 2
courses 3
enrollments 5
1001 완료 / recorded_amount 100000
1004 취소 / recorded_amount 150000
1005 신청 / recorded_amount 120000
활성 중복 0
전체 recorded_amount 590000
취소 제외 4건 / recorded_amount 440000
```

통과 메시지:

```text
Chapter 07 course project changes passed
```

### 04 최종 완료 게이트

`04_course_project_validation.sql`은 다음을 함께 판정합니다.

```text
명명 제약조건 15개
NOT NULL 열 20개
최종 행 수 3/2/3/5
서비스 JOIN 5행
학생101 신청 2 / 강의301 신청 2 / 강사201 강의 2
고아 관계 0
공백·허용값·금액 범위 오류 0
활성 중복 신청 0
1001·1004·1005 상태와 기록 금액
전체 590000 / 취소 제외 440000
```

통과 메시지:

```text
Chapter 07 course project validation passed
```

## 핵심 테스트와 선택 테스트

`05_course_project_integrity_tests.sql`은 핵심 요구사항의 경계와 실패를 다룹니다.

```text
성공: price=0, recorded_amount=0, description=NULL
실패: 대표 NOT NULL 위반
실패: 학생·강사 이메일 중복
실패: 존재하지 않는 강사·학생·강의 참조
실패: 잘못된 난이도·신청 상태
실패: 음수 가격·recorded_amount
실패: 두 번째 활성 신청
실패: 참조 중인 학생·강사 삭제
```

기준 상태를 보존하면 다음 메시지가 출력됩니다.

```text
Chapter 07 core integrity test baseline preserved
```

`06_course_project_optional_tests.sql`은 허용 경계와 공백 문자열의 세부 규칙을 다룹니다.

```text
성공: description=NULL·한 글자 이름
성공: 완료 뒤 재신청
성공: 참조되지 않는 학생 삭제
실패: 학생 이름·이메일 공백
실패: 강사 이름·이메일·전문 분야 공백
실패: 강의 제목 공백
```

기준 상태를 보존하면 다음 메시지가 출력됩니다.

```text
Chapter 07 optional integrity test baseline preserved
```

## 초기화

`reset_course_project.sql`은 현재 DB와 읽기 전용 상태를 확인한 뒤 알려진 테이블을 자식→부모 순서로 삭제합니다. 전체 삭제를 명시적 트랜잭션으로 묶고 `DROP SCHEMA ... CASCADE`는 사용하지 않습니다.

예상하지 않은 객체가 `course_project` 안에 남아 있으면 `DROP SCHEMA`가 실패하며 앞서 삭제한 알려진 테이블도 함께 롤백됩니다.

통과 메시지:

```text
Chapter 07 course project reset passed
```

## Chapter 08 인계

Chapter 08의 JOIN·집계 실습 전에 `04_course_project_validation.sql`을 실행합니다. Chapter 08의 실행 전 게이트인 `code/chapter08/00_check_course_project.sql`도 같은 `recorded_amount`와 590000·340000·440000 기준을 사용합니다.

