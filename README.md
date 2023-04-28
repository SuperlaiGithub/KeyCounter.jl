# KeyCounter.jl

Utility to count keys presses on a Linux system. Useful for determining the frequency with which particular keys and key combinations are used when developing a keyboard layout.

## Installation

Once you have a working Julia installation use the following command
```bash
sudo julia -e 'using Pkg; Pkg.add("KeyCounter"); using KeyCounter; install()'
```

Since we require root privileges, alternatively use `sudo julia` and then
```
]add KeyCounter
install()
```

## Event Number

KeyCounter needs to read keyboard events from a file in `/dev/input`. However, there are several files numbered `event0`, `event1`, etc and which corresponds to your keyboard is somewhat random. KeyCounter will attempt to autodetect the correct one, but this is likely to not succeed.

To determine the correct number, either `sudo hexdump /dev/input/eventN` each N in turn and type some keys and see if there is any data produced.

Alternatively, examine the text file `/proc/bus/input/devices` and look for a section with the correct `N: [Name]` line and a corresponding `H: ... kbd eventN` line.

## Julia Usage

First `sudo julia` and then
```julia
using KeyCounter
settings["input"] = "/dev/input/eventN"
countkeys()
```

Other possible settings (ie `settings["key"] = value`) are
    * `output`: (String) filename to save results to
    * `interval`: (String) frequency to save results, in the format `[Nd][Nh][Nm][Ns]`
    * `quiet`: (Bool) whether to suppress output
    * `debug`: (Bool) whether to display debugging information
    * `user`: (Int) user id for ownership of the output file (as we are running as root)

## Commandline Usage

From the command line use
```bash
keycounter []
```

## Uninstallation

From the command line use
```bash
keycounter-uninstall
```

Alternatively, `sudo julia` and then
```julia
using KeyCounter
uninstall()
]remove KeyCounter
```

## Credits & License

Copyright 2023 Harry Ray. Licensed under GPLv3.

Keymaps originally from `logkeys` (https://github.com/kernc/logkeys), used under GPLv3.
