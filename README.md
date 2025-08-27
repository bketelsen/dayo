# Dayo - experimental
A system built with mkosi for my own usage.

This is a hard fork of ["not-so-immutable-os"](https://github.com/MoltenArmor/not-so-immutable-os), with a focus on providing a server image and a desktop image.

This system is based on Debian, using as many systemd components as we can. Basically it is based on the idea of [immutable `/usr`](https://0pointer.net/blog/fitting-everything-together.html), but it does not enable secure boot and verity by default.

Profiles:
- `desktop`: Include desktop base files in the main image, including `pipewire`, `upower`, `accountservice` and so on.
  - `xfce`: Include XFCE desktop environment in the main image.
  - `mate`: Include MATE desktop environment in the main image.
- `sysext-only`: Enable some special config to build sysext images only.

Sysext apps:
- `sysext-zsh`: Zsh.
- `sysext-chromium`: Chromium browser.
- `sysext-incus`: Incus system container and VM manager, plus qemu.
- `sysext-podman`: Podman container tool and `podman-docker` symlink.
- `sysext-vmware`: VMWare tools.
- `sysext-kate`: Kate editor.
- `sysext-ncat`: Netcat.
- `sysext-virt-viewer`: Virt viewer tool.
- `sysext-apt-file`: apt-file command-line tool.
- `sysext-mkosi-tools`: Tools for using mkosi to build other distros.
- `sysext-gnome-boxes`: GNOME Boxes VM tool.
- `sysext-gnome-connections`: GNOME Connections.

Install mkosi:
Install `mkosi` with pipx like this:

```bash
pipx install git+https://github.com/systemd/mkosi.git@main
```

then run `pipx ensurepath` to update your path.

To build it:

```
mkosi --profile desktop --profile xfce build
```

To try it in VM:

```
mkosi --profile desktop --profile xfce --console gui vm
```

To apply update:

```
mkosi --profile desktop --profile xfce sysupdate update
```

To build sysext images:

```
# Enable profiles you are using.
mkosi [--profile desktop --profile xfce] --profile sysext-only [--dependency <APP>] build
```

Enter volatile RW mode:
```
enter-rw
```

Exit volatile RW mode and drop all operations:
```
exit-rw
```

Execute command with `/etc` writable:
```
unlock-etc [-d|--directly] <command>
```

Tips:
- After attaching sysext (and their confext dependencies) images, you are recommended to run `systemd-sysusers && systemd-tmpfiles --create && systemtl preset-all`.
- After attaching GNOME-related sysext images (for example, `sysext-gnome-boxes`), you **HAVE TO** run `glib-compile-schemas /usr/share/glib-2.0/schemas/ --targetdir=~/.local/share/glib-2.0/schemas/` to use these apps.

todo:

- [ ] podman storage resarch
- [ ] sysupdate
- [ ] base/server default dhcp setup?
- [ ] keymap / locale setup