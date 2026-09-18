# 指定7z.exe的安装路径
$7zPath = "D:\Program Files\7-Zip\7z.exe"

if (-Not (Test-Path $7zPath)) {
    Write-Host "未找到7z.exe程序，请确认安装路径是否正确。"
    Pause
    exit
}

# 提示用户输入输出目录
$outputRootDir = Read-Host "请输入输出目录的完整路径（删掉引号，否则会报错）"

if ([string]::IsNullOrWhiteSpace($outputRootDir)) {
    Write-Host "输出路径不能为空，脚本已终止。"
    Pause
    exit
}

# 获取当前脚本所在目录作为源目录
$sourceDir = $PSScriptRoot

# 获取当前目录及所有子文件夹中的文件，并排除脚本文件自身
$files = Get-ChildItem -Path $sourceDir -Recurse -File | Where-Object { $_.FullName -ne $MyInvocation.MyCommand.Path }

foreach ($file in $files) {
    # 计算当前文件所在目录相对于源目录的相对路径
    $regexPattern = "^" + [regex]::Escape($sourceDir)
    $relativePath = $file.DirectoryName -replace $regexPattern, ""
    $relativePath = $relativePath.TrimStart('\')
    
    # 拼接并检查输出目录树结构，若不存在则逐层创建
    $targetDir = Join-Path -Path $outputRootDir -ChildPath $relativePath
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    }

    # 定义目标压缩包的文件名及完整路径
    $zipName = "$($file.BaseName).zip"
    $targetPath = Join-Path -Path $targetDir -ChildPath $zipName

    # 调用7z执行压缩：格式ZIP，仅存储(mx0)，密码123456
    & $7zPath a -tzip -mx0 -p123456 "$targetPath" "$($file.FullName)"
}

Write-Host "全部文件处理完毕，已按原目录结构输出至: $outputRootDir"
Pause