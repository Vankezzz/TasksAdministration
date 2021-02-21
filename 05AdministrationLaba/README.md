# 05AdministrationLaba
> Использовать `lvm` в работе
>1. Создать файловую систему на логическом томе и смонтировать её;
>2. Создать файл, заполненный нулями на весь размер точки монтирования;
>3. Расширить файловую систему;
>4. Добавить несколько новых файлов и создать снимок;
>5. Удалить файлы и после монтирования снимка убедиться, что созданные нами файлы имеются на диске;
>6. Сделать слияние томов;
>7. Создать зеркало.

## Создать файловую систему на логическом томе и смонтировать её
0. Добавляем к нашей системе дисков, в моем случае два по 1 гб - sdb и sdc
1. Помечаем диски, что они будут использоваться для LVM: `sudo pvcreate /dev/sdb /dev/sdc`
```
Вывод:
Physical volume "/dev/sdb" successfully created.
Physical volume "/dev/sdc" successfully created.
```
2. Проверяем, что сформировались физические тома: `sudo lvmdiskscan`
```
  /dev/sdb   [       1,00 GiB] LVM physical volume
  /dev/sdc   [       1,00 GiB] LVM physical volume
```
3. Создаем группу`adminlaba5` : `sudo vgcreate adminlaba5 /dev/sdb /dev/sdc`
```
Volume group "adminlaba5" successfully created
```
4. Просмотреть информацию о созданных группах можно командой: `sudo vgdisplay`
5. Создаем логический том на 1 гб : `sudo lvcreate -L 1G adminlaba5`
```
 Logical volume "lvol0" created.
```
6. Посмотреть результат создания логического тома: `sudo lvdisplay `
```
--- Logical volume ---
  LV Path                /dev/adminlaba5/lvol0
  LV Name                lvol0
  VG Name                adminlaba5
  LV UUID                YPLJVk-D2vy-Okwo-uIOx-Kw1o-XmZJ-2bWKB0
  LV Write Access        read/write
  LV Creation host, time user-VirtualBox, 2020-12-12 07:34:47 +0300
  LV Status              available
  # open                 0
  LV Size                1,00 GiB
  Current LE             256
  Segments               2
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:0
```
7. Создание файловой системы ext4: `sudo mkfs.ext4 /dev/adminlaba5/lvol0`
```
mke2fs 1.45.5 (07-Jan-2020)
Creating filesystem with 262144 4k blocks and 65536 inodes
Filesystem UUID: dc98adc3-49dd-429a-b7a7-e145bfda289b
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done
```
8. Монтирование нашей файловой системы:`sudo mount /dev/adminlaba5/lvol0 /mnt`
9. Для постоянного монтирования раздела добавляем строку в fstab:`sudo vim /etc/fstab`
```
В открывшимся файле в конце добавим:
/dev/adminlaba5/lvol0  /mnt    ext4    defaults        1 2
```
10. Проверяем настройку fstab, смонтировав раздел: `sudo mount -a`
11. Проверяем, что диск примонтирован:`df -hT`
```
/dev/mapper/adminlaba5-lvol0 ext4      976M  2,6M  907M   1% /mnt
```

## Создать файл, заполненный нулями на весь размер точки монтирования
Теперь создадим файл, который займет всё пространство на лог.томе (1гб):
```
sudo dd if=/dev/zero of=/mnt/test.file bs=1M count=2000 status=progress
```
Как результат будет:
```
862978048 bytes (863 MB, 823 MiB) copied, 1 s, 862 MB/s
dd: error writing '/mnt/test.file': No space left on device
958+0 records in
957+0 records out
1003896832 bytes (1,0 GB, 957 MiB) copied, 1,19836 s, 838 MB/s
```
И командой `df -hT` мы увидим, что наш раздел забит полностью

## Уменьшить файловую систему
1. Удалим файл, который был создан на предыдущем шаге: `sudo rm -rf /mnt/test.file`
2. Отмонтируем раздел: `sudo umount /mnt`
3. Чтобы не был отрезан хвост ФС, делаем уменьшение ФС на 500 мб : `sudo resize2fs /dev/adminlaba5/lvol0 500M`
4. Выполняем проверку диска: `sudo e2fsck -fy /dev/adminlaba5/lvol0`
5. Уменьшаем размер тома на 500 мб: `lvreduce -L-500 /dev/adminlaba5/lvol0`
```
Size of logical volume adminlaba5/lvol0 changed from 1,00 GiB (256 extents) to 524,00 MiB (131 extents).
Logical volume adminlaba5/lvol0 successfully resized.
```
## Добавить несколько новых файлов и создать снимок
1. Создадим парочку новых файлов: `sudo touch /mnt/file{1..5}`
2. Создадим снимок на 200мб: `sudo lvcreate -L 200M -s -n snapsh /dev/adminlaba5/lvol0`
3. Результат создания новых файлов и создания снимка: `sudo lsblk`
```
sdb                       8:16   0     1G  0 disk 
├─adminlaba5-lvol0-real 253:1    0   524M  0 lvm  
│ ├─adminlaba5-lvol0    253:0    0   524M  0 lvm  
│ └─adminlaba5-snapsh   253:3    0   524M  0 lvm  
└─adminlaba5-snapsh-cow 253:2    0   200M  0 lvm  
  └─adminlaba5-snapsh   253:3    0   524M  0 lvm  
```
## Удалить файлы и после монтирования снимка убедиться, что созданные нами файлы имеются на диске
1. Удалим несколько файлов: `sudo rm -f /mnt/file{1..3}`
2. Теперь нам необходимо восстановить файлы используя при этом созданный нами снимок:
```
sudo mkdir /snap
sudo mount /dev/adminlaba5/snapsh /snap
ls /snap
sudo umount /snap
```

## Сделать слияние томов
Отмонтируем файловую систему и произведем слияние. Это делает следующими командами, заодно удостоверимся, что файлы оказались снова в нашей системе:
```
sudo umount /mnt
sudo lvconvert --merge /dev/adminlaba5/lvol0
sudo mount /dev/adminlaba5/lvol0 /mnt
ls /mnt
```
## Создать зеркало
1. Для этого понадобится добавить еще устройств в PV и VG. Это сделаем следующими командами:
```
sudo pvcreate /dev/sd{e,f}
sudo vgcreate vgmirror /dev/sd{e,f}
sudo lvcreate -l+80%FREE -m1 -n mirror1 vgmirror
```
2. Ну и теперь нужно произвести синхронизацию оригинала и зеркала. Для этого выполним команды:
```
sudo lvs
sudo lsblk
```
##
# Ссылки
1. https://www.dmosk.ru/instruktions.php?object=lvm
