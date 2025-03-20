# syntax=docker/dockerfile:1
ARG python_version=3.12
ARG webchanges_tag=v3.28.1

FROM python:${python_version}-slim-bookworm
ARG webchanges_tag
ENV APP_USER=webchanges
ENV PYTHONUTF8=1

RUN apt-get update && \
    apt-get install -y \
        rsyslog \
        cron \
        tini \
        nodejs \
        npm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Extract version number without the 'v' prefix for pip
RUN WEBCHANGES_VERSION=$(echo ${webchanges_tag} | sed 's/^v//') && \
    python3 -m pip install --no-cache-dir webchanges==${WEBCHANGES_VERSION} && \
    python3 -m pip install --no-cache-dir \
        html5lib \
        beautifulsoup4 \
        jsbeautifier \
        cssbeautifier \
        jq \
        chump \
        pyopenssl \
        minidb \
        python-dateutil \
        zstandard \
        vobject && \
    python3 -m pip install --no-cache-dir webchanges[use_browser]

# Install browser for webchanges
RUN playwright install chrome

WORKDIR /

RUN addgroup $APP_USER && \
    adduser --disabled-password --ingroup $APP_USER $APP_USER

RUN mkdir -p /data/webchanges && \
    chown -R $APP_USER:$APP_USER /data/webchanges && \
    chmod 0755 /data/webchanges

VOLUME /data/webchanges

COPY crontabfile ./crontabfile
COPY run.sh ./run.sh
RUN chmod +x ./run.sh

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/bin/bash", "run.sh"]
