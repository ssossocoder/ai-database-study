# Chapter 07 프로젝트 설계 결정 기록

## 프로젝트

온라인 강의 수강신청 데이터베이스

## 1. 포함 범위

```text
course_project.students
course_project.instructors
course_project.courses
course_project.enrollments
```

## 2. 제외 범위

| ID | 제외 기능 | 후속 검토 구조 |
| --- | --- | --- |
| P07-O01 | 실제 결제 승인·실패·환불 이력 | payments, payment_events, refunds |
| P07-O02 | 강의 정원·대기열 | capacity, waitlist, 동시 신청 제어 |
| P07-O03 | 상태 변경 전체 이력 | enrollment_status_history |
| P07-O04 | 강의 콘텐츠·진도·수료 | sections, lessons, progress |
| P07-O05 | 수강평·쿠폰·할인 이력 | reviews, coupons, promotions |

## 3. 핵심 요구사항

| ID | 요구사항 | 반영 구조 | 검증 |
| --- | --- | --- | --- |
| P07-R01 | 학생은 이름·이메일·가입일을 가진다 | students | 정상 입력·조회 |
| P07-R02 | 강사는 이름·이메일·전문 분야를 가진다 | instructors | 정상 입력·조회 |
| P07-R03 | 강의는 제목·선택 설명·난이도·기준 가격·개설일을 가진다 | courses | 정상·경계 입력 |
| P07-R04 | 강의는 정확히 한 강사를 참조한다 | courses.instructor_id FK | 없는 강사 실패 |
| P07-R05 | 신청은 학생·강의·신청일·상태·신청 시 기록 금액을 가진다 | enrollments | 최종 상태 조회 |
| P07-R06 | 상태는 신청·수강중·완료·취소 중 하나다 | 상태 CHECK | 잘못된 상태 실패 |
| P07-R07 | 학생·강사 이메일은 각 테이블에서 공백·동일 문자열 중복이 불가하다 | CHECK·UNIQUE | 공백·중복 실패 |
| P07-R08 | 강의 기준 가격과 신청 시 기록 금액은 음수일 수 없다 | NUMERIC·CHECK | 0 성공·음수 실패 |
| P07-R09 | 존재하는 학생·강사·강의만 참조한다 | FK·RESTRICT | 없는 부모·부모 삭제 실패 |

## 4. 프로젝트 결정

| ID | 결정 | 근거 | 구현·검증 |
| --- | --- | --- | --- |
| P07-D01 | 무료 금액은 0으로 표현하고 NULL·음수는 허용하지 않음 | 0은 확정 금액, NULL은 미확정값과 구분 | NOT NULL·CHECK·경계 테스트 |
| P07-D02 | 할인 기능이 없는 현재 범위에서는 신청 생성 시 courses.price를 recorded_amount에 복사·보존 | 현재 기준 가격과 신청 당시 기록값을 구분 | INSERT ... SELECT, NUMERIC(12,0), 과거 행 유지 |
| P07-D03 | 같은 학생·강의의 진행 중 신청은 최대 한 건 | 중복 신청 방지와 완료·취소 이력 보존 | 부분 고유 인덱스 |
| P07-D04 | 변경 SQL은 예상 이전 상태를 조건과 사전 검사에 포함 | 잘못된 상태 덮어쓰기와 부분 변경 방지 | 트랜잭션·상태 검사·자동 완료 검사 |
| P07-D05 | 학생과 강사는 별도 테이블 | 현재 속성과 업무 역할이 다름 | 두 부모 테이블 |
| P07-D06 | 참조 중 부모 삭제는 제한 | 과거 신청 관계 보호 | ON DELETE RESTRICT |

## 5. 금액 의미와 타입

```text
courses.price
→ 현재 강의 기준 가격

enrollments.recorded_amount
→ 신청 시점에 신청 행에 기록한 금액

payments·refunds
→ 실제 결제 승인·환불 거래, 현재 범위 제외
```

금액 타입:

```sql
NUMERIC(12, 0)
```

현재 프로젝트에는 할인·쿠폰이 없으므로 신규 신청 SQL은 해당 시점의 `courses.price`를 조회해 `recorded_amount`로 복사한다. 이후 강의 가격이 바뀌어도 과거 신청 행은 갱신하지 않는다. 이 복사 규칙은 교차 테이블 `CHECK`로 구현하지 않고 신청 생성 SQL과 검증으로 관리한다.

전체 기록 금액과 취소 제외 기록 금액은 회계 매출이나 환불 후 순수 금액이 아니다.

## 6. 미확정 질문

| ID | 질문 | 현재 처리 | 확정 시 검토 |
| --- | --- | --- | --- |
| P07-Q01 | 학생과 강사 사이에서도 이메일을 전역 고유하게 제한해야 하는가 | 테이블별 UNIQUE | 통합 users·roles 모델 |
| P07-Q02 | 탈퇴 시 개인정보와 신청 이력을 어떻게 보존·익명화하는가 | 부모 삭제 제한 | 소프트 삭제·익명화 |
| P07-Q03 | 상태 전이와 변경 이력을 어느 수준까지 DB에서 관리하는가 | 현재 상태와 조건부 UPDATE | 상태 이력·트리거·서비스 로직 |

## 7. 관계와 활성 신청 정책

```text
instructors 1 : 0..N courses
students    1 : 0..N enrollments
courses     1 : 0..N enrollments
```

```sql
CREATE UNIQUE INDEX uq_course_enrollments_active
ON course_project.enrollments (student_id, course_id)
WHERE status IN ('신청', '수강중');
```

완료·취소 이력 뒤에는 새 신청이 가능하지만 신청·수강중 상태의 중복 행은 차단한다.

## 8. 상태값과 상태 전이

```text
CHECK가 제한하는 상태값
→ 신청, 수강중, 완료, 취소

이번 프로젝트의 변경 흐름
→ 신청 → 수강중 또는 취소
→ 수강중 → 완료 또는 취소
→ 완료·취소 행은 유지하고 필요하면 새 신청 생성
```

완전한 상태 전이와 변경 이력은 P07-Q03으로 남긴다.

## 9. AI 제안 비교 기록

| AI 제안 | 요구사항 근거 | 문제·누락 | 사람의 최종 결정 |
| --- | --- | --- | --- |
| 학생·강사를 users로 통합 | 미확정 | 기본 범위를 복잡하게 함 | P07-D05에 따라 분리 |
| 모든 FK에 CASCADE | 근거 없음 | 과거 신청 이력 삭제 위험 | P07-D06 RESTRICT |
| 전체 이력에 UNIQUE(student_id, course_id) | P07-D03과 불일치 | 완료·취소 뒤 재신청까지 차단 | 활성 상태 부분 고유 인덱스 |
| recorded_amount 제거 | P07-R05와 불일치 | 신청 시 기록 금액 소실 | 유지 |
| 취소 시 recorded_amount를 0으로 변경 | 실제 환불 요구 없음 | 신청 기록과 결제·환불 의미 혼합 | 원래 값 유지 |

## 10. 실행 검증 기록

```text
실행 환경:
실행 날짜:
PostgreSQL 버전:
DBeaver 버전:
Auto-commit 상태:

01 schema 결과:
02 seed 결과:
03 changes 결과:
04 validation 결과:
05 core integrity tests 결과:
06 optional tests 결과:

최종 행 수:
students =
instructors =
courses =
enrollments =

활성 중복 신청 조회 결과:
전체 recorded_amount 합계:
취소 제외 recorded_amount 합계:
검증 통과 메시지:

남은 문제:
```

## 11. Chapter 08 인계 기준

```text
students 3행
instructors 2행
courses 3행
enrollments 5행
1001 완료 / recorded_amount 100000
1004 취소 / recorded_amount 150000
1005 신청 / recorded_amount 120000
활성 중복 신청 0건
전체 recorded_amount 590000
취소 제외 recorded_amount 440000
```

