#!/bin/sh
	#***************************************************************************
	#*                                                                         *
	#*   This program is free software; you can redistribute it and/or modify  *
	#*   it under the terms of the GNU General Public License as published by  *
	#*   the Free Software Foundation; either version 2 of the License, or     *
	#*   (at your option) any later version.                                   *
	#*                                                                         *
	#***************************************************************************

	# -----------------------------------------------
	# With this script the target machine
	# may be selected
	# file     : configure.sh
	# author   : puehringer edgar
	# date     : 08.06.2020
	# -----------------------------------------------

if [ -z "$1" ]
then
  echo 'usage: configure.sh [ PC-1350 | PC-1360 | PC-2500 ]'
  exit 0
fi

if [ "$1" != "PC-1350" -a "$1" != "PC-1360" -a "$1" != "PC-2500" ]
then
  echo 'usage: configure.sh [ PC-1350 | PC-1360 | PC-2500 ]'
  exit 0
fi

OUTFILE=target.h

echo '.ifndef target_h' >  $OUTFILE
echo '.define target_h' >> $OUTFILE
echo ' '                >> $OUTFILE
echo '; -----------------------------------------------' >> $OUTFILE
echo '; Target machine - dont edit, use configure.sh'    >> $OUTFILE
echo '; -----------------------------------------------' >> $OUTFILE
if [ "$1" = "PC-1350" ]
then
  echo '__PC_1350__  = 1' >> $OUTFILE
  echo '__PC_1360__  = 0' >> $OUTFILE
  echo '__PC_2500__  = 0' >> $OUTFILE
elif [ "$1" = "PC-1360" ]
then
  echo '__PC_1350__  = 0' >> $OUTFILE
  echo '__PC_1360__  = 1' >> $OUTFILE
  echo '__PC_2500__  = 0' >> $OUTFILE
elif [ "$1" = "PC-2500" ]
then
  echo '__PC_1350__  = 0' >> $OUTFILE
  echo '__PC_1360__  = 0' >> $OUTFILE
  echo '__PC_2500__  = 1' >> $OUTFILE
fi
echo ' '                >> $OUTFILE                                                                                
echo '.endif'           >> $OUTFILE
echo ' '                >> $OUTFILE                                                                                
echo '; -----------------------------------------------' >> $OUTFILE
echo '; Memory location of the BASIC start pointer'      >> $OUTFILE
echo '; -----------------------------------------------' >> $OUTFILE
if [ "$1" = "PC-1350" ]
then
  echo ';28417' >> $OUTFILE
elif [ "$1" = "PC-1360" ]
then
  echo ';65495' >> $OUTFILE
elif [ "$1" = "PC-2500" ]
then
  echo ';28049' >> $OUTFILE
fi

