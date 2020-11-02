#!/bin/bash
# Obfuscation script to pull from Github and replace $variables

# Declare variables
source /home/config/secret.key

ENDER_RESET_TIME='0'
UPDATE_SERVER=1
UPDATE_PLUGIN=1
HEAPSIZE=1024
JAR_FILE='server.jar'
DEOBFUSCATE=1

#------------------
# Begin Switches
#------------------
while [ "$#" -gt 0 ];
do
  case "$1" in
    -h|--help)
      echo "-h|--help was triggered"
      exit 1
      ;;

    -e|--ender)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
      ENDER_RESET_TIME=$2
      shift
      else
        echo "Error in -e|--ender syntax. Script failed."
        exit 1
      fi
      ;;

	-xms|--min-heap-size)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
      MIN_HEAP_SIZE=$2
      shift
      else
        echo "Error in -hs|--heap-size syntax. Script failed."
        exit 1
      fi
      ;;

    -xmx|--max-heap-size)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
      MAX_HEAP_SIZE=$2
      shift
      else
        echo "Error in -hs|--heap-size syntax. Script failed."
        exit 1
      fi
      ;;

    -n|--name)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
      SERVER_NAME=$2
      shift
      else
        echo "Error in -n|--name syntax. Script failed."
        exit 1
      fi
      ;;

    -jf|--jar-file)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
      JAR_FILE=$2
      shift
      else
        echo "Error in -jf|--jar-file syntax. Script failed."
        exit 1
      fi
      ;;

    -us|--update-server)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
      UPDATE_SERVER=$2
      shift
      else
        echo "Error in -us|--update-server syntax. Script failed."
        exit 1
      fi
      ;;

    -up|--update-plugin)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
      UPDATE_PLUGIN=$2
      shift
      else
        echo "Error in -up|--update-plugin syntax. Script failed."
        exit 1
      fi
      ;;

    -d|--deobfuscate)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
      DEOBFUSCATE=$2
      shift
      else
        echo "Error in -d|--deobfuscate syntax. Script failed."
        exit 1
      fi
      ;;

    --) # End of all options.
        shift
        break
        ;;

    -?*)
        printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
        ;;

    '') # Empty case: If no more options then break out of the loop.
        break
        ;;

    *)  # Anything unrecognized
        echo "The value "$1" was not expected. Script failed."
        exit 1
        ;;
  esac

  shift
done

#------------------
# DEFINE SERVER NAME
#------------------
SERVER_NAME=${secret_key['$server_name_'$SERVER_NAME]}
if [ -z "$SERVER_NAME" ]; then
	echo "Please set a correct server name using --name"
	exit 1
fi

#------------------
# Pull from Github
#------------------
if [[ $UPDATE_SERVER == 1 ]]; then
	git reset --hard
	git pull --recurse-submodules
	git submodule update --init --recursive --force
fi

#------------------
# Deobfuscation
#------------------
if [[ $DEOBFUSCATE == 1 ]]; then
	echo "Starting to deobfuscate files..."
	for i in $(find . -regextype posix-basic -regex '.*/.\{1,13\}.\(yml\|txt\|menu\|properties\|key\|conf\|php\)');
	do
		sed -i "s|\$server_name$|$SERVER_NAME|g" $i
		for key in "${!secret_key[@]}"
		do
		  sed -i "s|$key|${secret_key[$key]}|g" $i
		done
	done
	echo "Deobfuscation complete."
fi

#------------------
# Reset end dimension
#------------------
if [[ $ENDER_RESET_TIME > 0 && $(find . -name '*_the_end') ]];
then
	ENDER_DIR=$(find . -type d -name "*_the_end" | wc -l)
	ENDER_REGION_DIR=''$ENDER_DIR'/DIM1/region'
	if [ $(find $ENDER_DIR -mtime -$ENDER_RESET_TIME -type f -name "$level.dat" 2>/dev/null) ]; then
	  echo "Time to reset end dimension."
	  rm "$ENDER_DIR/level.dat" "$ENDER_REGION_DIR/r.0.0.mca" "$ENDER_REGION_DIR/r.0.-1.mca" "$ENDER_REGION_DIR/r.-1.0.mca" "$ENDER_REGION_DIR/r.-1.-1.mca"
	else
	  echo "Not time to reset end dimension."
	fi
fi

#------------------
# Update plugins
#------------------
if [[ $UPDATE_PLUGIN > 0 ]];
then
    rm plugins/*.jar
	for i in $(awk '/\|/ {print $2}' plugin.md)
	do
		find /home/plugins/ -iname $i'[\-.0-9 ]*jar' -exec cp "{}" plugins  \;
	done
fi

#------------------
# Java arguments
#------------------
G1NewSizePercent=40
G1MaxNewSizePercent=50
G1HeapRegionSize=16
G1ReservePercent=15
InitiatingHeapOccupancyPercent=20

if (($MAX_HEAP_SIZE < 12000))
then
   G1NewSizePercent=30
   G1MaxNewSizePercent=40
   G1HeapRegionSize=8
   G1ReservePercent=20
   InitiatingHeapOccupancyPercent=15
fi

#------------------
# Java startup
#------------------
echo "Starting server..."
java -Xms${MIN_HEAP_SIZE}M -Xmx${MAX_HEAP_SIZE}M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=${G1NewSizePercent} -XX:G1MaxNewSizePercent=${G1MaxNewSizePercent} -XX:G1HeapRegionSize=${G1HeapRegionSize}M -XX:G1ReservePercent=${G1ReservePercent} -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=${InitiatingHeapOccupancyPercent} -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -Dterminal.jline=false -Dterminal.ansi=true -Dfile.encoding=UTF-8 -Dcom.mojang.eula.agree=true -jar $JAR_FILE nogui