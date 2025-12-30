# Cron Manager Script

A professional interactive Bash script to manage cron jobs.  
Supports adding, listing, editing, removing tasks, and using predefined templates. Logs all actions.

---

## Features

- Interactive menu for managing cron jobs
- CLI mode with `--cmd`, `--cron`, and `--comment` options
- Add, edit, remove cron tasks
- Support for task comments
- Templates for common schedules (every 5 minutes, daily, weekdays, etc.)
- Logging of all actions to `$HOME/cron_manager.log`

---

## Installation

1. Clone the repository or copy the `cron_manager.sh` script to your system.
2. Make the script executable:

```bash
chmod +x cron_manager.sh
```

3. Run the script:

`./cron_manager.sh`

---

## Usage

### Interactive Mode

Run the script without arguments to start the menu:

`./cron_manager.sh`

Menu options:

1. **Add task** – add a new cron task interactively
    
2. **List tasks** – show current cron jobs with line numbers
    
3. **Remove task** – remove a task by its line number (deletes comment if exists)
    
4. **Edit task** – edit an existing task
    
5. **Add template task** – choose a predefined schedule template
    
6. **Exit** – quit the script

### CLI Mode

Add a task via command line:

```bash
./cron_manager.sh add --cmd "/usr/bin/python3 /opt/backup.py" --cron "*/5 * * * *" --comment "Backup every 5 minutes"
```

Other CLI commands:

```bash
./cron_manager.sh list 
./cron_manager.sh remove 3 
./cron_manager.sh edit 2 
./cron_manager.sh template daily_3am
```

### Templates

Available templates:

| Template Name      | Cron Schedule  | Description                |
| ------------------ | -------------- | -------------------------- |
| every_5_min        | `*/5 * * * *`  | Every 5 minutes            |
| every_15_min       | `*/15 * * * *` | Every 15 minutes           |
| every_hour         | `0 * * * *`    | Every hour                 |
| daily_3am          | `0 3 * * *`    | Daily at 3 AM              |
| daily_6am          | `0 6 * * *`    | Daily at 6 AM              |
| daily_noon         | `0 12 * * *`   | Daily at 12 PM             |
| daily_midnight     | `0 0 * * *`    | Daily at midnight          |
| weekdays_9am       | `0 9 * * 1-5`  | Monday–Friday at 9 AM      |
| weekdays_5pm       | `0 17 * * 1-5` | Monday–Friday at 5 PM      |
| weekends_10am      | `0 10 * * 6,7` | Saturday & Sunday at 10 AM |
| monday_8am         | `0 8 * * 1`    | Every Monday at 8 AM       |
| friday_6pm         | `0 18 * * 5`   | Every Friday at 6 PM       |
| first_day_of_month | `0 0 1 * *`    | First day of each month    |
| every_10_min       | `*/10 * * * *` | Every 10 minutes           |
| every_30_min       | `*/30 * * * *` | Every 30 minutes           |

---

### Logging

All actions are logged to:

`cron_manager.log`

---

## Notes

- Ensure the script is run with the same user whose crontab you want to manage.
    
- Commands must be full paths (`/usr/bin/python3 /opt/backup.py`).
    
- Editing/removing tasks requires the line number displayed in the **List tasks** menu.
    

---

# Русский / Russian

## Скрипт Cron Manager

Интерактивный Bash-скрипт для управления задачами cron.  
Поддерживает добавление, просмотр, редактирование, удаление задач и использование шаблонов. Все действия логируются.

---

## Возможности

- Интерактивное меню для управления cron
    
- Режим CLI с опциями `--cmd`, `--cron`, `--comment`
    
- Добавление, редактирование, удаление задач
    
- Поддержка комментариев к задачам
    
- Шаблоны для стандартных расписаний
    
- Логирование всех действий в `cron_manager.log`
    

---

## Установка

1. Скопируйте скрипт `cron_manager.sh` или клонируйте репозиторий.
    
2. Сделайте скрипт исполняемым:
    

`chmod +x cron_manager.sh`

3. Запуск скрипта:
    

`./cron_manager.sh`

---

## Использование

### Интерактивный режим

Запуск без аргументов:

`./cron_manager.sh`

Меню:

1. **Add task** – добавить новую задачу
    
2. **List tasks** – показать текущие задачи cron с номерами строк
    
3. **Remove task** – удалить задачу по номеру строки (удаляет комментарий, если есть)
    
4. **Edit task** – редактировать существующую задачу
    
5. **Add template task** – выбрать шаблон расписания
    
6. **Exit** – выход
    

---

### CLI режим

Добавление задачи через командную строку:

```bash
./cron_manager.sh add --cmd "/usr/bin/python3 /opt/backup.py" --cron "*/5 * * * *" --comment "Резервное копирование каждые 5 минут"
```

Другие команды:

```bash
./cron_manager.sh list 
./cron_manager.sh remove 3 
./cron_manager.sh edit 2 
./cron_manager.sh template daily_3am
```

---

### Шаблоны

Доступные шаблоны:

|Имя шаблона|Расписание|Описание|
|---|---|---|
|every_5_min|`*/5 * * * *`|Каждые 5 минут|
|every_15_min|`*/15 * * * *`|Каждые 15 минут|
|every_hour|`0 * * * *`|Каждый час|
|daily_3am|`0 3 * * *`|Ежедневно в 3:00|
|daily_6am|`0 6 * * *`|Ежедневно в 6:00|
|daily_noon|`0 12 * * *`|Ежедневно в 12:00|
|daily_midnight|`0 0 * * *`|Ежедневно в полночь|
|weekdays_9am|`0 9 * * 1-5`|Пн–Пт в 9:00|
|weekdays_5pm|`0 17 * * 1-5`|Пн–Пт в 17:00|
|weekends_10am|`0 10 * * 6,7`|Сб–Вс в 10:00|
|monday_8am|`0 8 * * 1`|Каждый понедельник в 8:00|
|friday_6pm|`0 18 * * 5`|Каждая пятница в 18:00|
|first_day_of_month|`0 0 1 * *`|Первый день месяца|
|every_10_min|`*/10 * * * *`|Каждые 10 минут|
|every_30_min|`*/30 * * * *`|Каждые 30 минут|

---

### Логирование

Все действия сохраняются в:

`cron_manager.log`

---

## Примечания

- Скрипт должен запускаться от пользователя, чей crontab управляется.
    
- Команды должны быть полными путями (`/usr/bin/python3 /opt/backup.py`).
    
- Для редактирования/удаления используйте номера строк из меню **List tasks**.
    
