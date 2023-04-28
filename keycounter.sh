#!/bin/bash
sudo julia -q -e 'using KeyCounter; run()' -- --user `id -u` "$@"
