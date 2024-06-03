# Set the base path relative to the script's location
$patchPath = $PSScriptRoot
$source = "$patchPath\Data\HigurashiEp10_Data\"  # Source path where patch data is located
$gridImagesSource = "$patchPath\Steamgrid\"  # Source path for grid images

function Get-SteamInstallPath {
    $registryPath = "HKCU:\Software\Valve\Steam"

    if (Test-Path $registryPath) {
        $installPath = Get-ItemProperty -Path $registryPath -Name "SteamPath" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty "SteamPath" -ErrorAction SilentlyContinue
        if ($installPath) {
            return $installPath
        }
    }
    return $null
}

$steamInstallPath = Get-SteamInstallPath

if ($steamInstallPath) {
    Write-Output "Steam이 다음과 같은 경로에서 발견: $steamInstallPath"

    # Define the path to the libraryfolders.vdf file
    $libraryFoldersPath = Join-Path -Path $steamInstallPath -ChildPath "config\libraryfolders.vdf"

    # Check if the libraryfolders.vdf file exists
    if (Test-Path $libraryFoldersPath) {
        # Read the contents of the libraryfolders.vdf file
        $libraryFoldersContent = Get-Content -Path $libraryFoldersPath -Raw

        # Extract the paths from the libraryfolders.vdf file
        $libraryFolders = [regex]::Matches($libraryFoldersContent, '"path"\s+"([^"]+)"') | ForEach-Object {
            $_.Groups[1].Value
        }

        # Initialize a variable to store the game path
        $gamePath = $null

        # App ID for HouPlus
        $appId = "2491040"

        # Iterate over each library folder and check for the game
        foreach ($folder in $libraryFolders) {
            $appsPath = Join-Path -Path $folder -ChildPath "steamapps\appmanifest_$appId.acf"
            if (Test-Path $appsPath) {
                $gameInstallFolderPath = (Get-Content -Path $appsPath | Select-String -Pattern '"installdir"\s+"([^"]+)"').Matches.Groups[1].Value
                $gamePath = Join-Path -Path $folder -ChildPath "steamapps\common\$gameInstallFolderPath"
                break
            }
        }

        # Check if the game path was found
        if ($gamePath) {
            Write-Host ""
            Write-Output "게임이 다음과 같은 경로에 설치됨: $gamePath"
            Write-Host ""
        } else {
            Write-Host ""
            Write-Output "경고: 게임 파일을 찾을 수 없습니다."
            Read-Host "Enter 키를 눌러 패치 인스톨러를 종료할 까나, 까나...?"
            exit
        }
    } else {
        Write-Output "libraryfolders.vdf 파일을 찾을 수 없음."
        Read-Host "Enter 키를 눌러 패치 인스톨러를 종료할 까나, 까나...?"
        exit
    }
} else {
    Write-Output "Steam 발견 실패."
    Read-Host "Enter 키를 눌러 패치 인스톨러를 종료할 까나, 까나...?"
    exit
}

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
    $destination = "$gamePath\HigurashiEp10_Data"  # Correct destination path

    Write-Host "한글패치 설치 경로: $destination"
    
    # Verify if the game directory exists
    if (Test-Path "$gamePath\HigurashiEp10.exe") {
        Write-Host "게임 파일 설치 확인 완료. 한글패치 설치 시작..."
        
        # Copy game data files
        $files = Get-ChildItem -Path $source -Recurse
        $fileCount = $files.Count
        $current = 0
        foreach ($file in $files) {
            $current++
            $percentComplete = ($current / $fileCount) * 100
            $progress = "`r한글패치 설치 중... [$current/$fileCount] {0:N0}%" -f $percentComplete
            Write-Host $progress -NoNewline
            $targetPath = Join-Path $destination $file.FullName.Substring($source.Length)
            if ($file.PSIsContainer) {
                if (-Not (Test-Path $targetPath)) {
                    New-Item -Path $targetPath -ItemType Directory
                }
            } else {
                if (-Not (Test-Path (Split-Path -Path $targetPath -Parent))) {
                    New-Item -Path (Split-Path -Path $targetPath -Parent) -ItemType Directory
                }
                Copy-Item -Path $file.FullName -Destination $targetPath -Force
            }
        }
        Write-Host "`n한글패치가 성공적으로 설치되었습니다."

        # Handle Steamgrid images
        $userDataDir = Join-Path $steamPath 'userdata'
        Write-Host "Steamgrid 이미지 설치 시작..."
        Write-Host "한글패치 설치 경로: $userDataDir"
        if (Test-Path $gridImagesSource) {
            $images = Get-ChildItem -Path $gridImagesSource -Recurse
            $imageCount = $images.Count
            $current = 0
            foreach ($image in $images) {
                $current++
                $percentComplete = ($current / $imageCount) * 100
                $progress = "`rSteamgrid 이미지 설치 중... [$current/$imageCount] {0:N0}%" -f $percentComplete
                Write-Host $progress -NoNewline
                foreach ($userDir in Get-ChildItem -Path $userDataDir -Directory) {
                    $gridDestination = Join-Path $userDir.FullName 'config\grid'
                    if (-Not (Test-Path $gridDestination)) {
                        New-Item -Path $gridDestination -ItemType Directory
                    }
                    $targetGridPath = Join-Path $gridDestination $image.Name
                    Copy-Item -Path $image.FullName -Destination $targetGridPath -Force
                }
            }
            Write-Host "`nSteamgrid 이미지가 다음과 같은 경로에 성공적으로 설치되었습니다: $userDataDir\*\config\grid"
        } else {
            Write-Host "Error: Steamgrid 이미지를 찾을 수 없습니다. $gridImagesSource"
        }

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