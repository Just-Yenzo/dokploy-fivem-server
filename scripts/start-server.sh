#!/bin/bash
CUR_V="$(find ${SERVER_DIR} -maxdepth 1 -name 'fiveminstalled-*' | cut -d '-' -f 2,3)"
LAT_V="$(wget -q -O - ${SRV_ADR} | grep -B 1 'LATEST RECOMMENDED' | tail -n -2 | tail -n -1 | grep -oP '(?<=\()[^\)]+')"
DL_URL=${SRV_ADR}"$(wget -q -O - ${SRV_ADR} | grep -B 1 'LATEST RECOMMENDED' | tail -n -2 | head -n -1 | cut -d '"' -f 2 | cut -c 2-)"

mkdir -p ${SERVER_DIR}
chown -R ${USER}:${USER} ${SERVER_DIR}

if [ "${MANUAL_UPDATES}" == "true" ]; then
    if [ "$CUR_V" == "manual" ]; then
        if [ -f ${SERVER_DIR}/fx.tar.xz ]; then
            echo "---File 'fx.tar.xz' found, installing...---"
            rm -f ${SERVER_DIR}/fiveminstalled-*
            cd ${SERVER_DIR}
            tar -xf fx.tar.xz
            rm -f fx.tar.xz
            touch fiveminstalled-manual
            echo "---Installation complete---"
        else
            echo "---FiveM found---"
        fi
    elif [ ! -f ${SERVER_DIR}/fx.tar.xz ]; then
        echo "-------------------------------------------------------------------------"
        echo "-------------------!!!Manual updates enabled!!!--------------------------"
        echo "----------Please put 'fx.tar.xz' in /serverdata and restart--------------"
        echo "-------------------------------------------------------------------------"
        sleep infinity
    else
        echo "---File 'fx.tar.xz' found, installing...---"
        rm -f ${SERVER_DIR}/fiveminstalled-*
        cd ${SERVER_DIR}
        tar -xf fx.tar.xz
        rm -f fx.tar.xz
        touch fiveminstalled-manual
        echo "---Installation complete---"
    fi
else
    if [ ! -f ${SERVER_DIR}/fiveminstalled-* ]; then
        if [ -z "${LAT_V}" ]; then
            if [ ! -f ${SERVER_DIR}/fx.tar.xz ]; then
                echo "-------------------------------------------------------------------------"
                echo "--------Could not get latest game version from master server-------------"
                echo "-----Please put 'fx.tar.xz' in /serverdata and restart the Docker--------"
                echo "-------------------------------------------------------------------------"
                sleep infinity
            else
                echo "---File 'fx.tar.xz' found, installing...---"
                cd ${SERVER_DIR}
                tar -xf fx.tar.xz
                rm -f fx.tar.xz
                touch ${SERVER_DIR}/fiveminstalled-manual
            fi
        else
            echo "---FiveM not found, downloading!---"
            cd ${SERVER_DIR}
            echo "---Attempting download from $DL_URL---"
            if wget -q -nc --show-progress --progress=bar:force:noscroll "$DL_URL"; then
                echo "---Download complete---"
            else
                echo "---Download failed, putting server in sleep mode---"
                sleep infinity
            fi
            tar -xf fx.tar.xz
            rm -f fx.tar.xz
            touch ${SERVER_DIR}/fiveminstalled-$LAT_V
        fi
    fi

    echo "---Version Check---"
    if [ "$CUR_V" == "manual" ]; then
        echo "---Manual version found---"
    elif [ -z "${LAT_V}" ]; then
        echo "---Could not get latest version from master server---"
        if [ -f ${SERVER_DIR}/fx.tar.xz ]; then
            echo "---Installing local fx.tar.xz---"
            rm -f ${SERVER_DIR}/fiveminstalled-*
            cd ${SERVER_DIR}
            tar -xf fx.tar.xz
            rm -f fx.tar.xz
            touch fiveminstalled-manual
        fi
    elif [ "$LAT_V" != "$CUR_V" ]; then
        echo "---Newer version found, installing!---"
        rm -f ${SERVER_DIR}/fiveminstalled-*
        cd ${SERVER_DIR}
        wget -q -nc --show-progress --progress=bar:force:noscroll "$DL_URL"
        tar -xf fx.tar.xz
        rm -f fx.tar.xz
        touch fiveminstalled-$LAT_V
    else
        echo "---FiveM Version up-to-date---"
    fi
fi

if [ ! -d "${SERVER_DIR}/resources" ]; then
  echo "---SERVER-DATA not found, downloading...---"
  cd ${SERVER_DIR}
  wget -qO server-data.zip "http://github.com/citizenfx/cfx-server-data/archive/master.zip"
  unzip -q server-data.zip
  mv ${SERVER_DIR}/cfx-server-data-master/resources ${SERVER_DIR}/resources
  rm server-data.zip && rm -rf cfx-server-data-master/
fi

echo "---Prepare Server---"
if [ ! -f ~/.screenrc ]; then
    echo "defscrollback 30000
bindkey \"^C\" echo 'Blocked. Please use command \"quit\" to exit.'" > ~/.screenrc
fi

if [ ! -z "${GAME_CONFIG}" ] && [ ! -f "${SERVER_DIR}/server.cfg" ]; then
    echo "---No server.cfg found, downloading default one...---"
    cd ${SERVER_DIR}
    wget -q -nc --show-progress --progress=bar:force:noscroll "https://raw.githubusercontent.com/ich777/docker-fivem-server/master/configs/server.cfg"
fi

chmod -R ${DATA_PERM} ${DATA_DIR}
echo "---Checking for old logs---"
find ${SERVER_DIR} -maxdepth 1 -name "masterLog.*" -exec rm -f {} \;

if [ ! -f ${SERVER_DIR}/run.sh ]; then
    echo "---Couldn't find run.sh in /serverdata, sleep mode---"
    sleep infinity
fi

echo "---Starting Server---"
cd ${SERVER_DIR}
if [ -z "${GAME_CONFIG}" ]; then
    screen -S FiveM -L -Logfile ${SERVER_DIR}/masterLog.0 -d -m ${SERVER_DIR}/run.sh +sv_licenseKey ${SERVER_KEY} +sv_hostname "${SRV_NAME}" ${START_VARS}
else
    screen -S FiveM -L -Logfile ${SERVER_DIR}/masterLog.0 -d -m ${SERVER_DIR}/run.sh +exec ${GAME_CONFIG} +sv_licenseKey ${SERVER_KEY} +sv_hostname "${SRV_NAME}" ${START_VARS}
fi

sleep 2
if [ "${ENABLE_WEBCONSOLE}" == "true" ]; then
    /opt/scripts/start-gotty.sh 2>/dev/null &
fi

screen -S watchdog -d -m /opt/scripts/start-watchdog.sh
tail -f ${SERVER_DIR}/masterLog.0
