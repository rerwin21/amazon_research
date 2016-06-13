# -*- coding: utf-8 -*-
"""
@author: rerwin21
"""

#%%
import boto.ec2
from time import sleep
import os


#%% used my vols profile: rootkey_3.csv
access_key = "access_key"
secret_key = "secret_key"

conn = boto.ec2.connect_to_region("us-east-1", 
                                  aws_access_key_id=access_key,
                                  aws_secret_access_key=secret_key)


#%%
reservation = conn.run_instances('ami-df28d2b2',
                                 key_name='pub_key_er',
                                 security_groups=['security-group-vols'],
                                 instance_type='t2.micro',
                                 min_count=5,
                                 max_count=5)
                                
                                 
#%%
instance_lst = reservation.instances


#%%
for instance in instance_lst:
    while instance.update() != "running":
        sleep(5)
    print "%s is running" % instance.ip_address


#%%
args_tarpath = "/home/rerwin21/amazon_proj/amazon/get_num_reviews_aws.py"
key_path = "~/.ssh/id_rsa"

for instance_IP in instance_lst:
    ip_address = instance_IP.ip_address
    arg_tuple = (key_path, args_tarpath, ip_address)
    os.system('scp -i %s %s ubuntu@%s:~' % arg_tuple)


#%%
instances = [instance.id for instance in instance_lst]


#%%
conn.terminate_instances(instance_ids=instances)                                 