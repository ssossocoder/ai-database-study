# Chapter 04 실행 안내

이 폴더는 Chapter 04 답안 초안과 실행용 SQL을 함께 둔다. LMS에는 아직 아무것도 제출하지 않는다.

## 실행 전 확인

1. DBeaver에서 `ai_database_book` 연결의 SQL Editor를 연다.
2. [`00_preflight.sql`](../../code/chapter04/00_preflight.sql)을 실행하여 현재 데이터베이스가 맞고 `public.students`가 없는지 확인한다.
3. `public.students`가 이미 있거나 행이 남아 있으면, 임의로 `DROP`/`TRUNCATE`하지 말고 현재 상태를 먼저 확인한다. 이 과제의 시작 상태가 아니면 새 실습 DB를 쓰거나, 본인이 만든 실습 테이블임을 확인한 뒤에만 직접 정리한다.
4. 비밀번호, 전체 접속 URL, API Key는 SQL 결과·캡처·답안에 넣지 않는다.

## 권장 실행 순서

| 순서 | 파일 또는 작업 | 실행 범위 | 기대 상태 |
| ---: | --- | --- | --- |
| 1 | [`00_preflight.sql`](../../code/chapter04/00_preflight.sql) | 전체 | 현재 DB와 기존 테이블 상태 확인 |
| 2 | [`01_create_students.sql`](../../code/chapter04/01_create_students.sql) | 전체, 한 번만 | 빈 `public.students` 생성 |
| 3 | [`02_insert_students.sql`](../../code/chapter04/02_insert_students.sql) | 전체, 한 번만 | 샘플 학생 6명 |
| 4 | [`03_select_students.sql`](../../code/chapter04/03_select_students.sql) | 블록별 | 각 SELECT 결과 기록 |
| 5 | 답안 5~7절의 SQL | **한 블록씩** | 가상 학생 추가·수정·삭제를 관찰 |
| 6 | [`04_update_delete_students.sql`](../../code/chapter04/04_update_delete_students.sql) | 블록별 | **초기 6명 상태에서만** 5명 최종 상태 |
| 7 | [`verify_students.sql`](../../code/chapter04/verify_students.sql) | 전체 | 최종 상태 검증 |
| 8 | [`05_safe_dml_exercises.sql`](../../code/chapter04/05_safe_dml_exercises.sql) | 필요한 블록만 | UPDATE·DELETE·제약조건 실패 관찰 |

`04_update_delete_students.sql`은 5~7절의 가상 학생 실습을 모두 끝낸 현재 상태에서 바로 실행하면 안 된다. 그 파일의 기대값(학생 5명)은 **01·02 실행 직후의 6명 기준 상태**를 전제로 한다.

## 답안에서 직접 해야 할 부분

- 실제 SQL 결과(현재 사용자, 스키마, 행 수, `RETURNING` 값)를 `chapter04_answer.md`의 `[직접 실행 후 기록]` 자리에 입력한다.
- DBeaver 화면을 지정된 `images/` 경로에 저장하고 Markdown 이미지 링크를 넣는다.
- 5절의 가상 학생 이름·이메일은 본인이 원하는 가상 값으로 바꿀 수 있다. 바꾼 경우 6~7절의 `WHERE email = ...`도 같은 값으로 바꾼다.
- 오류 메시지는 PostgreSQL/DBeaver가 실제로 표시한 핵심 문구를 적는다. 버전에 따라 전체 문장은 다를 수 있다.
- 13절 성찰은 자신의 실행 경험에 맞게 다시 쓴다.

## Git 사용 범위

이 작업은 로컬 Git 저장소에 파일만 추가한다. 원격 GitHub 푸시와 LMS 제출은 하지 않는다.
