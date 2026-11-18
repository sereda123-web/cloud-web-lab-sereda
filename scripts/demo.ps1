# Демонстраційні запити для скріншотів звіту (Windows PowerShell).
# Використання:  .\scripts\demo.ps1 [-BaseUrl https://ВАШ-СЕРВІС.onrender.com]
# Токен береться зі змінної ADMIN_TOKEN або з файлу .env і НІКОЛИ не друкується.
param([string]$BaseUrl = "http://localhost:5000")

chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$token = $env:ADMIN_TOKEN
if (-not $token -and (Test-Path ".env")) {
    $line = Select-String -Path ".env" -Pattern '^ADMIN_TOKEN=' | Select-Object -First 1
    if ($line) { $token = ($line.Line -replace '^ADMIN_TOKEN=', '').Trim().Trim('"').Trim("'") }
}
if (-not $token) { Write-Host "ADMIN_TOKEN не знайдено (ні у змінній середовища, ні у .env)" -ForegroundColor Red; exit 1 }

function Step($title, $shown) {
    Write-Host ""
    Write-Host "### $title" -ForegroundColor Cyan
    Write-Host "> $shown" -ForegroundColor DarkGray
}
function Call([string[]]$CurlArgs) {
    & curl.exe -sS -w "`nHTTP %{http_code}`n" @CurlArgs
}

Step "1. Публічна сторінка" "curl $BaseUrl/"
Call @("$BaseUrl/")

Step "2. Health check" "curl $BaseUrl/health"
Call @("$BaseUrl/health")

Step "3. Публічне читання записів" "curl $BaseUrl/api/records"
Call @("$BaseUrl/api/records")

Step "4. Захищений endpoint БЕЗ токена (очікується 401)" "curl $BaseUrl/api/admin/stats"
Call @("$BaseUrl/api/admin/stats")

Step "5. Захищений endpoint з НЕПРАВИЛЬНИМ токеном (очікується 401)" "curl -H 'Authorization: Bearer wrong' $BaseUrl/api/admin/stats"
Call @("-H", "Authorization: Bearer wrong", "$BaseUrl/api/admin/stats")

Step "6. Захищений endpoint з токеном (очікується 200)" "curl -H 'Authorization: Bearer ****' $BaseUrl/api/admin/stats"
Call @("-H", "Authorization: Bearer $token", "$BaseUrl/api/admin/stats")

# JSON передаємо через тимчасовий файл (UTF-8 без BOM), щоб уникнути проблем з лапками в PowerShell
$json = '{"student_name":"Мельник Іван","subject":"Cloud test","status":"present"}'
$tmp = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tmp, $json, (New-Object System.Text.UTF8Encoding($false)))

Step "7. Створення запису з токеном (очікується 201)" "curl -X POST -H 'Content-Type: application/json' -H 'Authorization: Bearer ****' -d '{...}' $BaseUrl/api/records"
Call @("-X", "POST", "-H", "Content-Type: application/json; charset=utf-8", "-H", "Authorization: Bearer $token", "--data-binary", "@$tmp", "$BaseUrl/api/records")
Remove-Item $tmp -ErrorAction SilentlyContinue

Step "8. Перевірка: новий запис у списку" "curl $BaseUrl/api/records"
Call @("$BaseUrl/api/records")
