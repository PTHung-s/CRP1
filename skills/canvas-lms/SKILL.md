---
name: canvas-lms
description: Download files from Canvas LMS and send them via Telegram using bash + curl.
---

# Canvas File Tools

Use OpenClaw's **bash** tool (`exec`) to run curl commands. All API calls go through native curl.

## Credentials

Loaded from env vars:
- `$CANVAS_T` — Canvas API token
- `$CANVAS_URL` — Canvas instance URL (https://vinuni.instructure.com)
- `$TELEGRAM_T` — Telegram bot token
- `$TELEGRAM_CHAT_ID` — target chat ID

## Command Reference

### 1. List files in a course

```bash
curl -s -H "Authorization: Bearer $CANVAS_T" "$CANVAS_URL/api/v1/courses/<course_id>/files?per_page=50"
```

Parse the JSON output to find `id` and `display_name` for each file.

### 2. Download a file from Canvas

First get the download URL:
```bash
url=$(curl -s -H "Authorization: Bearer $CANVAS_T" "$CANVAS_URL/api/v1/files/<file_id>" | node -e "process.stdin.on('data',d=>{const j=JSON.parse(d);process.stdout.write(j.url||'')})")
```

Then download:
```bash
curl -s -L -H "Authorization: Bearer $CANVAS_T" -o "downloads/<filename>" "$url"
```

Or download directly in one step:
```bash
curl -s -L -H "Authorization: Bearer $CANVAS_T" -o "downloads/<filename>" "$CANVAS_URL/api/v1/files/<file_id>/download"
```

### 3. Send a file to Telegram

```bash
curl -s -F "chat_id=$TELEGRAM_CHAT_ID" -F "document=@downloads/<filename>" -F "caption=<caption>" "https://api.telegram.org/bot$TELEGRAM_T/sendDocument"
```

### 4. Send a text message to Telegram

On Windows, curl.exe corrupts inline JSON. Use Invoke-RestMethod:
```powershell
$m='{"chat_id":'+$TELEGRAM_CHAT_ID+',"text":"message"}'; Invoke-RestMethod -Uri "https://api.telegram.org/bot$TELEGRAM_T/sendMessage" -Method Post -ContentType "application/json" -Body $m
```

Alternative via file (if JSON is complex):
```bash
echo '{"chat_id":8700188981,"text":"msg"}' > $env:TEMP\tg.txt
curl -s -d @$env:TEMP\tg.txt -H "Content-Type: application/json" "https://api.telegram.org/bot$TELEGRAM_T/sendMessage"
```

### 5. Download and send in one workflow

```bash
# Step 1: Download
curl -s -L -H "Authorization: Bearer $CANVAS_T" -o "downloads/<filename>" "$CANVAS_URL/api/v1/files/<file_id>/download"

# Step 2: Send
curl -s -F "chat_id=$TELEGRAM_CHAT_ID" -F "document=@downloads/<filename>" -F "caption=<caption>" "https://api.telegram.org/bot$TELEGRAM_T/sendDocument"
```

## Workflow

1. ALWAYS start by listing files: `curl -s -H "Authorization: Bearer $CANVAS_T" "$CANVAS_URL/api/v1/courses/<course_id>/files?per_page=50"`
2. Find the file_id from the JSON response
3. Download with the direct download URL
4. Send with sendDocument API
5. Always use `curl.exe` (not `Invoke-WebRequest`) for multipart uploads. Forward-slashes in file paths.

## Notes
- Canvas API returns JSON — parse `id` and `display_name` fields
- Telegram max file size: 50MB
- File downloads go to `downloads/` subdirectory
- Use `Invoke-RestMethod` (not `curl.exe -d`) for Telegram JSON API calls — curl.exe corrupts inline JSON on Windows
- Use `curl.exe -F` for file uploads (sendDocument) — multipart form-data works fine
- All API responses return JSON with `ok: true/false`
