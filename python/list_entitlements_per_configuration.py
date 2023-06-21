#!/usr/bin/env python3
"""
FortiFlex: list entitlements per configuration id

Provide API credentials and program serialnumber via environment variables

@Author: Joeri Van Hoof
@Date: 21/06/2023
@Links: https://github.com/40net-cloud/fortiflex
"""

import os
import sys
import requests
import json
import argparse

## Variables
program_sn = os.getenv('FORTIFLEX_PROGRAM_SN')
api_user = os.getenv('FORTIFLEX_API_USER')
api_password = os.getenv('FORTIFLEX_API_PASSWORD')

fc_oauth = 'https://customerapiauth.fortinet.com/api/v1/oauth/token/'
flex_url = 'https://support.fortinet.com'

def retrieve_auth_token():
    body = {
        'username':'{}'.format(api_user),
        'password':'{}'.format(api_password),
        'client_id':'flexvm',
        'grant_type':'password'
    }
    print ('--> Connecting to FortiCare and retieving API Token...')
    results = requests.post(fc_oauth,json=body)
    if(results.ok):
        jData = json.loads(results.content)
        token = jData['access_token']
        return(token)
    else:
        print('--> unable to login: {}'.format(results))
        
    return 0

def list_entitlements_per_configuration_id(token,configuration_id):
    endpoint = '/ES/api/fortiflex/v2/entitlements/list'
    url = '{}{}'.format(flex_url,endpoint)
    body = {
        "configId":"{}".format(configuration_id)
    }
    results = requests.post(url,headers={'Authorization': 'Bearer {}'.format(token)},json=body)
    if(results.ok):
        print ('--> Listing available entitlements for configuration id {} ...'.format(configuration_id))
        jData = json.loads(results.content)
        jObjects = jData['entitlements']
        for x in range(len(jObjects)):
            print ('"{}","{}"'.format(jObjects[x]['serialNumber'],jObjects[x]['token']))
    else:
        print('--> unable to fetch entitlements: {}'.format(results))
    return()

parser=argparse.ArgumentParser(description='FortiFlex: List all entitlements in CSV format for a configuration id. API username, password and program serialnumber eed to be provided using environment variables.')
parser.add_argument('--id', help='FortiFlex configuration id to list all entitlements', required=True, type=int)
args = parser.parse_args()

token = retrieve_auth_token()
list_entitlements_per_configuration_id(token, args.id)
