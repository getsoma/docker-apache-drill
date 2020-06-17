FROM alpine:3.6

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL \
    maintainer="smizy" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.docker.dockerfile="/Dockerfile" \
    org.label-schema.license="Apache License 2.0" \
    org.label-schema.name="smizy/apache-drill" \
    org.label-schema.url="https://github.com/smizy" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/smizy/docker-apache-drill"

# ENV DRILL_VERSION            $VERSION
ENV DRILL_VERSION            1.17.0
ENV DRILL_HOME               /usr/local/apache-drill-${DRILL_VERSION}
ENV DRILL_CONF_DIR           ${DRILL_HOME}/conf
ENV DRILL_JARS_DIR           ${DRILL_HOME}/jars
ENV DRILL_LOG_DIR            /var/log/drill
ENV DRILL_HEAP               4G
ENV DRILL_MAX_DIRECT_MEMORY  8G
ENV DRILLBIT_MAX_PERM        512M
ENV DRILLBIT_CODE_CACHE_SIZE 1G
ENV DRILL_CLUSTER_ID         drillbits1
ENV DRILL_ZOOKEEPER_QUORUM   zookeeper:2181

ENV JAVA_HOME   /usr/lib/jvm/default-jvm
ENV PATH        $PATH:${JAVA_HOME}/bin:${DRILL_HOME}/bin

RUN set -x \
    && apk --no-cache add \
        bash \
        java-snappy-native \
        libc6-compat \
        openjdk8 \
        procps \
        su-exec \ 
    && mirror_url=http://apache.mirrors.pair.com/ \
    && wget -q -O - ${mirror_url}/drill/drill-${DRILL_VERSION}/apache-drill-${DRILL_VERSION}.tar.gz \
        | tar -xzf - -C /usr/local \
    ## user/dir/permmsion
    && adduser -D  -g '' -s /sbin/nologin -u 1000 docker \
    && adduser -D  -g '' -s /sbin/nologin -G docker drill \
    && mkdir -p \
        ${DRILL_LOG_DIR} \
    && chown -R drill:docker \
        ${DRILL_HOME} \
        ${DRILL_LOG_DIR} \
    && sed -i.bk -e 's/MaxPermSize/MaxMetaspaceSize/g' ${DRILL_CONF_DIR}/drill-env.sh \
    && sed -i.bk -e 's/MaxPermSize/MaxMetaspaceSize/g' ${DRILL_HOME}/bin/drill-config.sh  

RUN cd security \
    && mvn clean install
COPY target/*.jar  ${DRILL_JARS_DIR}

COPY etc/*  ${DRILL_CONF_DIR}/
COPY bin/*  /usr/local/bin/ 
COPY lib/*  /usr/local/lib/ 
 
VOLUME ["${DRILL_LOG_DIR}"]

WORKDIR ${DRILL_HOME}

EXPOSE 8047

ENTRYPOINT ["entrypoint.sh"]
CMD ["drillbit" ]
