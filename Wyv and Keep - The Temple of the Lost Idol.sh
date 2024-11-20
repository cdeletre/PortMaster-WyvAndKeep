#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

# PM
source "${controlfolder}/control.txt"
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls
source "${controlfolder}/tasksetter"

# Variables
GAMEDIR="/${directory}/ports/wyvandkeep"
cd "${GAMEDIR}"

> "${GAMEDIR}/log.txt" && exec > >(tee "${GAMEDIR}/log.txt") 2>&1

# Patcher config
export PATCHER_FILE="${GAMEDIR}/tools/install_wyvandkeep"
export PATCHER_GAME="$(basename "${0%.*}")" # This gets the current script filename without the extension
export PATCHER_TIME="1 to 5 minutes"

# -------------------- BEGIN FUNCTIONS --------------------

find_game_package()
{
  echo "Searching game package"
  find $1 -iname "*wyv*and*keep*bin" -print0 |
  while IFS= read -r -d '' line; do
    echo -n "Checking $line "
    unzip -l $line | grep -i "WyvAndKeep.exe" 2>&1 >/dev/null
    if [[ $? -eq 0 ]];then
      echo "- found WyvAndKeep.exe"
      mv "${line}" "${GAMEDIR}/gamepackage.bin"
      return 0
    fi
    echo "- WyvAndKeep.exe not found"
  done

  [[ -f "${GAMEDIR}/gamepackage.bin" ]] && return 0
  echo "Game package not found"
  return 1
}

# --------------------- END FUNCTIONS ---------------------

# Setup mono
monodir="${HOME}/mono"
monofile="${controlfolder}/libs/mono-6.12.0.122-aarch64.squashfs"
$ESUDO mkdir -p "${monodir}"
$ESUDO umount "${monofile}" || true
$ESUDO mount "${monofile}" "${monodir}"

bind_directories "${HOME}/.local/share/WyvAndKeep" "${GAMEDIR}/savedata"

# Setup path and other environment variables
export MONO_PATH="${GAMEDIR}/dlls"
export LD_LIBRARY_PATH="${GAMEDIR}/libs:${LD_LIBRARY_PATH}"
export PATH="${monodir}/bin:${PATH}"

if [[ ! -f "${GAMEDIR}/gamedata/WyvAndKeep.exe" ]];then
    find_game_package
    if [[ ! $? -eq 0 ]]; then
      "${GAMEDIR}/tools/text_viewer" -e -f 25 -w -t "Game files missing" -m "Game files are missing. Copy wyvandkeep-bin into the wyvandkeep port folder"
      exit 1
    fi
    if [[ -f "${controlfolder}/utils/patcher.txt" ]]; then
        source "${controlfolder}/utils/patcher.txt"
        $ESUDO kill -9 $(pidof gptokeyb)
    else
      echo "This port requires the latest version of PortMaster."
      "${GAMEDIR}/tools/text_viewer" -e -f 25 -w -t "PortMaster needs to be updated" -m "This port requires the latest version of PortMaster. Please update PortMaster first."
      exit 0
    fi

fi

cd "$GAMEDIR/gamedata"

$GPTOKEYB "mono" &
pm_platform_helper "mono"
$TASKSET mono "WyvAndKeep.exe"

pm_finish


