# 03AdministrationLaba
> Первая часть:
>* Создать нескольких пользователей с паролем и шеллом;
>* Создать группу admin и включить туда парочку пользователей и root;
>* Запретить всем пользователям, кроме группы admin, логин в систему по SSH в выходные дни (суббота и воскресенье, без учета праздников).
>> Вторая часть:
>* Установить docker;
>* Дать конкретному пользователю права работать с docker;


# Часть 1
1. Создать нескольких пользователей с паролем и шеллом: 
 ```
 sudo useradd -p password -s /bin/bash victim1
 sudo useradd -p password -s /bin/bash victim2
 sudo useradd -p password -s /bin/bash victim3
 ```
2. Создать группу admin и включить туда парочку пользователей и root:
 ```
 sudo groupadd admin
 sudo usermod -aG admin victim2
 sudo usermod -aG admin victim3
 sudo usermod -aG admin root
 ```
3. Запретить всем пользователям, кроме группы admin, логин в систему по SSH в выходные дни (суббота и воскресенье, без учета праздников):
 * Установим pam_script: 
 ```
 sudo apt install libpam-script
 ```
 * Создадим скрипт для проверки пользователя: `sudo vim /usr/share/libpam-script/pam_script_acct`
 ```
 #!bin/bash
script="$1"
shift

if groups $PAM_USER | grep admin > /dev/null
then
        exit 0
else
        if [[ $(date +%u) -lt 6 ]] # если дата дня недели меньше 6 (то есть субботы и воскресенья)
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
 * Сделаем его исполняемым:
```
sudo chmod +x /usr/share/libpam-script/pam_script_acct
```
 * Занесем команду исполнения скрипта: `sudo vim /etc/pam.d/sshd`
```
После строки : account    required     pam_nologin.so
Добавим: account    required     pam_script.so
```
 * Проверяем вход по ssh: `ssh victim1@localhost`



## Часть 2
1. Установить docker:
Установка docker'а производилась [по инструкции](https://losst.ru/ustanovka-docker-na-ubuntu-16-04)
```
sudo apt update && sudo apt upgrade
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update && apt-cache policy docker-ce
sudo apt install -y docker-ce
```
> Как итог, у нас добавилась новая группа `docker`, которую можно увидеть, выполнив команду `cat /etc/group`
2. Дать конкретному пользователю права работать с docker, просто добавляем его в группу:
```
 sudo usermod -aG docker victim1
```
3. Зайдем в пользователя и проверим версию docker:
```
ssh victim1@localhost
docker --version
```
