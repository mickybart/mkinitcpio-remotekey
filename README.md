# mkinitcpio-remotekey

Remote key hook permit you to unlock a computer without the need to connect an usb stick with the keyfile or using your keyboard to enter the code. It will use the network to download a keyfile to unlock an encrypted root device. The hook will use sftp to connect on a private and secured server to download a keyfile in /crypto_keyfile.bin.

By doing so, we can preload a keyfile that will be used by another hook (encrypt or encryptssh) to unlock the encrypted root device.

The initramfs will have a private ssh key embedded to be able to connect to the remote key server. If the initramfs is stored on an unencrypted /boot filesystem, everyone with a physical access to your computer will be able to get the private ssh key.

remotekey hook should be use with a lot of precaution and in a particular context.

## Precaution usage

### Safe usage

- Context: Family circle or a physical place where you trust everyone who can access physically your computer
- keyfiles are stored in an encrypted container or filesystem (eg: on a server where the storage is using encryption itself)
- The server should not be able to automatically unlock its encrypted filesystem (*simplified point of view*)
- Use a dedicated ssh key pair

If you are respecting **ALL** those conditions, it is safe to use this hook. 

If someone steal all your computers, as the server will need a manual step to be unlocked, it will not be possible for the client to automatically unlock itself. Your server is a sealed vault and your clients either.

Of course if you are able to get back your computers, start them offline (no network), reinstall from scratch  /efi or /boot with a safe source (except if you have a trustable secure boot), AND AFTER ONLY, rotate all ssh keys. 

### Unsafe usage

- You don't trust at least 1 person that can physically access your computer
- You need a zero trust approach
- You are using the same ssh key pair for remote key AND your day to day work

### End of life computer / uninstall

Minimal effort is to remove the ssh pub key from the server and never use again the ssh key pair with a new computer.

## Server side

The server store a keyfile that can be used to unlock an encrypted root device.

The server uses an openssh solution with sftp and chroot (https://wiki.archlinux.org/title/SCP_and_SFTP#Secure_file_transfer_protocol_(SFTP)_with_a_chroot_jail).

```bash
useradd -M -g nobody -s /usr/bin/nologin -d /home/keys -c "Remote keyfile storage" keys
mkdir -m755 /home/keys
mkdir -m700 /home/keys/.ssh
chown keys:nobody /home/keys/.ssh
su -s /bin/bash -c "umask 022; touch /home/keys/.ssh/authorized_keys" keys

cat <<EOF >> /etc/ssh/sshd_config

Match User keys
    ChrootDirectory %h
    X11Forwarding no
    AllowTcpForwarding no
    PasswordAuthentication no
    ForceCommand internal-sftp

EOF

systemctl reload sshd

mkdir -m700 /home/keys/keyfiles
chown keys:nobody /home/keys/keyfiles
su -s /bin/bash keys
cd /home/keys/keyfiles
umask 077

# add your keyfiles (be sure to set permission to 500 or 600 and owner to keys)
# add your public keys in /home/keys/.ssh/authorized_keys (use a DEDICATED public key; see unsafe usage; see Client side for details)

exit


```

## Client side

### Install

```bash
gpg --recv-keys F9E8AF21879815B6
pacman -S mkinitcpio-remotekey  # replace pacman with aur compatible solution
```


### Generate ssh key pair compatible with dropbear

```bash
dropbearkey -t ed25519
cat $HOME/.ssh/id_dropbear > /etc/dropbear/id_remotekey

# Add the content of $HOME/.ssh/id_dropbear.pub to your server in /home/keys/.ssh/authorized_keys
```

### Server, user and keyfile

Edit the `/etc/dropbear/remotekey` to specify:

- server ip (KEY_IP)
- server user (KEY_USER)
- keyfile path to use (KEY_FILE); if you are using chroot as suggested, / will be the home directory of KEY_USER

### /etc/mkiniticpio.conf

Example:

```bash
HOOKS=(base udev autodetect keyboard keymap modconf block netconf tinyssh remotekey encryptssh filesystems fsck)
```

remotekey need to be set after the network (eg: netconf) and before encrypt or encryptssh

Once done, do not forget to update the initramfs (eg: `mkinitcpio -p linux`). This step requires that the server is up and running because remotekey will scan ssh host keys (`ssh-keyscan`) to set `known_hosts`. 
