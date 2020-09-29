# Overview

I have done a ton of GSuite management over the last decade or so. During that
time I've come up with ways of dealing with common tasks that I think other's
might benefit from.

# Requirements

* [csvkit](https://csvkit.readthedocs.io/en/latest/) - Great set of tools for dealing with .csv files on the command line.
* sqlite3 - Simple file based database
* requirements.txt - Python dependencies
* client_secrets.json - You will need to generate client_secrets.json on an
  account that has permission to read the admin.directory.user.readonly
  endpoint. This can be done roughly via the following:  
  * Navigate to the [GCP](https://console.cloud.google.com) console
  * Create/go to a project in your organization
  * APIs & Services -> Dashboard -> + ENABLE APIS AND SERVICES -> Enable Admin SDK
  * APIs & Services -> OAuth consent screen -> Fill everything out. This is the information on the "this app needs access to your blah blah" dialog.
  * APIs & Services -> Credentials -> + CREATE CREDENTIALS -> OAuth client ID -> Desktop app
  * APIs & Services -> Credentials -> OAuth 2.0 Client IDs -> &lt;your client&gt; -> DOWNLOAD JSON
  * Rename long client_secrets_blah_blah.json to client_secrets.json.
  * Move that file into the directory with the extract_gsuite_users.py script.

# What?

Running setup_database.sh does the following:

1. The first step is to export the [user data](https://developers.google.com/admin-sdk/directory/v1/reference/users#resource) from the GSuite domain into a
   .json file. The extract_gsuite_users.py script handles this part by asking
   you to go through an offline oauth2 flow to generate a token before using
   the Python API to extract all users as JSON.
2. The JSON consistes of a list of dict-like nested objects that need to be
   flattened using json2csv.py. A nested dict looks like the following:  
   ```
   {
     "primaryEmail": "EmailAddress",
     "name": {
         "givenName": "FirstName",
         "familyName": "LastName"
     }
   }
   ```  
   Where the _"name"_ key contains sub-keys. This needs to be flattened into:  
   ```
   {
     "primaryEmail": "EmailAddress",
     "name.givenName": "FirstName",
     "name.familyName": "LastName"
   }
   ```  
   So that we can generate a .csv file from the JSON data that we extracted from GSuite:  
   ```
   | primaryEmail      | name.givenName | name.familyName |
   |------------------ | -------------- | ------------ |
   | email@example.com | FirstName      | LastName     |
   ```  
3. csvsql is part of csvkit and is used to load .csv data into a sqlite3
   database which we can use to explore our GSuite data locally.

# Why?

## Print user counts for every OU in the domain
```
sqlite3 all_users.db "select orgUnitPath,count(*) from users group by orgUnitPath order by orgUnitPath"
```

## Print suspended users that aren't in our terminated employees OU
```
sqlite3 all_users.db "select primaryEmail from users where suspended and orgUnitPath not like '/Staff/HR Terminated%'"
```

## Move suspended users that are not in our terminated OU, into the terminated OU using [GAM](https://github.com/jay0lee/GAM/wiki)
```
sqlite3 all_users.db "select primaryEmail from users where suspended and orgUnitPath not like '/Staff/HR Terminated%'" |\
    xargs -L1 -P10 -i gam update user '{}' org '/Staff/HR Terminated'
```
