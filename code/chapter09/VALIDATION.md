# Chapter 09 자동 검증 범위

`.github/workflows/validate-chapter09.yml`은 Chapter 09의 정적 정합성과 PostgreSQL 16 실제 실행을 함께 검증합니다.

```text
Chapter 07·08 기준 상태
→ transaction_lab 생성·seed
→ 첫 COMMIT
→ 임시 변경 ROLLBACK과 원상복구
→ 두 번째 COMMIT
→ 좌석 부족 0행 처리
→ 최종 정합성 판정
→ 취소·좌석 복구 ROLLBACK
→ SAVEPOINT 오류 복구
→ 두 세션 Lock timeout 복구
→ transaction_lab reset
→ course_project 불변 재검증
```

문서·발표자료는 `recorded_amount`, 이론 20장·실습 20장, 자산 버전 `20260809a`, 공통 TTS와 스크립트 동기화 구조를 함께 검사합니다.
