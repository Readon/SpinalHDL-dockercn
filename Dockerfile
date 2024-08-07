# Copyright 2023 by the SpinalHDL Docker contributors
# SPDX-License-Identifier: GPL-3.0-only
#
# Author(s): Pavel Benacek <pavel.benacek@gmail.com>
#            Yindong Xiao <xydarcher@163.com>

FROM ghcr.io/spinalhdl/docker:master AS base

FROM base AS builder

ARG JAVA_EXTRA_OPTS="-Xmx2g -Xms2g"
ENV JAVA_OPTS="${JAVA_OPTS} ${JAVA_EXTRA_OPTS}"
# ENV COURSIER_REPOSITORIES="https://repo.huaweicloud.com/repository/maven/"

# Install Visual Studio Code 
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
 && echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list \
 && apt-get update \
 && apt-get install -y code

ARG METALS_VERSION="1.23.0"
ARG DATA_DIR=/root/.vscode-server
ARG EXTENSION_DIR=/root/.vscode/extensions
RUN code --user-data-dir ${DATA_DIR} --install-extension scalameta.metals@${METALS_VERSION} && \
    code --user-data-dir ${DATA_DIR} --install-extension ms-ceintl.vscode-language-pack-zh-hans && \
    code --user-data-dir ${DATA_DIR} --install-extension mhutchie.git-graph && \
    code --user-data-dir ${DATA_DIR} --install-extension donjayamanne.githistory && \
    code --user-data-dir ${DATA_DIR} --install-extension YuTengjing.open-in-external-app

# ARG COURSIER_CMD="$EXTENSION_DIR/scalameta.metals-$METALS_VERSION/coursier"
# RUN $COURSIER_CMD install bloop:1.5.6 && \
#     $COURSIER_CMD install metals:0.11.12

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

COPY --from=builder /root/.vscode-server /root/.vscode-server
COPY --from=builder /root/.vscode/extensions /root/.vscode-server/extensions
# COPY --from=builder /sbt/.cache/coursier /sbt/.cache/coursier