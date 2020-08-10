#!/bin/bash
#
#db_name=tswebdb
db_name=engineering
tb1=mobile_mac
webportal_mac=($(mysql $db_name -e "select mac_address from $tb1" |egrep '[a-zA-Z0-9]{12}'))
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

function compare_ise_endpoint()
{
    # echo -e "Start create ise endpoint.."
    echo -e "=== Start compare ise endpoint.. ===" | awk '{ print strftime(), $0; fflush() }' >> $LOG
    echo -e "" |tr -d "\n" > $RESULT_PATH/$2_creating_lists.txt
    _groupId=$1
    
    # get endpoint with _groupId
    # ise_endpoints=($(curl -s --insecure \
    # --header  'Accept: application/json' \
    # --user $ISE_USER:$ISE_PASS \
    # $ISE_PAN?filter=groupId.EQ.$_groupId |egrep '[a-zA-Z0-9:]{17}' -o))

    ise_endpoints=($(cat $RESULT_PATH/ise_$2_endpoint_lists.txt))

    for ((j = 0; j < ${#webportal_mac[@]}; j++)); do
        # echo "${endpoint_all_mac[$j]}"
        webportal_mac_address=${webportal_mac[$j]:0:2}":"${webportal_mac[$j]:2:2}":"${webportal_mac[$j]:4:2}":"${webportal_mac[$j]:6:2}":"${webportal_mac[$j]:8:2}":"${webportal_mac[$j]:10:2}
        is_exist_in_ise=$(grep -i $webportal_mac_address /var/log/ise_$2_endpoint_lists.txt)
        if [ "$is_exist_in_ise" != "$webportal_mac_address" ]; then
        #   echo -e "No need to create endpoint,($webportal_mac_address)" | awk '{ print strftime(), $0; fflush() }' >> $LOG
        # else
          echo -e "Writing ise endpoint($webportal_mac_address).." | awk '{ print strftime(), $0; fflush() }' >> $LOG
          echo -e "$webportal_mac_address" >> $RESULT_PATH/$2_creating_lists.txt          
        fi
        # for ((i = 0; i < ${#ise_endpoints[@]}; i++)); do
        #     # echo "${ise_endpoints[$i]}"
        #     webportal_mac_address=${webportal_mac[$j]:0:2}":"${webportal_mac[$j]:2:2}":"${webportal_mac[$j]:4:2}":"${webportal_mac[$j]:6:2}":"${webportal_mac[$j]:8:2}":"${webportal_mac[$j]:10:2}
        #     if [ "$webportal_mac_address" == "${ise_endpoints[$i]}" ]; then
        #         is_exist_in_ise=true 
        #         echo "true"   
        #     fi
        # done
        # if [ "$is_exist_in_ise" == "false" ]; then
        #     # echo -e "Creating ise endpoint($webportal_mac_address).."
        #     echo -e "Writing ise endpoint($webportal_mac_address).." | awk '{ print strftime(), $0; fflush() }' >> $LOG
        #     echo -e "$webportal_mac_address" >> /var/log/$2_creating_lists.txt
        # else
        #     # echo -e "No need to create endpoint,($webportal_mac_address)"
        #     echo -e "No need to create endpoint,($webportal_mac_address)" | awk '{ print strftime(), $0; fflush() }' >> $LOG
        # fi
        # is_exist_in_ise=false
    done
    # echo -e "End create ise endpoint"
    echo -e "=== End compare ise endpoint ===" | awk '{ print strftime(), $0; fflush() }' >> $LOG
}

# main
compare_ise_endpoint $GEC_PC_ID $GEC_PC