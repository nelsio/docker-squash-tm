FROM alpine:3.7

ENV SQUASH_TM_VERSION='1.20.0'
ENV SQUASH_TM_URL='http://repo.squashtest.org/distribution/squash-tm-1.20.0.RELEASE.tar.gz'
ENV SQUASTM_HOME='/etc/squash-tm/bin'

RUN apk add \
	postgresql-client \
	mysql-client \
	openjdk8-jre \
	curl \
	nano

RUN cd /etc && \
	curl -L ${SQUASH_TM_URL} | tar xzv

COPY docker-entrypoint.sh /etc/squash-tm/bin/docker-entrypoint.sh

RUN chmod +x /etc/squash-tm/bin/docker-entrypoint.sh

EXPOSE 8080

WORKDIR ${SQUASTM_HOME}

ENTRYPOINT ["/etc/squash-tm/bin/docker-entrypoint.sh"]
