# Code Vault Pro - Automated Windows Installer via PowerShell
# Usage: irm https://devoandroweb.github.io/code-vault-releases/install.ps1 | iex

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Code Vault Pro - Windows Installation Assistant        " -ForegroundColor White
Write-Host "   https://github.com/Devoandroweb/code-vault-releases   " -ForegroundColor DarkCyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$repo = "Devoandroweb/code-vault-releases"
$apiUrl = "https://api.github.com/repos/$repo/releases/latest"

try {
    Write-Host "[1/3] Menghubungi GitHub Releases..." -ForegroundColor Yellow
    $headers = @{ "User-Agent" = "CodeVaultInstaller-PowerShell" }
    $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get

    $version = $release.tag_name
    Write-Host "      Versi terbaru ditemukan: $version" -ForegroundColor Green

    # Find Windows .exe asset
    $asset = $release.assets | Where-Object { $_.name -like "*setup*.exe" -or $_.name -like "*.exe" } | Select-Object -First 1

    if (-not $asset) {
        # Fallback to direct release URL
        $downloadUrl = "https://github.com/$repo/releases/latest"
        Write-Host "[!] Berkas .exe belum tersedia di release assets. Membuka halaman release..." -ForegroundColor Yellow
        Start-Process $downloadUrl
        exit 0
    }

    $downloadUrl = $asset.browser_download_url
    $fileName = $asset.name
    $tempPath = Join-Path $env:TEMP $fileName

    Write-Host "[2/3] Mengunduh $fileName ($([math]::Round($asset.size / 1MB, 2)) MB)..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempPath -UseBasicParsing

    Write-Host "[3/3] Menjalankan installer..." -ForegroundColor Green
    Start-Process -FilePath $tempPath

    Write-Host ""
    Write-Host "✓ Instalasi Code Vault Pro $version berhasil dimulai!" -ForegroundColor Cyan
    Write-Host "  Silakan ikuti instruksi pada wizard instalasi desktop." -ForegroundColor Gray
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "[-] Gagal mengunduh otomatis: $_" -ForegroundColor Red
    Write-Host "    Membuka halaman download browser langsung..." -ForegroundColor Gray
    Start-Process "https://github.com/$repo/releases/latest"
}
