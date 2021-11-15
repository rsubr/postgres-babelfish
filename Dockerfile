FROM ubuntu:focal AS builder
LABEL Author="Raja Subramanian" Description="Babelfish for PostgreSQL (Unofficial)"


# Stop dpkg-reconfigure tzdata from prompting for input
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y git python2 python2-dev \
        build-essential flex libxml2-dev libxslt-dev libssl-dev    \
        libreadline-dev zlib1g-dev libldap2-dev libpam0g-dev bison \
        uuid uuid-dev lld libossp-uuid-dev gnulib       \
        libxml2-utils xsltproc icu-devtools libicu66 libicu-dev gawk \
# For building babelfish extensions
        openjdk-8-jre openssl python2-dev libpq-dev pkgconf unzip libutfcpp-dev && \
# Clean up apt setup files
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


RUN mkdir /build
COPY ./docker-build.sh /build
RUN /build/docker-build.sh

############# STAGE 2

FROM ubuntu:focal
COPY --from=builder /usr/local/pgsql /usr/local

# Stop dpkg-reconfigure tzdata from prompting for input
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/local/pgsql/bin:${PATH}"

RUN apt-get update && \
    apt-get install -y libxml2 libreadline8 tzdata libldap-2.4-2 libpython2.7 libxslt1.1 libossp-uuid16 gosu && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create postgres user and set file permissions 
RUN set -eux && \
    groupadd -r postgres --gid=999 && \
    useradd -r -g postgres --uid=999 --home-dir=/var/lib/postgresql --shell=/bin/bash postgres && \
    mkdir -p /var/lib/postgresql && \
    chown -R postgres:postgres /var/lib/postgresql && \
    mkdir -p /var/run/postgresql && chown -R postgres:postgres /var/run/postgresql && \
    chmod 2777 /var/run/postgresql


ENV PGDATA /var/lib/postgresql/data
# this 777 will be replaced by 700 at runtime (allows semi-arbitrary "--user" values)
RUN mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 777 "$PGDATA"
VOLUME /var/lib/postgresql/data

RUN mkdir /docker-entrypoint-initdb.d
COPY docker-entrypoint.sh /usr/local/bin
ENTRYPOINT ["docker-entrypoint.sh"]

STOPSIGNAL SIGINT

EXPOSE 5432
CMD ["postgres"]
