# Copyright 2023 by the SpinalHDL Docker contributors
# SPDX-License-Identifier: GPL-3.0-only
#
# Author(s): Pavel Benacek <pavel.benacek@gmail.com>

FROM ghcr.io/spinalhdl/docker:master AS base

FROM base AS builder

ARG JAVA_EXTRA_OPTS="-Xmx2g -Xms2g"
ENV JAVA_OPTS="${JAVA_OPTS} ${JAVA_EXTRA_OPTS}"
ENV PATH="/root/.local/share/code-server/bin:${PATH}"

# Install Visual Studio Code 
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
 && sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list' \
 && sudo apt-get update \
 && sudo apt-get install -y code

ARG METALS_VERSION="1.23.0"
ARG EXTENSION_DIR=/root/.vscode-server/extensions
RUN code --install-extension scalameta.metals@${METALS_VERSION} && \
    code --install-extension ms-ceintl.vscode-language-pack-zh-hans && \
    code --install-extension mhutchie.git-graph && \
    code --install-extension donjayamanne.githistory && \
    code --install-extension YuTengjing.open-in-external-app

ENV COURSIER_CMD="$EXTENSION_DIR/scalameta.metals-$METALS_VERSION-universal/coursier"
RUN $COURSIER_CMD install bloop:1.5.6 && \
    $COURSIER_CMD install metals:0.11.12

FROM base AS run

ARG DEPS_RUNTIME="gtkwave"
RUN apt-get update && \
    apt-get install -y --no-install-recommends $DEPS_RUNTIME && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8

ARG JAVA_EXTRA_OPTS="-Xmx2g -Xms2g"
ENV JAVA_OPTS="${JAVA_OPTS} ${JAVA_EXTRA_OPTS}"
RUN git clone https://github.com/Readon/FormalTutorials.git && \ 
    cd FormalTutorials && \
    git checkout docker && \
    git submodule update --init --recursive && \
    sbt compile && \
    mill _.compile && \
    cd .. && rm -rf FormalTutorials

COPY --from=builder /root/.vscode-server/extensions /root/.vscode-server/extensions
COPY --from=builder /sbt/.cache/coursier /sbt/.cache/coursier