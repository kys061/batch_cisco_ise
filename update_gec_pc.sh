#!/bin/bash
#
db_name=tswebdb
mac=($(mysql tswebdb -e "select * from (select * from internal_assets_mac where not as_cls_cd = 1 or not as_ident_cd = 1 or not as_detail_cd = 5) as abc" |egrep '[a-z0-9]{12}' -o))
ISE_USER=ersadmin
ISE_PASS=Opasnet1!
ISE_PAN=https://66.86.125.12:9060/ers/config/endpoint
GEC_MOBILE=4a2d63a0-d21b-11ea-8f4f-e2c19cef1786
GEC_PC=34f3ff90-d21a-11ea-8f4f-e2c19cef1786
GEC_VDI=3a89f0d0-d21b-11ea-8f4f-e2c19cef1786

for ((i = 0; i < ${#mac[@]}; i++)); do
  # echo -e  ${mac[$i]:0:2}":"${mac[$i]:2:2}":"${mac[$i]:4:2}":"${mac[$i]:6:2}":"${mac[$i]:8:2}":"${mac[$i]:10:2}
  mac_address=${mac[$i]:0:2}":"${mac[$i]:2:2}":"${mac[$i]:4:2}":"${mac[$i]:6:2}":"${mac[$i]:8:2}":"${mac[$i]:10:2}
  curl --insecure  \
    --include \
    --header 'Content-Type:application/json' \
    --header 'Accept: application/json' \
    --user $ISE_USER:$ISE_PASS \
    --request POST $ISE_PAN \
    --data '
  {
    "ERSEndPoint" : {
    "name" : "'$mac_address'",
    "description" : "",
    "mac" : "'$mac_address'",
    "groupId" : "'$GEC_PC'",
    "staticGroupAssignment" : true
    }
  }'
done


mac_ext=($(mysql tswebdb -e "select mac_address from external_assets_mac where asset_type = 'pc' " |egrep '[a-z0-9]{12}' -o))

for ((i = 0; i < ${#mac_ext[@]}; i++)); do
  # echo -e  ${mac[$i]:0:2}":"${mac[$i]:2:2}":"${mac[$i]:4:2}":"${mac[$i]:6:2}":"${mac[$i]:8:2}":"${mac[$i]:10:2}
  mac_address=${mac_ext[$i]:0:2}":"${mac_ext[$i]:2:2}":"${mac_ext[$i]:4:2}":"${mac_ext[$i]:6:2}":"${mac_ext[$i]:8:2}":"${mac_ext[$i]:10:2}
  curl --insecure  \
    --include \
    --header 'Content-Type:application/json' \
    --header 'Accept: application/json' \
    --user $ISE_USER:$ISE_PASS \
    --request POST $ISE_PAN \
    --data '
  {
    "ERSEndPoint" : {
    "name" : "'$mac_address'",
    "description" : "",
    "mac" : "'$mac_address'",
    "groupId" : "'$GEC_PC'",
    "staticGroupAssignment" : true
    }
  }'
done

