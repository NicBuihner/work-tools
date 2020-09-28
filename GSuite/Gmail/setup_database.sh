#!/bin/bash

rm all_users.db
python3 extract_gsuite_users.py > all_users.json
python3 json2csv.py all_users.json > all_users.csv
csvsql \
    --db sqlite:///all_users.db \
    --tables users \
    --overwrite \
    --insert ./all_users.csv
