#!/usr/bin/python2.7
# -*- coding: utf-8 -*-


import requests
import pprint
import pymysql

REST_USER = "erstest"
REST_PASSWORD = "Opasnet1!"
api_url =  "https://10.11.0.81:9060/ers/config/endpoint"
headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
}
mac_address = "00:01:02:03:04:08"

DB_USER = "test"
DB_PASSWORD = "password"
db_name = "engineering"

logfile = "/home/saisei/dev/engineering/ise_api.log"

class MysqlController:
    def __init__(self, host, id, pw, db_name):
        self.conn = pymysql.connect(host=host, user= id, password=pw, db=db_name, charset='utf8')
        self.curs = self.conn.cursor()

    def insert_total(self,total):
        sql = 'INSERT INTO entire_nodes (count_of_nodes) VALUES (%s)'
        self.curs.execute(sql,(total,))
        self.conn.commit()

    def get_internal(self):
        sql = 'select member_id, mac_address from (select * from internal_assets_mac where not as_cls_cd = 1 or not as_ident_cd = 1 or not as_detail_cd = 5);'
        self.curs.execute(sql)
        return self.curs.fetchall()

    def get_zeroclient(self):
        sql= 'select member_id, mac_address from internal_assets_mac where internal_assets_mac.member_id = username and as_cls_cd = 1 and as_ident_cd = 1 and as_detail_cd = 5'
        self.curs.execute(sql)
        return self.curs.fetchall()

    def get_external(self):
        sql = 'select member_id, mac_address from mobile_mac;'
        self.curs.execute(sql)
        return self.curs.fetchall()
        # print(self.curs.fetchall())

        # self.conn.commit()

conn = MysqlController('localhost', DB_USER, DB_PASSWORD, db_name)
result=conn.get_external()

# print(result)
# print(result[0][2])
# print(conn)
_mac=[]
with open(logfile, 'r') as f:
    lines = f.readlines()
    # print(lines)
    for line in lines:
        _mac.append(line.rstrip('\n'))    
    # f.write(name+","+description+","+mac_address+"\n")


for row in result:
    # print(row)
    for i, col in enumerate(row):
        if i == 0:
            # name = col
            name = col
            # name.decode('utf_8')
        if i == 1:
            # print(col)
            try:
                col = col.upper()
                mac_address = col[0:2]+":"+col[2:4]+":"+col[4:6]+":"+col[6:8]+":"+col[8:10]+":"+col[10:12]
            except Exception as e:
                pass
            description = "SEC_VDI"
            if mac_address not in _mac:
                # print(mac_address)
                r = requests.post(api_url, headers=headers, auth=(REST_USER, REST_PASSWORD), json={
                    "ERSEndPoint" : {
                    "name" : name,
                    "description" : description,
                    "mac" : mac_address,
                    "groupId" : "f7684df0-d20c-11ea-be06-aef7c41e37a4",
                    "staticGroupAssignment" : "true"
                    }
                }, verify=False)
                with open(logfile, 'a') as f:
                    f.write(mac_address+"\n")
                print("({}) is updated in ISE with code ({})..".format(mac_address, r.status_code))
            else:
                print("There is no mac_address that is updated..")
                # pprint.pprint(r)



# r = requests.get(api_url, headers=headers, auth=(REST_USER, REST_PASSWORD), verify=False)
# print(r.json)
# r = requests.post(api_url, headers=headers, auth=(REST_USER, REST_PASSWORD), json={
#                     "ERSEndPoint" : {
#                     "name" : name,
#                     "description" : description,
#                     "mac" : mac_address,
#                     "groupId" : "f7684df0-d20c-11ea-be06-aef7c41e37a4",
#                     "staticGroupAssignment" : "true"
#                     }
#                 }, verify=False)

