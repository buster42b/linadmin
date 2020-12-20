# Часть 1
## 1. Создать нескольких пользователей, задать им пароли, домашние директории и шеллы.
Для создания пользователя используется команда **useradd** с ключами -d ( directory ) для указания директории и -s ( shell ) для указания пути до оболочки - bash, Zsh и т.д. - `sudo useradd -d /home/Dirname -s /path/to/shell Username`.
для добавления пароля используется команда **passwd** `sudo passwd Username`, после чего вводим и повторяем пароль (возможно сообщение о недостаточной сложности пароля, но оно не блокирует его использование если не созданы соответствующие политики).

![](https://raw.githubusercontent.com/buster42b/linadmin/main/lab3/Снимок%20экрана%20от%202020-12-21%2000-16-42.png)

Производим те же действия для создания ещё нескольких пользователей:

![](https://raw.githubusercontent.com/buster42b/linadmin/main/lab3/Снимок%20экрана%20от%202020-12-21%2000-20-33.png)

## 2. Создать группу **admin** и добавить в неё нескольких пользователей и пользователя root 
Создание группы производится практически аналогичной командой **groupadd** - `sudo groupadd admin`. после этого можно добавить туда пользователей командой **usermod** с ключами -aG - `sudo usermod -aG admin Username`. Для проверки выполним команду `id username` которая покажет группы, к которым принадлежит пользователь. Как итог - в группе админ есть добавленные пользователи (пользователь _root_ был добавлен аналогично)

![](https://raw.githubusercontent.com/buster42b/linadmin/main/lab3/Снимок%20экрана%20от%202020-12-21%2000-24-22.png)
![](https://raw.githubusercontent.com/buster42b/linadmin/main/lab3/Снимок%20экрана%20от%202020-12-21%2000-25-01.png)

## 3. Запретить всем пользователям, не входящим в группу admin, логин по ssh в выходные (не учитывая праздники).
Для этого нам понадобятся пакеты **SSH** (возможно в базовой комплектации ОС этот модуль установлен неполностью)и **PAM** (Pluggable Authentication Module) - установим их командами `sudo yum install pam pam_script openssh-server openssh-clients` для Centos и `sudo apt-get install libpam-script ssh` для других ОС. После установки переходим в файл **pam_scrript_acct** и вносим следующие изменения:

```bash
# !bin/bash

script="$1"
shift
#check if user belongs to admin group
if groups $PAM_USER | grep admin > /dev/null
then
        exit 0
else
#check if day of week is not sunday or saturday
        if [[ $(date +%u) -lt 6 ]]
        then
                exit 0
        else
                exit 1
        fi
fi

if [ ! -e "$script" ]
then
        exit 0
fi
```
Далее выдаём скрипту права на исполнение командой `sudo chmod +x`. после этого вносим в файл `/etc/pam.d/sshd` строку `account    required    pam_script.so` 

![](https://raw.githubusercontent.com/buster42b/linadmin/main/lab3/Снимок%20экрана%20от%202020-12-21%2000-19-45.png)

# Часть 2. Работа с правами docker.
## 1. Установить докер
установка докера производилась по [официальной инструкции](https://docs.docker.com/engine/install/)

```bash
$ curl -fsSL https://get.docker.com -o get-docker.sh
$ sudo sh get-docker.sh
```
## 2. Дать конкретному пользователю права работать с докером.
после этого выполним команду `suddo usermod -aG docker Username` чтобы добавить пользователя в группу docker - она создаётся автоматически при установке пакета. Проверим корректность - перейдём в аккаунт добавленного пользователя и выполним команду `docker run hello world`. Как видим, установка докера и выдача прав прошли корректно:
![](https://sun9-33.userapi.com/impg/NQImWSymvUPDzEFLrviD3DB7-2-fvTOkwllN0w/1gSm97RATGU.jpg?size=762x175&quality=96&proxy=1&sign=16000164d7d84856bfee74960ecd34ac)
![](https://sun9-60.userapi.com/impg/tsS3He2rqUVSN7i1qmevOeOJHYgLPYUgkT-NfQ/fbWS9NlOJy0.jpg?size=797x155&quality=96&proxy=1&sign=b6926b68228d13d502afc2ab17f422f3)

теперь пользователю доступны команды докера без необходимости повышения своих прав через sudo
```
docker ps -a
docker images
docker search
```
