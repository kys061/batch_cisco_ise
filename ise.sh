#!/bin/bash
#
db_name=tswebdb
webportal_mac=($(mysql engineering -e "select mac_address from mobile_mac" |egrep '[a-zA-Z0-9]{12}'))
# ISE_USER=ersadmin
ISE_USER=erstest
ISE_PASS=Opasnet1!
LOG=/var/log/batch_ise_webportal.log
GEC_MOBILE=GEC_MOBILE
GEC_PC=GEC_PC
GEC_VDI=GEC_VDI
# ISE_PAN=https://66.86.125.12:9060/ers/config/endpoint
ISE_PAN=https://10.11.0.81:9060/ers/config/endpoint
ISE_PAN_GROUP=https://10.11.0.81:9060/ers/config/endpointgroup
TEST_PC=f7684df0-d20c-11ea-be06-aef7c41e37a4
# TEST_PC=$(curl -s --insecure \
#         --header 'Accept: application/json' \
#         --user $ISE_USER:$ISE_PASS $ISE_PAN_GROUP |./jq '.SearchResult.resources[] | select(.name == "PC")' |./jq  '.id?' |sed -e 's/"//g')
GEC_MOBILE_ID=4a2d63a0-d21b-11ea-8f4f-e2c19cef1786
# GEC_MOBILE_ID=$(curl -s --insecure \
#         --header 'Accept: application/json' \
#         --user $ISE_USER:$ISE_PASS $ISE_PAN_GROUP |./jq '.SearchResult.resources[] | select(.name == "'$GEC_MOBILE'")' |./jq  '.id?' |sed -e 's/"//g')
GEC_PC_ID=00173090-d322-11ea-8b74-aef7c41e37a4
GEC_VDI_ID=3a89f0d0-d21b-11ea-8f4f-e2c19cef1786
is_exist_in_webportal=false
is_exist_in_ise=false
# ise_endpoint_all_mac=($(curl -s --insecure \
#      --header  'Accept: application/json' \
#      --user $ISE_USER:$ISE_PASS \
#      $ISE_PAN |egrep '[a-zA-Z0-9:]{17}' -o))


# parameter: $1-groupId
function create_ise_endpoint()
{
    echo -e "Start create ise endpoint.."
    echo -e "Start create ise endpoint.." | awk '{ print strftime(), $0; fflush() }' >> $LOG
    _groupId=$1
    
    # get endpoint with _groupId
    # ise_endpoints=($(curl -s --insecure \
    # --header  'Accept: application/json' \
    # --user $ISE_USER:$ISE_PASS \
    # $ISE_PAN?filter=groupId.EQ.$_groupId |egrep '[a-zA-Z0-9:]{17}' -o))

    ise_endpoints=($(cat /var/log/gec_pc_endpoint_lists.txt))

    for ((j = 0; j < ${#webportal_mac[@]}; j++)); do
        # echo "${endpoint_all_mac[$j]}"
        for ((i = 0; i < ${#ise_endpoints[@]}; i++)); do
            # echo "${ise_endpoints[$i]}"
            webportal_mac_address=${webportal_mac[$j]:0:2}":"${webportal_mac[$j]:2:2}":"${webportal_mac[$j]:4:2}":"${webportal_mac[$j]:6:2}":"${webportal_mac[$j]:8:2}":"${webportal_mac[$j]:10:2}
            if [ "$webportal_mac_address" == "${ise_endpoints[$i]}" ]; then
                is_exist_in_ise=true 
                echo "true"   
            fi
        done
        if [ "$is_exist_in_ise" == "false" ]; then
            echo -e "Creating ise endpoint($webportal_mac_address).."
            echo -e "Creating ise endpoint($webportal_mac_address).." | awk '{ print strftime(), $0; fflush() }' >> $LOG
            curl -s --insecure  \
                --include \
                --header 'Content-Type:application/json' \
                --header 'Accept: application/json' \
                --user $ISE_USER:$ISE_PASS \
                --request POST $ISE_PAN \
                --data '
            {
                "ERSEndPoint" : {
                "name" : "'$webportal_mac_address'",
                "description" : "",
                "mac" : "'$webportal_mac_address'",
                "groupId" : "'$_groupId'",
                "staticGroupAssignment" : true
                }
            }' |grep "HTTP" | awk '{ print strftime(), $0; fflush() }' >> $LOG #> /dev/null 2>&1
        else
            echo -e "No need to create endpoint,($webportal_mac_address)"
            echo -e "No need to create endpoint,($webportal_mac_address)" | awk '{ print strftime(), $0; fflush() }' >> $LOG
        fi
        is_exist_in_ise=false
    done
    echo -e "End create ise endpoint"
    echo -e "End create ise endpoint" | awk '{ print strftime(), $0; fflush() }' >> $LOG
}

function delete_ise_endpoint()
{
# 삭제 하는 로직 구현
#:NEED 태산 쪽에서 삭제 된 맥 정보를 제공하는 테이블이 있다면 그걸 기준으로 삭제 할수 있을것 같다.
for ((j = 0; j < ${#ise_endpoint_all_mac[@]}; j++)); do
    # echo "${endpoint_all_mac[$j]}"
    for ((i = 0; i < ${#webportal_mac[@]}; i++)); do
        webportal_mac_address=${webportal_mac[$i]:0:2}":"${webportal_mac[$i]:2:2}":"${webportal_mac[$i]:4:2}":"${webportal_mac[$i]:6:2}":"${webportal_mac[$i]:8:2}":"${webportal_mac[$i]:10:2}
        if [ "$webportal_mac_address" == "${ise_endpoint_all_mac[$j]}" ]; then
            is_exist_in_webportal=true 
            echo "true"   
        fi
    done
    if [ "$is_exist_in_webportal" == "false" ]; then
        #get ise endpoint id
        endpoint_id=$(curl -s --insecure \
                    --header 'Accept: application/json' \
                    --user $ISE_USER:$ISE_PASS \
                    $ISE_PAN?filter=mac.EQ.${ise_endpoint_all_mac[$j]} |./jq '.SearchResult.resources[0].id?' |sed -e 's/"//g')
        echo $endpoint_id" <> "${ise_endpoint_all_mac[$j]}
        curl -s --insecure --include \
            --header 'Accept: application/json' \
            --user $ISE_USER:$ISE_PASS \
            --request DELETE $ISE_PAN/$endpoint_id
    fi
    is_exist_in_webportal=false
done
}


#ISE에서 모든 맥 정보를 받아와서 웹포털 서버와 그룹 정보를 비교하여 다르면 웹포탈을 기준으로 ISE의 엔드포인트의 그룹 정보를 변경한다.
function udpate_ise_endpoint()
{
    _groupId=$1
    # ise_endpoint_all_mac=($(curl -s --insecure \
    # --header  'Accept: application/json' \
    # --user $ISE_USER:$ISE_PASS \
    # $ISE_PAN?filter=groupId.EQ.$_groupId |egrep '[a-zA-Z0-9:]{17}' -o))


    _total_count=$(curl -s --insecure \
        --header  'Accept: application/json' \
        --user $ISE_USER:$ISE_PASS \
        $ISE_PAN |./jq '.SearchResult.total?')

    _total_pages=`expr $_total_count / 20 + 1`

    for ((k = 1; k <= $_total_pages; k++)); do
        ise_endpoint_all_mac=($(curl -s --insecure \
            --header  'Accept: application/json' \
            --user $ISE_USER:$ISE_PASS \
            $ISE_PAN?page=$k |egrep '[a-zA-Z0-9:]{17}' -o))

        echo "page "$k".."
    # curl -s --insecure \
    #     --header  'Accept: application/json' \
    #     --user $ISE_USER:$ISE_PASS \
    #     $ISE_PAN?page=$j |egrep '[a-zA-Z0-9:]{17}' -o

    

    # ise_endpoint_all_mac=($(curl -s --insecure \
    #  --header  'Accept: application/json' \
    #  --user $ISE_USER:$ISE_PASS \
    #  $ISE_PAN?page=1 |egrep '[a-zA-Z0-9:]{17}' -o))

        for ((j = 0; j < ${#ise_endpoint_all_mac[@]}; j++)); do
            # echo "${endpoint_all_mac[$j]}"
            for ((i = 0; i < ${#webportal_mac[@]}; i++)); do
                webportal_mac_address=${webportal_mac[$i]:0:2}":"${webportal_mac[$i]:2:2}":"${webportal_mac[$i]:4:2}":"${webportal_mac[$i]:6:2}":"${webportal_mac[$i]:8:2}":"${webportal_mac[$i]:10:2}
                if [ "$webportal_mac_address" == "${ise_endpoint_all_mac[$j]}" ]; then
                    is_exist_in_webportal=true
                fi
            done
            if [ "$is_exist_in_webportal" == "false" ]; then
                #여기서 그룹 이름이 같은지 비교해야 함
                #ise의 맥주소로 엔드포인트의 id검색
                ise_endpoint_id=$(curl -s --insecure \
                        --header 'Accept: application/json' \
                        --user $ISE_USER:$ISE_PASS \
                        $ISE_PAN?filter=mac.EQ.${ise_endpoint_all_mac[$j]} |./jq '.SearchResult.resources[0].id?' |sed -e 's/"//g')
                
                #ise의 엔드포인트 id로 해당 엔드포인트의 그룹 id 검색
                ise_endpoint_groupid=$(curl -s --insecure \
                        --header 'Accept: application/json' \
                        --user $ISE_USER:$ISE_PASS \
                        $ISE_PAN/$endpoint_id |./jq '.ERSEndPoint.groupId?' |sed -e 's/"//g')
                
                #ise의 맥주소로 웹포털내에 원하는 그룹에 맥이 존재하는지 검색 (맥 검색시 맥주소 형태 변환해야함)
                webportal_mac_group=$(mysql engineering -e "select mac_address from mobile_mac where mac_address='${ise_endpoint_all_mac[$j]}'")
                
                # 웹포털 맥 그룹과 ise 엔드포인트 그룹이 같은 경우,,
                if [ ! -z $webportal_mac_group ]; then
                    echo -e "No need to update,,"

                # 웹포털 맥 그룹과 ise 엔트포인트 그룹이 다른 경우,,
                else
                    echo -e "${ise_endpoint_all_mac[$j]} is updated to $_groupId,," >> $LOG
                    # echo -e "${ise_endpoint_all_mac[$j]} -- $ise_endpoint_id -- $_groupId"
                    curl -s --insecure  \
                        --include \
                        --header 'Content-Type:application/json' \
                        --header 'Accept: application/json' \
                        --user $ISE_USER:$ISE_PASS \
                        --request PUT $ISE_PAN/$ise_endpoint_id \
                        --data '
                            {
                                "ERSEndPoint" : {
                                "groupId" : "'$_groupId'",
                                "staticGroupAssignment" : true
                                }
                            }'  > /dev/null 2>&1
                fi
            fi
            is_exist_in_webportal=false
        done    
    done

}

function make_endpoint_list(){
    echo "start code " | awk '{ print strftime(), $0; fflush() }'
    _groupId=$1

    _total_count=$(curl -s --insecure \
        --header  'Accept: application/json' \
        --user $ISE_USER:$ISE_PASS \
        $ISE_PAN |./jq '.SearchResult.total?')

    _total_pages=`expr $_total_count / 20 + 1`
    echo "" > /var/log/endpoint_lists.txt
    for ((k = 1; k <= $_total_pages; k++)); do
        echo "page $k.."
        ise_endpoint_all_id=($(curl -s --insecure \
                                        --header  'Accept: application/json' \
                                        --user $ISE_USER:$ISE_PASS \
                                        $ISE_PAN?page=$k |grep "id" |egrep '[a-zA-Z0-9-]{36}' -o)) #|egrep '[a-zA-Z0-9:]{17}' -o
        ise_endpoint_all_mac=($(curl -s --insecure \
                                        --header  'Accept: application/json' \
                                        --user $ISE_USER:$ISE_PASS \
                                        $ISE_PAN?page=$k |egrep '[a-zA-Z0-9:]{17}' -o))

        for ((i = 0; i < ${#ise_endpoint_all_id[@]}; i++)); do
            ise_endpoint_groupid=$(curl -s --insecure \
                    --header 'Accept: application/json' \
                    --user $ISE_USER:$ISE_PASS \
                    $ISE_PAN/${ise_endpoint_all_id[$i]} |./jq '.ERSEndPoint.groupId?' |sed -e 's/"//g') 
            if [ "$ise_endpoint_groupid" == "$_groupId" ]; then
                # for ((i = 0; i < ${#ise_endpoint_all_mac[@]}; i++)); do
                    echo ${ise_endpoint_all_mac[$i]} >> /var/log/gec_pc_endpoint_lists.txt
                # done
            fi
        done  
    done
    echo "end code " | awk '{ print strftime(), $0; fflush() }'
}

# start function..
create_ise_endpoint $GEC_PC_ID
# udpate_ise_endpoint $GEC_PC_ID
# make_endpoint_list $GEC_PC_ID



    # _total_count=$(curl -s --insecure \
    #     --header  'Accept: application/json' \
    #     --user $ISE_USER:$ISE_PASS \
    #     $ISE_PAN |./jq '.SearchResult.total?')

    # _total_pages=`expr $_total_count / 20 + 1`

    # for ((k = 1; k <= $_total_pages; k++)); do
    #     ise_endpoint_all_mac=($(curl -s --insecure \
    #         --header  'Accept: application/json' \
    #         --user $ISE_USER:$ISE_PASS \
    #         $ISE_PAN?page=$k |egrep '[a-zA-Z0-9:]{17}' -o))
    #     echo $k

    #     for ((j = 0; j < ${#ise_endpoint_all_mac[@]}; j++)); do
    #         echo "${ise_endpoint_all_mac[$j]}"
    #     done
    #     # ise_endpoint_all_mac=""
    # done
# 하루에 한번 그룹별 엔드포인트 파일을 생성하여 총 3개의 그룹에 대해서 파일을 생성한다.
# 생성한 파일을 읽어와 웹포털 디비의 맥주소와 비교하여 ise에 없는 맥주소에 대해서만 생성한다.
# ise에 맥주소가 올라와서 등록되었고, 웹포탈에도 동일한 맥이 등록되어서 아예 생성할수 없기 때문에 그룹에 등록할수 없는 경우가 있는가?


# for ((j = 0; j < ${#webportal_mac[@]}; j++)); do
#     for ((k = 1; k <= $_total_pages; k++)); do
#         echo -e $k".."
#         ise_endpoint_all_id=($(curl -s --insecure \
#             --header  'Accept: application/json' \
#             --user $ISE_USER:$ISE_PASS \
#             $ISE_PAN?page=$k |grep "id" |egrep '[a-zA-Z0-9-]{36}' -o)) #|egrep '[a-zA-Z0-9:]{17}' -o
        
#         ise_endpoint_all_mac=($(curl -s --insecure \
#             --header  'Accept: application/json' \
#             --user $ISE_USER:$ISE_PASS \
#             $ISE_PAN?page=$k |egrep '[a-zA-Z0-9:]{17}' -o))
        
#         for ((i = 0; i < ${#ise_endpoint_all_id[@]}; i++)); do
#             ise_endpoint_groupid=$(curl -s --insecure \
#                     --header 'Accept: application/json' \
#                     --user $ISE_USER:$ISE_PASS \
#                     $ISE_PAN/${ise_endpoint_all_id[$i]} |./jq '.ERSEndPoint.groupId?' |sed -e 's/"//g')

#             if [ "$ise_endpoint_groupid" == "$_groupId" ]; then
#                 echo ${ise_endpoint_all_mac[$i]} >> /var/log/endpoint_lists.txt
#                 # for ((j = 0; j < ${#webportal_mac[@]}; j++)); do
#                     for ((l = 0; l < ${#ise_endpoint_all_mac[@]}; l++)); do
#                         webportal_mac_address=${webportal_mac[$j]:0:2}":"${webportal_mac[$j]:2:2}":"${webportal_mac[$j]:4:2}":"${webportal_mac[$j]:6:2}":"${webportal_mac[$j]:8:2}":"${webportal_mac[$j]:10:2}
#                         echo "$webportal_mac_address == ${ise_endpoint_all_mac[$l]}"
#                         if [ "$webportal_mac_address" == "${ise_endpoint_all_mac[$l]}" ]; then
#                             is_exist_in_ise=true 
#                             echo "true"   
#                         fi
#                     done
#                     if [ "$is_exist_in_ise" == "false" ]; then
#                         echo -e "Created ise endpoint($webportal_mac_address).."
#                         echo -e "Created ise endpoint($webportal_mac_address).." >> $LOG
#                         curl --insecure  \
#                             --include \
#                             --header 'Content-Type:application/json' \
#                             --header 'Accept: application/json' \
#                             --user $ISE_USER:$ISE_PASS \
#                             --request POST $ISE_PAN \
#                             --data '
#                         {
#                             "ERSEndPoint" : {
#                             "name" : "",
#                             "description" : "",
#                             "mac" : "'$webportal_mac_address'",
#                             "groupId" : "'$_groupId'",
#                             "staticGroupAssignment" : true
#                             }
#                         }'  
#                     # else
#                     #     echo -e "No need to create endpoint, the mac lists in the webportal equal to ise endpoint group for ($_groupId)"
#                         # echo -e "No need to create endpoint, the mac lists in the webportal equal to ise endpoint group for ($1)" >> $LOG    
#                     fi
#                     is_exist_in_ise=false
#                 # done
#             fi    
#         done
#     done
# done


# curl --insecure \
#      --header 'Accept: application/vnd.com.cisco.ise.identity.endpointgroup.1.0+xml' \
#      --user $ISE_USER:$ISE_PASS \
#      $ISE_PAN?filter=mac.EQ.$endpoint_mac

# curl --insecure --include \
#      --header 'Accept: application/json' \
#      --user $ISE_USER:$ISE_PASS \
#      --request DELETE $ISE_PAN/$id









  #if ise 그룹아이디와 지정된 그룹아이디가 동일하면 엔드포인트 맥 비교
                # for ((j = 0; j < ${#webportal_mac[@]}; j++)); do
                #     - ise_endpoint_all_mac[k] == webportal_mac이 동일한지 비교동일하면
                #        is_exist_in_ise를 true
                #- 다르면(if [ "$is_exist_in_ise" == "false" ]; then)
                # echo -e "Created ise endpoint($webportal_mac_address).."
                # echo -e "Created ise endpoint($webportal_mac_address).." >> $LOG
                #         curl --insecure  \
                #             --include \
                #             --header 'Content-Type:application/json' \
                #             --header 'Accept: application/json' \
                #             --user $ISE_USER:$ISE_PASS \
                #             --request POST $ISE_PAN \
                #             --data '
                #         {
                #             "ERSEndPoint" : {
                #             "name" : "",
                #             "description" : "",
                #             "mac" : "'$webportal_mac_address'",
                #             "groupId" : "'$_groupId'",
                #             "staticGroupAssignment" : true
                #             }
                #         }'  
                #     else
                #     echo -e "No need to create endpoint, the mac lists in the webportal equal to ise endpoint group for ($1)"
                #     echo -e "No need to create endpoint, the mac lists in the webportal equal to ise endpoint group for ($1)" >> $LOG
                #     fi


                        
        # curl -s --insecure \
        # --header  'Accept: application/json' \
        # --user $ISE_USER:$ISE_PASS \
        # $ISE_PAN?filter=groupId.EQ.$_groupId&page=$k |egrep '[a-zA-Z0-9:]{17}' -o

        # get endpoint with _groupId
        # ise_endpoints=($(curl -s --insecure \
        # --header  'Accept: application/json' \
        # --user $ISE_USER:$ISE_PASS \
        # $ISE_PAN?filter=groupId.EQ.$_groupId&page=$k |egrep '[a-zA-Z0-9:]{17}' -o))
        # for ((i = 0; i < ${#ise_endpoints[@]}; i++)); do
        #     echo ${ise_endpoints[$i]} >> /var/log/endpoint_lists.txt
        # done