#!/usr/bin/env bash


PORT=9087

port_test="ss -tunlp sport eq :$PORT"
occupied=`$port_test`
occupied=`echo "$occupied" | grep ":$PORT"`
while [ ! -z "$occupied" ]; do
    PORT=$(shuf -i 9000-9999 -n1)
    port_test="ss -tunlp sport eq :$PORT"
    occupied=`$port_test`
    occupied=`echo "$occupied" | grep ":$PORT"`
done
	

WORKDIR=$(pwd)/..
echo "port: $PORT, home: $WORKDIR" | tee -a $HOME/spot.txt

while test $# -gt 0; do
    case "$1" in
        -h|--help)
          echo "$package - attempt to capture frames"
          echo " "
          echo "$package [options] application [arguments]"
          echo " "
          echo "options:"
          echo "-h, --help                      show brief help"
          echo "-p, --port 9000                 specify port to use"
          echo "-w, --workdir $WORKDIR          specify a work directory to mount"
          exit 0
          ;;
        -p|--port)
            shift
            if test $# -gt 0; then
                PORT=$1
            else
                echo "port unspecified, using default: $PORT"
            fi
            shift
            ;;
       -w|--workdir)
            shift
            if test $# -gt 0; then
                PORT=$1
            else
                echo "workdir unspecified, using default: $WORKDIR"
            fi  
            shift
            ;;
       *)
            break
            ;;
    esac
done

cmd="docker run -it --rm --privileged --gpus all --name rstudio_$PORT -e RSTUDIO_PORT=$PORT -p $PORT:$PORT -v $WORKDIR:/home/rstudio/workdir rstudio rstudio-server start"
echo "running RStudio on port $PORT in directory $WORKDIR"
eval $cmd
