#!/usr/bin/env bash
# Демонстраційні запити для скріншотів звіту (Linux/macOS/Git Bash).
# Використання:  bash scripts/demo.sh [BASE_URL]
# Токен береться зі змінної ADMIN_TOKEN або з файлу .env і НІКОЛИ не друкується.

BASE="${1:-http://localhost:5000}"

if [ -z "$ADMIN_TOKEN" ] && [ -f .env ]; then
  ADMIN_TOKEN=$(grep -E '^ADMIN_TOKEN=' .env | head -1 | cut -d= -f2- | tr -d '"\r')
fi
if [ -z "$ADMIN_TOKEN" ]; then
  echo "ADMIN_TOKEN не знайдено (ні у змінній середовища, ні у .env)"; exit 1
fi

step() { printf '\n### %s\n$ %s\n' "$1" "$2"; }
call() { curl -sS -w '\nHTTP %{http_code}\n' "$@"; }

step "1. Публічна сторінка" "curl $BASE/"
call "$BASE/"

step "2. Health check" "curl $BASE/health"
call "$BASE/health"

step "3. Публічне читання записів" "curl $BASE/api/records"
call "$BASE/api/records"

step "4. Захищений endpoint БЕЗ токена (очікується 401)" "curl $BASE/api/admin/stats"
call "$BASE/api/admin/stats"

step "5. Захищений endpoint з НЕПРАВИЛЬНИМ токеном (очікується 401)" \
     "curl -H 'Authorization: Bearer wrong' $BASE/api/admin/stats"
call -H "Authorization: Bearer wrong" "$BASE/api/admin/stats"

step "6. Захищений endpoint з токеном (очікується 200)" \
     "curl -H 'Authorization: Bearer ****' $BASE/api/admin/stats"
call -H "Authorization: Bearer $ADMIN_TOKEN" "$BASE/api/admin/stats"

step "7. Створення запису з токеном (очікується 201)" \
     "curl -X POST -H 'Content-Type: application/json' -H 'Authorization: Bearer ****' -d '{...}' $BASE/api/records"
call -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $ADMIN_TOKEN" \
     -d '{"student_name":"Мельник Іван","subject":"Cloud test","status":"present"}' "$BASE/api/records"

step "8. Перевірка: новий запис у списку" "curl $BASE/api/records"
call "$BASE/api/records"
