#!/bin/bash
sudo julia -q -e 'using KeyCounter; countkeys()' -- --user `id -u` "$@"
