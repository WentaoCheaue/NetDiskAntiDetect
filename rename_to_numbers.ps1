# 获取当前脚本所在目录
$sourceDir = $PSScriptRoot
$indexDir = Join-Path $sourceDir "index"

# 检查 index 目录是否存在，防止重复运行导致混乱
if (Test-Path $indexDir) {
    Write-Host "检测到 index 文件夹已存在。为防止数据覆盖，请先将其删除或移走后再运行本脚本。" -ForegroundColor Yellow
    Pause
    exit
}

# 创建 index 目录
New-Item -ItemType Directory -Force -Path $indexDir | Out-Null

# 获取所有文件和文件夹（排除脚本自身和 index 目录）
$allItems = Get-ChildItem -Path $sourceDir -Recurse | Where-Object {
    $_.FullName -ne $MyInvocation.MyCommand.Path -and
    $_.FullName -notmatch "^$([regex]::Escape($indexDir))"
}

# 分离文件和文件夹
$files = $allItems | Where-Object { -not $_.PSIsContainer }
# 文件夹必须按“深度”降序排序（从最深层的子文件夹开始处理）
# 这是为了防止先把父文件夹改名后，导致深层文件的路径找不到而报错
$dirs = $allItems | Where-Object { $_.PSIsContainer } | Sort-Object -Property @{Expression={($_.FullName -split '\\').Count}; Descending=$true}

$fileCounter = 1
$dirCounter = 1

Write-Host "正在处理文件..."
# 1. 优先处理所有文件
foreach ($file in $files) {
    # 计算相对路径
    $relativePath = $file.FullName.Substring($sourceDir.Length + 1)
    
    # 组装新文件名 (数字 + 原扩展名)
    $newName = "${fileCounter}$($file.Extension)"
    
    # 在 index 中创建对应的目录结构
    $indexFilePath = Join-Path $indexDir $relativePath
    $indexFileDir = Split-Path $indexFilePath -Parent
    if (-not (Test-Path $indexFileDir)) {
        New-Item -ItemType Directory -Force -Path $indexFileDir | Out-Null
    }
    
    # 在 index 中生成原名文件，并将“新名字”作为文本内容写进去，方便以后对应
    New-Item -ItemType File -Force -Path $indexFilePath -Value $newName | Out-Null
    
    # 将原文件重命名为数字
    Rename-Item -Path $file.FullName -NewName $newName
    $fileCounter++
}

Write-Host "正在处理文件夹..."
# 2. 然后处理文件夹（从最底层往上）
foreach ($dir in $dirs) {
    $relativePath = $dir.FullName.Substring($sourceDir.Length + 1)
    $newName = "$dirCounter"
    
    # 在 index 中补全可能存在的空文件夹
    $indexDirPath = Join-Path $indexDir $relativePath
    if (-not (Test-Path $indexDirPath)) {
        New-Item -ItemType Directory -Force -Path $indexDirPath | Out-Null
    }
    
    # 可选：在 index 的该目录下生成一个隐藏说明文件，记录这个文件夹被改成了什么数字
    $dirMapFile = Join-Path $indexDirPath "_folder_new_name.txt"
    New-Item -ItemType File -Force -Path $dirMapFile -Value $newName | Out-Null

    # 将原文件夹重命名为数字
    Rename-Item -Path $dir.FullName -NewName $newName
    $dirCounter++
}

Write-Host "重命名完成！已在 index 目录中生成原始结构及映射关系。" -ForegroundColor Green
Pause