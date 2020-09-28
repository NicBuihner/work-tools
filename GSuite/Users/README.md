# Requirements

* [csvkit](https://csvkit.readthedocs.io/en/latest/) - Great set of tools for dealing with .csv files on the command line.
* sqlite3 - Simple file based database
* requirements.txt - python dependencies

# What?

Running setup_database.sh does the following:

1. The first step is to export the user data from the GSuite domain into a
   .json file. The extract_gsuite_users.py script handles this part by asking
   you to go through an offline oauth2 flow to generate a token before using
   the Python API to extract all users as JSON.
2. The JSON consistes of a list of dict-like nested objects that need to be
   flattened. What that means that we need to normalized the nested dicts into
   a flat dict using json2csv.py. A nested dict looks like the following:  
   ```
   {
     "primaryEmail": "EmailAddress",
     "name": {
         "givenName": "FirstName",
         "surName": "LastName"
     }
   }
   ```  
   Needs to be flattened into:  
   ```
   {
     "primaryEmail": "EmailAddress",
     "name.givenName": "FirstName",
     "name.surName": "LastName"
   }
   ```  
   So that we can generate a .csv file from the JSON data that we extracted from GSuite:  
   ```
   | primaryEmail      | name.givenName | name.surName |
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
