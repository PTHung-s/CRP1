---
name: quiz
description: Generate interactive Telegram Quiz Polls from Canvas lecture PDFs using bash + curl + DeepSeek API.
---

# Quiz Skill

Use OpenClaw's **bash** tool (`exec`) with curl to call Canvas, DeepSeek, and Telegram APIs. No Python needed.

## Credentials

Loaded from env vars:
- `$CANVAS_T` — Canvas API token
- `$CANVAS_URL` — Canvas instance URL (https://vinuni.instructure.com)
- `$TELEGRAM_T` — Telegram bot token
- `$TELEGRAM_CHAT_ID` — target chat ID
- `$DEEPSEEK_T` — DeepSeek API key

## Full Workflow

### Step 1: Download the PDF from Canvas

```bash
curl -s -L -H "Authorization: Bearer $CANVAS_T" -o "downloads/<filename>" "$CANVAS_URL/api/v1/files/<file_id>/download"
```

### Step 2: Extract text from PDF

Use the `read` tool to read the downloaded PDF from the filesystem:
```
read("downloads/<filename>")
```
OpenClaw will extract readable text from the PDF. Use the returned text in the next step.

Alternative if PDF text is too long:
```bash
node -e "const fs=require('fs');fs.readFileSync('downloads/<filename>','utf8')"
```

### Step 3: Generate quiz questions with DeepSeek

Build a prompt and call DeepSeek API:

```bash
curl -s --max-time 90 -H "Authorization: Bearer $DEEPSEEK_T" -H "Content-Type: application/json" "https://api.deepseek.com/v1/chat/completions" -d '{"model":"deepseek-chat","messages":[{"role":"user","content":"Generate 5 multiple-choice quiz questions from this lecture. Return ONLY a JSON array (no markdown fences): [{\"question\":\"...\",\"options\":[\"Answer 1\",\"Answer 2\",\"Answer 3\",\"Answer 4\"],\"correct\":0,\"explanation\":\"...\"}]. Rules: correct is index 0-3 of the right answer. Options must NOT include letter prefixes (A) B) etc.). Distractors must be believable but clearly wrong to someone who studied. Questions test understanding, not recall. Explanation 1-2 sentences.\n\nLECTURE CONTENT:\n<TEXT_FROM_STEP_2>"}],"temperature":0.7}'
```

Parse the JSON response. The `choices[0].message.content` field contains the quiz JSON array.

### Step 4: Send quiz polls to Telegram

On Windows, curl.exe corrupts inline JSON — use Invoke-RestMethod:
```powershell
$p='{"chat_id":"'+$TELEGRAM_CHAT_ID+'","question":"Q","options":["A","B","C","D"],"type":"quiz","correct_option_id":0,"is_anonymous":false}'; Invoke-RestMethod -Uri "https://api.telegram.org/bot$TELEGRAM_T/sendPoll" -Method Post -ContentType "application/json" -Body $p
```

For batch polls, write each to a file then curl:
```bash
$q = '{"chat_id":"'+$TELEGRAM_CHAT_ID+'","question":"Q1","options":["A","B","C","D"],"type":"quiz","correct_option_id":0,"is_anonymous":false}'; $q | Out-File -Encoding ascii "$env:TEMP\p.json" -NoNewline; curl -s -d "@$env:TEMP\p.json" -H "Content-Type: application/json" "https://api.telegram.org/bot$TELEGRAM_T/sendPoll"
```

Repeat for each question. Wait 0.5s between sends:
```bash
Start-Sleep -Milliseconds 500
```

## Sending Options as JSON

For each option array entry, make sure:
- Options do NOT include letter prefixes (A) B) C) D))
- Options are plain text
- `correct_option_id` is 0-based index (0, 1, 2, or 3)

## Important

- Use `Invoke-RestMethod` (not `curl.exe`) for Telegram JSON API calls (sendMessage, sendPoll) — curl.exe corrupts inline JSON on Windows
- Use `curl.exe -F` for file uploads (sendDocument) — multipart form-data works fine
- Use `curl.exe -H "Authorization: Bearer"` for Canvas/DeepSeek API calls — those accept the JSON correctly
- Wait 0.5 seconds between poll sends to avoid rate limiting
- All API responses are JSON with `ok: true/false`
