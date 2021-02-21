# 04AdministrationLaba
>1. Создать R10;
>2. Создать на созданном RAID-устройстве раздел и файловую систему;
>3. Добавить запись в fstab для автомонтирования при перезагрузке.
>4. Сломать 1 из дисков и восстановить RAID-массив;

## Создать R10
1. Первым делом была развернута виртуальная машина под управленем ubuntu и далее были добавлены в систему 5 виртуальных дисков по 1 Gb каждый.
2. Установлена утилита `mdadm` — утилита для работы с программными RAID-массивами различных уровней. В данной инструкции рассмотрим примеры ее использования.
```
sudo apt install mdadm
```
3. Создаем RAID-массив:
```
mdadm --create --verbose /dev/md0 -l 10 -n 5 /dev/sd{b,c,d,e,f}
```
* /dev/md0 — устройство RAID, которое появится после сборки; 
* -l 10 — уровень RAID; 
* -n 5 — количество дисков, из которых собирается массив; 
* /dev/sd{b,c,d,e,f} — сборка выполняется из дисков sdb и sdc.
4. Проверка, что у наших дисков sd(b,c,d,e,f) появился раздел md0: `sudo lsblk`
5. Создание конфигурационного файла mdadm.conf. Система сама не запоминает какие RAID-массивы ей нужно создать и какие компоненты в них входят. Эта информация находится в файле mdadm.conf и в нее нужно добавить строки:
```
mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
```
* Пример содержимого:
```
DEVICE partitions
ARRAY /dev/md0 level=raid10 num-devices=5 metadata=1.2 name=user-VirtualBox:0 UUID=8ed504fa:101322e5:2499762b:993ac34a
```
* В данном примере хранится информация о массиве /dev/md0 — его уровень 10, он собирается из 5 дисков.


## Создать на созданном RAID-устройстве раздел и файловую систему
1. Создание файловой системы для массива выполняется также, как для раздела: `sudo mkfs.ext4 /dev/md0`
* Данной командой мы создаем на md0 файловую систему ext4.
2. Примонтировать раздел можно командой: `mount /dev/md0 /mnt`
* В данном случае мы примонтировали наш массив в каталог /mnt.

## Добавить запись в fstab для автомонтирования при перезагрузке.
```
Файл fstab - это текстовый файл, который содержит информацию о различных файловых системах и устройствах хранения информации в вашем компьютере. Это всего лишь один файл, определяющий, как диск и/или раздел будут использоваться и как будут встроены в остальную систему. Полный путь к файлу - /etc/fstab. Этот файл можно открыть в любом текстовом редакторе, но редактировать его возможно только от имени суперпользователя, т.к. файл является важной, неотъемлемой частью системы, без него система не загрузится.
```
0. Предварительно рекомендуется создать резервную копию fstab:
```
sudo cp /etc/fstab /etc/fstab_backup
```
1. Отредактируем файл fstab:
```
sudo vim /etc/fstab
```
* Чтобы данный раздел также монтировался при загрузке системы, добавляем в fstab следующее: `/dev/md0        /mnt    ext4    defaults    1 2`
* Источник: https://zalinux.ru/?p=4895
2. Для проверки правильности fstab, вводим:
```
umount /mnt
mount -a
df -h
```
* Мы должны увидеть:
`/dev/md0        2,4G  7,5M  2,3G   1% /mnt`

## Сломать 1 из дисков и восстановить RAID-массив
0. Я перезагрузил машину, предварительно вынув 5 диск
1. В случае выхода из строя одного из дисков массива, команда `cat /proc/mdstat` покажет следующее:
```
ersonalities : [raid10] 
md0 : active raid10 sde[3] sdd[2] sdc[1] sdb[0]
      2616320 blocks super 1.2 512K chunks 2 near-copies [5/4] [UUUU_]
      
unused devices: <none>
```
* о наличии проблемы нам говорит нижнее подчеркивание [UUUUU_] вместо [UUUUU]
2.Проверим какой диск вытащен: `lsblk`
* Вывод будет похож на это, также мы видим, что пропал диск sdf:
```
sdb      8:16   0     1G  0 disk   
└─md0    9:0    0   2,5G  0 raid10 /mnt
sdc      8:32   0     1G  0 disk   
└─md0    9:0    0   2,5G  0 raid10 /mnt
sdd      8:48   0     1G  0 disk   
└─md0    9:0    0   2,5G  0 raid10 /mnt
sde      8:64   0     1G  0 disk   
└─md0    9:0    0   2,5G  0 raid10 /mnt
sr0     11:0    1  47,5M  0 rom    /media/user/VBox_GAs_5.2.44
```

3. Для восстановления, сначала удалим сбойный диск, например:
```
mdadm /dev/md0 --remove /dev/sdf
```
4. Выключим машину и вставим диск запасной, а потом перезагрузим
5.Проверим какой диск вставлен: `lsblk`
* Вывод будет похож на это, также мы видим, что появился диск sdf (другой):
```
sdb      8:16   0     1G  0 disk   
└─md0    9:0    0   2,5G  0 raid10 /mnt
sdc      8:32   0     1G  0 disk   
└─md0    9:0    0   2,5G  0 raid10 /mnt
sdd      8:48   0     1G  0 disk   
└─md0    9:0    0   2,5G  0 raid10 /mnt
sde      8:64   0     1G  0 disk   
└─md0    9:0    0   2,5G  0 raid10 /mnt
sdf      8:80   0     1G  0 disk   
sr0     11:0    1  47,5M  0 rom    /media/user/VBox_GAs_5.2.44
```
6. Теперь добавим новый:`sudo mdadm /dev/md0 --add /dev/sdf`
7. Смотрим состояние массива:`mdadm -D /dev/md0`
* Вывод, убеждаемся в востановлении:
```
Version : 1.2
     Creation Time : Wed Dec  9 06:44:04 2020
        Raid Level : raid10
        Array Size : 2616320 (2.50 GiB 2.68 GB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Fri Dec 11 08:06:24 2020
             State : clean 
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : user-VirtualBox:0  (local to host user-VirtualBox)
              UUID : 8ed504fa:101322e5:2499762b:993ac34a
            Events : 40

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       5       8       80        4      active sync   /dev/sdf
```


### Ссылки
1. https://www.dmosk.ru/miniinstruktions.php?mini=mdadm 
2. https://help.ubuntu.ru/wiki/fstab
3. https://adminunix.ru/mdadm/
