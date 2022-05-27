#Dockerfile for building ChimeraOS install-media
#Based on Arch

FROM archlinux:base-devel
MAINTAINER Wouter Wijsman

#Install archiso
RUN yes | pacman -Syuu archiso lynx
RUN pacman --noconfirm -S --needed git pyalpm python-commonmark
RUN echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    useradd build -G wheel -m
RUN su - build -c "git clone https://aur.archlinux.org/pikaur.git /tmp/pikaur" && \
    su - build -c "cd /tmp/pikaur && makepkg -f" && \
    pacman --noconfirm -U /tmp/pikaur/pikaur-*.pkg.tar.zst

# Add a fake systemd-run script to workaround pikaur requirement.
RUN echo -e "#!/bin/bash\nif [[ \"$1\" == \"--version\" ]]; then echo 'fake 244 version'; fi\nmkdir -p /var/cache/pikaur\n" > /usr/bin/systemd-run && \
    chmod +x /usr/bin/systemd-run

#set working dir, you'll have to mount something yourself here
WORKDIR /root/chimeraos

# Build pikaur packages as the 'build' user
ENV BUILD_USER "build"

ENV GNUPGHOME  "/etc/pacman.d/gnupg"

#Copy archiso files from this git repo
ADD chimeraos /root/chimeraos
