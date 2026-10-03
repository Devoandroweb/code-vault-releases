#!/usr/bin/env bash
# Code Vault Pro - Automated Installer for macOS & Linux
# Usage: curl -fsSL https://devoandroweb.github.io/code-vault-releases/install.sh | bash

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e ""
echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   Code Vault Pro - macOS & Linux Installer               ${NC}"
echo -e "${CYAN}   https://github.com/Devoandroweb/code-vault-releases   ${NC}"
echo -e "${CYAN}==========================================================${NC}"
echo -e ""

OS="$(uname -s)"
ARCH="$(uname -m)"
REPO="Devoandroweb/code-vault-releases"
API_URL="https://api.github.com/repos/$REPO/releases/latest"

echo -e "${YELLOW}[1/3] Menghubungi GitHub Releases...${NC}"
LATEST_JSON=$(curl -fsSL -H "User-Agent: CodeVault-Installer" "$API_URL" 2>/dev/null || true)

if [ -z "$LATEST_JSON" ]; then
    echo -e "${RED}[!] Gagal menghubungi GitHub API. Mengalihkan ke browser...${NC}"
    if [ "$OS" = "Darwin" ]; then
        open "https://github.com/$REPO/releases/latest"
    else
        xdg-open "https://github.com/$REPO/releases/latest" 2>/dev/null || true
    fi
    exit 0
fi

# Parsing VERSION secara tangguh (mendukung minified JSON maupun multi-line JSON)
VERSION=""
if [[ "$LATEST_JSON" =~ \"tag_name\":[[:space:]]*\"([^\"]+)\" ]]; then
    VERSION="${BASH_REMATCH[1]}"
elif echo "$LATEST_JSON" | grep -q '"tag_name":'; then
    VERSION=$(echo "$LATEST_JSON" | grep -o '"tag_name": *"[^"]*"' | head -n 1 | cut -d '"' -f 4)
fi

# Sanitasi karakter VERSION (hanya perbolehkan huruf, angka, titik, strip, underscore)
VERSION=$(echo "$VERSION" | tr -cd 'a-zA-Z0-9._-')

if [ -z "$VERSION" ]; then
    VERSION="latest"
fi

echo -e "      Versi terbaru ditemukan: ${GREEN}${VERSION}${NC}"

if [ "$OS" = "Darwin" ]; then
    # macOS
    ALL_DMGS=$(echo "$LATEST_JSON" | grep -o 'https://github\.com/[^"]*\.dmg' || true)

    # Deteksi kecocokan arsitektur Mac (Apple Silicon vs Intel)
    DMG_URL=""
    if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
        DMG_URL=$(echo "$ALL_DMGS" | grep -E 'aarch64|arm64' | head -n 1 || true)
    elif [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "x64" ]; then
        DMG_URL=$(echo "$ALL_DMGS" | grep -E 'x64|x86_64' | head -n 1 || true)
    fi

    # Fallback jika nama file DMG tidak memiliki penanda arsitektur khusus
    if [ -z "$DMG_URL" ]; then
        DMG_URL=$(echo "$ALL_DMGS" | head -n 1)
    fi

    if [ -z "$DMG_URL" ]; then
        echo -e "${YELLOW}[!] Berkas .dmg belum tersedia di release assets. Membuka halaman rilis...${NC}"
        open "https://github.com/$REPO/releases/latest"
        exit 0
    fi

    TEMP_DMG="/tmp/CodeVault-${VERSION}.dmg"
    echo -e "${YELLOW}[2/3] Mengunduh macOS Disk Image (.dmg)...${NC}"
    echo -e "      Target: ${CYAN}${DMG_URL}${NC}"
    curl -L "$DMG_URL" -o "$TEMP_DMG" --progress-bar

    echo -e "${YELLOW}[3/3] Membuka installer disk image...${NC}"
    open "$TEMP_DMG"

    echo -e ""
    echo -e "${GREEN}✓ Berkas installer Code Vault Pro berhasil diunduh dan dibuka!${NC}"
    echo -e "  Silakan geser Code Vault ke folder Applications Anda."
    echo -e ""
    echo -e "${CYAN}💡 Tips Jika Muncul Peringatan Keamanan macOS (Gatekeeper):${NC}"
    echo -e "  Jika muncul pesan 'Code Vault is damaged and can't be opened':"
    echo -e "  Jalankan perintah ini di Terminal:"
    echo -e "  ${GREEN}xattr -cr \"/Applications/Code Vault.app\"${NC}"
    echo -e ""
else
    # Linux
    ALL_APPIMAGES=$(echo "$LATEST_JSON" | grep -o 'https://github\.com/[^"]*\.AppImage' || true)
    ALL_DEBS=$(echo "$LATEST_JSON" | grep -o 'https://github\.com/[^"]*\.deb' || true)

    APPIMAGE_URL=""
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "x64" ]; then
        APPIMAGE_URL=$(echo "$ALL_APPIMAGES" | grep -E 'x86_64|amd64|x64' | head -n 1 || true)
    elif [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
        APPIMAGE_URL=$(echo "$ALL_APPIMAGES" | grep -E 'aarch64|arm64' | head -n 1 || true)
    fi
    if [ -z "$APPIMAGE_URL" ]; then
        APPIMAGE_URL=$(echo "$ALL_APPIMAGES" | head -n 1)
    fi

    DEB_URL=""
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "x64" ]; then
        DEB_URL=$(echo "$ALL_DEBS" | grep -E 'amd64|x86_64' | head -n 1 || true)
    elif [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
        DEB_URL=$(echo "$ALL_DEBS" | grep -E 'arm64|aarch64' | head -n 1 || true)
    fi
    if [ -z "$DEB_URL" ]; then
        DEB_URL=$(echo "$ALL_DEBS" | head -n 1)
    fi

    if [ -n "$APPIMAGE_URL" ]; then
        TEMP_APP="/tmp/CodeVault-${VERSION}.AppImage"
        echo -e "${YELLOW}[2/3] Mengunduh AppImage Linux...${NC}"
        echo -e "      Target: ${CYAN}${APPIMAGE_URL}${NC}"
        curl -L "$APPIMAGE_URL" -o "$TEMP_APP" --progress-bar
        chmod +x "$TEMP_APP"
        echo -e "${GREEN}✓ Code Vault AppImage tersimpan di: $TEMP_APP${NC}"
        echo -e "  Menjalankan Code Vault Pro..."
        "$TEMP_APP" &
    elif [ -n "$DEB_URL" ]; then
        TEMP_DEB="/tmp/CodeVault-${VERSION}.deb"
        echo -e "${YELLOW}[2/3] Mengunduh paket .deb...${NC}"
        echo -e "      Target: ${CYAN}${DEB_URL}${NC}"
        curl -L "$DEB_URL" -o "$TEMP_DEB" --progress-bar
        echo -e "${GREEN}✓ Paket .deb tersimpan di: $TEMP_DEB${NC}"
        echo -e "  Jalankan: sudo dpkg -i $TEMP_DEB"
    else
        echo -e "${YELLOW}[!] Membuka halaman rilis di browser...${NC}"
        xdg-open "https://github.com/$REPO/releases/latest" 2>/dev/null || true
    fi
fi
