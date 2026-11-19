# Xeoma on Ubuntu Server: installation and graphical autostart

English | [Русский](https://claude.ai/chat/ca92efb6-638b-4b47-83c1-f7c6db78e88c#%D1%80%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9)

A script that installs Xeoma and configures it to start in graphical mode on Ubuntu Server without a desktop environment. After a reboot the system logs in to the console automatically, starts Xorg with a minimal window manager (Openbox) and launches the Xeoma client in fullscreen mode.

## Features

- Installs Xorg, Xinit and Openbox.
- Downloads and installs Xeoma, installs the Xeoma core service (`-install -coreauto`).
- Creates `~/.xinitrc` to start Openbox and the Xeoma client in fullscreen.
- Configures autologin on tty1 and `startx` autostart via `~/.profile`.
- Minimal graphical environment, no full desktop. Console stays available via Ctrl+Alt+F2, F3, etc.
- Safe to re-run: the `.profile` block is not duplicated; `.xinitrc` and `override.conf` are backed up before being changed (`*.bak.<timestamp>`, only if content differs).
- Asks before reinstalling over an existing Xeoma and before stopping a running one (SIGKILL is used only if a graceful stop fails, and is logged).
- Optional SHA256 check of the downloaded archive; download retries and timeouts.
- Log file: `/var/log/xeoma-install.log`.

## Requirements

- Ubuntu Server 18.04 (target system); other Debian/Ubuntu releases with systemd and apt are not verified.
- Root access.
- An existing user account that will run Xeoma.

## Installation

1. Download the script.
    
2. Make it executable:
    
    ```bash
    chmod +x install_xeoma_autostart.sh
    ```
    
3. Run as root:
    
    ```bash
    sudo ./install_xeoma_autostart.sh
    ```
    
    The username is requested interactively, or pass it with `-u`.
    
4. Reboot:
    
    ```bash
    reboot
    ```
    

### Options

```bash
sudo ./install_xeoma_autostart.sh [-u USER] [-y] [-h]
```

|Option|Description|
|---|---|
|`-u USER`|User that will run Xeoma (prompted if omitted)|
|`-y`|Non-interactive mode, answer "yes" to all questions|
|`-h`|Show help|

### Environment variables

|Variable|Description|
|---|---|
|`XEOMA_URL`|Override the download URL (default: Xeoma build from 2018-06-14)|
|`XEOMA_SHA256`|If set, the downloaded archive is verified against this checksum|

Example:

```bash
sudo XEOMA_URL="<url>" XEOMA_SHA256="<sha256>" ./install_xeoma_autostart.sh -u myuser -y
```

## What happens after reboot

- The system logs in automatically as the selected user on tty1.
- `~/.profile` runs `startx`.
- Xorg starts with Openbox.
- The Xeoma client opens in fullscreen mode.
- Other virtual terminals (Ctrl+Alt+F2 etc.) remain available.

## Retrieving the Xeoma password

To get the password for connecting from a remote Xeoma client:

```bash
~/Xeoma/xeoma.app -showpassword
```

## Editing configuration

- Startup script: `~/.xinitrc`
- Autostart condition: `~/.profile` (block between `# >>> xeoma-autostart >>>` and `# <<< xeoma-autostart <<<`)
- Autologin settings: `/etc/systemd/system/getty@tty1.service.d/override.conf`

## Notes

- Autologin on tty1 gives console access without a password: acceptable for a kiosk, keep physical access in mind.
- If the Xeoma client exits, the X session ends and autologin restarts it (intended kiosk behavior).
- If `~/.bash_profile` or `~/.bash_login` exists, bash ignores `~/.profile`; the script warns about this and the `startx` block must then be added to that file manually.
- Without `XEOMA_SHA256` the integrity of the archive is not verified (the script prints a warning).

## Extras

### Network setup script `setup-network.sh`

Interactive Bash script for initial network configuration on Ubuntu Server 18.04, run from the local console. Assigns static IPv4 addresses to physical Ethernet interfaces via Netplan: no DHCP, gateway, DNS or IPv6. Backs up the existing config and rolls back automatically on failure.

---

# Русский

# Xeoma на Ubuntu Server: установка и автозапуск в графическом режиме

Скрипт устанавливает Xeoma и настраивает его запуск в графическом режиме на Ubuntu Server без полноценного рабочего стола. После перезагрузки система автоматически входит в консоль, запускает Xorg с минимальным оконным менеджером (Openbox) и стартует клиент Xeoma в полноэкранном режиме.

## Возможности

- Установка Xorg, Xinit и Openbox.
- Загрузка и установка Xeoma, установка службы Xeoma core (`-install -coreauto`).
- Создание `~/.xinitrc`: запуск Openbox и клиента Xeoma в полноэкранном режиме.
- Автологин на tty1 и автозапуск `startx` через `~/.profile`.
- Минимальное графическое окружение без рабочего стола. Консоль доступна через Ctrl+Alt+F2, F3 и т. д.
- Безопасен при повторном запуске: блок в `.profile` не дублируется; `.xinitrc` и `override.conf` перед изменением копируются в бэкап (`*.bak.<timestamp>`, только если содержимое отличается).
- Спрашивает подтверждение перед переустановкой поверх существующего Xeoma и перед остановкой запущенного (SIGKILL применяется только если штатная остановка не удалась, и пишется в лог).
- Опциональная проверка SHA256 скачанного архива; ретраи и таймауты при загрузке.
- Лог: `/var/log/xeoma-install.log`.

## Требования

- Ubuntu Server 18.04 (целевая система); другие версии Debian/Ubuntu с systemd и apt не проверялись.
- Root-доступ.
- Существующий пользователь, от имени которого будет работать Xeoma.

## Установка

1. Скачайте скрипт.
    
2. Сделайте его исполняемым:
    
    ```bash
    chmod +x install_xeoma_autostart.sh
    ```
    
3. Запустите от root:
    
    ```bash
    sudo ./install_xeoma_autostart.sh
    ```
    
    Имя пользователя запрашивается интерактивно или передаётся через `-u`.
    
4. Перезагрузите систему:
    
    ```bash
    reboot
    ```
    

### Параметры

```bash
sudo ./install_xeoma_autostart.sh [-u USER] [-y] [-h]
```

|Параметр|Описание|
|---|---|
|`-u USER`|Пользователь, от которого запускается Xeoma (если не указан, будет запрос)|
|`-y`|Неинтерактивный режим, на все вопросы «yes»|
|`-h`|Справка|

### Переменные окружения

|Переменная|Описание|
|---|---|
|`XEOMA_URL`|Переопределить ссылку на загрузку (по умолчанию сборка Xeoma от 2018-06-14)|
|`XEOMA_SHA256`|Если задана, архив проверяется по этой контрольной сумме|

Пример:

```bash
sudo XEOMA_URL="<url>" XEOMA_SHA256="<sha256>" ./install_xeoma_autostart.sh -u myuser -y
```

## Что произойдёт после перезагрузки

- Система автоматически войдёт под выбранным пользователем на tty1.
- Из `~/.profile` будет выполнена команда `startx`.
- Запустится Xorg с Openbox.
- Клиент Xeoma откроется в полноэкранном режиме.
- Остальные виртуальные терминалы (Ctrl+Alt+F2 и т. д.) останутся доступны.

## Просмотр пароля Xeoma

Пароль для подключения с удалённого клиента Xeoma:

```bash
~/Xeoma/xeoma.app -showpassword
```

## Изменение конфигурации

- Скрипт запуска графики: `~/.xinitrc`
- Условие автозапуска: `~/.profile` (блок между `# >>> xeoma-autostart >>>` и `# <<< xeoma-autostart <<<`)
- Настройки автологина: `/etc/systemd/system/getty@tty1.service.d/override.conf`

## Примечания

- Автологин на tty1 даёт доступ к консоли без пароля: для киоска допустимо, но учитывайте физический доступ.
- Если клиент Xeoma завершится, завершится и X-сессия, а автологин запустит всё заново (так и задумано для киоска).
- Если существует `~/.bash_profile` или `~/.bash_login`, bash игнорирует `~/.profile`; скрипт предупредит об этом, и блок `startx` нужно будет добавить в этот файл вручную.
- Без `XEOMA_SHA256` целостность архива не проверяется (скрипт выводит предупреждение).

## Дополнительно

### Скрипт настройки сети `setup-network.sh`

Интерактивный Bash-скрипт для первичной настройки сети на Ubuntu Server 18.04, запускается с локальной консоли. Назначает статические IPv4-адреса физическим Ethernet-интерфейсам через Netplan: без DHCP, шлюза, DNS и IPv6. Делает резервную копию и автоматически откатывается при ошибке.
