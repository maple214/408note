# 408 笔记 · 每日同步到 GitHub
# 计划任务: 408note-daily-sync（每天 23:50）
# 行为: 有变更才提交并推送；无变更直接退出；暂存区疑似含密钥则中止

$repo = 'C:\Users\35043\考研笔记'
$log  = Join-Path $repo '.sync.log'
Set-Location -LiteralPath $repo

function Log([string]$m) {
  "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $m" | Add-Content -LiteralPath $log -Encoding UTF8
}

# 无人值守：SSH 绝不等待交互输入
$env:GIT_SSH_COMMAND = 'ssh -o BatchMode=yes -o ConnectTimeout=20'

git add -A
$changed = git status --porcelain
if (-not $changed) { Log '无变更，跳过'; exit 0 }
$count = @($changed).Count

# 秘密守卫：暂存区出现常见密钥特征就中止
$staged = git diff --cached --unified=0
if ($staged -match 'gh[pousr]_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|BEGIN [A-Z ]*PRIVATE KEY|appSecret') {
  Log "中止：暂存区疑似含密钥（$count 个变更），请人工检查后再提交"
  exit 2
}

git commit -q -m "sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm')  ($count files)"
if ($LASTEXITCODE -ne 0) { Log 'git commit 失败'; exit 1 }

git pull --rebase --autostash --quiet origin main
if ($LASTEXITCODE -ne 0) { Log 'git pull --rebase 失败（可能有冲突，需人工处理）'; exit 1 }

git push --quiet origin main
if ($LASTEXITCODE -ne 0) { Log 'git push 失败（检查网络或凭据）'; exit 1 }

Log "已推送：$count 个变更"
exit 0