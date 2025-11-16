ARG SIGNAL_CLI_VERSION=0.13.9
ARG LIBSIGNAL_CLIENT_VERSION=0.58.2
# ARG SIGNAL_CLI_NATIVE_PACKAGE_VERSION=0.13.7+morph027+1

# ARG SWAG_VERSION=1.6.7
ARG GRAALVM_VERSION=21.0.0

ARG BUILD_VERSION_ARG=unset

# FROM golang:1.22-bookworm AS buildcontainer
FROM signal:test AS buildcontainer

ARG SIGNAL_CLI_VERSION
ARG LIBSIGNAL_CLIENT_VERSION
# ARG SWAG_VERSION
ARG GRAALVM_VERSION
ARG BUILD_VERSION_ARG
# ARG SIGNAL_CLI_NATIVE_PACKAGE_VERSION

# COPY ext/libraries/libsignal-client/v${LIBSIGNAL_CLIENT_VERSION} /tmp/libsignal-client-libraries
# # COPY ext/libraries/libsignal-client/signal-cli-native.patch /tmp/signal-cli-native.patch
# # COPY ext/patches/signal-cli-native-arch.patch /tmp/signal-cli-native-arch.patch

# # use architecture specific libsignal_jni.so
# RUN arch="$(uname -m)"; \
#         case "$arch" in \
#             aarch64) \
# 							# mkdir -p /usr/lib/aarch64-linux-gnu/ && \
# 							cp /tmp/libsignal-client-libraries/arm64/libsignal_jni.so /tmp/libsignal_jni.so ;; \
# 							# cp /tmp/libsignal-client-libraries/arm64/libsignal_jni.so /usr/lib/aarch64-linux-gnu/ ;; \
# 			armv7l) cp /tmp/libsignal-client-libraries/armv7/libsignal_jni.so /tmp/libsignal_jni.so ;; \
#             x86_64) cp /tmp/libsignal-client-libraries/x86-64/libsignal_jni.so /tmp/libsignal_jni.so ;; \
# 			*) echo "Unknown architecture" && exit 1 ;; \
#         esac;

# RUN dpkg-reconfigure debconf --frontend=noninteractive \
# 	&& apt-get -qq update \
# 	&& apt-get -qqy install --no-install-recommends \
# 		wget software-properties-common git locales zip unzip \
# 		file build-essential libz-dev zlib1g-dev < /dev/null > /dev/null \
# 	&& rm -rf /var/lib/apt/lists/*

# RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
#     dpkg-reconfigure --frontend=noninteractive locales && \
#     update-locale LANG=en_US.UTF-8

# ENV JAVA_OPTS="-Djdk.lang.Process.launchMechanism=vfork"

# ENV LANG en_US.UTF-8


# RUN arch="$(uname -m)"; \
#         case "$arch" in \
#             aarch64) wget -nv https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-${GRAALVM_VERSION}/graalvm-community-jdk-${GRAALVM_VERSION}_linux-aarch64_bin.tar.gz -O /tmp/gvm.tar.gz ;; \
#             armv7l) echo "GRAALVM doesn't support 32bit" ;; \
#             x86_64) wget -nv https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-${GRAALVM_VERSION}/graalvm-community-jdk-${GRAALVM_VERSION}_linux-x64_bin.tar.gz -O /tmp/gvm.tar.gz ;; \
# 			*) echo "Invalid architecture" ;; \
#         esac;

# RUN cd /tmp && mkdir -p /tmp/graalvm && tar xf gvm.tar.gz -C /tmp/graalvm --strip-components=1
COPY . /tmp/signal-cli

RUN cd /tmp/signal-cli \
		&& sed -i 's/Signal-Android\/5.22.3/Signal-Android\/5.51.7/g' src/main/java/org/asamk/signal/BaseConfig.java

RUN cd /tmp/signal-cli \
		&& export GRAALVM_HOME=/tmp/graalvm \
		&& export PATH=/tmp/graalvm/bin:$PATH \
		&& ./gradlew build

RUN cd /tmp/signal-cli \
		&& export GRAALVM_HOME=/tmp/graalvm \
		&& export PATH=/tmp/graalvm/bin:$PATH \
		&& ./gradlew installDist

RUN cd /tmp/signal-cli \
		&& export GRAALVM_HOME=/tmp/graalvm \
		&& export PATH=/tmp/graalvm/bin:$PATH \
		&& ./gradlew distTar

RUN cd /tmp/signal-cli \
		&& export GRAALVM_HOME=/tmp/graalvm \
		&& export PATH=/tmp/graalvm/bin:$PATH \
		&& ./gradlew fatJar

RUN cd /tmp/signal-cli \
		&& export GRAALVM_HOME=/tmp/graalvm \
		&& export PATH=/tmp/graalvm/bin:$PATH \
		&& ./gradlew run --args="--help"

RUN cd /tmp/signal-cli \
		&& ls build/install/signal-cli/lib/libsignal-client-${LIBSIGNAL_CLIENT_VERSION}.jar || (echo "\n\nsignal-client jar file with version ${LIBSIGNAL_CLIENT_VERSION} not found. Maybe the version needs to be bumped in the signal-cli-rest-api Dockerfile?\n\n" && echo "Available version: \n" && ls build/install/signal-cli/lib/libsignal-client-* && echo "\n\n" && exit 1)

RUN cd /tmp \
		&& cp signal-cli/build/install/signal-cli/lib/libsignal-client-${LIBSIGNAL_CLIENT_VERSION}.jar libsignal-client.jar \
		&& zip -qu libsignal-client.jar libsignal_jni.so


RUN cp /tmp/signal-cli/build/install/signal-cli/lib/libsignal-client-${LIBSIGNAL_CLIENT_VERSION}.jar /tmp/signal-cli/lib/libsignal-client-${LIBSIGNAL_CLIENT_VERSION}.jar

# RUN ls /tmp/signal-cli/lib/libsignal-client-${LIBSIGNAL_CLIENT_VERSION}.jar || (echo "\n\nsignal-client jar file with version ${LIBSIGNAL_CLIENT_VERSION} not found. Maybe the version needs to be bumped in the signal-cli-rest-api Dockerfile?\n\n" && echo "Available version: \n" && ls /tmp/signal-cli/lib/libsignal-client-* && echo "\n\n" && exit 1)

RUN cp /tmp/signal-cli/build/install/signal-cli/lib/signal-cli-*.jar /tmp/signal-cli/lib/

# workaround until upstream is fixed
RUN cd /tmp/signal-cli/lib \
	&& unzip signal-cli-${SIGNAL_CLI_VERSION}.jar \
	&& sed -i 's/Signal-Android\/5.22.3/Signal-Android\/5.51.7/g' org/asamk/signal/BaseConfig.class \
	&& zip -r signal-cli*.jar org/ META-INF/ \
	&& rm -rf META-INF \
	&& rm -rf org

RUN cd /tmp/ \
	&& zip -qu /tmp/signal-cli/lib/libsignal-client-${LIBSIGNAL_CLIENT_VERSION}.jar libsignal_jni.so \
	&& zip -qr signal-cli.zip signal-cli/* \
	&& rm -rf /opt/signal-cli \
  && unzip -q /tmp/signal-cli.zip -d /opt \
	&& rm -f /tmp/signal-cli.zip







FROM ubuntu:jammy

ENV GIN_MODE=release

ENV PORT=8080

ARG SIGNAL_CLI_VERSION
ARG BUILD_VERSION_ARG

ENV BUILD_VERSION=$BUILD_VERSION_ARG

RUN dpkg-reconfigure debconf --frontend=noninteractive \
	&& apt-get -qq update \
	&& apt-get -qq install -y --no-install-recommends util-linux supervisor netcat openjdk-21-jre curl libc6 < /dev/null > /dev/null \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/lib/aarch64-linux-gnu/jni \
	&& mkdir -p /usr/java/packages/lib


COPY --from=buildcontainer /tmp/libsignal_jni.so /usr/lib/aarch64-linux-gnu/jni/
COPY --from=buildcontainer /tmp/libsignal_jni.so /usr/lib/aarch64-linux-gnu/
COPY --from=buildcontainer /tmp/libsignal_jni.so /usr/java/packages/lib/

RUN chmod 755 /usr/lib/aarch64-linux-gnu/jni/libsignal_jni.so \
    && chmod 755 /usr/lib/aarch64-linux-gnu/libsignal_jni.so \
    && chmod 755 /usr/java/packages/lib/libsignal_jni.so

ENV JAVA_OPTS="-Djava.library.path=/usr/lib/aarch64-linux-gnu/jni:/usr/lib/aarch64-linux-gnu:/usr/java/packages/lib -Djdk.lang.Process.launchMechanism=vfork"

COPY --from=buildcontainer /tmp/signal-cli/build/install/signal-cli /opt/signal-cli
COPY entrypoint.sh /entrypoint.sh

RUN ls /opt/signal-cli/lib/

RUN groupadd -g 1000 signal-api \
	&& useradd --no-log-init -M -d /home -s /bin/bash -u 1000 -g 1000 signal-api \
	&& ln -s /opt/signal-cli/bin/signal-cli /usr/bin/signal-cli \
	&& mkdir -p /signal-cli-config/ \
	&& mkdir -p /home/.local/share/signal-cli

EXPOSE ${PORT}

ENV SIGNAL_CLI_CONFIG_DIR=/home/.local/share/signal-cli
ENV SIGNAL_CLI_UID=1000
ENV SIGNAL_CLI_GID=1000

ENTRYPOINT ["/entrypoint.sh"]
