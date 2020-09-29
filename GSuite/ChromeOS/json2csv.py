#!/usr/bin/env python3

import json
import sys
import csv

from flatten_dict import flatten


def main():
    with open(sys.argv[1], 'r') as f:
        d = json.load(f)

    fields = set()
    rows = []
    for row in d:
        fd = flatten(row, reducer='dot', enumerate_types=(list,))
        fields.update(set(fd.keys()))
        rows.append(fd)

    c = csv.DictWriter(sys.stdout, fieldnames=fields)
    c.writeheader()
    c.writerows(rows)


if __name__ == '__main__':
    main()
