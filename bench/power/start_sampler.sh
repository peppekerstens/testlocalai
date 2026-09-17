#!/usr/bin/env bash
pkill -f "python3 /tmp/[s]ampler.py"
rm -f /tmp/power.csv
nohup python3 /tmp/sampler.py /tmp/power.csv 10800 >/tmp/sampler.log 2>&1 < /dev/null &
disown
