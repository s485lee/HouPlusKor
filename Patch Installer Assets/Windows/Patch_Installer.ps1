# --- Color Functions ---
function Write-Color {
    param(
        [string]$Message,
        [ConsoleColor]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Print-Header {
    param([string]$chapterName)
    Clear-Host
    Write-Color "================================================================" Green
    Write-Color " Windows용 쓰르라미 울 적에 한글패치 인스톨러: $chapterName" Green
    Write-Color "================================================================" Green
}

function Section-Header {
    param([string]$Title)
    Write-Host ""
    Write-Color "===[ $Title ]===" Blue
}

function Print-Footer {
    Write-Host ""
    Write-Color "==============================================" Green
    Write-Color "하우~☆! 오모치카에리~!" Green
    Write-Color "한글패치가 성공적으로 적용되었습니다." Green
    Write-Color "게임을 Steam에서 실행해 주세요. 니파~☆" Green
    Write-Color "==============================================" Green
    Write-Host ""
    Write-Color "종료하려면 아무 키나 누르세요..." Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# --- Chapter Name mapping (by AppID) ---
function Get-ChapterName {
    param([string]$AppId)
    switch ($AppId) {
#        "310360" { return "오니카쿠시 편" }
#        "410890" { return "와타나가시 편" }
#        "472870" { return "타타리고로시 편" }
#        "526490" { return "히마츠부시 편" }
#        "577480" { return "메아카시 편" }
#        "668350" { return "츠미호로보시 편" }
#        "1034940" { return "미나고로시 편" }
#        "1243670" { return "마츠리바야시 편" }
#        "1941110" { return "쓰르라미 울 적에: 례" }
        "2491040" { return "쓰르라미 울 적에: 봉+" }
    }
}

# --- Configuration ---
$AppId = "2491040"
$chapterName = Get-ChapterName -AppId $AppId

# Assume the patch data and grid images are located relative to the script
$patchPath = $PSScriptRoot
$Source = Join-Path $patchPath "Data\HigurashiEp10_Data"  # Patch files (data)
$GridImagesSource = Join-Path $patchPath "Data\Steamgrid"    # Steamgrid images

# --- Check that the patch source exists ---
if (-not (Test-Path $Source)) {
    Write-Color "오류: 한글패치 데이터 폴더가 존재하지 않습니다: $Source" Red
    Write-Color "패치 파일을 다시 다운로드한 후 패치 인스톨러를 실행해 주세요." Yellow
    exit 1
}

# --- Steam Path & Libraryfolders.vdf Detection ---
function Get-SteamInstallPath {
    $regPath = "HKCU:\Software\Valve\Steam"
    if (Test-Path $regPath) {
        $steamPath = (Get-ItemProperty -Path $regPath -Name SteamPath -ErrorAction SilentlyContinue).SteamPath
        return $steamPath
    }
    return $null
}

$steamInstallPath = Get-SteamInstallPath

Print-Header -chapterName $chapterName
Write-Color " " Cyan
Write-Color "제작자: Montmorency (https://github.com/s485lee)" Cyan
Write-Color " " Cyan
Write-Color "사용 안내:" Cyan
Write-Color "- Steam판: 인스톨러의 안내를 따라주세요." Cyan
Write-Color "- GOG/MangaGamer판: 해당 판을 사용 중이라면, 인스톨러의 안내에 따라 게임 .app 파일을 인스톨러 창으로 드래그해 주세요. Compatibility Pack이 필요할 수 있으니, 자세한 내용은 07th-Mod 위키를 참고하세요." Cyan

# If Steam is not found, ask for game folder until a valid one is provided
if (-not $steamInstallPath) {
    Write-Color "경고: Steam을 찾을 수 없습니다." Red
    Write-Color "자동으로 게임 파일을 찾을 수 없습니다." Yellow
    do {
        Write-Color "게임 폴더(예: ...\HigurashiEp10.exe가 있는 폴더)를 입력해 주세요:" Cyan
        $gamePath = Read-Host "게임 경로"
        $exePath = Join-Path $gamePath "HigurashiEp10.exe"
        if (-not (Test-Path $exePath)) {
            Write-Color "경고: 올바른 게임 경로가 아닙니다." Red
        }
    } until (Test-Path $exePath)
}
else {
    Section-Header "Steam 확인"
    Write-Color "Steam 확인 성공" Green

    # Define libraryfolders.vdf path
    $libraryFoldersPath = Join-Path $steamInstallPath "config\libraryfolders.vdf"
    if (-not (Test-Path $libraryFoldersPath)) {
        Write-Color "libraryfolders.vdf 파일을 찾을 수 없습니다." Red
        Write-Color "패치 인스톨러가 자동으로 게임 파일을 찾을 수 없습니다." Yellow
        do {
            Write-Color "게임 폴더(예: ...\HigurashiEp10.exe가 있는 폴더)를 입력해 주세요:" Cyan
            $gamePath = Read-Host "게임 경로"
            $exePath = Join-Path $gamePath "HigurashiEp10.exe"
            if (-not (Test-Path $exePath)) {
                Write-Color "경고: 올바른 게임 경로가 아닙니다." Red
            }
        } until (Test-Path $exePath)
    }
    else {
        Section-Header "게임 경로 확인"
        $libraryFoldersContent = Get-Content -Path $libraryFoldersPath -Raw
        $libraryFolders = [regex]::Matches($libraryFoldersContent, '"path"\s+"([^"]+)"') | ForEach-Object {
            $_.Groups[1].Value
        }

        $gamePath = $null
        foreach ($folder in $libraryFolders) {
            $manifestPath = Join-Path $folder "steamapps\appmanifest_$AppId.acf"
            if (Test-Path $manifestPath) {
                $installdirLine = Get-Content $manifestPath | Select-String -Pattern '"installdir"\s+"([^"]+)"'
                if ($installdirLine) {
                    $gameFolder = ($installdirLine.Matches[0].Groups[1].Value)
                    $gamePath = Join-Path $folder "steamapps\common\$gameFolder"
                    break
                }
            }
        }

        # If auto-detect fails, allow manual entry repeatedly until correct
        if (-not $gamePath -or -not (Test-Path (Join-Path $gamePath "HigurashiEp10.exe"))) {
            Section-Header "수동 경로 설정"
            Write-Color "패치 인스톨러가 자동으로 게임 파일을 찾을 수 없습니다." Yellow
            do {
                Write-Color "게임 폴더(예: ...\HigurashiEp10.exe가 있는 폴더)를 입력해 주세요:" Cyan
                $gamePath = Read-Host "게임 경로"
                $exePath = Join-Path $gamePath "HigurashiEp10.exe"
                if (-not (Test-Path $exePath)) {
                    Write-Color "경고: 올바른 게임 경로가 아닙니다." Red
                }
            } until (Test-Path $exePath)
        }
        else {
            Write-Color "게임 경로 확인 성공: $gamePath" Green
        }
    }
}

# --- Confirm Installation ---
$destination = Join-Path $gamePath "HigurashiEp10_Data"
Write-Host ""
Write-Color "다음 경로에 한글패치를 설치합니다: $destination" Cyan
Write-Host ""

do {
    Write-Color "한글패치를 설치하시겠습니까? (y/n)" Yellow
    $userConfirm = Read-Host "선택"
} until ($userConfirm -eq "y" -or $userConfirm -eq "n")

if ($userConfirm -eq "n") {
    Write-Color "작업이 취소되었습니다." Red
    exit 0
}

# --- Helper function for progress bar ---
function Show-ProgressBar {
    param(
        [int]$current,
        [int]$total,
        [string]$prefix = "패치 설치 중"
    )
    # Calculate percentage
    $percentComplete = [math]::Round(($current / $total) * 100)
    $barLength = 30
    $filledLength = [math]::Floor($barLength * ($percentComplete / 100))
    $bar = ("█" * $filledLength) + ("-" * ($barLength - $filledLength))
    Write-Host -NoNewline "`r${prefix}: [$bar] ${percentComplete}% ($current/$total)"
}

# --- Patch Installation with Progress Bar ---
Section-Header "패치 설치 진행"
if (-not (Test-Path $destination)) {
    New-Item -Path $destination -ItemType Directory | Out-Null
}

$files = Get-ChildItem -Path $Source -Recurse
$fileCount = $files.Count
$current = 0

foreach ($file in $files) {
    $current++
    Show-ProgressBar -current $current -total $fileCount -prefix "패치 설치 중"
    $targetPath = Join-Path $destination $file.FullName.Substring($Source.Length)
    if ($file.PSIsContainer) {
        if (-not (Test-Path $targetPath)) {
            New-Item -Path $targetPath -ItemType Directory | Out-Null
        }
    }
    else {
        $parent = Split-Path -Path $targetPath -Parent
        if (-not (Test-Path $parent)) {
            New-Item -Path $parent -ItemType Directory | Out-Null
        }
        Copy-Item -Path $file.FullName -Destination $targetPath -Force
    }
}
Write-Host "`n" 
Write-Color "한글패치가 성공적으로 설치되었습니다." Green

# --- Steamgrid Image Installation ---
Section-Header "Steamgrid 이미지 설치"
$regSteamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -Name SteamPath).SteamPath
$userDataDir = Join-Path $regSteamPath "userdata"

if (Test-Path $GridImagesSource) {
    $gridImages = Get-ChildItem -Path $GridImagesSource -Recurse
    $gridCount = $gridImages.Count

    if ($gridCount -gt 0) {
        $current = 0
        foreach ($userDir in Get-ChildItem -Path $userDataDir -Directory) {
            $gridDestination = Join-Path $userDir.FullName "config\grid"
            if (-not (Test-Path $gridDestination)) {
                New-Item -Path $gridDestination -ItemType Directory | Out-Null
            }
            foreach ($image in $gridImages) {
                $current++
                Show-ProgressBar -current $current -total $gridCount -prefix "Steamgrid 이미지 설치 중"
                $targetGridPath = Join-Path $gridDestination $image.Name
                Copy-Item -Path $image.FullName -Destination $targetGridPath -Force
            }
        }
        Write-Host "`n"
        Write-Color "Steamgrid 이미지가 성공적으로 설치되었습니다." Green
    } else {
        Write-Color "Steamgrid 이미지가 없습니다. 스킵합니다." Yellow
    }
} else {
    Write-Color "Steamgrid 이미지를 찾을 수 없어 이미지를 설치하지 않습니다." Yellow
}

Print-Footer
