#!/bin/bash

rm all_devices.db
python3 extract_chromebooks.py > all_devices.json
python3 json2csv.py all_devices.json > all_devices.csv
csvsql \
    --db sqlite:///all_devices.db \
    --tables cros \
    --insert all_devices.csv
