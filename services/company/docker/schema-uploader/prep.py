"""
prep.py

prep Python module
"""

# prep.py — prep Python module

import sys
import json

with open(sys.argv[1]) as f:
    with open("./data.json", 'w') as t:
        s = {"schema": f.read()}
        t.write(json.dumps(s))
