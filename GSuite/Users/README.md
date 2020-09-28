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
     "name": {
         "givenName": "FirstName",
         "surName": "LastName"
     }
   }
   ```  
   Needs to be flattened into:  
   ```
   {
     "name.givenName": "FirstName",
     "name.surName": "LastName"
   }
   ```  
   So that we can generate a .csv file from the JSON data that we extracted from GSuite:  
   ```
   | name.givenName | name.surName |
   | -------------- | ------------ |
   | FirstName      | LastName     |
   ```  

