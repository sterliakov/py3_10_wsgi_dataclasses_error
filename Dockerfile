FROM python:3.10-slim

ARG APP_USER
ARG SERVER_ADMIN
ARG SERVER_NAME
ARG DEBIAN_FRONTEND=noninteractive

ADD requirements.txt /requirements.txt
RUN mkdir -p /var/www/html/proof/
WORKDIR /var/www/html
RUN set -ex \
    && python -m venv pyenv && . pyenv/bin/activate \
    && RUN_DEPS="libpcre3 mime-support apache2" \
    && BUILD_DEPS="build-essential  apache2-dev" \
    && apt-get update && apt-get install -y --no-install-recommends $RUN_DEPS $BUILD_DEPS \
    && pip install --no-cache-dir -U pip \
    && pip install --no-cache-dir -r /requirements.txt \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $BUILD_DEPS \
    && mod_wsgi-express install-module | tee /etc/apache2/mods-available/wsgi_express.load /etc/apache2/mods-available/wsgi_express.conf

RUN groupadd -r ${APP_USER} && useradd --no-log-init -r -g ${APP_USER} ${APP_USER}
RUN mkdir -p /var/log/apache2 && chown -R ${APP_USER} /var/log/apache2/ && chmod -R 777 /var/log/apache2/ && \
    mkdir -p /var/run/apache2 && chown -R ${APP_USER} /var/run/apache2/ && chmod -R 777 /var/run/apache2/
RUN printf "export APP_USER=\"$APP_USER\"\nexport SERVER_ADMIN=\"$SERVER_ADMIN\"\nexport SERVER_NAME=\"$SERVER_NAME\"" >> /etc/apache2/envvars
RUN a2enmod wsgi_express

ADD ./wsgi.py ./proof/wsgi.py

ADD ./site.conf /etc/apache2/sites-available/000-default.conf
RUN service apache2 start
USER ${APP_USER}:${APP_USER}
ENTRYPOINT apache2ctl -D FOREGROUND
