#!/usr/bin/env bash
#
# install-rog-control-center-x11.sh tarafından kurulan her şeyi kaldırır.
#
# Kullanım:
#   chmod +x uninstall-rog-control-center-x11.sh
#   ./uninstall-rog-control-center-x11.sh
#
set -euo pipefail

BUILD_DIR="$HOME/build-asusctl"
LOG_FILE="$HOME/rog-control-center-build.log"
BIN_PATH="/usr/local/bin/rog-control-center"
DESKTOP_FILE="$HOME/.local/share/applications/rog-control-center.desktop"
ICON_PATH="/usr/share/icons/hicolor/512x512/apps/rog-control-center.png"

log() { echo -e "\n\033[1;33m==> $1\033[0m"; }

log "1) Binary kaldırılıyor"
if [[ -f "$BIN_PATH" ]]; then
    sudo rm -f "$BIN_PATH"
    echo "   Silindi: $BIN_PATH"
else
    echo "   Bulunamadı, atlanıyor: $BIN_PATH"
fi

log "2) İkon kaldırılıyor"
if [[ -f "$ICON_PATH" ]]; then
    sudo rm -f "$ICON_PATH"
    echo "   Silindi: $ICON_PATH"
    if command -v gtk-update-icon-cache &>/dev/null; then
        sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
    fi
else
    echo "   Bulunamadı, atlanıyor: $ICON_PATH"
fi

log "3) Menü kısayolu kaldırılıyor"
if [[ -f "$DESKTOP_FILE" ]]; then
    rm -f "$DESKTOP_FILE"
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    echo "   Silindi: $DESKTOP_FILE"
else
    echo "   Bulunamadı, atlanıyor: $DESKTOP_FILE"
fi

log "4) Kaynak/derleme klasörü kaldırılıyor"
if [[ -d "$BUILD_DIR" ]]; then
    rm -rf "$BUILD_DIR"
    echo "   Silindi: $BUILD_DIR"
else
    echo "   Bulunamadı, atlanıyor: $BUILD_DIR"
fi

log "5) Build log dosyası kaldırılıyor"
if [[ -f "$LOG_FILE" ]]; then
    rm -f "$LOG_FILE"
    echo "   Silindi: $LOG_FILE"
else
    echo "   Bulunamadı, atlanıyor: $LOG_FILE"
fi

# ---------------------------------------------------------------------------
log "Bilerek dokunulmayanlar"
cat <<'EOF'
  - asusd.service ve asusctl (daemon): kaldırılmadı. Bunlar ROG donanım
    kontrolünün (fan, güç profili, RGB vs.) temeli; silersen sadece GUI
    değil, tüm donanım kontrolü de gider. Kaldırmak istersen:

        sudo systemctl disable --now asusd.service
        sudo pacman -Rns asusctl rog-control-center

  - rustup / cargo: kaldırılmadı, başka projelerde de kullanılıyor olabilir.
    Kaldırmak istersen:  rustup self uninstall

  - base-devel, cmake, clang, fontconfig, mesa, libinput vb. build
    bağımlılıkları: kaldırılmadı. Bunlar sistemde başka paketler
    tarafından da kullanılıyor olabileceği için pacman ile otomatik
    silinmiyor — elle kaldırmak istersen önce 'pacman -Qtdq' ile
    gereksiz/yetim paketleri kontrol et.
EOF

log "Kaldırma tamamlandı"
