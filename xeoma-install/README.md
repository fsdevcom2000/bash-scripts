# Automated Installation and Autostart of Xeoma in Graphical Mode on Ubuntu Server 18.04

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
    
1. Make it executable:
    
    ```
    chmod +x install_xeoma_autostart.sh
    ```
    
1. Run as root:
    
    ```
    sudo ./install_xeoma_autostart.sh
    ```
1. After installation, reboot the system:
    
    ```
    reboot
    ```
    

## What Happens After Reboot

- The system automatically logs in as user `vmadmin` on tty1.
    
- `.profile` triggers `startx`.
    
- Xorg starts with Openbox.
    
- Xeoma client launches in fullscreen mode.
    
- Console remains accessible via Ctrl+Alt+F2 and other virtual terminals.
    

## Retrieving the Xeoma Password

To view the password for connecting from a remote Xeoma client, run:

```
/home/vmadmin/Xeoma/xeoma.app -showpassword
```
## Editing Configuration

If you need to modify the launch behavior, edit:

- Startup script: `/home/vmadmin/.xinitrc`
    
- Autostart condition: `/home/vmadmin/.profile`
    
- Autologin settings: `/etc/systemd/system/getty@tty1.service.d/override.conf`
    

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

- Система автоматически войдет под пользователем `vmadmin` на tty1.
    
- Из `.profile` будет выполнена команда `startx`.
    
- Запустится Xorg с Openbox.
    
- Клиент Xeoma откроется в полноэкранном режиме.
    
- Консоль останется доступной через Ctrl+Alt+F2 и другие виртуальные терминалы.
    

## Просмотр пароля Xeoma

Для отображения пароля подключения запустите:

`/home/vmadmin/Xeoma/xeoma.app -showpassword`

## Изменение конфигурации

При необходимости можно изменить следующие файлы:

- Скрипт запуска графики: `/home/vmadmin/.xinitrc`
    
- Условие автозапуска: `/home/vmadmin/.profile`
    

- Настройки автологина: `/etc/systemd/system/getty@tty1.service.d/override.conf`


