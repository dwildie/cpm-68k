losetup -P /dev/loop0 $(pwd)/test.img 
mount /dev/loop0p2 /mnt/usb/
cp target/* /mnt/usb/
ls -al /mnt/usb
umount /mnt/usb
losetup -d /dev/loop0
