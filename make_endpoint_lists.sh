#!/bin/bash
#
db_name=tswebdb
tb1=mobile_mac
webportal_mac=($(mysql engineering -e "select mac_address from $tb1" |egrep '[a-zA-Z0-9]{12}'))
ISE_USER=erstest
ISE_PASS=Opasnet1!
LOG=/var/log/batch_ise_webportal.log
RESULT_PATH=/var/log/ssid_mac

# ISE_PAN=https://66.86.125.12:9060/ers/config/endpoint
ISE_PAN=https://10.11.0.81:9060/ers/config/endpoint
ISE_PAN_GROUP=https://10.11.0.81:9060/ers/config/endpointgroup

GEC_MOBILE=gec_mobile
GEC_PC=gec_pc
GEC_VDI=gec_vdi

GEC_MOBILE_ID=4a2d63a0-d21b-11ea-8f4f-e2c19cef1786
GEC_PC_ID=00173090-d322-11ea-8b74-aef7c41e37a4
GEC_VDI_ID=3a89f0d0-d21b-11ea-8f4f-e2c19cef1786

is_exist_in_webportal=false
is_exist_in_ise=false

#TODO: 현재는 gec_pc만 분류하게 되어있어서, 추가되는 그룹들도 같이 개별 파일로 리스트 작성되도록 추가해야함.
#/var/log/ise_$2_endpoint_lists.txt 
# ise_그룹이름_endpoint_lists 
# 아이스 내에 엔드포인트를 그룹별로 필터하여 리스트 작성한 파일 
# 총 그룹별로 파일이 작성 될 예정
function make_endpoint_list(){
    echo "start make_endpoint_list" | awk '{ print strftime(), $0; fflush() }' >> $LOG
    _groupId=$1

    _total_count=$(curl -s --insecure \
        --header  'Accept: application/json' \
        --user $ISE_USER:$ISE_PASS \
        $ISE_PAN |./jq '.SearchResult.total?')

    _total_pages=`expr $_total_count / 20 + 1`
    echo "Total page($_total_pages) in total count($_total_count)..." | awk '{ print strftime(), $0; fflush() }' >> $LOG
    if [ ! -d $RESULT_PATH ]; then
        mkdir $RESULT_PATH
    fi
    echo "" |tr -d "\n" > $RESULT_PATH/ise_$2_endpoint_lists.txt
    for ((k = 1; k <= $_total_pages; k++)); do
        echo "Making endpoints $k/$_total_pages.." | awk '{ print strftime(), $0; fflush() }' >> $LOG
        ise_endpoint_all_id=($(curl -s --insecure \
                                        --header  'Accept: application/json' \
                                        --user $ISE_USER:$ISE_PASS \
                                        $ISE_PAN?page=$k |grep "id" |egrep '[a-zA-Z0-9-]{36}' -o)) #|egrep '[a-zA-Z0-9:]{17}' -o
        ise_endpoint_all_mac=($(curl -s --insecure \
                                        --header  'Accept: application/json' \
                                        --user $ISE_USER:$ISE_PASS \
                                        $ISE_PAN?page=$k |egrep '[a-zA-Z0-9:]{17}' -o))
        # printf '%s\n' ${ids[@]} | grep -i "4cf34f60-d616-11ea-9206-aef7c41e37a4"

        for ((i = 0; i < ${#ise_endpoint_all_id[@]}; i++)); do
            ise_endpoint_groupid=$(curl -s --insecure \
                    --header 'Accept: application/json' \
                    --user $ISE_USER:$ISE_PASS \
                    $ISE_PAN/${ise_endpoint_all_id[$i]} |./jq '.ERSEndPoint.groupId?' |sed -e 's/"//g') 
            if [ "$ise_endpoint_groupid" == "$_groupId" ]; then
                # for ((i = 0; i < ${#ise_endpoint_all_mac[@]}; i++)); do
                # TRNAME=`echo $1 | tr '[A-Z]' '[a-z]'`
                echo ${ise_endpoint_all_mac[$i]} | tr '[A-Z]' '[a-z]' >> $RESULT_PATH/ise_$2_endpoint_lists.txt
                # done
            fi
        done  
    done
    # echo "" >> /var/log/webportal_${tb1}_endpoint_lists.txt
    echo "end make_endpoint_list" | awk '{ print strftime(), $0; fflush() }' >> $LOG
}

function rotate_log() {
  MAXLOG=5
  MAXSIZE=20480000
  log_name=/var/log/batch_ise_webportal.log
  file_size=$(du -b $log_name | tr -s '\t' ' ' | cut -d' ' -f1)
  if [ $file_size -gt $MAXSIZE ]; then
    for i in $(seq $((MAXLOG - 1)) -1 1); do
      if [ -e $log_name"."$i ]; then
        mv $log_name"."{$i,$((i + 1))}
      fi
    done
    mv $log_name $log_name".1"
    touch $log_name
  fi
}

# main
echo "=== ${0##*/} started ===" | awk '{ print strftime(), $0; fflush() }' >> $LOG
make_endpoint_list $GEC_PC_ID $GEC_PC

sleep 1

rotate_log

# make_endpoint_list $GEC_MOBILE_ID $GEC_MOBILE