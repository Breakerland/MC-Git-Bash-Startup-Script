#!/bin/bash
# Obfuscation script to pull from Github and replace $variables

# Variables
# ORIGIN=origin
# BRANCH=master
ender_dir='/home/container/survie_new_the_end'
ender_region_dir=''$ender_dir'/DIM1/region'
ender_level_file='level.dat'
ender_reset_time='7'

# Declare variables
source secret.key

# Pull from Github
git reset --hard
git pull

# Deobfuscate variables
echo "Starting to deobfuscate files..."
shopt -s nullglob
for i in server.properties plugins/*/*.yml plugins/*/*.txt plugins/BreakerLandMenu/menus/*.menu;
do
    for key in "${!secret_key[@]}"
    do 
      sed -i "s|$key|${secret_key[$key]}|g" $i
    done
done
echo "Deobfuscation complete."

# Reset end dimension
if [ $(find $ender_dir -mtime -$ender_reset_time -type f -name "$ender_session_file" 2>/dev/null) ]; then
  echo "Time to reset end dimension."
  rm "$ender_dir/$ender_level_file" "$ender_region_dir/r.0.0.mca" "$ender_region_dir/r.0.-1.mca" "$ender_region_dir/r.-1.0.mca" "$ender_region_dir/r.-1.-1.mca"
else
  echo "Not time to reset end dimension."
fi

if (($1 < 12000))
then
   G1NewSizePercent=30
   G1MaxNewSizePercent=40
   G1HeapRegionSize=8
   G1ReservePercent=20
   InitiatingHeapOccupancyPercent=15
else
   G1NewSizePercent=40
   G1MaxNewSizePercent=50
   G1HeapRegionSize=16
   G1ReservePercent=15
   InitiatingHeapOccupancyPercent=20
fi

# Start server
echo "Starting server..."
java -Xms$1M -Xmx$1M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=$G1NewSizePercent -XX:G1MaxNewSizePercent=$G1MaxNewSizePercent -XX:G1HeapRegionSize=$G1HeapRegionSizeM -XX:G1ReservePercent=$G1ReservePercent -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=$InitiatingHeapOccupancyPercent -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -Dterminal.jline=false -Dterminal.ansi=true -Dfile.encoding=UTF-8 -Dcom.mojang.eula.agree=true -jar server.jar nogui
