Systemd Service Manager
Description
This Bash script provides a simple menu-driven interface for managing Systemd services on Linux systems. It allows users to create, delete, restart services, reload Systemd configuration, and enable/disable auto-start for services.

Features
Create a new Systemd service with customizable description, executable path, and user.
Delete an existing service.
Restart a service.
Reload Systemd daemon.
Enable or disable auto-start for a service.
Requirements
Linux system with Systemd (e.g., Ubuntu, Fedora).
Bash shell.
Root privileges (uses sudo for Systemd operations).
Usage
Make the script executable:

chmod +x ssm.sh
Run the script:

./ssm.sh
Follow the on-screen menu to select an option.

Menu Options
1) Create service: Prompts for service name, description, executable path, and user. Optionally starts and enables the service.
2) Delete service: Stops, disables, and removes the service file.
3) Restart service: Restarts the specified service.
4) Reload systemd configuration: Reloads the Systemd daemon.
5) Enable auto-start: Enables auto-start for the specified service.
6) Disable auto-start: Disables auto-start for the specified service.
0) Exit: Exits the script.
Example
To create a service:

Select option 1.
Enter service name (e.g., myservice).
Enter description (e.g., My custom service).
Enter executable path (e.g., /path/to/script.sh).
Enter user (default: root).
Choose to start and enable if desired.
The service file will be created at /etc/systemd/system/myservice.service.

Notes
Services are created with a simple type, always restart policy, and after network target.
Ensure the executable path exists or confirm to proceed.
Error handling is basic; use with caution on production systems.
Менеджер служб Systemd
Описание
Этот Bash-скрипт предоставляет простой интерфейс с меню для управления службами Systemd в системах Linux. Он позволяет создавать, удалять, перезапускать службы, перезагружать конфигурацию Systemd и включать/отключать автозапуск для служб.

Возможности
Создание новой службы Systemd с настраиваемым описанием, путём к исполняемому файлу и пользователем.
Удаление существующей службы.
Перезапуск службы.
Перезагрузка демона Systemd.
Включение или отключение автозапуска для службы.
Требования
Система Linux с Systemd (например, Ubuntu, Fedora).
Оболочка Bash.
Права root (использует sudo для операций с Systemd).
Использование
Сделайте скрипт исполняемым:

chmod +x ssm.sh
Запустите скрипт:

./ssm.sh
Следуйте меню на экране для выбора опции.

Опции меню
1) Создать службу: Запрашивает имя службы, описание, путь к исполняемому файлу и пользователя. Опционально запускает и включает службу.
2) Удалить службу: Останавливает, отключает и удаляет файл службы.
3) Перезапустить службу: Перезапускает указанную службу.
4) Перезагрузить конфигурацию systemd: Перезагружает демон Systemd.
5) Включить автозапуск: Включает автозапуск для указанной службы.
6) Отключить автозапуск: Отключает автозапуск для указанной службы.
0) Выход: Выход из скрипта.
Пример
Для создания службы:

Выберите опцию 1.
Введите имя службы (например, myservice).
Введите описание (например, Моя кастомная служба).
Введите путь к исполняемому файлу (например, /path/to/script.sh).
Введите пользователя (по умолчанию: root).
Выберите запуск и включение, если нужно.
Файл службы будет создан в /etc/systemd/system/myservice.service.

Примечания
Службы создаются с типом simple.
Убедитесь, что путь к исполняемому файлу существует, или подтвердите продолжение.
Обработка ошибок базовая; используйте с осторожностью в продакшен-системах.