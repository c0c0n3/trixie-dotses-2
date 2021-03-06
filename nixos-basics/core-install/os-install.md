OS Installation
===============
> Minimal NixOS setup.

Just let the NixOS installer do its job.

    # nixos-generate-config --root /mnt
    # nixos-install
    
At the end of the installation process, the installer will ask you to enter
a password for the root user. After the installer is done
    
    $ reboot

and log in as `root` with the password you've entered. You should have a
fully functional NixOS system you can start configuring to suit your needs.
Yay!


### Notes

###### Network Connection
The `nixos-install` command needs to pull down files from the Internet. If
you're box is plugged into a network, the installer should bring up a wired
connection, so you're gonna be fine. On the other hand, if all you have is
wireless access, then you may have to edit the generated config file to
specify some connection parameters. The NixOS manual explains [what to
do][nixos-wireless] to get out of the woods.

###### Grub Device 
The manual says you have to edit the config file generated by the first
command above to set `boot.loader.grub.device`. But in our case this is
not relevant as the generated config tells the installer to modify the
EFI variables so that the firmware will start [systemd-boot][arch-systemd-boot]
instead of Grub. See below.

###### Generated Configuration
If all went well, you should end up with a `/etc/nixos/configuration.nix`
similar to the below:

    { config, pkgs, ... }:

    {
        imports =
        [ # Include the results of the hardware scan.
            ./hardware-configuration.nix
        ];

        # Use the systemd-boot EFI boot loader.
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        
        # The global useDHCP flag ...
        networking.useDHCP = false;
        networking.interfaces.enp0s3.useDHCP = true;

        # This value determines the NixOS release ...
        system.stateVersion = "19.09";
    }

This is your NixOS configuration spec that tells NixOS how to assemble
and configure your system.

Starting from NixOS `19.09`, `useDHCP` should be specified separately
for each network interface and the global `networking.useDHCP` gets
deprecated. But the global `useDHCP` defaults to `true` which is why
the installer generates the two `networking.*` settings above.

###### Direct EFI Boot
The Linux kernel can be booted directly from the UEFI firmware through the
[EFI boot stub][arch-efistub]. So technically you don't need a boot loader
if:

* NixOS is the only OS to boot; and
* you only ever want to boot in the most recent NixOS configuration
(generation).

Not having a boot loader could make sense in some cases. For example, I've
been using Virtual Box VM's as dedicated local dev envs (e.g. local build
VM, Java IDE VM, Haskell VM) to avoid having to install software directly
on my laptop---ya, been bitten by dependency hell way too many times!
In these cases, I wanna start a VM and get into whatever dev env sort of,
well, you know, quick man! So it makes sense to bypass not only the boot
loader but also the display manager and get automatically logged into my
VM user account.

Boot loaders have a timeout parameter you can set to 0 to get rid of
screens/menus and boot directly into the default OS. You could set the
boot loader timeout to 0 in your NixOS config with

    boot.loader.timeout = 0;

Sort of out of sight out of mind, you know. But why not get rid of the
boot loader altogether then? (After all, it's one less program to install,
configure, and update.) For simple cases, it's a no-brainer. In fact, some
firmware is configured to try executing a specific UEFI Shell script on
the ESP partition: `/boot/startup.nsh`. This is what Virtual Box does too
and I've used this feature to set up direct EFI boot for my Arch Linux VM's:

    $ cd /boot
    $ echo vmlinuz-linux root=/dev/sda2 initrd=/initramfs-linux.img > startup.nsh

For even faster boot times, a better option would be to use something like
[efibootmgr][arch-efistub] to set your motherboard's boot entries. The
reason why I didn't do it that way for my Arch VM's is that Virtual Box
[can't persist EFI variables after shutdown][VBoxArchGuest].

Now doing something similar for NixOS is not as straightforward because
I'd first need to come up with a clever, robust way to deal with NixOS
generations---have a look at any of the files in `/boot/loader/entries`
to get a feel of what you're getting yourself into...But if you really
wanna go down this road, as a starting point look at these config entries
in the NixOS manual

    boot.loader.generationsDir.copyKernels
    boot.loader.generationsDir.enable




[arch-efistub]: https://wiki.archlinux.org/index.php/EFISTUB
    "EFISTUB"
[arch-systemd-boot]: https://wiki.archlinux.org/index.php/systemd-boot
    "systemd-boot"
[nixos-wireless]: https://nixos.org/nixos/manual/index.html#sec-wireless
    "Wireless Networks"
[VBoxArchGuest]: https://wiki.archlinux.org/index.php/VirtualBox#Installation_steps_for_Arch_Linux_guests
    "Installation steps for Arch Linux guests"
