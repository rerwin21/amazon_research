# -*- coding: utf-8 -*-
"""
@author: rerwin21
"""

#%% import boto for EC2 AWS automation
import boto.ec2
from time import sleep
import os


#%% used my vols profile: rootkey_3.csv
access_key = "access_key"
secret_key = "secret_key"


#%% get a connection to the east region
conn = boto.ec2.connect_to_region("us-east-1", 
                                  aws_access_key_id=access_key,
                                  aws_secret_access_key=secret_key)


#%% create the reservation of instances
reservation = conn.run_instances('ami-df28d2b2',
                                 key_name='pub_key_er',
                                 security_groups=['security-group-vols'],
                                 instance_type='t2.micro',
                                 min_count=3,
                                 max_count=3)
                                
                                 
#%% get list of instances
instance_lst = reservation.instances


#%% get a status update and wait if the instance isn't up and running yet
for instance in instance_lst:
    while instance.state != "running":
        sleep(5)
        instance.update()
    print "%s is running" % instance.ip_address


#%% SCP file to each host (consider replacing with fabric 'local' call as parallel task)
args_tarpath = "/home/rerwin21/amazon_proj/amazon/get_num_reviews_aws.py"
key_path = "~/.ssh/id_rsa"

for instance_IP in instance_lst:
    ip_address = instance_IP.ip_address
    arg_tuple = (key_path, args_tarpath, ip_address)
    os.system('scp -i %s %s ubuntu@%s:~' % arg_tuple)


#%% get username and host
hosts = ["ubuntu@" + ip.ip_address for ip in instance_lst]


#%% Create the host dict to be passed later in our task 
host_dict = {host: (0, 10 + x) for x, host in enumerate(hosts)}


#%% import fabric for SSH automation
from fabric.api import run, parallel, env
from fabric.tasks import execute


#%% set environment variable 
env.hosts = hosts


#%% define function, that runs the task on each host, in parallel
# also, make sure the script arguments host-specific
@parallel
def webscraper(host_dict):
    host = "ubuntu@" + env.host
    start_end = host_dict[host]
    run("python get_num_reviews_aws.py %s %s" % start_end)


#%% run on hosts
# don't need to set the 'hosts=' argument because I stored them in an environment variable
execute(webscraper, host_dict)


#%% Get the instance ID for each instance
instances = [instance.id for instance in instance_lst]


#%% terminate the EC2 instances
conn.terminate_instances(instance_ids=instances)


#%% clear hosts
env.hosts = []