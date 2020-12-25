# ДЗ 6 поставка ПО

1. Качаем необходимые для лабы пакеты:
```
yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils
```
 Качаем NGINX и openssl:
 ```
 wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.18.0-2.el7.ngx.src.rpm
 wget https://www.openssl.org/source/latest.tar.gz
 tar -xvf latest.tar.gz
 ```

 Создается директория nginx-1.18.0-2.el7.ngx.src.rpm:
 ```
# rpm -i nginx-1.18.0-2.el7.ngx.src.rpm
warning: nginx-1.18.0-2.el7.ngx.src.rpm: Header V4 RSA/SHA1 Signature, key ID 7bd9bf62: NOKEY
warning: user builder does not exist - using root
warning: group builder does not exist - using root
 ```
 
2. Собираем и тестируем.

 Устанавливаем зависимости:
 
 `yum-builddep rpmbuild/SPECS/nginx.spec`
 
 Изменяем nginx.spec:
 
 `vi rpmbuild/SPECS/nginx.spec`
 
   В блоке %build в параметры configure добавим openssl, чтобы получилось вот так:
   
 ```
./configure %{BASE_CONFIGURE_ARGS} \
        --with-cc-opt="%{WITH_CC_OPT}" \
        --with-ld-opt="%{WITH_LD_OPT}" \
        --with-openssl=/root/openssl-1.1.1i \
        --with-debug
```
 
 Собираем пакет:
 
```
 # rpmbuild -bb rpmbuild/SPECS/nginx.spec
```

  Проверяем наличие пакетов: 
  
  `ls -la rpmbuild/RPMS/x86_64/`
  
  
  ```
  total 4584
  drwxr-xr-x. 2 root root      98 Dec 21 14:42 .
  drwxr-xr-x. 3 root root      20 Dec 21 14:42 ..
  -rw-r--r--. 1 root root 2222344 Dec 21 14:42 nginx-1.18.0-2.el8.ngx.x86_64.rpm
  -rw-r--r--. 1 root root 2467080 Dec 21 14:42 nginx-debuginfo-1.18.0-2.el8.ngx.x86_64.rpm
  ```
  
  Проверили, видим, что пакеты есть.
  
  Теперь пробуем установить и протестировать:
  
  ```
  $ systemctl start nginx
  ==== AUTHENTICATING FOR org.freedesktop.systemd1.manage-units ====
  Authentication is required to start 'nginx.service'.
  Authenticating as: root
  Password:
  ==== AUTHENTICATION COMPLETE ====
  
  $ 
  ```
  
  Проверяем еще раз:
  
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
  Работает.
  
3. Создаем свой репозиторий и закидываем пакеты в него.

Копируем пакет в каталог для статики у nginx и скачиваем туда репозиторий Percona-Server:

```
sudo -i
mkdir /usr/share/nginx/html/repo
cd /usr/share/nginx/html/repo
cp ~/rpmbuild/RPMS/x86_64/nginx-1.18.0-2.el8.ngx.x86_64.rpm .
wget https://repo.percona.com/centos/7Server/RPMS/noarch/percona-release-1.0-9.noarch.rpm
```
 
 Инициализируем репозиторий:
 
  ```
  # createrepo .
  Directory walk started
  Directory walk done - 2 packages
  Temporary output repo path: ./.repodata/
  Preparing sqlite DBs
  Pool started (with 5 workers)
  Pool finished
  ```
  
 Добавим в настройке nginx строку `autoindex on;` в блоке `location /`, чтобы нормально отображались директории.
 
Перезапустим nginx: 

`nginx -s reload`

Проверим на всякий случай, работает ли как надо:

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
  
Работает.

.


Добавим репозиторий в `/etc/yum.repos.d`: `vi /etc/yum.repos.d/test.repo`

  ```
  [test]
  name=test-nginx-percona                                                                               
  baseurl=http://localhost:50050/repo                                                                   
  gpgcheck=0                                                                                            
  enabled=1 
  ```
  
  Проверяем:
  
  ```
  # yum repolist | grep test
  test                               test-nginx-percona
  ```
  
Пробуем установить персону из личного репозитория:

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
  
  Название репозитория - test, значит, всё работает.
