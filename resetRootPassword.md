# Reset Root Password in Linux: Emergency Mode
1. Reboot machine, at boot menu: `e`
2. Add `rd.break` after `rhgb quiet`, at `linux ($root)` section
3. Ctrl+X
4. Now in emergency shell
```sh
mount -o rw,remount /sysroot
chroot /sysroot
# If command not found:
find / -name "chroot"
passwd
# Set new password
touch /.autorelabel
exit
exit
```
