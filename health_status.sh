#!/bin/bash
# Copyright
# Author: dodoslav novak
# Goal: Check and show application health, depends on BC config
# Version: 1.9
#
        
BC_CONFIG="/opt/monitoring/process.param"      #variable with path to .param file in config
DEBUG=false                                                     #true or false, for output of check_config function which check prerequisites


function echo2                  #function to echo, if debug is on it will show more info 
        {
        if [ "$DEBUG" == true ]
                then 
                echo DEBUG: $@
                fi
        }
function fexist                 #functio to handle checking if file exist with easy output
        {
        if [ -f "$@" ]
                then
                echo2 file "$@" found
        else
                echo ERROR: file "$@" not found
                exit -1
                fi
        }

function check_config           #function to check prerequisites before run actual script
        {
################################## USER CHECK
        U=$(whoami)
        if [ "$U" != "root" ]   #root is really needed for LSOF
                then
                echo "INFO: Permission denied - connection information is not available." #because of lsof and others
                fi
        
        LSOF=lsof
        whereis lsof 2>&1 1>/dev/null
        if [ $? -ne 0 ]
                then
                if [ -f "/opt/freeware/sbin/lsof" ]
                        then
                        LSOF=/opt/freeware/sbin/lsof
                else
                        echo INFO: lsof not found!
                        fi
        else
                LSOF=lsof
                fi
	LSOF=$LSOF" "

################################## DEBUG STATUS
        if [ "$DEBUG" == true ]         #just output if debug is on
                then
                echo DEBUG is ON
                fi

################################## BC CONFIG CHECK
        if [ -f "$BC_CONFIG" ]          #check if BC config really exist
                then
                echo2 $BC_CONFIG is found 
        else
                echo ERROR: File $BC_CONFIG not found!
                exit 1
                fi
        }

function portstat 
        {

        echo
        }



function robi           #main function
        {
        echo
        MAX=8
        IFS=$'\n'       #set separator new line for now
        LIST=()         #list of procesess to check
        for LINE in `grep "pim;" "$BC_CONFIG" | grep -v "^#" | cut -d";" -f3; grep "dwh;" "$BC_CONFIG" | grep -v "^#" | cut -d";" -f3`
                do
                if [ "$MAX" -lt "${#LINE}" ]
                        then
                        MAX=${#LINE} 
                        fi
                LIST+=("$LINE")
                done
        
        for (( C=1; C<=$MAX; C++))
                do
                CIARA="$CIARA""-"
                done

        if [ "${#LIST[@]}" -eq 0 ]
                then
                echo "WARNING: No processes found with tag $TAG in $BC_CONFIG"
                echo
                echo
                fi

        printf "%-20s | %-10s | %-16s | %-10s | %-10s | %-"$MAX"s | %-5s \n" "  STATUS" "PID" "RUNNING" "STARTED" "USER" "PROCES"  "CONNECTION"
        printf "%-20s | %-10s | %-16s | %-10s | %-10s | %-"$MAX"s | %-10s  %-5s \n" "  ------------------" "----------" "----------------" "----------" "----------" "$CIARA" "----------------"


        for ITEM in ${LIST[@]}
                do
                PS=$(ps -ef | grep -v "grep" | grep "$ITEM" | wc -l | sed 's/ //g')
                if [ "$PS" -eq 0 ]
                        then
                        PS="NOT RUNNING"
                        PID=" --- "
                        TIME=" --- "
                        STIME=" --- "
                        PSUSER=" --- "
                        DB=" --- "
                elif [ "$PS" -eq 1  ] 
                        then
                        PID=$(ps -ef | grep -v "grep" | grep "$(echo "$ITEM" | sed 's/ /\\ /g' )" | sed 's/  */ /g' | sed 's/^ *//' | cut -f2 -d" " )
                        PSUSER=$(ps -fo user -p "$PID" | sed 1d | sed 's/ //g' )
                        PS="OK"
                        TIME=$( ps -eo pid,cmd,etime | grep -v grep | sed 's/  */ /g' | sed 's/^ //g' | grep "^$PID" | rev | cut -d" " -f1 | rev |  sed 's/\-/days /' | sed 's/^1days/1day/')  
                        DB=$($LSOF -i -P 2>/dev/null | grep "ESTAB" | grep -v "Updated" | sed 's/  */ /g' | cut -d" " -f2,9 | grep "$PID" | sed 's/\[..1\]//g'  | cut -d">" -f2 | cut -d":" -f1 |  uniq | sed 's/$/ /g' |tr -d "\n" 2>/dev/null)
			STIME=$( ps -ef | sed 's/  */ /g' | sed 's/^ //g' | cut -d" " -f2,5,6 | grep "$PID " | cut -d " " -f2,3 | sed 's/ -//g' | sed 's/pts\/[0-9]//' )
                        if [ -z "$DB" ]
                                then
                                DB=" --- "
                                if [ "$(whoami)" != "root" ] && [ "$(whoami)" != "$PSUSER" ] 
                                        then
                                        DB="NO PERMISSION"
                                        fi
                        else
                                IFS=$'\x20'
                                PPOM=""
                                for ITEMM in $DB
                                        do
                                        NUMBER=$($LSOF -i -P 2>/dev/null | grep "ESTAB" | grep -v "Updated" | sed 's/  */ /g' | cut -d" " -f2,9 | grep "$PID" | cut -d">" -f2 | cut -d":" -f1 | grep "$ITEMM" | wc -l | sed 's/ //g')
                                        PPOM=$PPOM" "$NUMBER"x "$ITEMM","
                                        done
                                DB=$PPOM
                                DB=$(echo $DB | sed 's/,$//')
                        fi

                else
                        PS="ProcessCount: $PS"
                        if [ "$(ps -ef | grep -v "grep" | grep "$( echo "$ITEM" | sed 's/ /\\ /g' )" | awk '{ print $1}' | grep -v "nobody" | wc -l )" -eq 1 ] 
                                then
                                PID=$(ps -ef | grep -v "grep" | sed 's/  */ /g' | grep "$( echo "$ITEM" | sed 's/ /\\ /g')" | sed 's/^ *//g' | cut -d" " -f1,2 | grep -v "nobody" | cut -d" " -f2 )
                                PSUSER=$(ps -fo user -p "$PID" | sed 1d | sed 's/ //g' )
                                TIME=$(ps -efo pid,etime | grep "$PID" | sed 's/  */ /g' | sed 's/^ *//' | cut -f2 -d" " | sed 's/\-/days /' | sed 's/^1days/1day/')
                                DB=$($LSOF -i -P 2>/dev/null | grep "ESTAB" | grep -v "Updated" | sed 's/  */ /g' | cut -d" " -f2,9 | grep "$PID" | cut -d">" -f2 | cut -d":" -f1 | grep -v "$(hostname)" | uniq | sed 's/$/, /' | tr -d "\n" 2>/dev/null)
                                if [ -z "$DB" ]
                                        then
                                        DB=" --- "
                                        if [ "$(whoami)" != "root" ]
                                                then
                                                DB=" N/A "
                                                fi
                                        fi

                                STIME=$(ps -ef | sed 's/  */ /g' | sed 's/^ //g' | cut -d" " -f2,5,6 | grep "$PID" | cut -d " " -f2,3 | sed 's/pts..//'  | sed 's/ -//g')
                        else
                                PID="NA"
                                PSUSER="NA"
                                TIME="NA"
                                DB="NA"
                                STIME="NA"
                                fi
                        fi

                ITEM=$( echo "$ITEM" | sed 's/^ //g')
		STIME=$( echo "$STIME" | sed 's/?//')
                printf "%-20s | %-10s | %-16s | %-10s | %-10s | %-"$MAX"s | %-5s \n" "  $PS" "$PID" "$TIME" "$STIME" "$PSUSER" "$ITEM" "$DB" 
                done
	echo
        }

############################################################################# END OF DECLARATION PART


check_config    #fucntion to check variables of this script
robi            #function which print the table of processes
