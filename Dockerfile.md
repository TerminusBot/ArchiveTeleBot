# ArchiveTeleBot_Dockerfile

Docker configuration to run https://github.com/Terminus2049/ArchiveTeleBot telegram archive.org/is bot.

The original source has various hard coded values which this Dockerfile will allow you to change through argumenits:

* **`BOTTOKEN`** is your Telegram bot key and will be used to replace all `"TOKEN"` strings within the code
* **`SERVERURL`** is the archive server URL that is by default hard coded to `http://206.189.252.32:8083` and should be changed for non-terminus2049 instances
* **`SERVERURL2`** is the archive server URL that is by default hard coded to `http://206.189.252.32:8085` and should be changed for non-terminus2049 instances. This is only relevant if you intend to run `Archive_by_2049bbsBot.py`
* **`UID`** and **`GID`** are used to change the user that code will runs as (via su-exec)

`BOTTOKEN` is required. The rest are optional. Note: this version will also change the location where the archive.csv is stored to be the same as where the archive pages (saved by monolith) are stored: `/srv/web/mono` in docker host.

# Get bot key

from t.me/BotFather place provided key into a local file named `bottoken` or change the value in the build commands with the key value provided from BotFather.

# Local build

The bottoken value is taken from a `./bottoken` file that should only contain the telegram bot token. Replace other wise.

    docker build \
     --rm=false \
     --build-arg UID=`id -u` --build-arg GID=`id -g` \
     --build-arg BOTTOKEN="`cat ./bottoken | head -1`" \
     --build-arg SERVERURL=http://localhost:8000 \
     --build-arg SERVERURL2=http://localhost:8000 \
     -t telegrambot . 


# Production Build

This creates a /home/apps/telegrambot directory on the docker server/host to store archive data. Change to your needs (e.g. change the YOURSERVER string in the build command). 

    id telegrambot \
      || useradd --no-create-home \
                 --home-dir /home/apps/telegrambot \
                 -s /usr/sbin/nologin \
                 telegrambot
    mkdir -p /home/apps/telegrambot/data
    chown -R telegrambot:telegrambot  /home/apps/telegrambot

    docker build \
     --rm \
     --build-arg UID=`id telegrambot -u` \
     --build-arg GID=`id telegrambot -g` \
     --build-arg BOTTOKEN="`cat ./bottoken | head -1`" \
     --build-arg SERVERURL=https://YOURSERVER/archive \
     --build-arg SERVERURL2=https://YOURSERVER/archive \
     -t telegrambot .

# Install

add to rc.local or append --restart=always to the following:

    DIR=/home/apps/telegrambot
    docker run --rm -d -v $DIR/data:/srv/web/mono --name telegrambot -it telegrambot &


# Serving local archive

ArchiveTeleBot uses monolith to make a local copy of the requested page. This is saved into /srv/web/mono in the docker host. The examples above use `-v` to map this to a local directory. You can then serve this directory.

Serve using a quick python web server: `cd data; python3 -m http.server`

Serve using a nginx file explorer configuration added to an existing server config:

    location /archive {
      alias /home/apps/telegrambot/data;
      autoindex on;
      include /etc/nginx/mime.types;
      types {
        text/plain csv;
        text/html  html;
      }
    }


# Testing

    mkdir data

    docker run --rm -v `pwd`/data:/srv/web/mono --name telegrambot -it telegrambot /bin/ash

    docker run --rm -v `pwd`/data:/srv/web/mono --name telegrambot -it telegrambot su-exec telegrambot:telegrambot monolith https://google.com -o /srv/web/mono/test.html
    
    docker run --rm -v `pwd`/data:/srv/web/mono --name telegrambot -it telegrambot su-exec telegrambot:telegrambot python ArchiveTeleBot/ArchiveTeleBot.py
    
    docker run --rm -v `pwd`/data:/srv/web/mono --name telegrambot -it telegrambot su-exec telegrambot:telegrambot python ArchiveTeleBot/Archive_by_2049bbsBot.py
    
    docker run --rm -v `pwd`/data:/srv/web/mono --name telegrambot -it telegrambot

    python3 -m http.server

