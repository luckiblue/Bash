#!/usr/bin/env bash
if_sudo () {
 SUDO='';
 if [[ $EUID != 0 ]]; then
  echo -e "To execute this script You must be root.\nExiting..."
  exit 0;
 fi
}

lvm_resize () {
clear
DATE="`date +"%Y%m%d"`";
echo "***Volume extend tool***"
echo "--------------------------------------"
 myarr=($(df -h | awk 'NR > 1 {gsub("%",""); if ($5 > 60) print $5";"$1}' | awk '/mapper/' | sort -rn)); # assign FS names with free space below 10% to array
 if [ ${#myarr[@]} -eq 0 ]; then
  echo "There is no action needed in this filesystem."
  exit 0;
 fi
 : ' ///Multiline comment section///
 Loop which iterates on elements of array called `myarr` to show vg`s and it`s
 lv`s where free space is coming to an end.
 variable j - counter for free_space_vg array
 variable vg_info - in this variable is stored vgdisplay for each space ending lv
 array free_space_vg - created to store vgname and it`s basic size info like PE_size, Free_PE, etc.
     ///End of multiline comment section///
 '
 j=0;
 for i in "${myarr[@]}"
 do
  vg_info="`vgdisplay $(echo $i | awk -F "mapper/|-" '{print $2}')`"; # vgdisplay for each volume group with space ending logical volume
  free_space_vg[$j]="`echo -e $vg_info | awk '{print $7, $49, $53, $58, $66}'`"; # print $7:name_of_VG, $49:PE_size, $53:Total_PE, $58:Allocated_PE, $66:Free_PE
  echo $i | awk -F "mapper/|-" '{print "\033[32mvg: "$2"\tlv: "$3"\033[0m"}' # prints vg and lv names which needs to be resized (depending on script assumptions)
  let j=j+1;
 done
 echo "--------------------------------------"
 printf '%s\n' "${free_space_vg[@]}" | awk '{if ($5 < 10) print "\033[31mThere is not enough free space in VG "$1". Current free space: "$2 * $5" MiB.\nIncrease size of this VG, then run the script again.\033[0m" ;else print "There is "$2 * $5" MiB of space in VG "$1"."}'
 VGS_WITH_LVS_TO_RESIZE="`printf '%s\n' "${free_space_vg[@]}" | awk '{if ($5 > 0) print $1}'`"
 echo -e "\n\033[35mVGs with free space: "$VGS_WITH_LVS_TO_RESIZE"\033[0m";
 
 echo "From highlihted in green options choose which lv You want to extend";
 read LV_TO_EXTEND;
 if [[ -z $LV_TO_EXTEND ]]; then
  echo -e "You didn't select any of LV name.\nExiting..."
  exit 0;
 fi
 IF_LV_EXIST="`lvs | awk -v lvexist=$LV_TO_EXTEND '($1 == lvexist) {print $1}'`"
 if [[ -z $IF_LV_EXIST ]]; then
  echo -e "Selected LV \033[31m"$LV_TO_EXTEND"\033[0m does not exist.\nExiting..."
  exit 0;
 fi
 
 LV_PATH="`printf '%s\n' "${myarr[@]}" | awk -F ";" '{print $2}' | awk -v lvsearch=$LV_TO_EXTEND '$0 ~ lvsearch {print $0}'`"
 VG_OWNER_OF_LV="`printf '%s\n' "${myarr[@]}" | awk -F "mapper/|-" -v lvsearch=$LV_TO_EXTEND '($3 == lvsearch) {print $2}'`"
 VG_OWNER_FREE_PE="`printf '%s\n' "${free_space_vg[@]}" | awk -v vgsearch=$VG_OWNER_OF_LV '($1 == vgsearch) {print $5}'`"
 VG_OWNER_PE_SIZE="`printf '%s\n' "${free_space_vg[@]}" | awk -v vgsearch=$VG_OWNER_OF_LV '($1 == vgsearch) {print $2}'`"
 VG_OWNER_FREE_SPACE_MiB="`python -c "print $VG_OWNER_FREE_PE*$VG_OWNER_PE_SIZE"`"
  
 echo -e "You are about to extend volume \033[36m"$LV_TO_EXTEND"\033[0m";
 
 echo -e "VG which containts \033[36m"$LV_TO_EXTEND"\033[0m is \033[35m"$VG_OWNER_OF_LV"\033[0m with \033[34m"$VG_OWNER_FREE_PE"\033[0m free PE and PE size at \033[32m"$VG_OWNER_PE_SIZE"\033[0m MiB";
 echo -e "You can add up to "$VG_OWNER_FREE_SPACE_MiB" MiB to this LV."
 echo "How much of space You want to add? [in MiB]"
 read SPACE_TO_ADD;
 if ! [[ $SPACE_TO_ADD =~ ^[0-9]+$ ]]; then
  echo -e "\033[31mIncorrect value: "$SPACE_TO_ADD".\033[0m\nExiting..."
  exit 0;
 fi
 
 IS_VGFREESPACE="`python -c "print 0 if $SPACE_TO_ADD > $VG_OWNER_FREE_SPACE_MiB else 1"`"
 if [ $IS_VGFREESPACE == 0 ];then
  echo -e "Not enough space in VG.\nExiting..."
  exit 0;
 fi
 
 VGINFO="`python -c "print $VG_OWNER_FREE_SPACE_MiB-$SPACE_TO_ADD"`"
 echo -e "You will add "$SPACE_TO_ADD" MiB to LV "$LV_TO_EXTEND".\nAfter this action there will be "$VGINFO" MiB of free space in "$VG_OWNER_OF_LV
 
 echo -e "Continue?"
 select ANSWER in "Yes" "No"; do
  case $ANSWER in
   Yes ) break;;
   No ) exit 0;;
   * ) echo -e "Unknown answer.\nExiting..." && exit 0;;
  esac
 done
 
 LVEXTEND="`echo "lvextend -L +"$SPACE_TO_ADD"M "$LV_PATH`"
 $LVEXTEND >> /tmp/lvresize$DATE.log 2>&1f 
 
 echo -e "Would You like to extend FS of this LV too?"
 select ANSWER_FS in "Yes" "No"; do
  case $ANSWER_FS in
   Yes ) break;;
   No ) exit 0;;
   * ) echo -e "Unknown answer.\nExiting..." && exit 0;;
  esac
 done
 
 FS_MNTPOINT="`mount | awk -v lvsearch=$LV_TO_EXTEND '$0 ~ lvsearch {print $3}'`"
 FS_TYPE="`mount | awk -v lvsearch="$LV_TO_EXTEND" '$0 ~ lvsearch {print $5}'`"
 echo "FS type mounted on "$FS_MNTPOINT" is "$FS_TYPE"."
 if [ $FS_TYPE == "xfs" ]; then
  FS_EXTEND_CMD=$(xfs_growfs $FS_MNTPOINT)
 else echo "This filesystem needs to be resized manually."
 fi
 $FS_EXTEND_CMD >> /tmp/lvresize$DATE.log 2>&1
 exit 0;
}

if_sudo;
lvm_resize;
exit 0;