FROM centos:7

RUN yum update && yum upgrade && yum install -y wget

WORKDIR /root/mkimage

ADD files/ /root/mkimage/

VOLUME /output

ENTRYPOINT [ "linux32", "/root/mkimage/make-docker-image.sh" ]
