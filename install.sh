#!/usr/bin/env bash
set -Eeuo pipefail

# Установщик clamav-scan-usb.
# Репозиторий должен быть публичным, а основная ветка называться main.

REPO_OWNER="InstalerUP"
REPO_NAME="clamav-scan-usb"
BRANCH="main"

BASE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"

PROGRAM_NAME="clamav-scan-usb"
INSTALL_PATH="/usr/local/bin/${PROGRAM_NAME}"
DOC_DIR="/usr/local/share/doc/${PROGRAM_NAME}"
BACKUP_DIR="/var/backups/${PROGRAM_NAME}"

# Цвета сообщений (если терминал их поддерживает).
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

# Запрашиваем ответ именно с терминала.
# Это позволяет задавать вопросы, даже если установщик был скачан в файл.
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

# Установщик должен запускаться в интерактивном терминале.
if [[ ! -r /dev/tty || ! -w /dev/tty ]]; then
    error "Нужен интерактивный терминал."
    error "Запустите установщик из обычного терминала."
    exit 1
fi

# Проверяем права администратора.
if [[ "$EUID" -ne 0 ]]; then
    error "Для установки нужны права администратора."
    printf 'Запустите: sudo bash install.sh\n'
    exit 1
fi

# Проверяем, что это Debian/Ubuntu-подобная система.
if [[ ! -x /usr/bin/apt-get ]]; then
    error "Этот установщик рассчитан на системы с apt, например Ubuntu."
    exit 1
fi

# curl нужен для скачивания файлов.
if ! command -v curl >/dev/null 2>&1; then
    error "Не найден curl, необходимый для скачивания файлов."
    printf 'Установите его командой: apt-get install curl\n'
    exit 1
fi

# Не допускаем случайного использования незаполненного шаблона.
if [[ "$REPO_OWNER" == "YOUR_GITHUB_USERNAME" ]]; then
    error "В install.sh не указан владелец репозитория."
    error "Замените YOUR_GITHUB_USERNAME на свой логин GitHub."
    exit 1
fi

printf '\n'
printf 'Установка %s\n' "$PROGRAM_NAME"
printf 'Источник: %s\n\n' "$BASE_URL"

if ! ask_yes_no "Продолжить установку или обновление?"; then
    info "Установка отменена."
    exit 0
fi

# Проверяем необходимые программе пакеты.
missing_packages=()

if ! command -v clamscan >/dev/null 2>&1; then
    missing_packages+=("clamav")
fi

if ! command -v pv >/dev/null 2>&1; then
    missing_packages+=("pv")
fi

# Устанавливаем только отсутствующие пакеты и только с согласия пользователя.
if ((${#missing_packages[@]} > 0)); then
    printf '\nНе найдены необходимые пакеты: %s\n' "${missing_packages[*]}"

    if ! ask_yes_no "Установить их через apt?"; then
        error "Без необходимых пакетов установка утилиты отменена."
        exit 1
    fi

    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing_packages[@]}"
else
    info "Необходимые пакеты ClamAV и pv уже установлены."
fi

# Временный каталог удалится после завершения установщика.
TMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TMP_DIR"' EXIT

SCRIPT_TMP="${TMP_DIR}/${PROGRAM_NAME}"
README_TMP="${TMP_DIR}/README.md"

info "Скачивание скрипта с GitHub..."

if ! curl --fail --location --silent --show-error \
    "${BASE_URL}/${PROGRAM_NAME}" -o "$SCRIPT_TMP"; then
    error "Не удалось скачать основной скрипт."
    error "Проверьте имя репозитория, ветку и доступность GitHub."
    exit 1
fi

# Проверяем, что файл действительно похож на Bash-скрипт.
if ! IFS= read -r first_line < "$SCRIPT_TMP" ||
   [[ "$first_line" != "#!/usr/bin/env bash" &&
      "$first_line" != "#!/bin/bash" ]]; then
    error "У скачанного файла отсутствует ожидаемый Bash shebang."
    error "Установка остановлена; существующая версия не изменена."
    exit 1
fi

# Проверяем синтаксис до установки.
if ! bash -n "$SCRIPT_TMP"; then
    error "В скачанном скрипте обнаружена синтаксическая ошибка."
    error "Установка остановлена; существующая версия не изменена."
    exit 1
fi

# README нужен для локальной документации; его отсутствие не блокирует установку.
if ! curl --fail --location --silent --show-error \
    "${BASE_URL}/README.md" -o "$README_TMP"; then
    warn "README.md скачать не удалось; программа всё равно будет установлена."
    rm -f -- "$README_TMP"
fi

# Если программа уже установлена, сначала сохраняем резервную копию.
if [[ -e "$INSTALL_PATH" || -L "$INSTALL_PATH" ]]; then
    info "Обнаружена существующая установка."

    if ! ask_yes_no "Заменить её новой версией?"; then
        info "Обновление отменено."
        exit 0
    fi

    if [[ ! -f "$INSTALL_PATH" || -L "$INSTALL_PATH" ]]; then
        error "Путь установки существует, но это не обычный файл."
        error "Автоматическая замена небезопасна."
        exit 1
    fi

    if ! head -n 1 "$INSTALL_PATH" | grep -Eq '^#!/(usr/bin/env bash|bin/bash)$'; then
        error "Существующий файл не похож на ожидаемый Bash-скрипт."
        error "Он не будет перезаписан автоматически."
        exit 1
    fi

    mkdir -p "$BACKUP_DIR"
    BACKUP_PATH="${BACKUP_DIR}/${PROGRAM_NAME}-$(date +%Y%m%d-%H%M%S)"
    cp -p -- "$INSTALL_PATH" "$BACKUP_PATH"
    info "Резервная копия сохранена: $BACKUP_PATH"
fi

# Сначала готовим файлы во временном каталоге назначения.
# Затем перемещаем проверенный скрипт на место.
install -d -m 755 "$(dirname "$INSTALL_PATH")"
install -d -m 755 "$DOC_DIR"

install -m 755 "$SCRIPT_TMP" "${INSTALL_PATH}.new"
mv -f -- "${INSTALL_PATH}.new" "$INSTALL_PATH"

if [[ -f "$README_TMP" ]]; then
    install -m 644 "$README_TMP" "${DOC_DIR}/README.md"
fi

printf '\n'
info "Установка завершена."
printf 'Команда запуска: sudo %s\n' "$PROGRAM_NAME"
printf 'Путь программы:  %s\n' "$INSTALL_PATH"
printf 'Документация:    %s\n' "$DOC_DIR/README.md"
printf '\n'
warn "Перед использованием убедитесь, что база ClamAV обновлена."