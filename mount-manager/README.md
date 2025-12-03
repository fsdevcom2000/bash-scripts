## English

### Overview

This script is an interactive and safe tool for mounting ext4 partitions on Linux and automatically adding them to `/etc/fstab`.  
It provides a menu-based selection of devices, validates inputs, prevents duplicate fstab entries, checks mount point safety, and supports rollback if mounting fails.

### Features

- Automatic detection of ext4 partitions.
    
- Interactive menu for selecting a partition.
    
- Safe creation of mount points.
    
- Detection of non-empty mount directories.
    
- Duplicate protection for `/etc/fstab`.
    
- Backup and automatic rollback of `/etc/fstab` if an error occurs.
    
- Mounting the new partition immediately.
    
- Clear console output and straightforward logic.
    

### Requirements

- Linux system with ext4 partitions.
    
- Bash shell.
    
- Sudo privileges.
    
- `lsblk`, `blkid`, and coreutils available.
    

### Usage

    
1. Make this script executable:
    
    `chmod +x mount-manager.sh`
    
2. Run the script:
    
    `./mount-manager.sh`
    
3. Follow the interactive prompts:
    
    - Select a partition.
        
    - Enter or confirm a mount point.
        
    - Confirm if the mount point is not empty.
        
    - The script will update `/etc/fstab` and immediately mount the partition.
        

### What the script does

1. Lists ext4 partitions using `lsblk`.
    
2. Allows choosing one partition from a menu.
    
3. Obtains its UUID.
    
4. Creates a mount directory (if needed).
    
5. Verifies that `/etc/fstab` does not contain a duplicate entry.
    
6. Backs up `/etc/fstab`.
    
7. Appends the new entry in a safe format.
    
8. Mounts the selected device.
    
9. Shows a success message.
    

### Rollback behavior

If mounting fails, `/etc/fstab` is automatically restored from the backup file to prevent system boot issues.

### Notes

- The script modifies `/etc/fstab`. Use it carefully.
    
- Only ext4 partitions are supported.
    
- The script is intended for local servers, VPS systems, and administrative automation.
    

---

## Русский

### Обзор

Этот скрипт представляет собой интерактивный и безопасный инструмент для монтирования ext4-разделов в Linux и автоматического добавления их в `/etc/fstab`.  
Он предлагает выбор устройства через меню, проверяет ввод, защищает от дублей в fstab, проверяет безопасность точки монтирования и выполняет откат при ошибке.

### Возможности

- Автоматический поиск ext4-разделов.
    
- Интерактивное меню выбора.
    
- Безопасное создание точки монтирования.
    
- Проверка, пустая ли папка для монтирования.
    
- Защита от повторных записей в `/etc/fstab`.
    
- Резервная копия и автоматический откат при ошибке монтирования.
    
- Мгновенное монтирование выбранного раздела.
    
- Четкие сообщения и понятная логика.
    

### Требования

- Linux с ext4-разделами.
    
- Bash.
    
- Права sudo.
    
- Команды `lsblk`, `blkid`, coreutils.
    

### Использование

    
1. Сделайте скрипт исполняемым:
    
    `chmod +x mount-manager.sh`
    
2. Запустите:
    
    `./mount-manager.sh`
    
3. Следуйте инструкции:
    
    - Выберите раздел из списка.
        
    - Укажите точку монтирования.
        
    - Подтвердите, если папка непустая.
        
    - Скрипт добавит запись в `/etc/fstab` и смонтирует диск.
        

### Что делает скрипт

1. Показывает ext4-разделы через `lsblk`.
    
2. Даёт меню выбора.
    
3. Получает UUID выбранного раздела.
    
4. Создаёт директорию, если нужно.
    
5. Проверяет отсутствие дублей в `/etc/fstab`.
    
6. Создаёт резервную копию fstab.
    
7. Добавляет новую запись.
    
8. Монтирует раздел.
    
9. Выводит сообщение об успехе.
    

### Откат

Если монтирование не удалось, `/etc/fstab` автоматически восстанавливается из резервной копии, предотвращая проблемы при загрузке.

### Примечания

- Скрипт изменяет `/etc/fstab`. Используйте аккуратно.
    
- Поддерживаются только ext4-разделы.
    
- Подходит для серверов, VPS и автоматизации администрирования.