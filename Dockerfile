FROM debian:8
#FROM    phusion/baseimage:0.9.16

MAINTAINER Goacid <goacid@kurty.net>

ENV DEBIAN_FRONTEND noninteractive

# Add haproxy latest repo
RUN echo deb http://httpredir.debian.org/debian jessie-backports main | \
tee /etc/apt/sources.list.d/backports.list
#RUN echo deb http://archive.ubuntu.com/ubuntu trusty-backports main universe | \
#tee /etc/apt/sources.list.d/backports.lis
# update apt
RUN apt-get update # && apt-get -o Dpkg::Options::=--force-confold --force-yes -fuy upgrade
RUN apt-get -y install vim telnet wget

# Install haproxy
RUN apt-get -y install haproxy -t jessie-backports
#RUN apt-get -y install haproxy -t trusty-backports
RUN sed -i 's/^ENABLED=.*/ENABLED=1/' /etc/default/haproxy
# ADD datas/haproxy.cfg /etc/haproxy/haproxy.cfg

#Install Letsencrypt for haproxy
RUN apt-get -y install certbot -t jessie-backports
RUN apt-get -y install unzip

RUN cd /tmp &&\
    wget https://github.com/janeczku/haproxy-acme-validation-plugin/archive/0.1.1.zip &&\
    unzip 0.1.1.zip &&\
    cd haproxy-acme-validation-plugin-0.1.1/ &&\
    mv acme-http01-webroot.lua /etc/haproxy/ &&\
    mv cert-renewal-haproxy.sh /etc/haproxy/ &&\
    echo "letsencrypt certonly --text --webroot --webroot-path   /var/tmp -d mail1.kurty.net -d webmail.kurty.net --renew-by-default --agree-tos   --email goacid@kurty.net" > /etc/haproxy/renew.sh

# Supervisor
RUN apt-get install -y supervisor && mkdir -p /var/log/supervisor
RUN apt-get install -y python-pip && pip install supervisor-stdout 

#Clean apt datas
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#Supervisor will launch all needed process
COPY datas/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord"]

# Start line :
# docker run -p 91.121.111.38:80:80  --name="haproxy" -h haproxy.kurty.net -i -t goa_haproxy_fresh /bin/bash
# docker run -p 91.121.111.38:80:80  --name="haproxy" -h haproxy.kurty.net -v /data/docker/perso_dockerconf/kurty/haproxy/datas/haproxy.cfg:/etc/haproxy/haproxy.cfg -t goa_haproxy_fresh
# docker build -t goa_haproxy_fresh 
