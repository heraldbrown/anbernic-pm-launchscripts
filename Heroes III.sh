#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}											  
export HOME=/root

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
if [ -z ${TASKSET+x} ]; then
  source $controlfolder/tasksetter
fi

get_controls
																		   
				 
CUR_TTY=/dev/tty0
PORTDIR="/mnt/sdcard/Roms/PORTS/"
SHDIR=$(dirname "$0")
GAMEDIR="$SHDIR/vcmi"
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
					   
cd $GAMEDIR

$ESUDO chmod 666 $CUR_TTY
$ESUDO touch log.txt
$ESUDO chmod 666 log.txt
export TERM=linux
printf "\033c" > $CUR_TTY
				 
printf "\033c" > $CUR_TTY
## RUN SCRIPT HERE

if [ -f "$GAMEDIR/libs/libicudata.so.63.bz2" ]; then
    bzip2 -fd "$GAMEDIR/libs/libicudata.so.63.bz2"
fi
												  
  
if [[ ! -d "${GAMEDIR}/data/" ]]; then
  FILES_TO_REMOVE=()
  BUILDER_OPTIONS=()
  if [ -f setup_heroes_of_might_and_magic_3_*.exe ]; then
# Install from gog installer										  
    FILES_TO_REMOVE+=(setup_heroes_of_might_and_magic_3_*.exe setup_heroes_of_might_and_magic_3_*.bin)
    BUILDER_OPTIONS+=("--gog" setup_heroes_of_might_and_magic_3_*.exe)
  elif [ -d "${GAMEDIR}/cd1" ] && [ -d "${GAMEDIR}/cd2" ]; then
    BUILDER_OPTIONS+=("--cd1" "${GAMEDIR}/cd1" "--cd2" "${GAMEDIR}/cd2")
    FILES_TO_REMOVE+=("${GAMEDIR}/cd1" "${GAMEDIR}/cd2")
  elif [ -d "${GAMEDIR}/install" ]; then
    BUILDER_OPTIONS+=("--data" "${GAMEDIR}/install")
    FILES_TO_REMOVE+=("${GAMEDIR}/install")
  else
    echo "Missing game files, see README for more info." > $CUR_TTY
    sleep 5
    printf "\033c" > $CUR_TTY
    $ESUDO systemctl restart oga_events &
    exit 1
  fi

  LD_LIBRARY_PATH="${PWD}/libs" bin/vcmibuilder --dest "${PWD}/data/" ${BUILDER_OPTIONS[@]}
  $ESUDO rm -fRv ${FILES_TO_REMOVE[@]}
  cd $GAMEDIR
fi

echo "Starting game." > $CUR_TTY
								
export PORTMASTER_HOME="${GAMEDIR}"
export LD_LIBRARY_PATH="${GAMEDIR}/libs:${LD_LIBRARY_PATH}"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
$GPTOKEYB "MainGUI" -c vcmi.gptk &
													   
							

$TASKSET bin/vcmiclient 2>&1 | $ESUDO tee -a ./log.txt
											   
$ESUDO kill -9 $(pidof gptokeyb)
$ESUDO killall -9 tee
unset LD_LIBRARY_PATH
unset SDL_GAMECONTROLLERCONFIG
$ESUDO systemctl restart oga_events &
									 

printf "\033c" > $CUR_TTY
						 
