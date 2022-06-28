# Postgres v13.4 with Babelfish

This project builds docker images of Postgres with the [Babelfish](https://babelfishpg.org/) extensions.

> Babelfish for PostgreSQL is an open source project available under the Apache 2.0 and PostgreSQL licenses. It provides the capability for PostgreSQL to understand queries from applications written for Microsoft SQL Server. Babelfish understands the SQL Server wire-protocol and T-SQL, the Microsoft SQL Server query language, so you don’t have to switch database drivers or re-write all of your application queries. With Babelfish, applications currently running on SQL Server can now run directly on PostgreSQL with fewer code changes.

## Docker Image Notes

This image builds the Babelfish binaries and packages it using the [official Postgresql Docker](https://hub.docker.com/_/postgres) process.

Primary difference between official Posgresql docker image and this version is that the postgres binaries are in `/usr/local/bin`, extensions are in `/usr/local/share` and `PGDATA` is in `/var/lib/postgresql/data`.

## Running

```bash
docker pull rsubr/postgres-babelfish

# Location to store PGDATA, run once for initdb to succeed, after PG start up press Ctrl+C and exit
mkdir data
docker run --rm -e POSTGRES_PASSWORD=password -v ${PWD}/data:/var/lib/postgresql/data rsubr/postgres-babelfish

# By defaut Postgres listens only on localhost and inaccessible to external hosts
# Extract postgres.conf so it can be customized
docker run -i --rm rsubr/postgres-babelfish cat /usr/local/share/postgresql/postgresql.conf.sample > my-postgres.conf

# Customize my-postgres.conf
# listen_addresses = '*' # Listen on all interfaces

# Run PG with customized postgres.conf
docker run -v ${PWD}/data:/var/lib/postgresql/data -v ${PWD}/my-postgres.conf:/var/lib/postgresql/data/postgresql.conf rsubr/postgres-babelfish
```

## Building

```bash
docker build -t postgres-babelfish .
```
