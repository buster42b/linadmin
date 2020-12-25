# ДЗ 6 поставка ПО

Устанавливаем необходимые пакеты:
yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils

Загружаем SRPM пакет NGINX:
wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.18.0-2.el7.ngx.src.rpm

Создаем древо каталогов для сборки:
rpm -i nginx-1.18.0-2.el7.ngx.src.rpm

Качаем исходники для openssl:
wget https://www.openssl.org/source/latest.tar.gz
tar -xvf latest.tar.gz

Ставим зависимости:
yum-builddep rpmbuild/SPECS/nginx.spec

Ставим spec файл чтобы NGINX собирался как надо.
Секция build:

    %build
    ./configure %{BASE_CONFIGURE_ARGS} \
        --with-cc-opt="%{WITH_CC_OPT}" \
        --with-ld-opt="%{WITH_LD_OPT}" \
        --with-openssl=/root/openssl-1.1.1i \
        --with-debug

Теперь можно приступить к сборке RPM пакета:
rpmbuild -bb rpmbuild/SPECS/nginx.spec

Убедимся что пакеты создались:
ls -la rpmbuild/RPMS/x86_64/

Теперь можно установить наш пакет и убедиться что nginx работает
yum localinstall -y rpmbuild/RPMS/x86_64/nginx-1.18.0-2.el7.ngx.x86_64.rpm
systemctl start nginx
systemctl status nginx

Далее мы будем использовать его для доступа к своему репозиторию

2. Теперь приступим к созданию своего репозитория.

Директория для статики у NGINX по умолчанию /usr/share/nginx/html

Создадим там каталог repo:
mkdir /usr/share/nginx/html/repo

Копируем туда наш собранный RPM и, например, RPM для установки репозитория Percona-Server:
cp rpmbuild/RPMS/x86_64/nginx-1.18.0-2.el7.ngx.x86_64.rpm /usr/share/nginx/html/repo/
wget https://repo.percona.com/centos/7Server/RPMS/noarch/percona-release-1.0-9.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-1.0-9.noarch.rpm

Инициализируем репозиторий командой:
createrepo /usr/share/nginx/html/repo/

    Spawning worker 0 with 2 pkgs (Видим что в репозитории два пакета)
    Workers Finished
    Saving Primary metadata
    Saving file lists metadata
    Saving other metadata
    Generating sqlite DBs
    Sqlite DBs complete

Для прозрачности настроим в NGINX доступ к листингу каталога:
В location / в файле /etc/nginx/conf.d/default.conf добавим директиву autoindex on. В результате location будет выглядеть так:

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        autoindex on;
    }

Проверяем синтаксис и перезапускаем NGINX:
nginx -t

    nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    nginx: the configuration file /etc/nginx/nginx.conf syntax is ok

nginx -s reload

Теперь ради интереса можно посмотреть в браузере или curl-ануть:
curl -a http://localhost/repo/

    <html>
    <head><title>Index of /repo/</title></head>
    <body>
    <h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
    <a href="repodata/">repodata/</a>                                          14-Dec-2020 13:08                   -
    <a href="nginx-1.18.0-2.el7.ngx.x86_64.rpm">nginx-1.18.0-2.el7.ngx.x86_64.rpm</a>                  14-Dec-2020 13:07             2175188
    <a href="percona-release-1.0-9.noarch.rpm">percona-release-1.0-9.noarch.rpm</a>                   12-Mar-2019 13:35               16664
    </pre><hr></body>
    </html>

Все готово для того, чтобы протестировать репозиторий! Добавим его в /etc/yum.repos.d:

cat >> /etc/yum.repos.d/mai.repo << EOF
[mai]
name=mai-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF

Убедимся что репозиторий подключился и посмотрим что в нем есть:
yum repolist enabled | grep mai

Переустановим nginx из нашего репозитория:
yum reinstall nginx

Посмотрим список всех пакетов, отфильтровав их:
yum list | grep mai

Установим репозиторий percona-release из нашего репозитория:
yum install percona-release -y

</details>
 
## Инструкция

1. Настраиваем виртуалку - качаем всё, что нужно.
 - Штуки для сборки:
```
sudo -i
yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils
```
 - NGINX и к нему причитающееся:
 Я решил собирать nginx, а не своё приложение не потому что так написано в мануале и проще, а потому что не придумал, что собрать.
 ```
 wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.18.0-2.el7.ngx.src.rpm
 wget https://www.openssl.org/source/latest.tar.gz
 tar -xvf latest.tar.gz
 ```
 До загрузки пакета:
 ```
# rpm -i nginx-1.18.0-2.el7.ngx.src.rpm
error: open of nginx-1.18.0-2.el7.ngx.src.rpm failed: No such file or directory
 ```
 После загрузки пакета:
 ```
# rpm -i nginx-1.18.0-2.el7.ngx.src.rpm
warning: nginx-1.18.0-2.el7.ngx.src.rpm: Header V4 RSA/SHA1 Signature, key ID 7bd9bf62: NOKEY
warning: user builder does not exist - using root
warning: group builder does not exist - using root
 ```
 
2. Сборка пакета и тестирование.
 - Установка зависимостей - `yum-builddep rpmbuild/SPECS/nginx.spec`
 
 - Поправим nginx.spec - `vi rpmbuild/SPECS/nginx.spec`:
   В блоке %build в параметры configure добавим openssl, чтобы получилось вот так:
 ```
./configure %{BASE_CONFIGURE_ARGS} \
        --with-cc-opt="%{WITH_CC_OPT}" \
        --with-ld-opt="%{WITH_LD_OPT}" \
        --with-openssl=/root/openssl-1.1.1i \
        --with-debug
```
 - Собираем пакет!:
```
 # rpmbuild -bb rpmbuild/SPECS/nginx.spec
 ...
 checking for C compiler ... not found

./configure: error: C compiler cc is not found

error: Bad exit status from /var/tmp/rpm-tmp.hy64gl (%build)


RPM build errors:
    Bad exit status from /var/tmp/rpm-tmp.hy64gl (%build)
```
Не нашёл сишный компилятор.
 - Ставим компилятор и собираем ещё раз: `dd if=/dev/zero of=/mnt/test.file bs=1M count=8000 status=progress` 
 ```
 # yum install -y gcc
 # rpmbuild -bb rpmbuild/SPECS/nginx.spec
 ...
```
  Ждём.
  - Проверяем наличие пакетов: `ls -la rpmbuild/RPMS/x86_64/`
  ```
  total 4584
  drwxr-xr-x. 2 root root      98 Dec 21 14:42 .
  drwxr-xr-x. 3 root root      20 Dec 21 14:42 ..
  -rw-r--r--. 1 root root 2222344 Dec 21 14:42 nginx-1.18.0-2.el8.ngx.x86_64.rpm
  -rw-r--r--. 1 root root 2467080 Dec 21 14:42 nginx-debuginfo-1.18.0-2.el8.ngx.x86_64.rpm
  ```
  На месте.
  - Попробуем установить и протестировать:
  ```
  # yum localinstall -y rpmbuild/RPMS/x86_64/nginx-1.18.0-2.el8.ngx.x86_64.rpm
  # systemctl start nginx
  Failed to start nginx.service: Access denied
  See system logs and 'systemctl status nginx.service' for details.
  ```
  Интересно. Выйдем из рута и попробуем от обычного пользователя:
  ```
  # exit
  # sudo passwd
  ...
  # systemctl start nginx
  ==== AUTHENTICATING FOR org.freedesktop.systemd1.manage-units ====
  Authentication is required to start 'nginx.service'.
  Authenticating as: root
  Password:
  ==== AUTHENTICATION COMPLETE ====
  Job for nginx.service failed because the control process exited with error code.
  See "systemctl status nginx.service" and "journalctl -xe" for details.
  ```
  Что ж такое. Смотрим логи, понимаем, что он не смог стартовать на 80 порт потому что порт занят. Ладно, в `/etc/nginx/conf.d/default.conf` поменяем 80 порт на 50050 и попробуем ещё раз.
  ```
  $ systemctl start nginx
  ==== AUTHENTICATING FOR org.freedesktop.systemd1.manage-units ====
  Authentication is required to start 'nginx.service'.
  Authenticating as: root
  Password:
  ==== AUTHENTICATION COMPLETE ====
  
  $ 
  ```
  Точно работает?
  ```
  $ systemctl status nginx
  ● nginx.service - nginx - high performance web server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Mon 2020-12-21 15:01:49 UTC; 5s ago
     Docs: http://nginx.org/en/docs/
  Process: 41236 ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf (code=exited, status=0/SUCCESS)
 Main PID: 41237 (nginx)
    Tasks: 2 (limit: 12558)
   Memory: 2.0M
   CGroup: /system.slice/nginx.service
           ├─41237 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx.conf
           └─41238 nginx: worker process
  ```
  Точно.
3. Создание своего репозитория и запихивание туда пакетов:
 - Копирование пакета в каталог для статики у nginx + скачивание туда же ещё какого-нибудь репозитория (в примере - Percona-Server):
```
sudo -i
mkdir /usr/share/nginx/html/repo
cd /usr/share/nginx/html/repo
cp ~/rpmbuild/RPMS/x86_64/nginx-1.18.0-2.el8.ngx.x86_64.rpm .
wget https://repo.percona.com/centos/7Server/RPMS/noarch/percona-release-1.0-9.noarch.rpm
```
  - Инициализируем репозиторий:
  ```
  # createrepo .
  Directory walk started
  Directory walk done - 2 packages
  Temporary output repo path: ./.repodata/
  Preparing sqlite DBs
  Pool started (with 5 workers)
  Pool finished
  ```
  - Добавим в настройке nginx строку `autoindex on;` в блоке `location /`, чтобы нормально отображались директории
  - Перезапустим nginx: `nginx -s reload`
  - Проверим на всякий случай, работает ли как надо:
  ```
  # curl -a http://localhost:50050/repo/
  <html>
  <head><title>Index of /repo/</title></head>
  <body>
  <h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
  <a href="repodata/">repodata/</a>                                          21-Dec-2020 15:08                   -
  <a href="nginx-1.18.0-2.el8.ngx.x86_64.rpm">nginx-1.18.0-2.el8.ngx.x86_64.rpm</a>                  21-Dec-2020 15:07             2222344
  <a href="percona-release-1.0-9.noarch.rpm">percona-release-1.0-9.noarch.rpm</a>                   12-Mar-2019 13:35               16664
  </pre><hr></body>
  </html>
  ```
  Выходит, что работает.
  - Добавим репозиторий в `/etc/yum.repos.d`: `vi /etc/yum.repos.d/test.repo`
  ```
  [test]
  name=test-nginx-percona                                                                               
  baseurl=http://localhost:50050/repo                                                                   
  gpgcheck=0                                                                                            
  enabled=1 
  ```
  Проверим:
  ```
  # yum repolist | grep test
  test                               test-nginx-percona
  ```
  - Попробуем установить персону из личного репозитория:
  ```
  # yum install percona-release
test-nginx-percona                                                     68 kB/s | 2.1 kB     00:00
Dependencies resolved.
======================================================================================================
 Package                        Architecture          Version               Repository           Size
======================================================================================================
Installing:
 percona-release                noarch                1.0-9                 test                 16 k

Transaction Summary
======================================================================================================
Install  1 Package

Total download size: 16 k
Installed size: 18 k
  ```
  Как видим, название репозитория - test, значит, всё работает.
  
  
> Готово!
