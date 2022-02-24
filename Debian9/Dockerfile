FROM debian:latest

MAINTAINER goacid <goacid@kurty.net>

LABEL Name HAProxy OSS
LABEL Release OSS Edition
LABEL Vendor HAProxy
LABEL Version 2.5.3

ENV HAPROXY_BRANCH 2.5
ENV HAPROXY_MINOR 2.5.3
ENV HAPROXY_MD5 947a65fefe192239d92cb45dc93a34d7
ENV HAPROXY_SRC_URL http://www.haproxy.org/download

ENV HAPROXY_UID haproxy
ENV HAPROXY_GID haproxy

# acme.sh env
ENV CF_Token="set here or as a secret, or in docker-compose"
ENV DEPLOY_HAPROXY_PEM_PATH="/etc/haproxy/certs"
ENV DEPLOY_HAPROXY_RELOAD="supervisorctl restart haproxy"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y vim unzip procps htop telnet curl wget cron

# Supervisor
RUN apt-get install -y supervisor && mkdir -p /var/log/supervisor

#Build haproxy from source
RUN apt-get install -y libssl1.1 zlib1g libpcre3 liblua5.3-0 tar curl socat && \
    apt-get install -y gcc make libc6-dev libssl-dev libpcre3-dev zlib1g-dev liblua5.3-dev && \
    curl -sfSL "$HAPROXY_SRC_URL/$HAPROXY_BRANCH/src/haproxy-$HAPROXY_MINOR.tar.gz" -o haproxy.tar.gz && \
    echo "$HAPROXY_MD5  haproxy.tar.gz" | md5sum -c - && \
    groupadd "$HAPROXY_GID" && \
    useradd -g "$HAPROXY_GID" "$HAPROXY_UID" && \
    mkdir -p /tmp/haproxy && \
    tar -xzf haproxy.tar.gz -C /tmp/haproxy --strip-components=1 && \
    rm -f haproxy.tar.gz && \
    make -C /tmp/haproxy TARGET=linux-glibc CPU=generic USE_PCRE=1 USE_REGPARM=1 USE_OPENSSL=1 \
                            USE_ZLIB=1 USE_TFO=1 USE_LINUX_TPROXY=1 USE_LUA=1 \
			    USE_PROMEX=1 \
                            all install-bin install-man && \
    ln -s /usr/local/sbin/haproxy /usr/sbin/haproxy && \
    mkdir -p /var/lib/haproxy && \
    chown "$HAPROXY_UID:$HAPROXY_GID" /var/lib/haproxy && \
    rm -rf /tmp/haproxy && \
    mkdir -p /etc/haproxy/certs && \
    apt-get purge -y --auto-remove gcc make libc6-dev libssl-dev libpcre3-dev zlib1g-dev liblua5.3-dev


#RUN cd /tmp &&\
#    wget https://github.com/janeczku/haproxy-acme-validation-plugin/archive/0.1.1.zip &&\
#    unzip 0.1.1.zip &&\
#    cd haproxy-acme-validation-plugin-0.1.1/ &&\
#    mv acme-http01-webroot.lua /etc/haproxy/ &&\
#    mv cert-renewal-haproxy.sh /etc/haproxy/ &&\
#    echo "for domain in `ls /etc/letsencrypt/live/|grep -v README` ; do cat /etc/letsencrypt/live/$domain/privkey.pem /etc/letsencrypt/live/$domain/fullchain.pem | tee /etc/haproxy/certs/$domain.pem >/dev/null; done" > /etc/haproxy/tee.sh &&\
#    echo "letsencrypt certonly --text --webroot --webroot-path   /var/tmp -d exemple1.fr -d exemple2.fr --renew-by-default --agree-tos   --email user@exemple.fr" > /etc/haproxy/renew.sh
#


#Clean apt datas
RUN apt-get upgrade -y
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Acme.sh
RUN curl https://get.acme.sh | sh -s email=sslle@kurty.net
RUN \
    bash /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt && \
    bash /root/.acme.sh/acme.sh --uninstall-cronjob && \
    echo "acme.sh --issue --dns dns_cf --ocsp-must-staple --keylength ec-384 -d '*.kurty.net' --force" > /root/cert.sh && \
    echo "acme.sh --deploy -d '*.kurty.net' --deploy-hook haproxy --ecc" >> /root/cert.sh

# Crontab
COPY datas/acmesh /etc/cron.d/acmesh
COPY datas/kurty /etc/cron.d/kurty

#Supervisor will launch all needed process
COPY datas/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord"]

