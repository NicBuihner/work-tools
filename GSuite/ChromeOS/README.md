# Overview

I have done a ton of GSuite management over the last decade or so. During that
time I've come up with ways of dealing with common tasks that I think other's
might benefit from.

# Requirements

* [csvkit](https://csvkit.readthedocs.io/en/latest/) - Great set of tools for dealing with .csv files on the command line.
* sqlite3 - Simple file based database
* requirements.txt - Python dependencies
* client_secrets.json - You will need to generate client_secrets.json on an
  account that has permission to read the admin.directory.chromeos.readonly
  endpoint. This can be done roughly via the following:  
  * Navigate to the [GCP](https://console.cloud.google.com) console
  * Create/go to a project in your organization
  * APIs & Services -> Dashboard -> + ENABLE APIS AND SERVICES -> Enable Admin SDK
  * APIs & Services -> OAuth consent screen -> Fill everything out. This is the information on the "this app needs access to your blah blah" dialog.
  * APIs & Services -> Credentials -> + CREATE CREDENTIALS -> OAuth client ID -> Desktop app
  * APIs & Services -> Credentials -> OAuth 2.0 Client IDs -> &lt;your client&gt; -> DOWNLOAD JSON
  * Rename long client_secrets_blah_blah.json to client_secrets.json.
  * Move that file into the directory with the extract_chromebooks.py script.

# What?

Running setup_database.sh does the following:

1. The first step is to export the [device
   data](https://developers.google.com/admin-sdk/directory/v1/reference/chromeosdevices#resource)
   from the GSuite domain into a .json file. The extract_chromebooks.py script
   handles this part by asking you to go through an offline oauth2 flow to
   generate a token before using the Python API to extract all devices as JSON.
   We also cull some keys here to prevent sqlite3 from complaining about the
   number of columns.
2. The JSON consistes of a list of dict-like nested objects that need to be
   flattened using json2csv.py. A nested dict looks like the following:  
   ```
   {
     "serialNumber": "FBXBLAHBLAH01",
     "deviceId": "b2d957e2-01dc-11eb-ab0e-1f82accfbbaf",
     "recentUsers": [
        {
         "type": "UserType",
         "email": "user@example.com"
        }
     ]
   }
   ```  
   Where the _"name"_ key contains a list. This needs to be flattened into:  
   ```
   {
     "serialNumber": "FBXBLAHBLAH01",
     "deviceId": "b2d957e2-01dc-11eb-ab0e-1f82accfbbaf",
     "recentUsers.0.type": "UserType",
     "recentUsers.0.email": "user@example.com"
   }
   ```  
   So that we can generate a .csv file from the JSON data that we extracted from GSuite:  
   ```
   | serialNumber  | deviceId                             | recentUsers.0.type | recentUsers.0.email |
   | ------------- | ------------------------------------ | ------------------ | ------------------- |
   | FBXBLAHBLAH01 | b2d957e2-01dc-11eb-ab0e-1f82accfbbaf | UserType           | user@example.com    |
   ```  
3. csvsql is part of csvkit and is used to load .csv data into a sqlite3
   database which we can use to explore our GSuite data locally.

# Why?

## Count devices whose lastSync was prior to 2020-09-01
```
sqlite3 all_devices.db "select count(*) from cros where lastSync>'2020-09-01'"
```

## Move devices whose lastSync was prior to 2020-09-01 using [GAM](https://github.com/jay0lee/GAM/wiki)
```
sqlite3 all_devices.db "select deviceId from cros where lastSync>'2020-09-01'" |\
    xargs -L1 -P10 -i gam update cros '{}' org '/Chrome Devices/Lost or Missing'
```

## Count devices by model
```
sqlite3 all_devices.db "select model,count(model) from cros group by model order by model"
```

## Count devices by supportEndDate
```
sqlite3 -csv all_devices.db "select supportEndDate,count(supportEndDate) from cros group by supportEndDate order by supportEndDate"
```

## Move list of chromebook serial numbers into an OU using [GAM](https://github.com/jay0lee/GAM/wiki)
```
< ListOfSerials xargs -L1 -i sqlite3 all_devices.db "select deviceId from cros where serialNumber like '{}'" |\
    xargs -L1 -P10 -i gam update cros '{}' org '/Student/Ridgemont High'
```

