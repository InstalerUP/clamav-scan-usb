# clamav-scan-usb
Interactive scanning of USB drives using ClamAV.
> ❔ The readme file and the program's text-based interface itself are provided exclusively in Russian.

## Описание

Интерактивная Bash-утилита для проверки USB-накопителей с помощью ClamAV в Ubuntu и других Debian-подобных Linux-системах.

## Возможности

- Выбор раздела USB-накопителя в терминале.
- Проверка выбранного раздела с помощью ClamAV.
- Отображение прогресса сканирования.
- Работа с временным монтированием накопителя.
- Интерактивное завершение и обработка ошибок.

Перед использованием ознакомьтесь с исходным кодом и убедитесь, что он соответствует вашим требованиям безопасности.

## Требования

- Ubuntu или другая Debian-подобная система с `apt`.
- Bash.
- `curl` для скачивания файлов.
- ClamAV (`clamscan`).
- `pv` для отображения прогресса.
- Права администратора для установки и сканирования.

Установщик предложит установить отсутствующие пакеты `clamav` и `pv`.

## Установка

Скачайте установщик и просмотрите его перед запуском:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/InstalerUP/clamav-scan-usb/main/install.sh \
  -o /tmp/clamav-scan-usb-install.sh \
  && less /tmp/clamav-scan-usb-install.sh
```

После просмотра запустите установщик:

```bash
sudo bash /tmp/clamav-scan-usb-install.sh
```

Установщик запросит подтверждение, проверит необходимые компоненты и установит программу.

## Использование

Запустите утилиту:

```bash
sudo clamav-scan-usb
```

Следуйте инструкциям в терминале. Перед отключением USB-накопителя дождитесь завершения сканирования и корректного размонтирования.

## Обновление

Повторно скачайте установщик:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/InstalerUP/clamav-scan-usb/main/install.sh \
  -o /tmp/clamav-scan-usb-install.sh \
  && less /tmp/clamav-scan-usb-install.sh
```

После просмотра запустите его:

```bash
sudo bash /tmp/clamav-scan-usb-install.sh
```

Установщик обнаружит существующую версию и предложит обновление. Перед заменой он сохранит резервную копию скрипта.

## Удаление

Скачайте и просмотрите деинсталлятор:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/InstalerUP/clamav-scan-usb/main/uninstall.sh \
  -o /tmp/clamav-scan-usb-uninstall.sh \
  && less /tmp/clamav-scan-usb-uninstall.sh
```

Запустите его:

```bash
sudo bash /tmp/clamav-scan-usb-uninstall.sh
```

Удаление требует подтверждения. Утилита и её установленная документация будут удалены. ClamAV, `pv` и резервные копии останутся в системе.

## Пути установки

- Исполняемый файл: `/usr/local/bin/clamav-scan-usb`
- Документация: `/usr/local/share/doc/clamav-scan-usb/README.md`
- Резервные копии: `/var/backups/clamav-scan-usb/`

## Безопасность

- Сканирование монтирует флешку только для чтения.
- Установщик не запускает сканирование автоматически.
- Скачанные файлы проверяются перед установкой.
- При обновлении существующая версия сохраняется в резервной копии.
- Установка и удаление требуют прав администратора.
- Утилита не заменяет обновление вирусной базы ClamAV.
- Перед сканированием убедитесь, что выбрали правильный раздел накопителя.

## Лицензия

MIT License