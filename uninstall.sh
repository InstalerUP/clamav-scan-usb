#!/usr/bin/env bash
set -Eeuo pipefail

PROGRAM_NAME="clamav-scan-usb"
INSTALL_PATH="/usr/local/bin/${PROGRAM_NAME}"
DOC_DIR="/usr/local/share/doc/${PROGRAM_NAME}"
README_PATH="${DOC_DIR}/README.md"
BACKUP_DIR="/var/backups/${PROGRAM_NAME}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

info() {
    printf "${GREEN}[INFO]${RESET} %s\n" "$*"
}

warn() {
    printf "${YELLOW}[ВНИМАНИЕ]${RESET} %s\n" "$*"
}

error() {
    printf "${RED}[ОШИБКА]${RESET} %s\n" "$*" >&2
}

ask_yes_no() {
    local answer

    while true; do
        printf '%s [д/н]: ' "$1"

        if ! IFS= read -r answer </dev/tty; then
            return 1
        fi

        case "${answer,,}" in
            д|да|y|yes)
                return 0
                ;;
            н|нет|no|n)
                return 1
                ;;
            *)
                printf 'Введите «д» или «н».\n'
                ;;
        esac
    done
}

if [[ ! -r /dev/tty || ! -w /dev/tty ]]; then
    error "Нужен интерактивный терминал."
    exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
    error "Для удаления нужны права администратора."
    printf 'Запустите: sudo bash uninstall.sh\n'
    exit 1
fi

printf '\nУдаление %s\n\n' "$PROGRAM_NAME"

if [[ ! -e "$INSTALL_PATH" && ! -L "$INSTALL_PATH" &&
      ! -e "$README_PATH" ]]; then
    info "Утилита не найдена по стандартным путям установки."
    exit 0
fi

printf 'Будут удалены:\n'

if [[ -e "$INSTALL_PATH" || -L "$INSTALL_PATH" ]]; then
    printf '  - %s\n' "$INSTALL_PATH"
fi

if [[ -e "$README_PATH" ]]; then
    printf '  - %s\n' "$README_PATH"
fi

printf '\n'
printf 'Не будут удалены:\n'
printf '  - ClamAV и другие установленные пакеты\n'
printf '  - резервные копии в %s\n' "$BACKUP_DIR"
printf '  - базы сигнатур и пользовательские данные\n\n'

if ! ask_yes_no "Вы действительно хотите удалить утилиту?"; then
    info "Удаление отменено."
    exit 0
fi

# Удаляем только файлы, относящиеся к этой утилите.
rm -f -- "$INSTALL_PATH"
rm -f -- "$README_PATH"

# Удаляем каталог документации, только если он теперь пуст.
rmdir "$DOC_DIR" 2>/dev/null || true

printf '\n'
info "Удаление завершено."
info "ClamAV, pv и резервные копии сохранены."