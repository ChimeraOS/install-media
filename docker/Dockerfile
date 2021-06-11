#Dockerfile for building GamerOS
#Based on Arch

FROM archlinux:base
MAINTAINER Wouter Wijsman

#Install archiso
RUN yes | pacman -Syuu grep file archiso lynx

#set working dir, you'll have to mount something yourself here
WORKDIR /root/gameros

#Copy archiso files from this git repo
ADD gameros /root/gameros
