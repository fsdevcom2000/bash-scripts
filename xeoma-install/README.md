# Installing Xeoma on Ubuntu Server 18.04 and Configuring Autostart in Graphical Mode

This project provides a fully automated script for installing and configuring Xeoma to start in graphical mode on Ubuntu Server 18.04 without a desktop environment.  
The system automatically logs in to the console, launches Xorg with a minimal window manager, and starts the Xeoma client in fullscreen mode.

## Features

- Automatic installation of Xorg, Openbox, and Xinit.
    
- Automated download and installation of Xeoma.
    
- Xeoma core service installation.
    
- Configuration of .xinitrc for GUI autostart.
    
- Autologin setup on tty1.
    
- Automatic execution of startx.
    
- Minimal graphical environment with no full desktop.
    
- Console access via Ctrl+Alt+F2, F3, etc.
    

## Requirements

- Ubuntu Server 18.04
    
- Root access
    
- User account "vmadmin" (can be changed in the script install_xeoma_autostart.sh)

- The script no longer requires manually specifying the user. In version 2 (install_xeoma_autostart_v2.sh), the username will be requested automatically during execution.

## Installation

1. Download the installation script:
    
2. Make it executable:
    
    ```
    chmod +x install_xeoma_autostart.sh
    ```
    
3. Run as root:
    
    ```
    sudo ./install_xeoma_autostart.sh
    ```
4. After installation, reboot the system:
    
    ```
    reboot
    ```
    

## What Happens After Reboot

- The system automatically logs in as user `$USER` on tty1.
    
- `.profile` triggers `startx`.
    
- Xorg starts with Openbox.
    
- Xeoma client launches in fullscreen mode.
    
- Console remains accessible via Ctrl+Alt+F2 and other virtual terminals.
    

## Retrieving the Xeoma Password

To view the password for connecting from a remote Xeoma client, run:

```
/home/$USER/Xeoma/xeoma.app -showpassword
```
## Editing Configuration

If you need to modify the launch behavior, edit:

- Startup script: `/home/$USER/.xinitrc`
    
- Autostart condition: `/home/$USER/.profile`
    
- Autologin settings: `/etc/systemd/system/getty@tty1.service.d/override.conf`
    

## Extras
### Network Setup Script `setup-network.sh`

Interactive Bash script for initial network configuration on Ubuntu Server 18.04, run from the local console. Assigns static IPv4 addresses to physical Ethernet interfaces via Netplan — no DHCP, gateway, DNS or IPv6. Backs up the existing config and rolls back automatically on failure.

# Version 3.0

## Usage


```bash
sudo ./install_xeoma_autostart_v3.sh [-u USER] [-y] [-h]
```

|Option|Description|
|---|---|
|`-u USER`|User that will run Xeoma (prompted if omitted)|
|`-y`|Non-interactive mode, answer "yes" to all questions|
|`-h`|Show help|

|Environment variable|Description|
|---|---|
|`XEOMA_URL`|Override the download URL (default: Xeoma build from 2018-06-14)|
|`XEOMA_SHA256`|If set, the downloaded archive is verified against this checksum|

Requirements: root, systemd, apt. Log: `/var/log/xeoma-install.log`. After installation: `reboot`. Client password: `~/Xeoma/xeoma.app -showpassword`.

## Changes compared to v2

**Reliability**

- `set -Eeuo pipefail`; `trap` reports the failing line and cleans up the temp directory.
- Log written to `/var/log/xeoma-install.log`.
- Warning if the Xeoma core binary is not found after installation.

**Idempotency and safety**

- The `.profile` block is wrapped in markers and no longer duplicated on re-runs.
- Backups of `.xinitrc` and `override.conf` before overwriting (only if content differs).
- Warning if `~/.bash_profile` or `~/.bash_login` exists (bash ignores `~/.profile` then).
- Processes are stopped gracefully first; SIGKILL is used only if needed and is logged.

**Download**

- `mktemp` instead of fixed `/tmp` paths; retries and timeouts for `wget`.
- Archive contents checked; optional SHA256 verification.
- URL can be overridden via `XEOMA_URL`.

**Automation**

- Options `-u`, `-y`, `-h`; no hanging on `read` without a terminal.

**Fixes**

- `systemctl daemon-reexec` → `daemon-reload`.
- Home directory taken via `getent passwd` instead of `/home/$USER`.
- Paths quoted; `DEBIAN_FRONTEND=noninteractive` and `--no-install-recommends` for apt.
- Clearer final message for the client password command; correct script name in usage.

## Notes

- Autologin on tty1 gives console access without a password: acceptable for a kiosk, keep physical access in mind.
- If the Xeoma client exits, the X session ends and autologin restarts it (intended kiosk behavior).
- Test on a non-production machine before rollout.
---

# Автоматическая установка и автозапуск Xeoma в графическом режиме на Ubuntu Server 18.04

Этот проект содержит полностью автоматизированный скрипт для установки и настройки Xeoma, который запускается в графическом режиме на сервере Ubuntu 18.04 без полноценного рабочего стола.  
Система автоматически входит в консоль, запускает Xorg с минимальным оконным менеджером и автоматически стартует клиент Xeoma в полноэкранном режиме.

## Возможности

- Автоматическая установка Xorg, Openbox и Xinit.
    
- Автоматическая загрузка и установка Xeoma.
    
- Установка Xeoma в режиме core service.
    
- Настройка `.xinitrc` для автозапуска графики.
    
- Настройка автологина на tty1.
    
- Автоматический запуск `startx`.
    
- Минимальное графическое окружение без рабочего стола.
    
- Доступ к консоли через Ctrl+Alt+F2, F3 и другие терминалы.
    

## Требования

- Ubuntu Server 18.04
    
- Root-доступ
    
- Пользователь "vmadmin" (можно изменить в скрипте install_xeoma_autostart.sh)

- В версии 2 (install_xeoma_autostart_v2.sh) скрипт больше не требует ручного изменения пользователя. Имя пользователя будет запрошено автоматически при выполнении.

## Установка

1. Скачайте скрипт:
    
2. Сделайте его исполняемым:
    
    ```
    chmod +x install_xeoma_autostart.sh
    ```
    
3. Запустите от root:
    
    ```
    sudo ./install_xeoma_autostart.sh
    ```
    
4. После завершения перезагрузите систему:
    
    ```
    reboot
    ```
    

## Что произойдет после перезагрузки

- Система автоматически войдет под пользователем `$USER` на tty1.
    
- Из `.profile` будет выполнена команда `startx`.
    
- Запустится Xorg с Openbox.
    
- Клиент Xeoma откроется в полноэкранном режиме.
    
- Консоль останется доступной через Ctrl+Alt+F2 и другие виртуальные терминалы.
    

## Просмотр пароля Xeoma

Для отображения пароля подключения запустите:

`/home/$USER/Xeoma/xeoma.app -showpassword`

## Изменение конфигурации

При необходимости можно изменить следующие файлы:

- Скрипт запуска графики: `/home/$USER/.xinitrc`
    
- Условие автозапуска: `/home/$USER/.profile`
- Настройки автологина: `/etc/systemd/system/getty@tty1.service.d/override.conf`


## Дополнительно
### Скрипт настройки сети `setup-network.sh`

Интерактивный Bash-скрипт для первичной настройки сети на Ubuntu Server 18.04, запускается с локальной консоли. Назначает статические IPv4-адреса физическим Ethernet-интерфейсам через Netplan — без DHCP, шлюза, DNS и IPv6. Делает резервную копию и автоматически откатывается при ошибке.

# Версия 3.0

## Использование

```bash
sudo ./install_xeoma_autostart_v3.sh [-u USER] [-y] [-h]
```

|Параметр|Описание|
|---|---|
|`-u USER`|Пользователь, от которого запускается Xeoma (если не указан, будет запрос)|
|`-y`|Неинтерактивный режим, на все вопросы «yes»|
|`-h`|Справка|

|Переменная окружения|Описание|
|---|---|
|`XEOMA_URL`|Переопределить ссылку на загрузку (по умолчанию сборка Xeoma от 2018-06-14)|
|`XEOMA_SHA256`|Если задана, архив проверяется по этой контрольной сумме|

Требования: root, systemd, apt. Лог: `/var/log/xeoma-install.log`. После установки: `reboot`. Пароль клиента: `~/Xeoma/xeoma.app -showpassword`.

## Изменения по сравнению с v2

**Надёжность**

- `set -Eeuo pipefail`; `trap` показывает строку с ошибкой и удаляет временный каталог.
- Лог в `/var/log/xeoma-install.log`.
- Предупреждение, если бинарник ядра Xeoma не найден после установки.

**Идемпотентность и безопасность**

- Блок в `.profile` обёрнут в маркеры и не дублируется при повторных запусках.
- Бэкапы `.xinitrc` и `override.conf` перед перезаписью (только если содержимое отличается).
- Предупреждение, если есть `~/.bash_profile` или `~/.bash_login` (тогда bash игнорирует `~/.profile`).
- Процессы сначала останавливаются штатно; SIGKILL применяется только при необходимости и пишется в лог.

**Загрузка**

- `mktemp` вместо фиксированных путей в `/tmp`; ретраи и таймауты у `wget`.
- Проверка содержимого архива; опциональная проверка SHA256.
- Ссылку можно переопределить через `XEOMA_URL`.

**Автоматизация**

- Параметры `-u`, `-y`, `-h`; скрипт не зависает на `read` без терминала.

**Исправления**

- `systemctl daemon-reexec` -> `daemon-reload`.
- Домашний каталог определяется через `getent passwd`, а не `/home/$USER`.
- Пути в кавычках; для apt добавлены `DEBIAN_FRONTEND=noninteractive` и `--no-install-recommends`.
- Понятное финальное сообщение про команду показа пароля; верное имя скрипта в справке.

## Примечания

- Автологин на tty1 даёт доступ к консоли без пароля: для киоска допустимо, но учитывайте физический доступ.
- Если клиент Xeoma завершится, завершится и X-сессия, а автологин запустит всё заново (так и задумано для киоска).
    




