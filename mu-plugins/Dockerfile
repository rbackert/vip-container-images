FROM ghcr.io/automattic/vip-container-images/alpine:3.18.2@sha256:367c1c2028f27954eee67c4ce681459edb240044561848d013e079ad9cce6cff

RUN \
    apk add --no-cache git && \
    git clone --depth 1 --no-remote-submodules -b staging https://github.com/Automattic/vip-go-mu-plugins /mu-plugins && \
    git clone --depth 1 https://github.com/Automattic/vip-go-mu-plugins-ext /mu-plugins-ext && \
    cd /mu-plugins && \
    sed -i -e "s,git@github.com:,https://github.com/," .gitmodules && \
    git submodule update --init --recursive --depth 1 && \
    rsync -a -r --delete --exclude-from="/mu-plugins-ext/.dockerignore" /mu-plugins-ext/* /mu-plugins && \
    rm -rf /mu-plugins-ext && \
    rm -rf /mu-plugins/tests /mu-plugins/__tests__ /mu-plugins/bin /mu-plugins/ci && \
    gitsha=$(git rev-parse --short HEAD) && gitdate=$(git show -s --format=%cs "$gitsha") && date=$(date -d "$gitdate" '+%Y%m%d') && echo "{ \"tag\": \"staging\", \"stack_version\": \"${date}-${gitsha}\" }" > "/mu-plugins/.version" && \
    install -d -m 0755 /shared

COPY run.sh /run.sh

VOLUME ["/shared"]
CMD ["/bin/sh", "/run.sh"]
