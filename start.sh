#!/bin/bash
# Obfuscation script to pull from Github and replace $variables

# Declare variables
source secret.key

ENDER_RESET_TIME='0'
AUTO_UPDATE=1
HEAPSIZE='1024M'
JAR_FILE='server.jar'

#------------------
# Pull from Github
#------------------
if [[ $AUTO_UPDATE == 1 ]]; then
	git reset --hard
	git pull --recurse-submodules
	git submodule update --init --recursive --force
fi

#------------------
# Deobfuscation
#------------------
if [[ $DEOBFUSCATE == 1 ]]; then
	echo "Starting to deobfuscate files..."
	shopt -s nullglob
	for i in server.properties spigot.yml bukkit.yml config.yml waterfall.yml plugins/*/*.yml plugins/*/*.key plugins/*/*.txt plugins/BreakerLandMenu/menus/*.menu;
	do
		for key in "${!secret_key[@]}"
		do 
		  sed -i "s|$key|${secret_key[$key]}|g" $i
		done
	done
	echo "Deobfuscation complete."
fi

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

    -hs|--heap-size)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
      HEAPSIZE=$2
      shift
      else
        echo "Error in -hs|--heap-size syntax. Script failed."
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

    -au|--auto-update)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
      AUTO_UPDATE=$2
      shift
      else
        echo "Error in -au|--auto-update syntax. Script failed."
        exit 1
      fi
      ;;

    --)              # End of all options.
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
# Reset end dimension
#------------------
if [ $ENDER_RESET_TIME > 0 && $(find . -name '*_the_end') ];
then
	ENDER_DIR=$(find . -type d -name "*_the_end" | wc -l)
	ENDER_REGION_DIR=''$ENDER_DIR'/DIM1/region'
	if [ $(find $ENDER_DIR -mtime -$ENDER_RESET_TIME -type f -name "$level.dat" 2>/dev/null) ]; then
	  echo "Time to reset end dimension."
	  rm "$ENDER_DIR/level.dat" "$ENDER_REGION_DIR/r.0.0.mca" "$ENDER_REGION_DIR/r.0.-1.mca" "$ENDER_REGION_DIR/r.-1.0.mca" "$ENDER_REGION_DIR/r.-1.-1.mca"
	else
	  echo "Not time to reset end dimension."
	fi
else
	echo ""
fi

#------------------
# Java arguments
#------------------
G1NewSizePercent=40
G1MaxNewSizePercent=50
G1HeapRegionSize=16
G1ReservePercent=15
InitiatingHeapOccupancyPercent=20

if (($1 < 12000))
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
java -Xms$HEAPSIZE -Xmx$HEAPSIZE -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=${G1NewSizePercent} -XX:G1MaxNewSizePercent=${G1MaxNewSizePercent} -XX:G1HeapRegionSize=${G1HeapRegionSize}M -XX:G1ReservePercent=${G1ReservePercent} -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=${InitiatingHeapOccupancyPercent} -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -Dterminal.jline=false -Dterminal.ansi=true -Dfile.encoding=UTF-8 -Dcom.mojang.eula.agree=true -jar $JAR_FILE nogui
