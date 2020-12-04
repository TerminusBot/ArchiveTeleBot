# See README.md for build and use

FROM python:3.8-alpine

ARG UID=0
ARG GID=0
ARG MONOLITHVERSION=2.3.1
# Token created by https://t.me/BotFather 
ARG BOTTOKEN=CHANGEME:TOTHETOKENGIVENWHENREGISTERBOT
# Url used to server files
ARG SERVERURL=http://206.189.252.32:8083
ARG SERVERURL2=http://206.189.252.32:8085

ENV UID=$UID \
    GID=$GID \
    MONOLITHVERSION=$MONOLITHVERSION \
    BOTTOKEN=$BOTTOKEN \
    SERVERURL=$SERVERURL \
    SERVERURL2=$SERVERURL2 \
    PATH="/root/.cargo/bin/:${PATH}"

WORKDIR /code

# MONLITH
# First build and install dependency 
# libressl and cargo must stay for monolith to work
# TODO: move libressl-dev 
RUN set -xe \
    && apk add --no-cache --virtual .build-deps1 git tar ca-certificates openssl make g++ \
    && apk add --no-cache libressl-dev su-exec cargo \
    && wget https://github.com/Y2Z/monolith/archive/v${MONOLITHVERSION}.tar.gz -O monolith.tar.gz \
    && tar zxvf monolith.tar.gz \
    && cd monolith* \
    && make install clean \
    && cd .. && rm -rf monolith* \
    && apk del .build-deps1

# Archive code
# modifications made with sed:
#   add telegram bot token
#   change the local server url used to create html index
#   change location of the archive.csv to location of the html so docker can mount
RUN set -xe \
    && apk add --no-cache --virtual .build-deps2 git \
    && pip install archivenow slimit pyTelegramBotAPI requests bs4 \
    && git clone https://github.com/Terminus2049/ArchiveTeleBot.git \
    && mkdir -p /srv/web/mono/ \
    && sed -i "s%\"TOKEN\"%\"$BOTTOKEN\"%g" ArchiveTeleBot/*.py \
    && sed -i "s%http://206.189.252.32:8083/%$SERVERURL/%g" ArchiveTeleBot/*.py \
    && sed -i "s%http://206.189.252.32:8085/%$SERVERURL2/%g" ArchiveTeleBot/*.py \
    && sed -i "s%archive.csv%/srv/web/mono/archive.csv%g" ArchiveTeleBot/*.py \
    && sed -i "s/Title = Title.replace(' ','_')/import re\n        Title = re.sub('[^\\\\w\\\\d_-]', '_', Title, flags=re.UNICODE)\n        print('Title '+Title)/" ArchiveTeleBot/*.py \
    && apk del .build-deps2
#    && sed -i "s%monolith %su-exec $UID:$GID monolith %g" ArchiveTeleBot/*.py \


# cleanup:
# could be the apk del has to be moved to all runs with AP
RUN addgroup -g $GID telegrambot \
    && adduser -D -H -h /code -s /usr/sbin/nologin -u $UID -G telegrambot telegrambot \
    && chown $UID:$GID /code /srv/web/mono \
    && chmod 755 -R /root
## ^^ chmod root because monolith was installed there and su-exec wont work otherwise 

# Add for shiney app based on https://github.com/velaco/alpine-r/blob/master/shiny-3.5.0-r1/Dockerfile

#RUN echo $(whoami)

# if all RUNS not placed together image could wind up being twice as large so if you split for troubleshooting do not forget to combine back into one single RUN command

CMD [ "su-exec", "telegrambot:telegrambot", "python", "./ArchiveTeleBot/ArchiveTeleBot.py" ]

