#!/usr/bin/env bash
#
# CachyOS / XFCE (X11) için rog-control-center'ı X11 desteğiyle kaynaktan
# derleyip kuran ve test eden script.
#
# Kullanım:
#   chmod +x install-rog-control-center-x11.sh
#   ./install-rog-control-center-x11.sh
#
set -euo pipefail

REPO_URL="https://github.com/OpenGamingCollective/asusctl.git"
BUILD_DIR="$HOME/build-asusctl"
LOG_FILE="$HOME/rog-control-center-build.log"

log() { echo -e "\n\033[1;32m==> $1\033[0m"; }
err() { echo -e "\033[1;31m[HATA] $1\033[0m" >&2; }

trap 'err "Script $LINENO. satırda başarısız oldu. Detaylar: $LOG_FILE"' ERR

# ---------------------------------------------------------------------------
log "1) Root olarak çalışmadığından emin oluyoruz"
if [[ $EUID -eq 0 ]]; then
    err "Bu scripti root olarak değil, normal kullanıcı olarak çalıştırın (sudo gerektiğinde script kendi soracak)."
    exit 1
fi

# ---------------------------------------------------------------------------
log "2) Eski paketler kaldırılıyor (varsa)"
sudo pacman -Rns --noconfirm rog-control-center rog-control-center-x11 2>/dev/null || true
echo "   asusctl (daemon) korunuyor, sadece GUI paketleri kaldırıldı."

# ---------------------------------------------------------------------------
log "3) Derleme bağımlılıkları kuruluyor"
sudo pacman -S --needed --noconfirm \
    base-devel git pkgconf cmake clang \
    fontconfig freetype2 libxkbcommon mesa seatd libinput \
    systemd-libs asusctl 2>&1 | tee -a "$LOG_FILE"

# ---------------------------------------------------------------------------
log "4) Rust/cargo kontrol ediliyor (rustup önerilir, pacman'daki eski kalabiliyor)"
if ! command -v rustup &>/dev/null; then
    echo "   rustup bulunamadı, kuruluyor..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    source "$HOME/.cargo/env" 2>/dev/null || true
fi
rustup default stable
rustc --version

# ---------------------------------------------------------------------------
log "5) Kaynak kod indiriliyor / güncelleniyor"
if [[ -d "$BUILD_DIR" ]]; then
    echo "   Var olan klasör bulundu, temizlenip güncelleniyor: $BUILD_DIR"
    cd "$BUILD_DIR"
    git fetch --all
    git reset --hard origin/main
    git clean -fdx
else
    git clone "$REPO_URL" "$BUILD_DIR"
    cd "$BUILD_DIR"
fi
git submodule update --init --recursive 2>/dev/null || true

# ---------------------------------------------------------------------------
log "6) X11 destekli GUI derleniyor (bu birkaç dakika sürebilir)"
cargo build --release --features "rog-control-center/x11" 2>&1 | tee -a "$LOG_FILE"

BIN_PATH="$BUILD_DIR/target/release/rog-control-center"
if [[ ! -x "$BIN_PATH" ]]; then
    err "Binary oluşmadı: $BIN_PATH. Log dosyasına bakın: $LOG_FILE"
    exit 1
fi

# ---------------------------------------------------------------------------
log "7) Binary sisteme kuruluyor (/usr/local/bin)"
sudo install -Dm755 "$BIN_PATH" /usr/local/bin/rog-control-center
echo "   Kuruldu: /usr/local/bin/rog-control-center"

# ---------------------------------------------------------------------------
log "8) İkon kuruluyor ve .desktop dosyası oluşturuluyor (XFCE menüsü için)"

ICON_SRC="$BUILD_DIR/rog-control-center/data/rog-control-center.png"
ICON_DEST_DIR="/usr/share/icons/hicolor/512x512/apps"

if [[ -f "$ICON_SRC" ]]; then
    sudo install -Dm644 "$ICON_SRC" "$ICON_DEST_DIR/rog-control-center.png"
    echo "   İkon kuruldu: $ICON_DEST_DIR/rog-control-center.png"
    ICON_NAME="rog-control-center"
else
    echo "   Uyarı: Kaynakta ikon dosyası bulunamadı ($ICON_SRC), varsayılan sistem ikonu kullanılacak."
    ICON_NAME="utilities-terminal"
fi

# Icon cache'i güncelle ki XFCE yeni ikonu hemen görsün
if command -v gtk-update-icon-cache &>/dev/null; then
    sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
fi

mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/rog-control-center.desktop" <<EOF
[Desktop Entry]
Name=ROG Control Center
Comment=ASUS ROG Control Center (X11 build)
Exec=/usr/local/bin/rog-control-center
Icon=${ICON_NAME}
Type=Application
Categories=System;HardwareSettings;
Terminal=false
StartupNotify=true
EOF
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
echo "   Menüye eklendi: rog-control-center.desktop (Icon=${ICON_NAME})"

# ---------------------------------------------------------------------------
log "9) asusd servisi kontrol ediliyor / başlatılıyor"
sudo mkdir -p /etc/asusd
sudo systemctl enable --now asusd.service
sudo systemctl reset-failed asusd 2>/dev/null || true
sudo systemctl restart asusd

if systemctl is-active --quiet asusd; then
    echo "   asusd servisi çalışıyor."
else
    err "asusd servisi başlatılamadı. 'journalctl -u asusd -n 50' ile kontrol edin."
fi

# ---------------------------------------------------------------------------
log "10) Test: GUI 3 saniyeliğine başlatılıp arka planda çalıştığı doğrulanıyor"
/usr/local/bin/rog-control-center &
GUI_PID=$!
sleep 3
if kill -0 "$GUI_PID" 2>/dev/null; then
    echo "   ✅ rog-control-center çalışıyor (PID: $GUI_PID). Test amaçlı kapatılıyor."
    kill "$GUI_PID" 2>/dev/null || true
else
    err "GUI 3 saniye içinde kapandı / crash oldu. Aşağıdaki komutla debug edin:"
    echo "   rog-control-center 2>&1 | tee ~/rog-cc-debug.log"
fi

# ---------------------------------------------------------------------------
log "Kurulum tamamlandı"
cat <<EOF

Özet:
  Binary       : /usr/local/bin/rog-control-center
  Kaynak       : $BUILD_DIR
  Build log    : $LOG_FILE
  Menü kısayolu: ~/.local/share/applications/rog-control-center.desktop

Manuel test için:
  rog-control-center

Sorun devam ederse şu çıktıları paylaşın:
  journalctl -u asusd -n 50 --no-pager
  rog-control-center 2>&1 | head -n 50
EOF
