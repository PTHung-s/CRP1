Terminal session. bash(exec) only. Text discarded. Vars: CANVAS_T CANVAS_URL TELEGRAM_T TELEGRAM_CHAT_ID DEEPSEEK_T.

# Canvas
curl -s -H "Authorization: Bearer $CANVAS_T" "$CANVAS_URL/api/v1/courses?per_page=50"
curl -s -H "Authorization: Bearer $CANVAS_T" "$CANVAS_URL/api/v1/courses/ID/files?per_page=50"
curl -s -L -H "Authorization: Bearer $CANVAS_T" -o "downloads/FILE" "$CANVAS_URL/api/v1/files/ID/download"

# Telegram send text (curl.exe CORRUPTS JSON on Windows -- use Invoke-RestMethod)
$m='{"chat_id":'+$TELEGRAM_CHAT_ID+',"text":"MSG"}'; Invoke-RestMethod -Uri "https://api.telegram.org/bot$TELEGRAM_T/sendMessage" -Method Post -ContentType "application/json" -Body $m

# Telegram send file (curl -F form-data works fine)
curl -s -F "chat_id=$TELEGRAM_CHAT_ID" -F "document=@downloads/FILE" "https://api.telegram.org/bot$TELEGRAM_T/sendDocument"

# Telegram sendPoll
$p='{"chat_id":"'+$TELEGRAM_CHAT_ID+'","question":"Q","options":["A","B","C","D"],"type":"quiz","correct_option_id":0,"is_anonymous":false}'; Invoke-RestMethod -Uri "https://api.telegram.org/bot$TELEGRAM_T/sendPoll" -Method Post -ContentType "application/json" -Body $p

# DeepSeek
curl -s --max-time 90 -H "Authorization: Bearer $DEEPSEEK_T" -H "Content-Type: application/json" "https://api.deepseek.com/v1/chat/completions" -d "{\"model\":\"deepseek-chat\",\"messages\":[{\"role\":\"user\",\"content\":\"PROMPT\"}],\"temperature\":0.7}"

# Quiz flow: download PDF -> read file -> DeepSeek -> parse JSON -> sendPoll for each
$ 