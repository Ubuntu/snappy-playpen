#!/bin/bash

#      Copyright (C) 2009-2013 Team XBMC
#      http://xbmc.org
#
#  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with XBMC; see the file COPYING.  If not, write to
#  the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
#  http://www.gnu.org/copyleft/gpl.html

APP=Kodi
prefix="$SNAP"
exec_prefix="$SNAP"
bindir="${exec_prefix}/bin"
bin_name=kodi
APP="${bindir}/${bin_name} --standalone $@"

# Path for Kodi data.
export KODI_HOME="$datarootdir/kodi"

if [ "$SNAP_ARCH" == "amd64" ]; then
	ARCH="x86_64-linux-gnu"
elif [ "$SNAP_ARCH" == "armhf" ]; then
	ARCH="arm-linux-gnueabihf"
else
	ARCH="$SNAP_ARCH-linux-gnu"
fi
export LIBGL_DRIVERS_PATH=$SNAP/usr/lib/$ARCH/dri


PULSE_START="$(which start-pulseaudio-x11)"
if [ -n "$PULSE_START" ]; then
  $PULSE_START
else
  PULSE_SESSION="$(which pulse-session)"
  if [ -n "$PULSE_SESSION" ]; then
    XBMC="$PULSE_SESSION $XBMC"
  fi
fi

LOOP=1
CRASHCOUNT=0
LASTSUCCESSFULSTART=$(date +%s)

while [ $(( $LOOP )) = "1" ]
do
  $APP
  RET=$?
  NOW=$(date +%s)
  if [ $(( ($RET >= 64 && $RET <=66) || $RET == 0 )) = "1" ]; then # clean exit
    LOOP=0
  else # crash
    DIFF=$((NOW-LASTSUCCESSFULSTART))
    if [ $(($DIFF > 60 )) = "1" ]; then # Not on startup, ignore
      LASTSUCESSFULSTART=$NOW
      CRASHCOUNT=0
    else # at startup, look sharp
      CRASHCOUNT=$((CRASHCOUNT+1))
      if [ $(($CRASHCOUNT >= 3)) = "1" ]; then # Too many, bail out
        LOOP=0
        echo "${APP} has exited in an unclean state 3 times in the last ${DIFF} seconds."
        echo "Something is probably wrong"
      fi
    fi
  fi
done
