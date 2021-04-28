#!/bin/bash
if [[ -z $RSTUDIO_PORT ]]; then
	RSTUDIO_PORT=9087
fi

echo "$UPASSWD" >> /etc/passwd

echo "www-port=$RSTUDIO_PORT" >> /etc/rstudio/rserver.conf

su -c "rstudio-server start" rstudio

eval "$@"
