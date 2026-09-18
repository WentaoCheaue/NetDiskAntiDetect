# 指定7z.exe的安装路径
$7zPath = "D:\Program Files\7-Zip\7z.exe"

if (-Not (Test-Path $7zPath)) {
    Write-Host "未找到7z.exe程序，请确认安装路径是否正确。"
    Pause
    exit
}

# 提示用户输入输出目录
$outputRootDir = Read-Host "请输入解压后的输出目录完整路径（删掉引号，否则会报错）"

if ([string]::IsNullOrWhiteSpace($outputRootDir)) {
    Write-Host "输出路径不能为空，脚本已终止。"
    Pause
    exit
}

# 获取当前脚本所在目录作为源目录
$sourceDir = $PSScriptRoot

# 获取当前目录及所有子文件夹中的 zip 文件
$files = Get-ChildItem -Path $sourceDir -Recurse -Filter "*.zip" -File

foreach ($file in $files) {
    # 计算当前文件所在目录相对于源目录的相对路径
    $regexPattern = "^" + [regex]::Escape($sourceDir)
    $relativePath = $file.DirectoryName -replace $regexPattern, ""
    $relativePath = $relativePath.TrimStart('\')
    
    # 拼接出对应的输出目录
    $targetDir = Join-Path -Path $outputRootDir -ChildPath $relativePath
    
    # 确保输出目录存在（虽然7z会自动创建，但在PowerShell中预先建好层级更稳妥）
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    }

    # 调用7z执行解压
    # 参数解析：
    # x: 提取文件（保持包内可能存在的路径）
    # -p123456: 输入密码
    # -o: 指定输出目录（注意 -o 和路径之间不能有空格）
    # -y: 对所有提示默认选"是"（如遇到同名文件自动覆盖）
    & $7zPath x "-p123456" "-o$targetDir" "-y" "$($file.FullName)"
}

Write-Host "全部文件解压完毕，已按原目录结构输出至: $outputRootDir"
Pause