# 获取当前脚本所在目录
$sourceDir = $PSScriptRoot
$indexDir = Join-Path $sourceDir "index"

# 检查 index 目录是否存在
if (-not (Test-Path -LiteralPath $indexDir)) {
    Write-Host "未检测到 index 目录，无法执行还原操作！" -ForegroundColor Red
    Pause
    exit
}

Write-Host "第一步：正在还原文件夹名称..."
$folderMapFiles = Get-ChildItem -LiteralPath $indexDir -Recurse -Filter "_folder_new_name.txt" | 
    Sort-Object -Property @{Expression={($_.FullName -split '\\').Count}; Ascending=$true}

foreach ($mapFile in $folderMapFiles) {
    $indexDirPath = $mapFile.Directory.FullName
    $relativeDirPath = $indexDirPath.Substring($indexDir.Length + 1)
    $originalFolderName = Split-Path $relativeDirPath -Leaf
    $parentRelativePath = Split-Path $relativeDirPath -Parent
    
    if ([string]::IsNullOrEmpty($parentRelativePath)) {
        $currentParentPath = $sourceDir
    } else {
        $currentParentPath = Join-Path $sourceDir $parentRelativePath
    }
    
    $numberedFolderName = (Get-Content -LiteralPath $mapFile.FullName -TotalCount 1).Trim()
    $currentFullPath = Join-Path $currentParentPath $numberedFolderName
    
    # 【关键修复】
    if (Test-Path -LiteralPath $currentFullPath) {
        Rename-Item -LiteralPath $currentFullPath -NewName $originalFolderName
    } else {
        Write-Host "警告: 找不到要还原的文件夹 $currentFullPath" -ForegroundColor Yellow
    }
}

Write-Host "第二步：正在还原文件名称..."
$fileMapFiles = Get-ChildItem -LiteralPath $indexDir -Recurse -File | 
    Where-Object { $_.Name -ne "_folder_new_name.txt" }

foreach ($mapFile in $fileMapFiles) {
    $indexDirPath = $mapFile.Directory.FullName
    
    if ($indexDirPath -eq $indexDir) {
        $targetDir = $sourceDir
    } else {
        $relativeDirPath = $indexDirPath.Substring($indexDir.Length + 1)
        $targetDir = Join-Path $sourceDir $relativeDirPath
    }
    
    $originalFileName = $mapFile.Name
    $numberedFileName = (Get-Content -LiteralPath $mapFile.FullName -TotalCount 1).Trim()
    $currentFullPath = Join-Path $targetDir $numberedFileName
    
    # 【关键修复】
    if (Test-Path -LiteralPath $currentFullPath) {
        Rename-Item -LiteralPath $currentFullPath -NewName $originalFileName
    } else {
        Write-Host "警告: 找不到要还原的文件 $currentFullPath" -ForegroundColor Yellow
    }
}

Write-Host "第三步：清理映射数据..."
# 【关键修复】删除时也使用 -LiteralPath
Remove-Item -LiteralPath $indexDir -Recurse -Force

Write-Host "还原完成！所有文件和文件夹已恢复原貌。" -ForegroundColor Green
Pause