#!/usr/bin/env python
#
# Convert year and date of the year to a ISO UTC date-time.
# 
# This tool is used to convert the Landsat time stamps to a standard date-time.
#
import sys
from datetime import datetime, timedelta
timestamp = datetime(int(sys.argv[1]), 1, 1) + timedelta(float(sys.argv[2]))
print timestamp.isoformat("T") + "Z"
