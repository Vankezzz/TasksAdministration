# 06AdministrationLaba
## Задание 
> Создать  RPM пакет
> Создать свой репозиторий и разместить там ранее собранный RPM.

## 1. Создание  RPM пакета.
1. Установим необходимые компоненты командой `yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils`
2. Скачаем nginx : `wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.18.0-2.el7.ngx.src.rpm`
3. Распакуем его : `rpm -i nginx-1.18.0-2.el7.ngx.src.rpm`
4. Скачать OpenSSL : `wget https://www.openssl.org/source/latest.tar.gz`
5. Распаковать его: `tar -xvf latest.tar.gz`
6. Мы скачали все, что нам нужно и теперь установим зависимости: `yum-builddep rpmbuild/SPECS/nginx.spec`
```
================================================================================
 Пакет                    Архитектура Версия                  Репозиторий Размер
================================================================================
Установка:
 openssl-devel            x86_64      1:1.1.1g-11.el8         baseos      2.3 M
 pcre-devel               x86_64      8.42-4.el8              baseos      551 k
Обновление:
 libselinux               x86_64      2.9-4.el8_3             baseos      165 k
 libselinux-utils         x86_64      2.9-4.el8_3             baseos      242 k
 python3-libselinux       x86_64      2.9-4.el8_3             baseos      283 k
 systemd                  x86_64      239-41.el8_3            baseos      3.5 M
 systemd-container        x86_64      239-41.el8_3            baseos      731 k
 systemd-libs             x86_64      239-41.el8_3            baseos      1.1 M
 systemd-pam              x86_64      239-41.el8_3            baseos      456 k
 systemd-udev             x86_64      239-41.el8_3            baseos      1.3 M
Установка зависимостей:
 keyutils-libs-devel      x86_64      1.5.10-6.el8            baseos       48 k
 krb5-devel               x86_64      1.18.2-5.el8            baseos      558 k
 libcom_err-devel         x86_64      1.45.6-1.el8            baseos       38 k
 libkadm5                 x86_64      1.18.2-5.el8            baseos      185 k
 libselinux-devel         x86_64      2.9-4.el8_3             baseos      199 k
 libsepol-devel           x86_64      2.9-1.el8               baseos       86 k
 libverto-devel           x86_64      0.3.0-5.el8             baseos       18 k
 pcre-cpp                 x86_64      8.42-4.el8              baseos       47 k
 pcre-utf16               x86_64      8.42-4.el8              baseos      195 k
 pcre-utf32               x86_64      8.42-4.el8              baseos      186 k
 pcre2-devel              x86_64      10.32-2.el8             baseos      605 k
 pcre2-utf32              x86_64      10.32-2.el8             baseos      220 k
...
```
7. Добавим в блок `%build` в параметры OpenSSL:
```
./configure %{BASE_CONFIGURE_ARGS} \
       --with-cc-opt="%{WITH_CC_OPT}" \
       --with-ld-opt="%{WITH_LD_OPT}" \
       --with-openssl=/root/openssl-1.1.1i \
       --with-debug
```
8. Собирем пакет : `rpmbuild -bb rpmbuild/SPECS/nginx.spec`
9. Проверяем, что пакет собран: `ls -la rpmbuild/RPMS/x86_64/`
```
drwxr-xr-x. 2 root root      98 дек 27 16:14 .
drwxr-xr-x. 3 root root      20 дек 27 16:14 ..
-rw-r--r--. 1 root root  786404 дек 27 16:14 nginx-1.18.0-2.el7.ngx.x86_64.rpm
-rw-r--r--. 1 root root 1789388 дек 27 16:14 nginx-debuginfo-1.18.0-2.el7.ngx.x86_64.rpm
```
10. Установим пакет для теста:`yum localinstall -y rpmbuild/RPMS/x86_64/nginx-1.18.0-2.el8.ngx.x86_64.rpm`
```
Обновить  1 пакет
Общий размер: 2.7 M
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Обновление  : 1:nginx-1.18.0-2.el7.ngx.x86_64                                                                                                                                                                1/2 
предупреждение: /etc/nginx/nginx.conf создан как /etc/nginx/nginx.conf.rpmnew
  Очистка     : 1:nginx-1.16.1-2.el7.x86_64                                                                                                                                                                    2/2 
  Проверка    : 1:nginx-1.18.0-2.el7.ngx.x86_64                                                                                                                                                                1/2 
  Проверка    : 1:nginx-1.16.1-2.el7.x86_64                                                                                                                                                                    2/2 
Обновлено:
  nginx.x86_64 1:1.18.0-2.el7.ngx                                                                                                                                             
Выполнено!
```

## 1. Создать свой репозиторий и разместить там ранее собранный RPM.


## 2. Создать свой репозиторий и загрузить туда rpm пакет.
1. Создадим папку: `mkdir /usr/share/nginx/html/repository`
2. Cкопируем туда пакеты:
```
cd /usr/share/nginx/html/repository
cp ~/rpmbuild/RPMS/x86_64/nginx-1.18.0-2.el8.ngx.x86_64.rpm .
```
3. Проинициализируем репозиторий: `createrepo .`
```
Spawning worker 0 with 1 pkgs
Spawning worker 1 with 1 pkgs
Workers Finished
Saving Primary metadata
Saving file lists metadata
Saving other metadata
Generating sqlite DBs
Sqlite DBs complete
```
4. Добавим автоиндексирование `autoindex on;`  в блоке `location /` в файл nginx.conf:

```
location / {
            proxy_pass https://services;
            proxy_set_header Host $host;
            autoindex on;
}
```
5. Перезапустим nginx: `nginx -s reload`
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
service nginx reload
```
6. Добавляем репозиторий и проверяем: `cat >> /etc/yum.repos.d/lab.repo << EOF`
7. Наконец переустановим nginx: `yum reinstall nginx`
```
Downloading packages:
nginx-1.18.0-2.el7.ngx.x86_64.rpm                                                                                                                          | 2.1 MB  00:00:00     
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : 1:nginx-1.18.0-2.el7.ngx.x86_64                                                                                                                                            1/1 
  Verifying  : 1:nginx-1.18.0-2.el7.ngx.x86_64                                                                                                                                            1/1 
Installed:
  nginx.x86_64 1:1.18.0-2.el7.ngx                                                                                                                             
```

