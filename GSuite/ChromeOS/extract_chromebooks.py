#!/usr/bin/env python3

import os
import pickle
import json
import sys

from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request

KEYS = set([
    'annotatedAssetId',
    'annotatedLocation',
    'annotatedUser',
    'autoUpdateExpiration',
    'bootMode',
    'deviceId',
    'etag',
    'ethernetMacAddress',
    'firmwareVersion',
    'kind',
    'lastEnrollmentTime',
    'lastKnownNetwork',
    'lastSync',
    'macAddress',
    'manufactureDate',
    'meid',
    'model',
    'notes',
    'orderNumber',
    'orgUnitPath',
    'osVersion',
    'platformVersion',
    'serialNumber',
    'status',
    'supportEndDate',
    'tpmVersionInfo',
    'willAutoRenew',
])


def get_credentials():
    creds = None

    # Check to see if we have a token file
    if os.path.exists('token.pickle'):
        with open('token.pickle', 'rb') as token:
            creds = pickle.load(token)
    # No token or the token is invalid
    if not creds or not creds.valid:
        # Refresh an expired token
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            # Don't have any tokens, get first token
            flow = InstalledAppFlow.from_client_secrets_file(
                'client_secrets.json',
                ['https://www.googleapis.com/auth/admin.directory.device.chromeos.readonly'],
            )
            creds = flow.run_console()
        # Save the token for later
        with open('token.pickle', 'wb') as token:
            pickle.dump(creds, token)
    # Return the valid, refreshed credentials
    return creds


def main():
    creds = get_credentials()
    service = build('admin', 'directory_v1', credentials=creds)
    devices = []
    req = service.chromeosdevices().list(
        customerId='my_customer',
        maxResults=200,
        projection='FULL'
    )
    resp = req.execute()
    these_devices = resp.get('chromeosdevices', [])
    while True:
        devices.extend(these_devices)
        print(f"Got {len(devices)}...", file=sys.stderr)
        req = service.chromeosdevices().list_next(
            previous_request=req,
            previous_response=resp,
        )
        if not req:
            break
        resp = req.execute()
        these_devices = resp.get('chromeosdevices', [])

    filtered_devices = []
    for row in devices:
        for bad_key in set(row.keys()).difference(KEYS):
            row.pop(bad_key)
        filtered_devices.append(row)

    json.dump(filtered_devices, sys.stdout)


if __name__ == '__main__':
    main()
