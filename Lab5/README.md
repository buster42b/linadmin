# Задание №5. Работа с lvm
## 1. Создать файловую систему на логическом томе и смонтировать её
Для данной лабораторной работы был собран аналогичный предыдущену стенд - 5 виртуальных жёстких дисков по 2Гб. 4 из них потребуются непосредственно в ходе работы и один на всякий случай (правильно было бы добавить чётное количество, если понадобится дополнительно монтировать зеркало к этому диску, но я забыл сделать это сразу)

![](https://camo.githubusercontent.com/09c4549c617efd1799faec981dbeecb652735e48a98ffccb3164e04e8732a970/68747470733a2f2f73756e392d35312e757365726170692e636f6d2f696d70672f46677249374d2d4442566a4a394d5178564c693177614e34334a5478636763514a34355958412f66546a74324361584f346b2e6a70673f73697a653d35313878323431267175616c6974793d39362670726f78793d31267369676e3d3733383737616461373938656663393736656336666633333634656431666332)

Так же установим необходимый пакет командой `sudo yum install -y lvm2`. Проверим базовую конфигурацию командами **lsblk** и **lvmdiskscan**:

![](https://sun9-60.userapi.com/impg/74BUAWG1OzGLJBUkkrQo-nKZbKvQh8QyuP-82A/6eOxN0G-6Tc.jpg?size=615x519&quality=96&proxy=1&sign=004c1dd72e5802e9e245ef5966a6f65c)

Добавим диск b как физический том командой `sudo pvcreate /dev/sdb`. Проверим создание командами `sudo pvdisplay` и `sudo pvs`:

![](https://sun9-54.userapi.com/impg/HB66iTetgpvQtdxA4KQeGf5GItkXAZsw88KDZQ/AykbCWjltbs.jpg?size=579x539&quality=96&proxy=1&sign=31da3c7e9b8509004fa68799fbe28d74)

Далее создадим виртуальную группу командой `sudo vgcreate labgr /dev/sdb` и проверим корректность создания командами `sudo vgdisplay -v labgr` и `sudo vgs`:

![](https://sun9-10.userapi.com/impg/ES_mVUUG0JDTw_sOVEt_MS85tmSCdQyoA1VKRw/bLJrslt8DwQ.jpg?size=625x611&quality=96&proxy=1&sign=c20176cd8397f40a60f76f87c639f681)

Повторим похожие действия для создания логической группы `sudo lvcreate -l+100%FREE -n first labgr` и проверяем `sudo lvdisplay` `sudo lvs`:

![](https://sun9-75.userapi.com/impg/yAstAlNA5rnWrdSri-CxzY3gJXnVm4laGP6Jmw/gsA8eLBYTIo.jpg?size=590x646&quality=96&proxy=1&sign=8979ad4ff985b36ef4c9b92cd22ef813)
![](https://sun9-19.userapi.com/impg/L4emBayRyAM1X_qb1CaIc0b3yxfWYpFJ8rBM8w/ajb_Q-wznxU.jpg?size=710x494&quality=96&proxy=1&sign=2a5037fbf01cf01047e579a992c79602)

Создадим файловую систему `sudo mkfs.ext4 /dev/mai/first` и смонтируем её `sudo mount /dev/labgr/first /mnt` `sudo mount`:

![](https://sun9-62.userapi.com/impg/G5pruNdC84nVVeRYtiTNZGSdiH0tupSmx45jfQ/KDmUAF4wFO8.jpg?size=621x383&quality=96&proxy=1&sign=3f2ba76be2666e0201a6d79b50bb46f5)
![](https://sun9-71.userapi.com/impg/l_cUjvvxwrHDTw3yr9Z-qWgZZuszmJevmGFgPw/XG5Qw-3hys0.jpg?size=1440x666&quality=96&proxy=1&sign=d4061a624dcd1aa5cc9c4d1157147f21)

## 2. Создать файл, заполенный нулями на весь размер точки монтирования.
Для этого просто выполним команду `sudo dd if=/dev/zero of=/mnt/mock.file bs=1M count=4500 status=progress` чтобы побайтово скопировать в файл 4500 чанков по 1М, после чего проверим состояние командой `df -h`:

![](https://sun9-16.userapi.com/impg/oSQTLNu2IBZ1rznSEdj1yhZWnRC5h9OOuNWx2A/KaxpuX2bItM.jpg?size=883x343&quality=96&proxy=1&sign=97d16c08602d3dabcb9cac464cd872ca)
## 3. Расширить vg, lv и файловую систему.
Введём команды:
```bash
sudo pvcreate /dev/sdc
sudo vgextend labgr /dev/sdc
sudo lvextend -l+100%FREE /dev/labgr/first
sudo lvdisplay
sudo lvs
sudo df -h
```
Результат:
![](https://sun9-53.userapi.com/impg/y-fO3YPClW68xkukpfKrTTk4v7Cs8z_piglneQ/a47HDToNTG4.jpg?size=776x404&quality=96&proxy=1&sign=3a8cbe9cf364848b6642b5d53932cb75)

Теперь произведём расширение файловой системы:

```bash
sudo resize2fs /dev/labgr/first
sudo df -h
```

![](https://sun9-22.userapi.com/impg/FGqWwugx9UdQrbpt8musI92ZRAjFl6RDDnah8g/67g1Of-Ahq0.jpg?size=866x332&quality=96&proxy=1&sign=dced738740a1e00a2a0e9cafa2dc47ab)

## 4. Уменьшить файловую систему.
Для уменьшения ФС отмонтируем её, после чего пересоберём том и систему. При уменьшении размеров системы необходимо учитывать минимальное пространство, которое ей необходимо, чтобы не обрезать нужные файлы, поэтому был оставлен небольшой запас:
```bash
sudo umount /mnt
sudo fsck -fy /dev/labgr/first
sudo resize2fs /dev/labgr/first 2100M             
//sudo resize2fs -M /dev/labgr/first чтобы ужать систему до возножного минимума
sudo mount /dev/labgr/first /mnt
sudo df -h
```

![](https://sun9-10.userapi.com/impg/GTqAbYxJBXg5ehTDSxC3Hr_Zw-0QJiSsACqQug/J-AutRyxO-4.jpg?size=955x503&quality=96&proxy=1&sign=ad2fcc0f17ded8b4c46bdfbd1effbe46)

## 5. Создать несколько новых файлов и создать снимок.
Создадим несколько файлов и сделаем снимок. Для этого выполним следующую последовательность команд:
```bash
sudo touch /mnt/fillerfile{1..5}
ls /mnt
sudo lvcreate -L 100M -s -n log_snapsh /dev/mai/first
sudo lvs
sudo lsblk
```
Результат - в нашей vg создан снапшот, по которому можно будет откатить систему к состоянию на момент его создания:
![](https://sun9-10.userapi.com/impg/0mXoEC3xi4ZmbSAKQAa7irTW4hUR0VzvrMciIg/WhC6qwI2FIc.jpg?size=933x727&quality=96&proxy=1&sign=545d54292e1b04c0906f1f45ec470bc0)

## 6. Удалить файлы и после монтирования снимка убедиться, что созданные нами файлы присутствуют.
Удалим файлы командой `sudo rm -f /mnt/fillerfile{1..3}`, после чего проверим есть ли удалённые файлы на снапшоте 
```bash
sudo mkdir /snapsh
sudo mount /dev/mai/log_snapsh /snapsh
ls /snapsh
sudo umount /snapsh
```
Видим результат:

![](https://sun9-43.userapi.com/impg/zMWrHz_ntnvl21LI_LYL-F8v_QPPu4d-pd3bqA/MI5j4WEIqkU.jpg?size=793x92&quality=96&proxy=1&sign=448a157ea1fb86947e0baa5fc9397dc4)

## 7. Сделать слияние томов.
Чтобы выполнить слияние томов необходимо сначала отмонтировать систему, после ввести команды
```bash
sudo umount /mnt
sudo lvconvert --merge /dev/labgr/log_snapsh
sudo mount /dev/labgr/first /mnt
ls /mnt
```

![](https://sun9-57.userapi.com/impg/8MJPJZ0N4IU9e0zDQLxR6Kx4UfGttTwmbiacIw/5iYbSveS-ts.jpg?size=788x125&quality=96&proxy=1&sign=5f18c80500c8cbebe56aeed60941b4e5)

## 8. Сделать зеркало.
Для этого понадобится добавить еще устройств в PV, их я заготовил заранее аналогичным образом.  После создадим VG `sudo vgcreate labgrMirror /dev/sd{d,e}` и смонтируем LV с флагом того, что она монтируется с созданием зеркала `sudo lvcreate -l+100%FREE -m1 -n fMirror labgrMirror`:

![](https://sun9-14.userapi.com/impg/Jxe2WM7rYTVlgwEFnStxYJvX4B0TCFOmrFTNew/xUn0qS6K-5A.jpg?size=405x130&quality=96&proxy=1&sign=61edcb86c5ce147d985c8a1882c04530)

Как видно из скрина, зеркало создано и синхронизировано:

![](https://sun9-56.userapi.com/impg/plk3NH1eTESD_rtGINcYAUGvHvZiVsf1tJxjTA/GN62RtVs3jg.jpg?size=906x579&quality=96&proxy=1&sign=56fac14b8b049f4c83aecd7246bf550e)
