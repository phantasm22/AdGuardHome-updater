#!/bin/sh

#AdGuardHome Updater for GL.INET and Asus routers created by phantasm22
#Last updated 12-June-2024
#v0.6

#Some useful colors that we can use             
NOCOLOR='\033[0m'   #Default Color
BLACK='\e[0;30m'
GRAY='\e[1;30m'
RED='\e[0;31m'
LTRED='\e[1;31m'
GREEN='\e[0;32m'
LTGREEN='\e[1;32m'
BROWN='\e[0;33m'
YELLOW='\e[1;33m'
BLUE='\e[0;34m'
LTBLUE='\e[1;34m'
PURPLE='\e[0;35m'
LTPURPLE='\e[1;35m'
CYAN='\e[0;36m'
LTCYAN='\e[1;36m'
LTGRAY='\e[0;37m'
WHITE='\e[1;37m'                                    
                                                                       
echo -e "${LTCYAN}AdGuardHome Upgrader for GL.INET and Asus Routers\n${NOCOLOR}"

#Set your preferred temp directory here. If not, updater will use /tmp if you have 50M free space             
AGHTMP="/overlay/tmp/" 

#This sets the AGH program and config file locations
PROG=$(find / -type f -name "AdGuardHome" 2>/dev/null | grep -v /overlay | head -n 1)
CONFIG=$(find / -type f -name "?d?uard?ome.yaml" 2>/dev/null | grep -v /overlay | head -n 1)
if ! test -f "$CONFIG"; then
   CONFIG=$(find /etc/AdGuardHome/ -type f -name "config.yaml" 2>/dev/null | grep -v /overlay | head -n 1)
fi 
SAGH=$(find / -name "S*?d?uard?ome" 2>/dev/null | grep -v /overlay | head -n 1)

#Router architecture type
MODEL=$(uname -m)
                                                                         
#Source versions: https://github.com/AdguardTeam/AdGuardHome/wiki/Platforms
BASEURL="https://static.adguard.com/adguardhome/"

case "$MODEL" in
  mips)
    echo -e "${GREEN}   Found supported arch type: ${BLUE}$MODEL${NOCOLOR}"
    FILE="AdGuardHome_linux_mipsle_softfloat.tar.gz"
    ;;
  aarch64)
    echo -e "${GREEN}   Found supported arch type: ${BLUE}$MODEL${NOCOLOR}"
    FILE="AdGuardHome_linux_arm64.tar.gz"
    ;;
  armv7l)
    echo -e "${GREEN}   Found supported arch type: ${BLUE}$MODEL${NOCOLOR}"
    FILE="AdGuardHome_linux_armv7.tar.gz"
    ;;
  *)
    echo -e "${RED}   ERROR: Cannot determine suitable arch type for download. Exiting...${NOCOLOR}"
    exit 1
    ;;
esac

AGH_RELEASE="release/"
AGH_BETA="beta/"

#Location to check for any updates
AGHRELURL="https://api.github.com/repos/AdguardTeam/AdGuardHome/releases"   

#Precheck
#Precheck                                                                                             
if [ -z $(which wget | xargs readlink) ] || [ $(which wget | xargs readlink) == "/usr/libexec/wget-ssl" ]; then
   echo -e "${GREEN}   Looking for suitable version of wget: ${BLUE}PASS!${NOCOLOR}"
else
   echo -e "${RED}   Can't find suitable wget. Please ${BLUE}opkg install wget-ssl ${RED}and check your symlinks. Exiting...${NOCOLOR}"
   exit 1
fi

if test -f "$PROG"; then
   echo -e "${GREEN}   Found AdGuardHome binary: ${BLUE}$PROG${NOCOLOR}"
   if test -f "$CONFIG"; then
      echo -e "${GREEN}   Found AdGuardHome yaml configuration file: ${BLUE}$CONFIG${NOCOLOR}" 
      if test -d "$AGHTMP"; then
         echo -e "${GREEN}   Found temp directory: ${BLUE}$AGHTMP${NOCOLOR}"
      else
         if test -d "/tmp"; then
            AGHTMP="/tmp/"
            echo -e "${GREEN}   Found temp directory: ${BLUE}$AGHTMP${NOCOLOR}"
         else
         echo -e "${RED}   Can't find suitable temp working directory. Check script parms. Exiting...${NOCOLOR}"
         exit 1
         fi
      fi
      TMPFREE=$(df -Pm $AGHTMP | sed 1d | grep -v used | awk '{ print $4 "\t" }' | awk -F\, '{gsub(/[\t]+$/, ""); print $1}')
      if [ $TMPFREE -ge "50" ]; then
         echo -e "${GREEN}   Temp directory ${BLUE}$AGHTMP${GREEN} has ${BLUE}${TMPFREE}M${GREEN} free...${BLUE}PASS!${NOCOLOR}"
      else
         echo -e "${GREEN} Temp directory ${BLUE}$AGHTMP${GREEN} has ${BLUE}${TMPFREE}M${GREEN} free...${RED}FAIL!${NOCOLOR}"
         exit 1
      fi
   else 
      echo -e "${RED}   Can't find existing AdGuardHome config file. Maybe dups? Exiting...${NOCOLOR}"
      exit 1
   fi
else
   echo -e "${RED}   Can't find existing AdGuardHome binary. Maybe dups? Exiting...${NOCOLOR}"
   exit 1
fi

if test -f "$SAGH"; then
   echo -e "${GREEN}   Found AdGuardHome startup script in ${BLUE}$SAGH\n${NOCOLOR}"
else 
   echo -e "${RED}   Can't find existing AdGuardHome startup script. AGH already installed? Exiting...${NOCOLOR}"
   exit 1
fi

#read -p "Press Enter to continue" </dev/tty


#Check to see if there are any updates
LATEST_REL=$(wget -q -O - $AGHRELURL | sed -n '/"prerelease": false,/q;p' | tail -4 | grep "tag_name" | cut -d ':' -f2 | cut -d '"' -f2 | cut -d 'v' -f2 | xargs)
LATEST_BETA=$(wget -q -O - $AGHRELURL | sed -n '/"prerelease": true,/q;p' | tail -4 | grep "tag_name" | cut -d ':' -f2 | cut -d '"' -f2 | cut -d 'v' -f2 | xargs)
INSTALLED=$($PROG --version | awk '{ print $4 " " }' | cut -d 'v' -f2 | xargs)

if [ "$LATEST_REL" == "" ]; then
   echo -e "${RED}   Error: Can't get release version info from website. Exiting...${NOCOLOR}"
   exit 1
else
   if [ "$LATEST_BETA" == "" ]; then 
      echo -e "${RED}   Error: Can't get beta version info from website. Exiting...${NOCOLOR}"
      exit 1
   fi
fi  

#INSTALLED=0.108.0-b.39
#INSTALLED=0.107.29

if [ "$INSTALLED" == "$LATEST_REL" ]; then
   echo -e "${GREEN}   Your installed version of ${BLUE}$INSTALLED${GREEN} is the same as the latest release version of ${BLUE}$LATEST_REL${NOCOLOR}"
   while true; do
      read -p "$(echo -e "${GREEN}   Would you like to switch to the latest beta version ${BLUE}${LATEST_BETA}? ${GREEN}[${LTGREEN}Y${GREEN}]es or [${LTGREEN}N${GREEN}]o: ${NOCOLOR}")" yesno
      case $yesno in
         [Yy] ) echo -e "\n${GREEN}   Installing beta version ${BLUE}$LATEST_BETA${GREEN} of AdGuardHome${NOCOLOR}"              
                VERINFO=$LATEST_BETA
                AGHVER=$BASEURL$AGH_BETA$FILE
                break;;
         [Nn] ) echo -e "\n${YELLOW}   Nothing to do. Exiting...${NOCOLOR}"
                exit 0;;
         *    ) echo -e "${RED}   Invalid response${NOCOLOR}\n";;
      esac
   done 
else
   if [ "$INSTALLED" == "$LATEST_BETA" ]; then
      echo -e "${GREEN}   Your installed version of ${BLUE}$INSTALLED${GREEN} is the same as the latest beta version of ${BLUE}$LATEST_BETA${NOCOLOR}"
   while true; do
      read -p "$(echo -e "${GREEN}   Would you like to switch to the latest release version ${BLUE}${LATEST_REL}? ${GREEN}[${LTGREEN}Y${GREEN}]es or [${LTGREEN}N${GREEN}]o: ${NOCOLOR}")" yesno   
      case $yesno in                                                                                                                
         [Yy] ) echo -e "\n${GREEN}   Installing release version ${BLUE}$LATEST_REL${GREEN} of AdGuardHome${NOCOLOR}"                 
                VERINFO=$LATEST_REL
                AGHVER=$BASEURL$AGH_RELEASE$FILE
                break;;                                                                                                             
         [Nn] ) echo -e "\n${YELLOW}   Nothing to do. Exiting...${NOCOLOR}"                                                         
                exit 0;;                                                                                                            
         *    ) echo -e "${RED}   Invalid response${NOCOLOR}\n";;                                                                   
      esac
   done
   else 
      echo -e "${GREEN}   Your installed version is ${BLUE}$INSTALLED${GREEN}\n   The latest beta version is ${BLUE}$LATEST_BETA${GREEN}\n   The latest release version is ${BLUE}$LATEST_REL${GREEN}\n"
      while true; do
          read -p "$(echo -e "${GREEN}   Would you like to upgrade to the latest [${LTGREEN}b${GREEN}]eta, [${LTGREEN}r${GREEN}]elease, or [${LTGREEN}q${GREEN}]uit? ")" brq
      case $brq in
         [bB] ) echo -e "\n${GREEN}   Installing beta version ${BLUE}$LATEST_BETA${GREEN} of AdGuardHome${NOCOLOR}" 
                VERINFO=$LATEST_BETA
                AGHVER=$BASEURL$AGH_BETA$FILE
                break;;
         [rR] ) echo -e "\n${GREEN}   Installing release version ${BLUE}$LATEST_REL${GREEN} of AdGuardHome${NOCOLOR}"
                VERINFO=$LATEST_REL
                AGHVER=$BASEURL$AGH_RELEASE$FILE
                break;;
         [qQ] ) echo -e "${YELLOW}   Exiting...${NOCOLOR}"
                exit 0;;
         *    ) echo -e "${RED}   Invalid response${NOCOLOR}\n";;
      esac
      done
   fi
fi

#read -p "Press Enter to continue" </dev/tty
                                                                                                                                                                                        
# Create backup after checking for available space                                                                                                                                                      
echo -e "${GREEN}   Checking available space for backups${NOCOLOR}"                                                                                                                                     
AGHFREE=$(df -Pm $(dirname $PROG) | sed 1d | grep -v used | awk '{ print $4 "\t" }' | awk -F\, '{gsub(/[\t]+$/, ""); print $1}')                                                                        
if [ $AGHFREE -ge "37" ]; then                                                                                                                                                                          
   echo -e "${GREEN}   Binary directory ${BLUE}$PROG${GREEN} has ${BLUE}${AGHFREE}M${GREEN} free...${BLUE}PASS!${NOCOLOR}"                                                                              
   while true; do                                                                                                                                                                                       
      read -p "$(echo -e "\n${GREEN}   Would you like to create a backup of your AdGuardHome binary? ${GREEN}[${LTGREEN}Y${GREEN}]es or [${LTGREEN}N${GREEN}]o: ${NOCOLOR}")" yesno1                    
         case $yesno1 in                                                                                                                                                                                
            [Yy] ) while true; do                                                                                                                                                                       
                      read -p "$(echo -e "${GREEN}   Would you like to create a backup of your AdGuardHome config file? ${GREEN}[${LTGREEN}Y${GREEN}]es or [${LTGREEN}N${GREEN}]o: ${NOCOLOR}")" yesno2 
                      case $yesno2 in                                                                                                                                                                
                         [Yy] ) printf "\n${GREEN}   Creating backup of AdGuardHome binary and config file...${NOCOLOR}"                                                                             
                                cp -f $PROG $PROG.old                                                                                                                                                   
                                if [ ! -f "$PROG.old" ]; then                                                                                                                                        
                                   printf "${RED}FAILURE! $PROG.old does not exist. Exiting...${NOCOLOR}"                                                                                            
                                exit 1                                                                                                                                                               
                                fi                                                                                                                                                                   
                                cp -f $CONFIG $CONFIG.backup                                                                                                                                            
                                if [ ! -f "$CONFIG.backup" ]; then                                                                                                                                   
                                   printf "${RED}FAILURE! $CONFIG.backup does not exist. Exiting...${NOCOLOR}"                                                                                       
                                exit 1                                                                                                                                                            
                                fi                                                                                                                                                                   
                                printf "${BLUE}SUCCESS!${NOCOLOR}\n"                                                                                                                                 
                                break;;                                                                                                                                                              
                         [Nn] ) echo -e "\n${YELLOW}   Skipping backup of AdGuardHome binary${NOCOLOR}"                                                                                              
                                printf "\n${GREEN}   Creating backup of AdGuardHome binary...${NOCOLOR}"                                                                                             
                                cp -f $PROG $PROG.old                                                                                                                                                   
                                if [ ! -f "$PROG.old" ]; then                                                                                                                                        
                                   printf "${RED}FAILURE! $PROG.old does not exist. Exiting...${NOCOLOR}"                                                                                            
                                exit 1                                                                                                                                                               
                                fi                                                                                                                                                                   
                                printf "${BLUE}SUCCESS!${NOCOLOR}\n"                                                                                                                                 
                                break;;                                                                                                                                                              
                         *    ) echo -e "${RED}   Invalid response${NOCOLOR}";;                                                                                                                      
                      esac                                                                                                                                                                          
                   done                                                                                                                                                                              
                   break;;                                                                                                                                                                              
            [Nn] ) echo -e "\n${YELLOW}   Skipping backup of AdGuardHome binary${NOCOLOR}"                                                                                                              
                   while true; do                                                                                                                                                                       
                      read -p "$(echo -e "\n${GREEN}   Would you like to create a backup of your AdGuardHome config file? ${GREEN}[${LTGREEN}Y${GREEN}]es or [${LTGREEN}N${GREEN}]o: ${NOCOLOR}")" yesno3
                      case $yesno3 in                                                                                                                                                                 
                         [Yy] ) printf "\n${GREEN}   Creating backup of AdGuardHome config file...${NOCOLOR}"                                                                                         
                                cp -f $CONFIG $CONFIG.backup                                                                                                                                             
                                if [ ! -f "$CONFIG.backup" ]; then                                                                                                                                    
                                   printf "${RED}FAILURE! $CONFIG.backup does not exist. Exiting...${NOCOLOR}"                                                                                        
                                   exit 1                                                                                                                                                             
                                fi                                                                                                                                                                    
                                printf "${BLUE}SUCCESS!${NOCOLOR}\n"                                                                                                                                 
                                break;;                                                                                                                                                               
                         [Nn] ) echo -e "\n${YELLOW}   Skipping backup of AdGuardHome binary and config file${NOCOLOR}"                                                                               
                                break;;                                                                                                                                                               
                         *    ) echo -e "${RED}   Invalid response${NOCOLOR}";;                                                                                                                       
                      esac                                                                                                                                                                            
                   done                                                                                                                                                                               
                   break;;                                                                                                                                                                                 
            * )    echo -e "${RED}   Invalid response${NOCOLOR}";;                                                                                                                                       
         esac                                                                                                                                                                                            
   done                                                                                                                                                                                                  
else           
   echo -e "${GREEN}   Binary directory ${BLUE}$PROG${GREEN} has ${BLUE}${AGHFREE}M${GREEN} free...${RED}FAILED! Skipping binary backup${NOCOLOR}"                                                                   
   while true; do                                                                                                                                                                                                    
      read -p "$(echo -e "\n${GREEN}   Would you like to create a backup of your AdGuardHome config file? ${GREEN}[${LTGREEN}Y${GREEN}]es or [${LTGREEN}N${GREEN}]o: ${NOCOLOR}")" yesno4                            
      case $yesno4 in                                                                                                                                                                                                
         [Yy] ) printf "\n${GREEN}   Creating backup of AdGuardHome config file...${NOCOLOR}"                                                                                                                        
                cp $CONFIG $CONFIG.backup                                                                                                                                                                            
                if [ ! -f "$CONFIG.backup" ]; then                                                                                                                                                                   
                   printf "${RED}FAILURE! $CONFIG.backup does not exist. Exiting...${NOCOLOR}"                                                                                                                       
                   exit 1                                                                                                                                                                                            
                fi                                                                                                                                                                                                   
                printf "${BLUE}SUCCESS!${NOCOLOR}\n"                                                                                                                                                                 
                break;;                                                                                                                                                                                              
         [Nn] ) echo -e "\n${YELLOW}   Skipping backup of AdGuardHome binary and config file${NOCOLOR}"                                                                                                              
                break;;                                                                                                                                                                                              
         *    ) echo -e "${RED}   Invalid response${NOCOLOR}";;                                                                                                                                                      
      esac                                                                                                                                                                                                           
   done                                                                                                                                                                                                              
fi   
#read -p "Press Enter to continue" </dev/tty

# Get AGH
echo -e "${GREEN}   Downloading version ${BLUE}$VERINFO${GREEN} of AdGuardHome${NOCOLOR}"
wget --backups=1 -q -P $AGHTMP $AGHVER

# Extracting new version
echo -e "${GREEN}   Extracting version ${BLUE}$VERINFO${GREEN} of AdGuardHome${NOCOLOR}"
if [ ! -f "$AGHTMP$FILE" ]; then
   echo -e "{RED}   $AGHTMP$FILE does not exist. Exiting...${NOCOLOR}"
   exit 1
fi
tar -xzf $AGHTMP$FILE -C $AGHTMP

# Disable AGH
printf "${GREEN}   Disabling running version of AdGuardHome...${NOCOLOR}"
if $SAGH stop 2>/dev/null; then
   printf "${BLUE}SUCCESS!${NOCOLOR}\n"
else
   printf "${RED}FAIL!${NOCOLOR}\n"
   echo -e "${RED}   Can't disable AdGuardHome. Exiting...${NOCOLOR}"
   rm -f "$AGHTMP""$FILE"*
   rm -fr "$AGHTMP"AdGuardHome
   exit 1
fi

# copy new AGH
echo -e "${GREEN}   Copying verion ${BLUE}$VERINFO${GREEN} into place${NOCOLOR}"
if [ -f "$AGHTMP"AdGuardHome/AdGuardHome ]; then
   cp -f "$AGHTMP"AdGuardHome/AdGuardHome $PROG
else 
   echo -e "{RED}   Can't find "$AGHTMP"AdGuardHome/AdGuardHome. Exiting...${NOCOLOR}"
   rm -f "$AGHTMP""$FILE"*
   rm -fr "$AGHTMP"AdGuardHome
   exit 1
fi

# Restart AGH
printf "${GREEN}   Restarting AdGuardHome...${NOCOLOR}"
if $SAGH start 2>/dev/null; then
   printf "${BLUE}Success!${NOCOLOR}\n"
else
   echo -e "${RED}   Can't restart AdGuardHome. Exiting....${NOCOLOR}"
   rm -f "$AGHTMP""$FILE"*
   rm -fr "$AGHTMP"AdGuardHome
   exit 1
fi

# Cleanup
echo -e "${GREEN}   Cleaning up AdGuardHome temp files${NOCOLOR}"
rm -f "$AGHTMP""$FILE"*
rm -fr "$AGHTMP"AdGuardHome

# Check new version
printf "${GREEN}   Checking installed version of AdGuardHome...${NOCOLOR}"
INSTALLED=$($PROG --version | awk '{ print $4 " " }' | cut -d 'v' -f2 | xargs)
if [ "$INSTALLED" == "$LATEST_REL" ]; then
   printf "${BLUE}PASS!${NOCOLOR}\n"                                                                                                                                                                                                                               
else                                                                                                                                              
   if [ "$INSTALLED" == "$LATEST_BETA" ]; then                                                                                                    
      printf "${BLUE}PASS!${NOCOLOR}\n"
      else
         printf "${RED}FAIL!${NOCOLOR}\n"
         echo -e "${RED}   FATAL ERROR: Installed version is ${BLUE}$INSTALLED${RED}, expect ${BLUE}$VERINFO${RED}. Exiting...${NOCOLOR}"
         exit 1
   fi
fi


# Done
echo -e "${LTGREEN}   Update completed!${NOCOLOR}" 
exit 0
