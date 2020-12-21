# RAID

Добавляем нескольно виртуальных дисков по гигабайту каждый                                                         .
![](https://raw.githubusercontent.com/buster42b/linadmin/main/lab4/Снимок%20экрана%20от%202020-12-21%2010-32-53.png)

Устанавливаем mdadm. Командой sudo mdadm --create /dev/md0 -l 10 -n 4 /dev/loop{27..30} создаем массив.\
![](https://raw.githubusercontent.com/buster42b/linadmin/main/lab4/Снимок%20экрана%20от%202020-12-21%2012-50-04.png)

Проверим состояние, выполнением команд:
cat /proc/mdstat
sudo mdadm --detail /dev/md0
![](hhttps://raw.githubusercontent.com/buster42b/linadmin/main/lab4/Снимок%20экрана%20от%202020-12-21%2011-01-05.png)

"Убиваем" диск loop30 и удаляем его из массива
sudo mdadm /dev/md0 --fail /dev/sdd
sudo mdadm /dev/md0 --remove /dev/sdd
![](https://raw.githubusercontent.com/buster42b/linadmin/main/lab4/Снимок%20экрана%20от%202020-12-21%2011-01-27.png)
Видно, что он поменял статус на removed.

Ставим на место удаленного другой диск (loop14)
sudo mdadm --add /dev/md0 /dev/sdf
cat /proc/mdstat
sudo mdadm --detail /dev/md0
![](https://raw.githubusercontent.com/buster42b/linadmin/main/lab4/Снимок%20экрана%20от%202020-12-21%2011-01-40.png)
Структура РЭЙДа восстановлена

Выполняем остановку и запуск РЭЙД
Основка выполняется командой sudo mdadm --stop /dev/md0 А запуск - командой sudo mdadm --assemble /dev/md0
После перезагруки машины мы собираем все заново, поскольку я читал гайд последовательно, а тренировался на лупах, но если бы использовал не лупы, то РЭЙД бы сохранился, но с номером 127

создадим файловую систему, для этого воспользуемся командой sudo fdisk /dev/md0 и далее:
    - нажимаем n - добавление нового раздела;
    - далее p - тип раздела основной;
    - далее либо нажимаем ENTER либо вводим 1 - номер раздела;
    - после чего указываем размер раздела командой +2048M;
    - Далее, чтобы сохранить результаты необходимо ввести команду w - запись таблиы разделов на диск и выход.

Создадим файловую систему командой sudo mkfs.ext4 /dev/md0p1
Узнаем UUID диска, для этого воспользуемся командой sudo blkid /dev/md0p1, которая и отобразит нам нужный UUID
Отредактируем файл /etc/fstab добавив строку следующего вида: UUID=24d17f2f-53d3-4f79-a047-2410aa8d13ed /mnt ext4 defaults 0 0
![](https://raw.githubusercontent.com/buster42b/linadmin/main/lab4/Снимок%20экрана%20от%202020-12-21%2011-46-02.png)
