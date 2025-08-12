# Build stage
FROM alpine:3.20 AS builder

# Install build dependencies
RUN apk add --no-cache \
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
        perl-io-socket-ssl \
        automake \
        autoconf \
        gettext

# Install Perl modules via cpanminus
RUN curl -L http://cpanmin.us | perl - App::cpanminus && \
    cpanm --notest \
        Data::Validate::IP \
        JSON::Any

# Download and build ddclient v4.0.0
RUN curl -o /tmp/ddclient.zip -L "https://github.com/ddclient/ddclient/archive/refs/tags/v4.0.0.zip" && \
    unzip /tmp/ddclient.zip -d /tmp/ && \
    cd /tmp/ddclient-4.0.0 && \
    ./autogen && \
    ./configure --sysconfdir=/etc/ddclient && \
    make && \
    make install DESTDIR=/build

# Runtime stage
FROM alpine:3.20

# Install runtime dependencies only
RUN apk add --no-cache \
        curl \
        perl \
        perl-utils \
        perl-netaddr-ip \
        perl-net-ip \
        perl-yaml \
        perl-log-log4perl \
        perl-io-socket-ssl \
        ca-certificates \
        tzdata && \
    # Create ddclient user and directories
    addgroup -g 1000 ddclient && \
    adduser -D -u 1000 -G ddclient -h /var/lib/ddclient -s /sbin/nologin ddclient && \
    mkdir -p \
        /etc/ddclient \
        /var/lib/ddclient \
        /var/cache/ddclient \
        /var/run/ddclient \
        /config && \
    chown -R ddclient:ddclient \
        /var/lib/ddclient \
        /var/cache/ddclient \
        /var/run/ddclient \
        /config

# Copy ddclient from build stage
COPY --from=builder /build/usr/local/bin/ddclient /usr/bin/ddclient

# Copy Perl modules from build stage
COPY --from=builder /usr/local/lib/perl5 /usr/local/lib/perl5

# Copy application files
COPY --chown=ddclient:ddclient root /

# Set executable permissions
RUN chmod +x /usr/bin/ddclient.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /usr/bin/ddclient -query || exit 1

# Switch to non-root user
USER ddclient

# Set working directory
WORKDIR /var/lib/ddclient

# Create volume mount point
VOLUME ["/config"]

# Default command
CMD ["/usr/bin/ddclient.sh"]
