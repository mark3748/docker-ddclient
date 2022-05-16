FROM alpine:3.11

RUN \
    apk add --no-cache \
        curl \
        wget \
        unzip \
        make \
        perl \
        perl-utils \
        perl-test-taint \
        perl-netaddr-ip \
        perl-net-ip \
        perl-yaml \
        perl-log-log4perl \
        perl-io-socket-ssl &&\
    curl -L http://cpanmin.us | perl - App::cpanminus && \
    cpanm \
        Data::Validate::IP \
        JSON::Any && \ 
    curl -o /tmp/ddclient.zip -L "https://github.com/ddclient/ddclient/archive/v3.10.0_2.zip" &&\
    unzip /tmp/ddclient.zip -d /tmp/ &&\
    install -Dm755 /tmp/ddclient-3.10.0_2/ddclient /usr/bin/ && \
    rm -rf \
        /config/.cpanm \
        /root/.cpanm \
        /tmp/*
COPY --chown=0:0 root/ /
RUN chmod +x /usr/bin/ddclient.sh
CMD /usr/bin/ddclient.sh
VOLUME /config
