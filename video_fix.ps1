param(
    [Parameter(Position=0)]
    [string]$InputPath
)

$ErrorActionPreference = 'Stop'

# Universal video compatibility patch for Strateny v Europe / Lost in Europe.
# Supports exact known retail lieu.exe 1.0 and 1.1 builds.
# Windows PowerShell 5.1 compatible. No Python or external tools required.
#
# Security design:
# - refuses unknown EXE hashes
# - verifies original bytes at every patch site
# - creates RX code section and RW non-executable data section
# - no new RWX section
# - no runtime IAT patching of eng.dll
# - replaces the supported input EXE only after the complete patched image is verified
# - verifies exact expected output SHA-256

$Profiles = @{
    '1.0' = @{
        SourceSha256 = '5563d02bd4f9a6c61d4b723d46e17dd53d3c05eb0c7d3420cd224fcdbc40c231'
        SourceSize = 684032
        OutputSha256 = '4ead00da328810d3219beec3e969c4de5260aa2e508959092a8b19d0be2139ea'
        ExpectedEngSha256 = 'd33187196682cfb9176c456cf5e04e04a53f03c7ea063a56c36f12b514b1e117'
        CodeB64 = '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HQDQSgCF23U6/xXA0EUAixUE0EoAhdJ1EYXAugEAAAAPRMKjBNBKAOseixUE0EoAKdA9wwkAAHYPxwUA0EoAAQAAALsBAAAAg8QIidhbw1Hopv///1mFwHUDMcDDVYnlg+T4uJbFQAD/4A8Li0QkBIXAdBuAeAwAdQmDuLAEAAAAdQwxwKMI0EoAowzQSgDDVujW////g8QEX16DxDDDDwtmkJB3Z2xTd2FwTGF5ZXJCdWZmZXJzAHdnbEdldEN1cnJlbnRDb250ZXh0AAAAAHdnbEdldEN1cnJlbnREQwBnbEZpbmlzaAAAAABnbERyYXdCdWZmZXIAAAAAZ2xHZXRJbnRlZ2VydgAAAGdsRHJhd1BpeGVscwAAAABnbFJhc3RlclBvczJmAAAAZ2xQaXhlbFpvb20AZ2xQaXhlbFN0b3JlaQAAAGdsQ2xlYXIAZ2xDbGVhckNvbG9yAAAAAGdsRGlzYWJsZQAAAGdsTG9hZElkZW50aXR5AABnbFBvcE1hdHJpeABnbFB1c2hNYXRyaXgAAAAAZ2xNYXRyaXhNb2RlAAAAAGdsUG9wQXR0cmliAGdsUHVzaEF0dHJpYgAAAABvcGVuZ2wzMi5kbGwAZpCQAABIRA=='
        VfixRva = [uint32]0x000AC000
        VdatRva = [uint32]0x000AD000
        RawPtr = 684032
        SizeImage = [uint32]0x000AE000
        VdatSize = 96
        Patches = @(
            @{ Va = [uint32]0x0040C4C9; Old = '3998880100'; New = 'e955000000'; Description = 'skip obsolete DirectDraw overlay capability/init/error path' }
            @{ Va = [uint32]0x00407F90; Old = '81ec200100'; New = 'e961470a00'; Description = 'legacy overlay frame update -> OpenGL presenter adapter' }
            @{ Va = [uint32]0x0040C590; Old = '558bec83e4f8'; New = 'e9c2010a0090'; Description = 'delay first movie update 2500 ms before movie clock/audio start' }
            @{ Va = [uint32]0x0040CA5E; Old = '80b940050100007403'; New = '909090909090909090'; Description = 'Esc skips every movie' }
        )
    }

    '1.1' = @{
        SourceSha256 = 'f2bb3e8c730b523524eeef7767c4074f376c5a0e7af850c59ea29aac37207577'
        SourceSize = 655360
        OutputSha256 = '82fca8ca1938e95649957c9ee523e618da085d98a48cbe49470127212f907c27'
        ExpectedEngSha256 = '6085c271c7bec17c00492b98e5e6c05e9209f970dc4d06c64fc93299215d29d3'
        CodeB64 = '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'
        VfixRva = [uint32]0x000A5000
        VdatRva = [uint32]0x000A6000
        RawPtr = 655360
        SizeImage = [uint32]0x000A7000
        VdatSize = 96
        Patches = @(
            @{ Va = [uint32]0x004078B0; Old = '83b988'; New = 'b001c3'; Description = 'legacy overlay support -> true' }
            @{ Va = [uint32]0x00408130; Old = '81ecf0'; New = 'c20400'; Description = 'legacy overlay init -> return' }
            @{ Va = [uint32]0x00408210; Old = '81ec0c0100'; New = 'e98bd30900'; Description = 'legacy overlay frame update -> OpenGL presenter' }
            @{ Va = [uint32]0x0040BB00; Old = '83ec30568bf1'; New = 'e9bb9c090090'; Description = 'delay first movie update 2500 ms before movie clock/audio start' }
            @{ Va = [uint32]0x0040BFAD; Old = '5f5e83c430'; New = 'e96e980900'; Description = 'movie update epilogue -> frame retirement' }
            @{ Va = [uint32]0x0040BFCE; Old = '80b940050100007403'; New = '909090909090909090'; Description = 'Esc skips every movie' }
        )
    }
}

function Get-Sha256File([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-Sha256Bytes([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($Bytes)
        return ([System.BitConverter]::ToString($hash)).Replace('-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Get-U16([byte[]]$Bytes, [int]$Offset) {
    return [System.BitConverter]::ToUInt16($Bytes, $Offset)
}

function Get-U32([byte[]]$Bytes, [int]$Offset) {
    return [System.BitConverter]::ToUInt32($Bytes, $Offset)
}

function Set-U16([byte[]]$Bytes, [int]$Offset, [uint16]$Value) {
    $tmp = [System.BitConverter]::GetBytes($Value)
    [System.Buffer]::BlockCopy($tmp, 0, $Bytes, $Offset, 2)
}

function Set-U32([byte[]]$Bytes, [int]$Offset, [uint32]$Value) {
    $tmp = [System.BitConverter]::GetBytes($Value)
    [System.Buffer]::BlockCopy($tmp, 0, $Bytes, $Offset, 4)
}

function Convert-HexToBytes([string]$Hex) {
    if (($Hex.Length % 2) -ne 0) { throw "Neplatny hex retazec." }
    $result = New-Object byte[] ($Hex.Length / 2)
    for ($i = 0; $i -lt $result.Length; $i++) {
        $result[$i] = [Convert]::ToByte($Hex.Substring($i * 2, 2), 16)
    }
    return $result
}

function Assert-BytesEqual([byte[]]$Data, [int]$Offset, [byte[]]$Expected, [string]$Where) {
    for ($i = 0; $i -lt $Expected.Length; $i++) {
        if ($Data[$Offset + $i] -ne $Expected[$i]) {
            $got = New-Object byte[] $Expected.Length
            [System.Buffer]::BlockCopy($Data, $Offset, $got, 0, $Expected.Length)
            $gotHex = ([BitConverter]::ToString($got)).Replace('-', '').ToLowerInvariant()
            $expHex = ([BitConverter]::ToString($Expected)).Replace('-', '').ToLowerInvariant()
            throw "Neocakavane bajty pri $Where.`n  subor:     $gotHex`n  ocakavane: $expHex"
        }
    }
}

function Write-SectionHeader(
    [byte[]]$Data,
    [int]$Offset,
    [string]$Name,
    [uint32]$VirtualSize,
    [uint32]$VirtualAddress,
    [uint32]$RawSize,
    [uint32]$RawPointer,
    [uint32]$Characteristics
) {
    # IMAGE_SECTION_HEADER = 40 bytes
    for ($i = 0; $i -lt 40; $i++) { $Data[$Offset + $i] = 0 }
    $nameBytes = [System.Text.Encoding]::ASCII.GetBytes($Name)
    $nameLen = [Math]::Min(8, $nameBytes.Length)
    [System.Buffer]::BlockCopy($nameBytes, 0, $Data, $Offset, $nameLen)
    Set-U32 $Data ($Offset + 8)  $VirtualSize
    Set-U32 $Data ($Offset + 12) $VirtualAddress
    Set-U32 $Data ($Offset + 16) $RawSize
    Set-U32 $Data ($Offset + 20) $RawPointer
    Set-U32 $Data ($Offset + 36) $Characteristics
}

function Resolve-InputPath([string]$Requested) {
    if ([string]::IsNullOrWhiteSpace($Requested)) {
        $candidate = Join-Path $PSScriptRoot 'lieu.exe'
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
        throw "Zadaj cestu k lieu.exe alebo poloz lieu.exe vedla tohto skriptu."
    }

    if (Test-Path -LiteralPath $Requested -PathType Container) {
        $candidate = Join-Path $Requested 'lieu.exe'
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            throw "V zadanom adresari sa nenachadza lieu.exe."
        }
        return (Resolve-Path -LiteralPath $candidate).Path
    }

    if (-not (Test-Path -LiteralPath $Requested -PathType Leaf)) {
        throw "Vstupny subor neexistuje: $Requested"
    }
    return (Resolve-Path -LiteralPath $Requested).Path
}

try {
    $InputPath = Resolve-InputPath $InputPath
    $inputHash = Get-Sha256File $InputPath

    $detectedVersion = $null
    $alreadyPatched = $false

    foreach ($version in $Profiles.Keys) {
        $p = $Profiles[$version]
        if ($inputHash -eq $p.SourceSha256) {
            $detectedVersion = $version
            break
        }
        if ($inputHash -eq $p.OutputSha256) {
            $detectedVersion = $version
            $alreadyPatched = $true
            break
        }
    }

    if ($null -eq $detectedVersion) {
        throw ("Tento lieu.exe nie je podporovany build 1.0 ani 1.1.`n" +
               "SHA-256: $inputHash`n" +
               "Subor nebude patchovany podla volnych signatur.")
    }

    $profile = $Profiles[$detectedVersion]
    Write-Host "Detegovany lieu.exe: verzia $detectedVersion" -ForegroundColor Cyan

    $engPath = Join-Path (Split-Path -Parent $InputPath) 'eng.dll'
    if (Test-Path -LiteralPath $engPath -PathType Leaf) {
        $engHash = Get-Sha256File $engPath
        if ($engHash -eq $profile.ExpectedEngSha256) {
            Write-Host "eng.dll: verzia zodpoveda detegovanemu lieu.exe." -ForegroundColor DarkGreen
        } else {
            Write-Warning ("eng.dll ma iny SHA-256. DLL sa nepatchuje, ale moze ist o zmiesanu instalaciu.`n" +
                           "  eng.dll:   $engHash`n" +
                           "  ocakavany: $($profile.ExpectedEngSha256)")
        }
    } else {
        Write-Host "eng.dll nebol vedla lieu.exe najdeny; DLL sa nepatchuje." -ForegroundColor DarkYellow
    }

    if ($alreadyPatched) {
        Write-Host "Tento lieu.exe uz obsahuje tento video fix; nic sa nemeni." -ForegroundColor Green
        Write-Host "SHA-256: $inputHash"
        exit 0
    }

    # In-place mode: build and verify everything first, then replace lieu.exe.
    $OutputPath = $InputPath
    $TempPath = Join-Path (Split-Path -Parent $InputPath) ('.lieu_video_fix_' + [Guid]::NewGuid().ToString('N') + '.tmp')

    [byte[]]$original = [System.IO.File]::ReadAllBytes($InputPath)
    if ($original.Length -ne $profile.SourceSize) {
        throw "Velkost vstupu nezodpoveda detegovanemu profilu."
    }

    $pe = [int](Get-U32 $original 0x3C)
    if (($original[$pe] -ne 0x50) -or ($original[$pe+1] -ne 0x45) -or
        ($original[$pe+2] -ne 0x00) -or ($original[$pe+3] -ne 0x00)) {
        throw "Vstup nie je platny PE executable."
    }

    $numSectionsOffset = $pe + 6
    $numSections = Get-U16 $original $numSectionsOffset
    $sizeOpt = Get-U16 $original ($pe + 20)
    $sectionTable = $pe + 24 + $sizeOpt
    if ($numSections -ne 3) {
        throw "Neocakavana PE struktura: $numSections sekcii namiesto 3."
    }

    [byte[]]$code = [Convert]::FromBase64String($profile.CodeB64)
    if ($code.Length -gt 0x1000) {
        throw "Interny renderer payload je prilis velky."
    }
    if ($original.Length -ne $profile.RawPtr) {
        throw "Raw offset novej sekcie nesedi s podporovanym buildom."
    }

    # Final file is original + one 4 KiB raw code section.
    [byte[]]$data = New-Object byte[] ($original.Length + 0x1000)
    [System.Buffer]::BlockCopy($original, 0, $data, 0, $original.Length)

    # .vfix: RX only
    Write-SectionHeader $data ($sectionTable + 3*40) '.vfix' `
        ([uint32]$code.Length) ([uint32]$profile.VfixRva) 0x1000 `
        ([uint32]$profile.RawPtr) ([Convert]::ToUInt32('60000020', 16))

    # .vdat: zero-initialized RW, non-executable
    Write-SectionHeader $data ($sectionTable + 4*40) '.vdat' `
        ([uint32]$profile.VdatSize) ([uint32]$profile.VdatRva) 0 0 `
        ([Convert]::ToUInt32('C0000080', 16))

    Set-U16 $data $numSectionsOffset 5

    $opt = $pe + 24
    $oldSizeCode = Get-U32 $data ($opt + 4)
    $oldSizeUninit = Get-U32 $data ($opt + 12)
    Set-U32 $data ($opt + 4)  ([uint32]($oldSizeCode + 0x1000))
    Set-U32 $data ($opt + 12) ([uint32]($oldSizeUninit + 0x1000))
    Set-U32 $data ($opt + 56) ([uint32]$profile.SizeImage)

    [System.Buffer]::BlockCopy($code, 0, $data, [int]$profile.RawPtr, $code.Length)

    foreach ($patch in $profile.Patches) {
        [uint32]$va = $patch.Va
        [byte[]]$old = Convert-HexToBytes $patch.Old
        [byte[]]$new = Convert-HexToBytes $patch.New
        if ($old.Length -ne $new.Length) {
            throw "Interna chyba dlzky patchu pri VA 0x$('{0:X8}' -f $va)."
        }
        $offset = [int]($va - 0x400000)
        Assert-BytesEqual $data $offset $old ("VA 0x{0:X8} ({1})" -f $va, $patch.Description)
        [System.Buffer]::BlockCopy($new, 0, $data, $offset, $new.Length)
    }

    $resultHash = Get-Sha256Bytes $data
    if ($resultHash -ne $profile.OutputSha256) {
        throw ("Vysledok nie je bitovo identicky s referencnym buildom.`n" +
               "  vysledok:  $resultHash`n" +
               "  ocakavany: $($profile.OutputSha256)")
    }

    # Write to a temporary file first. The original EXE is untouched until
    # the complete result is on disk and its SHA-256 has been re-verified.
    [System.IO.File]::WriteAllBytes($TempPath, $data)
    $tempHash = Get-Sha256File $TempPath
    if ($tempHash -ne $profile.OutputSha256) {
        Remove-Item -LiteralPath $TempPath -Force -ErrorAction SilentlyContinue
        throw ("Kontrola docasneho suboru zlyhala.`n" +
               "  vysledok:  $tempHash`n" +
               "  ocakavany: $($profile.OutputSha256)")
    }

    try {
        # Replace in one final step. No backup is kept by design.
        [System.IO.File]::Replace($TempPath, $InputPath, $null, $true)
    }
    catch {
        # Fallback for filesystems where File.Replace is unsupported.
        Remove-Item -LiteralPath $InputPath -Force
        Move-Item -LiteralPath $TempPath -Destination $InputPath -Force
    }

    $installedHash = Get-Sha256File $InputPath
    if ($installedHash -ne $profile.OutputSha256) {
        throw ("Patch bol zapisany, ale zaverecny SHA-256 nesedi.`n" +
               "  lieu.exe:   $installedHash`n" +
               "  ocakavany: $($profile.OutputSha256)")
    }

    Write-Host ""
    Write-Host "OK - lieu.exe bol priamo patchnuty." -ForegroundColor Green
    Write-Host "Subor: $InputPath"
    Write-Host "SHA-256: $installedHash"
    Write-Host "eng.dll sa nemeni."
    exit 0
}
catch {
    if ($TempPath -and (Test-Path -LiteralPath $TempPath)) {
        Remove-Item -LiteralPath $TempPath -Force -ErrorAction SilentlyContinue
    }
    Write-Host ""
    Write-Host "CHYBA: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
