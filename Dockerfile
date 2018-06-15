FROM centos:7

RUN yum update && yum upgrade && yum install -y wget

RUN echo "alias ll='ls -l'" >> /root/.bash_profile

WORKDIR /root/mkimage

ADD files/ /root/mkimage/

VOLUME /root/mkimage/output

ENTRYPOINT [ "/bin/sh", "--login" ]
