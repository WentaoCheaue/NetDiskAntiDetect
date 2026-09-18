# 获取当前脚本所在目录
$sourceDir = $PSScriptRoot
$indexDir = Join-Path $sourceDir "index"

# 检查 index 目录是否存在，防止重复运行导致混乱
if (Test-Path -LiteralPath $indexDir) {
    Write-Host "检测到 index 文件夹已存在。为防止数据覆盖，请先将其删除或移走后再运行本脚本。" -ForegroundColor Yellow
    Pause
    exit
}

# 创建 index 目录
New-Item -ItemType Directory -Force -Path $indexDir | Out-Null

# 获取所有文件和文件夹（排除脚本自身和 index 目录）
# 这里改用 -LiteralPath 防止源路径中包含中括号报错
$allItems = Get-ChildItem -LiteralPath $sourceDir -Recurse | Where-Object {
    $_.FullName -ne $MyInvocation.MyCommand.Path -and
    $_.FullName -notmatch "^$([regex]::Escape($indexDir))"
}

# 分离文件和文件夹
$files = $allItems | Where-Object { -not $_.PSIsContainer }
$dirs = $allItems | Where-Object { $_.PSIsContainer } | Sort-Object -Property @{Expression={($_.FullName -split '\\').Count}; Descending=$true}

$fileCounter = 1
$dirCounter = 1

Write-Host "正在处理文件..."
foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($sourceDir.Length + 1)
    $newName = "${fileCounter}$($file.Extension)"
    
    $indexFilePath = Join-Path $indexDir $relativePath
    $indexFileDir = Split-Path $indexFilePath -Parent
    if (-not (Test-Path -LiteralPath $indexFileDir)) {
        New-Item -ItemType Directory -Force -Path $indexFileDir | Out-Null
    }
    
    New-Item -ItemType File -Force -Path $indexFilePath -Value $newName | Out-Null
    
    # 【关键修复】使用 -LiteralPath 替代 -Path
    Rename-Item -LiteralPath $file.FullName -NewName $newName
    $fileCounter++
}

Write-Host "正在处理文件夹..."
foreach ($dir in $dirs) {
    $relativePath = $dir.FullName.Substring($sourceDir.Length + 1)
    $newName = "$dirCounter"
    
    $indexDirPath = Join-Path $indexDir $relativePath
    if (-not (Test-Path -LiteralPath $indexDirPath)) {
        New-Item -ItemType Directory -Force -Path $indexDirPath | Out-Null
    }
    
    $dirMapFile = Join-Path $indexDirPath "_folder_new_name.txt"
    New-Item -ItemType File -Force -Path $dirMapFile -Value $newName | Out-Null

    # 【关键修复】使用 -LiteralPath 替代 -Path
    Rename-Item -LiteralPath $dir.FullName -NewName $newName
    $dirCounter++
}

Write-Host "重命名完成！已在 index 目录中生成原始结构及映射关系。" -ForegroundColor Green
Pause