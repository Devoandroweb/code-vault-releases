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
LATEST_JSON=$(curl -fsSL -H "User-Agent: CodeVault-Installer" "$API_URL" || true)

if [ -z "$LATEST_JSON" ]; then
    echo -e "${RED}[!] Gagal menghubungi GitHub API. Mengalihkan ke browser...${NC}"
    if [ "$OS" = "Darwin" ]; then
        open "https://github.com/$REPO/releases/latest"
    else
        xdg-open "https://github.com/$REPO/releases/latest" 2>/dev/null || true
    fi
    exit 0
fi

VERSION=$(echo "$LATEST_JSON" | grep -m 1 '"tag_name":' | cut -d '"' -f 4)
echo -e "      Versi terbaru ditemukan: ${GREEN}${VERSION}${NC}"

if [ "$OS" = "Darwin" ]; then
    # macOS
    DMG_URL=$(echo "$LATEST_JSON" | grep -o 'https://[^"]*\.dmg' | head -n 1)
    if [ -z "$DMG_URL" ]; then
        echo -e "${YELLOW}[!] Berkas .dmg belum tersedia di release assets. Membuka halaman rilis...${NC}"
        open "https://github.com/$REPO/releases/latest"
        exit 0
    fi

    TEMP_DMG="/tmp/CodeVault-${VERSION}.dmg"
    echo -e "${YELLOW}[2/3] Mengunduh macOS Disk Image (.dmg)...${NC}"
    curl -L "$DMG_URL" -o "$TEMP_DMG" --progress-bar

    echo -e "${YELLOW}[3/3] Membuka installer disk image...${NC}"
    open "$TEMP_DMG"

    echo -e ""
    echo -e "${GREEN}✓ Berkas installer Code Vault Pro berhasil diunduh dan dibuka!${NC}"
    echo -e "  Silakan geser Code Vault ke folder Applications Anda."
    echo -e ""
else
    # Linux
    APPIMAGE_URL=$(echo "$LATEST_JSON" | grep -o 'https://[^"]*\.AppImage' | head -n 1)
    DEB_URL=$(echo "$LATEST_JSON" | grep -o 'https://[^"]*\.deb' | head -n 1)

    if [ -n "$APPIMAGE_URL" ]; then
        TEMP_APP="/tmp/CodeVault-${VERSION}.AppImage"
        echo -e "${YELLOW}[2/3] Mengunduh AppImage Linux...${NC}"
        curl -L "$APPIMAGE_URL" -o "$TEMP_APP" --progress-bar
        chmod +x "$TEMP_APP"
        echo -e "${GREEN}✓ Code Vault AppImage tersimpan di: $TEMP_APP${NC}"
        echo -e "  Menjalankan Code Vault Pro..."
        "$TEMP_APP" &
    elif [ -n "$DEB_URL" ]; then
        TEMP_DEB="/tmp/CodeVault-${VERSION}.deb"
        echo -e "${YELLOW}[2/3] Mengunduh paket .deb...${NC}"
        curl -L "$DEB_URL" -o "$TEMP_DEB" --progress-bar
        echo -e "${GREEN}✓ Paket .deb tersimpan di: $TEMP_DEB${NC}"
        echo -e "  Jalankan: sudo dpkg -i $TEMP_DEB"
    else
        echo -e "${YELLOW}[!] Membuka halaman rilis di browser...${NC}"
        xdg-open "https://github.com/$REPO/releases/latest" 2>/dev/null || true
    fi
fi
