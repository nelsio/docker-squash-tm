[![](https://images.microbadger.com/badges/image/canecas/squash-tm.svg)](https://microbadger.com/images/itmug/squash-tm "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/canecas/squash-tm.svg)](https://microbadger.com/images/itmug/squash-tm "Get your own version badge on microbadger.com")

# docker-squash-tm
Dockerized Squash-TM 1.20.0 \
Squash TM is an open source tool for test repository management: requirements management, test cases, campaign and more... Squash TM is full web and natively inter- and multi- projects. 

## Description
Light image from Alpine:3.7 with openjdk8-jre. It supports mysql (mariadb:10.2 tested), postgreSQL. \
The Squash-TM version is 1.20.0

## Quick Start
By default, Squash-tm will use an embedded H2 database but it is strongly suggested to use an external database (mysql, postgreSQL) \
So **you should definetly use the docker-compose** which creates the external database. Check the [docker-compose section](https://github.com/canecas/docker-squash-tm#docker-compose)


You can still launch the docker image squash-tm alone (H2 Embedded) for testing purpose :

```
docker run --name='squash-tm' -it --rm -p 8099:8080 canecas/squash-tm
```

The application take a few minutes to start especially when you start it the first time (database set up).

Once Squash-tm is started, go to `http://localhost:8099/squash`

The default username and password are:
- username: **admin**
- password: **admin**

## Configuration

### Environment variables
Default `DB_TYPE` is H2 The following environment variables allows to change for MySQL or PostgreSQL.

- **DB_TYPE**: Database type, one of h2, mysql, postgresql; default=`h2`
- **DB_HOST**: Hostname of the database container; default=`../data/squash-tm`
- **DB_PORT**: database engine listen port (3306=mysql, 5432=postgres); default=NULL
- **DB_NAME**: Name of the database; default=`squashtm`
- **DB_USERNAME**: Database username; default=`sa`
- **DB_PASSWORD**: Database password; default=`sa`
- **DB_URL**: DataBase URL; default=`jdbc:${DB_TYPE}://${DB_HOST}:${DB_PORT}/$DB_NAME`

## Docker-compose

This exemple enables mariadb:10.2 database.

```
  squash-tm-mdb:
    image: mariadb:10.2
    container_name: squash-tm-mdb
    # restart: always
    volumes: 
    - squash-tm-db:/var/lib/mysql
    environment:
      MYSQL_DATABASE: squashtm
      MYSQL_USER: user
      MYSQL_PASSWORD: Passw0rd
      MYSQL_RANDOM_ROOT_PASSWORD: '1'
    command :
      - '--sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES'
      - '--character-set-server=utf8' 
      - '--collation-server=utf8_bin'

  squash-tm:
    container_name: squash-tm
    depends_on:
      - squash-tm-mdb
    environment:
      DB_TYPE: mysql
      DB_HOST: squash-tm-mdb
      DB_PORT: 3306
      DB_NAME: squashtm
      DB_USERNAME: user
      DB_PASSWORD: Passw0rd
    ports:
    - 8099:8080/tcp
    image: canecas/squash-tm
    volumes:
    - squash-tm-bundles:/etc/squash-tm/bundles
    - squash-tm-logs:/etc/squash-tm/logs
    - squash-tm-plugins:/etc/squash-tm/plugins
    - squash-tm-conf:/etc/squash-tm/conf
```

This exemple enables PostgreSQL database.

```
  squash-tm-mdb:
    image: postgres
    container_name: squash-tm-mdb
    # restart: always
    volumes: 
    - squash-tm-db:/var/lib/mysql
    environment:
      POSTGRES_DB: squashtm
      POSTGRES_USER: user
      POSTGRES_PASSWORD: Passw0rd

  squash-tm:
    container_name: squash-tm
    depends_on:
      - squash-tm-mdb
    environment:
      DB_TYPE: postgresql
      DB_HOST: squash-tm-mdb
      DB_PORT: 5432
      DB_NAME: squashtm
      DB_USERNAME: user
      DB_PASSWORD: Passw0rd
    ports:
    - 8099:8080/tcp
    image: canecas/squash-tm
    volumes:
    - squash-tm-bundles:/etc/squash-tm/bundles
    - squash-tm-logs:/etc/squash-tm/logs
    - squash-tm-plugins:/etc/squash-tm/plugins
    - squash-tm-conf:/etc/squash-tm/conf
```

## Other Options
### Installation directory
The installation directory is `/etc/squash-tm`

### Mysql configuration
You can use the squash-tm-mdb dockerfile to create an image of the mariadb database with the editor's recommanded settings and add your settings.

my.cnf :

```
[mysqld]
sql-mode='NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES'
collation-server = utf8_bin
character-set-server = utf8
```

Then you can change your docker-compose file to include this image.

## Credits
https://www.squashtest.org \
https://github.com/fjudith/docker-squash-tm


## License
GNU General Public License v3.0
