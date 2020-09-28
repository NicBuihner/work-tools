#!/usr/bin/env python3

import os
import pickle
import json
import sys

from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request


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
                ['https://www.googleapis.com/auth/admin.directory.user.readonly'],
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
    users = []
    req = service.users().list(
        customer='my_customer',
        maxResults=500,
        projection='full'
    )
    resp = req.execute()
    these_users = resp.get('users', [])
    while True:
        users.extend(these_users)
        print(f"Got {len(users)}...", file=sys.stderr)
        req = service.users().list_next(
            previous_request=req,
            previous_response=resp,
        )
        if not req:
            break
        resp = req.execute()
        these_users = resp.get('users', [])
    json.dump(users, sys.stdout)


if __name__ == '__main__':
    main()
