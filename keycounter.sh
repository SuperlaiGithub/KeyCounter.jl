#!/bin/bash
sudo julia -q src/KeyCounter.jl -- --user `id -u` "$@"
