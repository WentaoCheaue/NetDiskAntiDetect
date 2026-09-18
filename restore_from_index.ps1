# 获取当前脚本所在目录
$sourceDir = $PSScriptRoot
$indexDir = Join-Path $sourceDir "index"

# 检查 index 目录是否存在
if (-not (Test-Path $indexDir)) {
    Write-Host "未检测到 index 目录，无法执行还原操作！" -ForegroundColor Red
    Pause
    exit
}

Write-Host "第一步：正在还原文件夹名称..."
# 获取所有文件夹的映射文件，并按路径深度“升序”排序（自上而下，从最外层文件夹开始还原）
$folderMapFiles = Get-ChildItem -Path $indexDir -Recurse -Filter "_folder_new_name.txt" | 
    Sort-Object -Property @{Expression={($_.FullName -split '\\').Count}; Ascending=$true}

foreach ($mapFile in $folderMapFiles) {
    # 获取在 index 目录中的当前路径
    $indexDirPath = $mapFile.Directory.FullName
    
    # 计算相对路径，例如 "dir1" 或 "dir1\dir2"
    $relativeDirPath = $indexDirPath.Substring($indexDir.Length + 1)
    
    # 分离出当前的原始文件夹名（最末端名称）和它的父级路径
    $originalFolderName = Split-Path $relativeDirPath -Leaf
    $parentRelativePath = Split-Path $relativeDirPath -Parent
    
    # 定位该文件夹在源目录中"当前"所在的父级绝对路径
    if ([string]::IsNullOrEmpty($parentRelativePath)) {
        $currentParentPath = $sourceDir
    } else {
        $currentParentPath = Join-Path $sourceDir $parentRelativePath
    }
    
    # 从文本中读取它被改成了什么数字
    $numberedFolderName = (Get-Content $mapFile.FullName -TotalCount 1).Trim()
    
    # 拼装它现在的实际完整路径
    $currentFullPath = Join-Path $currentParentPath $numberedFolderName
    
    # 执行重命名还原
    if (Test-Path $currentFullPath) {
        Rename-Item -Path $currentFullPath -NewName $originalFolderName
    } else {
        Write-Host "警告: 找不到要还原的文件夹 $currentFullPath" -ForegroundColor Yellow
    }
}

Write-Host "第二步：正在还原文件名称..."
# 获取所有的文件映射（排除掉刚才用于记文件夹名字的 _folder_new_name.txt）
$fileMapFiles = Get-ChildItem -Path $indexDir -Recurse -File | 
    Where-Object { $_.Name -ne "_folder_new_name.txt" }

foreach ($mapFile in $fileMapFiles) {
    $indexDirPath = $mapFile.Directory.FullName
    
    # 区分根目录文件和子文件夹内的文件
    if ($indexDirPath -eq $indexDir) {
        $targetDir = $sourceDir
    } else {
        $relativeDirPath = $indexDirPath.Substring($indexDir.Length + 1)
        $targetDir = Join-Path $sourceDir $relativeDirPath
    }
    
    # 原始文件名就是映射文件的名字
    $originalFileName = $mapFile.Name
    # 数字文件名写在映射文件内部
    $numberedFileName = (Get-Content $mapFile.FullName -TotalCount 1).Trim()
    
    # 由于文件夹已经在第一步全还原了，现在直接去原始路径找数字文件即可
    $currentFullPath = Join-Path $targetDir $numberedFileName
    
    if (Test-Path $currentFullPath) {
        Rename-Item -Path $currentFullPath -NewName $originalFileName
    } else {
        Write-Host "警告: 找不到要还原的文件 $currentFullPath" -ForegroundColor Yellow
    }
}

Write-Host "第三步：清理映射数据..."
# 删除 index 目录及其所有内容
Remove-Item -Path $indexDir -Recurse -Force

Write-Host "还原完成！所有文件和文件夹已恢复原貌。" -ForegroundColor Green
Pause