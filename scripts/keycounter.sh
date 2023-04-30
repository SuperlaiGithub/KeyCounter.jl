#!/bin/sh
if [ $1 = "--uninstall"]
then
    sudo julia -q -e 'using KeyCounter; uninstall()'
else
    sudo julia -q -e 'using KeyCounter; countkeys()' -- --user `id -u` "$@"
fi