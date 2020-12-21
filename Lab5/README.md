# Работа с lvm
## 1. Создать файловую систему на логическом томе и смонтировать её
Создаем 4 виртуальных жёстких диска по 1Гб.

![](https://camo.githubusercontent.com/09c4549c617efd1799faec981dbeecb652735e48a98ffccb3164e04e8732a970/68747470733a2f2f73756e392d35312e757365726170692e636f6d2f696d70672f46677249374d2d4442566a4a394d5178564c693177614e34334a5478636763514a34355958412f66546a74324361584f346b2e6a70673f73697a653d35313878323431267175616c6974793d39362670726f78793d31267369676e3d3733383737616461373938656663393736656336666633333634656431666332)

Устанавливаем влм `sudo yum install -y lvm2`. Проверяем базовую конфигурацию командами **lsblk** и **lvmdiskscan**:

![](https://github.com/buster42b/linadmin/blob/main/Lab5/1.png?raw=true)

Добавляемм диск b как физический том с помощью `sudo pvcreate /dev/sdb`. Проверяем создание командами `sudo pvdisplay` и `sudo pvs`:

![](https://github.com/buster42b/linadmin/blob/main/Lab5/2.png?raw=true)

Создаем виртуальную группу командой `sudo vgcreate labgr /dev/sdb` и проверяем корректность создания командами `sudo vgdisplay -v labgr` и `sudo vgs`:

![](https://github.com/buster42b/linadmin/blob/main/Lab5/3.png?raw=true)

Повторяем для создания логической группы `sudo lvcreate -l+100%FREE -n first labgr` и проверяем `sudo lvdisplay` `sudo lvs`:

![](https://github.com/buster42b/linadmin/blob/main/Lab5/4.png?raw=true)
![](https://github.com/buster42b/linadmin/blob/main/Lab5/5.png?raw=true)

Создаем файловую систему `sudo mkfs.ext4 /dev/mai/first` и монтируем её `sudo mount /dev/labgr/first /mnt` `sudo mount`:

![](https://github.com/buster42b/linadmin/blob/main/Lab5/6.png?raw=true)
![](https://github.com/buster42b/linadmin/blob/main/Lab5/7.png?raw=true)

## 2. Создать файл, заполенный нулями на весь размер точки монтирования.
Побайтово копируем в файл 4500 чанков по 1М `sudo dd if=/dev/zero of=/mnt/mock.file bs=1M count=4500 status=progress`, смотрим состояние командой `df -h`:

![](https://github.com/buster42b/linadmin/blob/main/Lab5/8.png?raw=true)
## 3. Расширить vg, lv и файловую систему.
```bash
sudo pvcreate /dev/sdc
sudo vgextend labgr /dev/sdc
sudo lvextend -l+100%FREE /dev/labgr/first
sudo lvdisplay
sudo lvs
sudo df -h
```
Результат:
![](https://github.com/buster42b/linadmin/blob/main/Lab5/9.png?raw=true)

Расширяем файловую систему:
```bash
sudo resize2fs /dev/labgr/first
sudo df -h
```
![](https://github.com/buster42b/linadmin/blob/main/Lab5/10.png?raw=true)

## 4. Уменьшить файловую систему.
```bash
sudo umount /mnt
sudo fsck -fy /dev/labgr/first
sudo resize2fs /dev/labgr/first 2100M             
//sudo resize2fs -M /dev/labgr/first чтобы ужать систему до возножного минимума
sudo mount /dev/labgr/first /mnt
sudo df -h
```
![](https://github.com/buster42b/linadmin/blob/main/Lab5/11.png?raw=true)

## 5. Создать несколько новых файлов и создать снимок.
```bash
sudo touch /mnt/fillerfile{1..5}
ls /mnt
sudo lvcreate -L 100M -s -n log_snapsh /dev/mai/first
sudo lvs
sudo lsblk
```
В vg создается снэпшот, по которому можно откатить систему к тому состоянию, которое было в момент создания снэпшота:
![](https://github.com/buster42b/linadmin/blob/main/Lab5/12.png?raw=true)

## 6. Удалить файлы и после монтирования снимка убедиться, что созданные нами файлы присутствуют.
Удаляем файлы  `sudo rm -f /mnt/fillerfile{1..3}`, ищем удалённые файлы на снэпшоте 
```bash
sudo mkdir /snapsh
sudo mount /dev/mai/log_snapsh /snapsh
ls /snapsh
sudo umount /snapsh
```
Получаем
![](https://github.com/buster42b/linadmin/blob/main/Lab5/13.png?raw=true)

## 7. Сделать слияние томов.
Монтируем систему, вводим
```bash
sudo umount /mnt
sudo lvconvert --merge /dev/labgr/log_snapsh
sudo mount /dev/labgr/first /mnt
ls /mnt
```
![](https://github.com/buster42b/linadmin/blob/main/Lab5/14.png?raw=true)

## 8. Сделать зеркало.
Создаем VG `sudo vgcreate labgrMirror /dev/sd{d,e}` и смонтируем LV с флагом того, что она монтируется с созданием зеркала `sudo lvcreate -l+100%FREE -m1 -n fMirror labgrMirror`:
![](https://github.com/buster42b/linadmin/blob/main/Lab5/15.png?raw=true)

Зеркало создано и синхронизировано:
![](https://github.com/buster42b/linadmin/blob/main/Lab5/16.png?raw=true)
