# -*- coding: utf-8 -*-
"""
@author: rerwin21
"""


#%%
import pandas as pd
import os


#%%
os.chdir('/home/rerwin21/amazon_proj/aws_files/')


#%%
files = os.listdir(os.getcwd())


#%%
dfs = [pd.read_csv(csv) for csv in files]


#%%
df = pd.concat(dfs)


#%%
path = os.path.join('~/amazon_proj', 'reviewer_info_total.csv')


#%%
df.to_csv(path, index=False)


#%% how many didn't get votes?
empty_votes = df[df['votes'].str.startswith('Helpful', na=False) != True]