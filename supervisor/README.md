# SUPERVISOR-MANAGER

## Overview / Обзор

**English:**  
SUPERVISOR-MANAGER is an interactive bash script for managing Supervisor (a Linux process control system) configurations through a menu-driven interface. It simplifies the creation and deletion of Supervisor configurations, particularly for users unfamiliar with Supervisor's configuration syntax.

**Русский:**  
SUPERVISOR-MANAGER — интерактивный bash-скрипт для управления конфигурациями Supervisor (система управления процессами в Linux) через меню. Скрипт упрощает создание и удаление конфигурационных файлов, особенно для пользователей, не знакомых с синтаксисом Supervisor.

---

## Core Functionality / Основные функции

### 1. Dependency Check and Installation / Проверка и установка зависимостей
- **English:** Checks if Supervisor (`supervisorctl`) is installed. If not, prompts to install via `apt`. Verifies Supervisor service is running using `systemctl`.  
- **Русский:** Проверяет наличие Supervisor (`supervisorctl`). При отсутствии предлагает установить через `apt`. Проверяет, что служба Supervisor запущена через `systemctl`.

### 2. Configuration Creation (Menu Option 1) / Создание конфигурации (опция 1 в меню)
- **English:** Prompts the user for program name, configuration filename (without `.conf`), application directory, path to Python file (`.py`), autostart/autorestart settings, and run user (default: `root`).  
- **Русский:** Запрашивает имя программы, имя конфигурационного файла (без `.conf`), директорию приложения, путь к Python-файлу (`.py`), настройки автозапуска и автоматического перезапуска, пользователя для запуска (по умолчанию `root`).

**Creates / Создаёт:**
- Configuration file in `/etc/supervisor/conf.d/` / Конфигурационный файл в `/etc/supervisor/conf.d/`
- Log files in `/var/log/` (`.err.log` and `.out.log`) / Лог-файлы в `/var/log/` (`.err.log` и `.out.log`)
- Sets proper permissions for log files / Настраивает права доступа к логам

**Automatic actions / Автоматические действия после создания:**
- Reloads Supervisor configuration (`reread`, `update`) / Перезагружает конфигурацию Supervisor
- Starts the program / Запускает программу

### 3. Configuration Deletion (Menu Option 2) / Удаление конфигурации (опция 2 в меню)
- **English:** Lists all configs from `/etc/supervisor/conf.d/`, shows each program's status via `supervisorctl status`, allows selecting a config for deletion, stops the program before deletion, and offers to delete associated log files.  
- **Русский:** Показывает список всех конфигов из `/etc/supervisor/conf.d/`, отображает статус каждой программы через `supervisorctl status`, позволяет выбрать конфиг для удаления, останавливает программу перед удалением и предлагает удалить связанные лог-файлы.

### 4. Implementation Details / Особенности реализации
- **English:** Uses `sudo` for root-required commands, creates config as a temporary file and moves it to target directory, automatically removes temp files on exit (`trap cleanup EXIT`), validates directories, files, and users, and detects Python 3 in the system.  
- **Русский:** Использует `sudo` для команд, требующих прав root, создаёт временный файл для конфига, затем перемещает в целевую директорию, автоматически удаляет временные файлы при выходе (`trap cleanup EXIT`), проверяет существование директорий, файлов и пользователей, ищет `python3` в системе.

---

## Example Supervisor Configuration / Пример конфигурации Supervisor

```ini
[program:program_name]
command=python3 /path/to/file.py
directory=/working/directory
autostart=true/false
autorestart=true/false
stderr_logfile=/var/log/name.err.log
stdout_logfile=/var/log/name.out.log
user=username
redirect_stderr=true
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=5
```


System Requirements / Требования к системе

English:

Linux system with systemd support
Access to apt for package installation
Superuser privileges (via sudo)
Python 3 (for running Python scripts)

Русский:

Linux-система с поддержкой systemd
Доступ к apt для установки пакетов
Права суперпользователя (через sudo)
Python 3 (для запуска Python-скриптов)