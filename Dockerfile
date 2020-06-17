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

# Downloading and installing Maven
RUN apk add --no-cache curl tar bash procps nss

# 1- Define a constant with the version of maven you want to install
ARG MAVEN_VERSION=3.6.3         

# 2- Define a constant with the working directory
ARG USER_HOME_DIR="/root"

# 3- Define the SHA key to validate the maven download
ARG SHA=c35a1803a6e70a126e80b2b3ae33eed961f83ed74d18fcd16909b2d44d7dada3203f1ffe726c17ef8dcca2dcaa9fca676987befeadc9b9f759967a8cb77181c0

# 4- Define the URL where maven can be downloaded from
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

# 5- Create the directories, download maven, validate the download, install it, remove downloaded file and set links
RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && echo "Downloading maven" \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  \
  && echo "Checking download hash" \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  \
  && echo "Unziping maven" \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  \
  && echo "Cleaning and setting links" \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

# 6- Define environmental variables required by Maven, like Maven_Home directory and where the maven repo is located
ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

COPY security/*  ${DRILL_HOME}/security/
RUN mvn -f ${DRILL_HOME}/security/pom.xml clean package \
    && cp ${DRILL_HOME}/security/target/*.jar  ${DRILL_JARS_DIR} \
    && cp ${DRILL_HOME}/security/target/libs/*.jar  ${DRILL_JARS_DIR} 

COPY etc/*  ${DRILL_CONF_DIR}/
COPY bin/*  /usr/local/bin/ 
COPY lib/*  /usr/local/lib/ 
 
VOLUME ["${DRILL_LOG_DIR}"]

WORKDIR ${DRILL_HOME}

EXPOSE 8047

ENTRYPOINT ["entrypoint.sh"]
CMD ["drillbit" ]
