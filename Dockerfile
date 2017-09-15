FROM node

# Install packages needed for deployment
RUN apt-get update && \
    apt-get install -y \
    --no-install-recommends \
    ca-certificates \
    python3-dev \
    python3-pip \
    jq \
    unzip \
    ocaml \
    libelf-dev \
    && rm -rf /var/lib/apt/lists/*
RUN pip3 install awscli

# Install nvm
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
ENV NVM_DIR="/home/node/.nvm"
RUN mv /root/.nvm $NVM_DIR && chown -R node:node $NVM_DIR

# Wrap nvm into a script
RUN /bin/echo -e '#! /bin/bash\n\
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"\n\
nvm $@'\
>> /bin/nvm
RUN chmod 0755 /bin/nvm

# Install Docker (for remote builds)
RUN set -x &&\
    VER="latest" &&\
    curl -L -o /tmp/docker-$VER.tgz https://get.docker.com/builds/Linux/x86_64/docker-$VER.tgz &&\
    tar -xz -C /tmp -f /tmp/docker-$VER.tgz &&\
    mv /tmp/docker/* /usr/bin

# Install Terraform
ENV TERRAFORM_VERSION=0.9.11
RUN curl -o terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform.zip -d /usr/bin && rm -f terraform.zip

# Install Java
RUN apt-get update && apt-get install -y --no-install-recommends \
		bzip2 \
		unzip \
		xz-utils \
	&& rm -rf /var/lib/apt/lists/*

RUN echo 'deb http://deb.debian.org/debian jessie-backports main' > /etc/apt/sources.list.d/jessie-backports.list

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home

ENV JAVA_HOME /usr/lib/jvm/default-java

RUN set -x \
	&& apt-get update \
	&& apt-get install -y \
		default-jdk \
		ca-certificates-java \
	&& rm -rf /var/lib/apt/lists/* \
	&& [ "$JAVA_HOME" = "$(docker-java-home)" ]

# see CA_CERTIFICATES_JAVA_VERSION notes above
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure
