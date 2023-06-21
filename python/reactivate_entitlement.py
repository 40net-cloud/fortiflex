#!/usr/bin/env python3
"""
FortiFlex: Regenerate token for a VM

Provide API credentials via environment variables

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

def regenerate_token(token,serial_number):
    endpoint = '/ES/api/fortiflex/v2/entitlements/reactivate'
    url = '{}{}'.format(flex_url,endpoint)
    body = {
        "serialNumber":"{}".format(serial_number)
    }
    results = requests.post(url,headers={'Authorization': 'Bearer {}'.format(token)},json=body)
    if(results.ok):
        print ('--> Reactivate serial number: {} ...'.format(serial_number))
        jData = json.loads(results.content)
        jObjects = jData['entitlements']
        for x in range(len(jObjects)):
            print ('"{}","{}","{}"'.format(jObjects[x]['serialNumber'],jObjects[x]['token'],jObjects[x]['status']))
    else:
        print('--> Error returned to login: {}'.format(results))
    return()

parser=argparse.ArgumentParser(description='FortiFlex: Reactivate token for specific serial number. API username and password need to be provided using environment variables.')
parser.add_argument('--serial-number', help='FortiFlex serial number', required=True, type=str)
args = parser.parse_args()


token = retrieve_auth_token()
regenerate_token(token, args.serial_number)
