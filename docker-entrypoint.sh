#! /bin/sh
# This portion of script where pulled from https://github.com/fjudith/docker-squash-tm and modified to install by default h2 database if no env setting are set up where launching docker image.

cd /etc/squash-tm/bin

DB_TYPE=${DB_TYPE:-'h2'}
DB_HOST=${DB_HOST:-'../data/squash-tm'}
DB_USERNAME=${DB_USERNAME:-'sa'}
DB_PASSWORD=${DB_PASSWORD:-'sa'}
DB_NAME=${DB_NAME:-'squashtm'}
# DB_PORT=${DB_PORT:-'3306'}
# DB_URL="jdbc:${DB_TYPE}://${DB_HOST}:${DB_PORT}/$DB_NAME"

if [[ "${DB_TYPE}" = "mysql" ]]; then
    echo 'Using MysQL'
    DB_PORT=${DB_PORT:-'3306'}
    DB_URL="jdbc:${DB_TYPE}://${DB_HOST}:${DB_PORT}/$DB_NAME"

    until nc -zv -w 5 ${DB_HOST} ${DB_PORT}; do echo waiting for mysql; sleep 2; done;

    if ! mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME -e "SELECT 1 FROM information_schema.tables WHERE table_schema = '$DB_NAME' AND table_name = 'ISSUE';" | grep 1 ; then
        echo 'Initializing MySQL database'
        mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME < ../database-scripts/mysql-full-install-version-$SQUASH_TM_VERSION.RELEASE.sql
    else
        echo 'Database already initialized'
    fi

elif [[ "${DB_TYPE}" = "postgresql" ]]; then
    echo 'Using PostgreSQL'
    DB_PORT=${DB_PORT:-'5432'}
    DB_URL="jdbc:${DB_TYPE}://${DB_HOST}:${DB_PORT}/$DB_NAME"

    until nc -zv -w 5 ${DB_HOST} ${DB_PORT}; do echo waiting for postgresql; sleep 2; done;

    if ! psql postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_HOST/$DB_NAME -c "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'issue';" | grep 1 ; then
        echo 'Initializing PostgreSQL database'
        sleep 10
        psql postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:${DB_PORT}/$DB_NAME -f ../database-scripts/postgresql-full-install-version-$SQUASH_TM_VERSION.RELEASE.sql
    else
        echo 'Database already initialized'
    fi
 sleep 10
elif [[ "${DB_TYPE}" = "h2" ]]; then
    echo 'Using h2'
    DB_URL="jdbc:${DB_TYPE}:${DB_HOST}"

        echo 'Initializing h2 database'
    java -cp h2*.jar org.h2.tools.RunScript -url ${DB_HOST} -script ../database-scripts/h2-full-install-version-$SQUASH_TM_VERSION.RELEASE.sql
fi


#! /bin/sh
#
#     This file is part of the Squashtest platform.
#     Copyright (C) Henix, henix.fr
#
#     See the NOTICE file distributed with this work for additional
#     information regarding copyright ownership.
#
#     This is free software: you can redistribute it and/or modify
#     it under the terms of the GNU Lesser General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     this software is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU Lesser General Public License for more details.
#
#     You should have received a copy of the GNU Lesser General Public License
#     along with this software.  If not, see <http://www.gnu.org/licenses/>.
#


#That script will :
#- check that the java environnement exists,
#- the version is adequate,
#- will run the application


# Default variables
JAR_NAME="squash-tm.war"  # Java main library
HTTP_PORT=${HTTP_PORT:-8080}               # Port for HTTP connector (default 8080; disable with -1)
# Directory variables
TMP_DIR=../tmp                             # Tmp and work directory
BUNDLES_DIR=../bundles                     # Bundles directory
CONF_DIR=../conf                           # Configurations directory
LOG_DIR=../logs                            # Log directory
TOMCAT_HOME=../tomcat-home                 # Tomcat home directory
PLUGINS_DIR=../plugins                     # Plugins directory
# DataBase parameters
DB_TYPE=${DB_TYPE:-"h2"}                       # Database type, one of h2, mysql, postgresql
DB_URL=${DB_URL:-"jdbc:h2:../data/squash-tm"}  # DataBase URL
DB_USERNAME=${DB_USERNAME:-"sa"}               # DataBase username
DB_PASSWORD=${DB_PASSWORD:-"sa"}               # DataBase password
## Do not configure a third digit here
REQUIRED_VERSION=1.8
# Extra Java args
JAVA_ARGS=${JAVA_ARGS:-"-Xms128m -Xmx512m -server"}

# Tests if java exists
echo -n "$0 : checking java environment... ";

java_exists=`java -version 2>&1`;

if [ $? -eq 127 ]
then
    echo;
    echo "$0 : Error : java not found. Please ensure that \$JAVA_HOME points to the correct directory.";
    echo "If \$JAVA_HOME is correctly set, try exporting that variable and run that script again. Eg : ";
    echo "\$ export \$JAVA_HOME";
    echo "\$ ./$0";
    exit -1;
fi

echo "done";

# Create logs , tmp and plugins directories if necessary
if [ ! -e "$LOG_DIR" ]; then
    mkdir $LOG_DIR
fi

if [ ! -e "$TMP_DIR" ]; then
    mkdir $TMP_DIR
fi

# Tests if the version is high enough
echo -n "checking version... ";

NUMERIC_REQUIRED_VERSION=`echo $REQUIRED_VERSION |sed 's/\./0/g'`;
java_version=`echo $java_exists | grep version |cut -d " " -f 3  |sed 's/\"//g' | cut -d "." -f 1,2 | sed 's/\./0/g'`;

if [ $java_version -lt $NUMERIC_REQUIRED_VERSION ]
then
    echo;
    echo "$0 : Error : your JRE does not meet the requirements. Please install a new JRE, required version ${REQUIRED_VERSION}.";
    exit -2;
fi

echo  "done";

# Let's go !
echo "$0 : starting Squash TM... ";

export _JAVA_OPTIONS="-Dspring.datasource.url=${DB_URL} -Dspring.datasource.username=${DB_USERNAME} -Dspring.datasource.password=${DB_PASSWORD} -Duser.language=en"
DAEMON_ARGS="${JAVA_ARGS} -Djava.io.tmpdir=${TMP_DIR} -Dlogging.dir=${LOG_DIR} -jar ${BUNDLES_DIR}/${JAR_NAME} --spring.profiles.active=${DB_TYPE} --spring.config.additional-location=${CONF_DIR}/ --spring.config.name=application,squash.tm.cfg --logging.config=${CONF_DIR}/log4j2.xml --squash.path.bundles-path=${BUNDLES_DIR} --squash.path.plugins-path=${PLUGINS_DIR} --server.port=${HTTP_PORT} --server.tomcat.basedir=${TOMCAT_HOME} "

exec java ${DAEMON_ARGS}

echo
echo 'Squash TM init process complete; ready for start up.'
echo

exec "$@"