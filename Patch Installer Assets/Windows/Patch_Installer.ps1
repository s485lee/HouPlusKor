# Set the base path relative to the script's location
$patchPath = $PSScriptRoot
$source = "$patchPath\Data\HigurashiEp10_Data\"  # Source path where patch data is located
$gridImagesSource = "$patchPath\Steamgrid\"  # Source path for grid images

# Ask the user to confirm if they want to install the patch
Write-Host "Windows용 쓰르라미 울 적에 봉+ 한글패치 인스톨러"
Write-Host ""
Write-Host "인스톨러 제작자: Montmorency (https://github.com/s485lee)"
Write-Host ""
Write-Host "인스톨러 제작에 도움을 주신 분: Côte-Vertu"
Write-Host ""
Write-Host "Windows용 쓰르라미 울 적에 봉+ 한글패치는 Steam판을 지원합니다."
Write-Host ""
Write-Host "GOG판이나 MangaGamer판이 설치된 경우, 인스톨러가 게임 파일을 자동으로 찾을 수 없습니다. 수동 설치 방법을 참고하세요."
Write-Host ""
Write-Host "주의: GOG판이나 MangaGamer판은 Compatibility Pack이 필요할 수 있습니다. 자세한 내용은 07th-Mod 위키를 참고하세요."
Write-Host ""
Write-Host "인스톨러는 자동으로 Steamgrid 이미지를 새로운 배경, 스탠딩 CG와 한글 로고로 교체합니다."
Write-Host ""
Write-Host "한글패치를 설치하려면 y 키를. 취소하려면 n 키를 눌러 주세요. (y/n)"
$userConfirm = Read-Host "선택"

if ($userConfirm -eq "y") {
    # Automatically find the Steam installation path
    $steamPath = Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -Name 'SteamPath' | Select-Object -ExpandProperty SteamPath
    $gamePath = Join-Path $steamPath 'steamapps\common\Higurashi When They Cry Hou+'
    $destination = "$gamePath\HigurashiEp10_Data"  # Correct destination path

    # Verify if the game directory exists
    if (Test-Path "$gamePath\HigurashiEp10.exe") {
        # Copy game data files
        $files = Get-ChildItem -Path $source -Recurse
        $fileCount = $files.Count
        $current = 0
        foreach ($file in $files) {
            $current++
            $percentComplete = ($current / $fileCount) * 100
            $progress = "`r한글패치 설치 중... [$current/$fileCount] {0:N0}%" -f $percentComplete
            Write-Host $progress -NoNewline
            Copy-Item -Path $file.FullName -Destination $destination -Force
        }
        Write-Host "`n한글패치가 성공적으로 설치되었습니다."

        # Handle Steam grid images
        $userDataDir = Join-Path $steamPath 'userdata'
        if (Test-Path $gridImagesSource) {
            $images = Get-ChildItem -Path $gridImagesSource -Recurse
            $imageCount = $images.Count
            $current = 0
            foreach ($image in $images) {
                $current++
                $percentComplete = ($current / $imageCount) * 100
                $progress = "`rSteamgrid 이미지 설치 중... [$current/$imageCount] {0:N0}%" -f $percentComplete
                Write-Host $progress -NoNewline
                $gridDestination = Join-Path $userDataDir 'config\grid'
                if (-Not (Test-Path $gridDestination)) {
                    New-Item -Path $gridDestination -ItemType Directory
                }
                Copy-Item -Path $image.FullName -Destination $gridDestination -Force
            }
            Write-Host "`nSteamgrid 이미지가 성공적으로 설치되었습니다."
        }
        # Completion message after successful installation
        Write-Host "하우~☆! 오모치카에리~!"
        Write-Host "한글패치가 성공적으로 적용되었습니다. 게임을 Steam에서 실행해 주세요. 니파~☆"
    } else {
        Write-Host "Error: 패치 인스톨러가 자동으로 게임 파일을 찾을 수 없습니다. Steam에서 게임이 설치되었는지 확인 후 인스톨러를 다시 실행해 주세요."
    }
} else {
    Write-Host "작업이 취소되었습니다."
}

# Wait for user action to close the script
Read-Host "Enter 키를 눌러 패치 인스톨러를 종료할 까나, 까나...?"