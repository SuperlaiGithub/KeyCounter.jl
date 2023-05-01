# KeyCounter.jl

Utility to count keys presses on a Linux system. Useful for determining the frequency with which particular keys and key combinations are used when developing a keyboard layout.

## Installation

Once you have a working Julia installation use the following command
```bash
sudo julia -e 'using Pkg; Pkg.add("KeyCounter"); using KeyCounter; install()'
```

Alternatively, start Julia as root using `sudo julia`. In the REPL press `]` to enter the package prompt and then use `add KeyCounter` to download the package. Once this is complete, press backspace to exit the package prompt and install the program using
```julia-repl
using KeyCounter
install()
```

## Event Number

KeyCounter needs to read keyboard events from a file in `/dev/input`. However, there are several files numbered `event0`, `event1`, etc and which corresponds to your keyboard is somewhat random. KeyCounter will attempt to autodetect the correct one, but this is likely to not succeed by itself.

Depending on how strange your setup or keyboard is, you should be able to auto detect your keyboard by supplying the `keyboard` parameter with the make and model of your keyboard (ie "Razer Blackwidow").

If KeyCounter can't determine the keyboard number correctly then you may be able to determine the correct event number by examining the text file `/proc/bus/input/devices`. Within this file look for a section with the correct `N: [Name]` line and a corresponding `H: ... kbd eventN` line.

Alternatively, use `sudo hexdump /dev/input/eventN` for each N in turn and type some keys and see if there is any data produced. For the correct N you should receive data whenever a key is pressed or released.

The correct value of N can then be passed to KeyCounter with the `event` parameter.

## Julia Usage

First `sudo julia` and then
```julia-repl
using KeyCounter
countkeys()
```
KeyCounter will attempt to auto detect the correct keyboard device. If this doesn't work you can supply the correct number, along with other settings as keyword arguments to `countkeys`. Acceptable keywords are detailed in the REPL help prompt (type `?countkeys`), which are summarised here.

    * keyboard: (String) name of the keyboard to assist with autodetecting. Using just keywords like the make and model works best (ie "logitech g512")
    * event: (Int) number of the event file to read from
    * input: (String) event file to read from (ie /dev/input/event0). Overrides `event` setting
    * output: (String) filename to save results to
    * interval: (String) frequency to save results, in the format `[Nd][Nh][Nm][Ns]`
    * quiet: (Bool) whether to suppress output
    * debug: (Bool) whether to display debugging information (overrides `quiet`)
    * user: (Int) user id for ownership of the output file (as we are running as root)

To stop counting keys, simply type `<CTRL>>+C` (`^C`) or, if running in the background, send SIGINT to the process. Keys counted will be saved to the output file before exiting.

## Commandline Usage

From the command line use
```
keycounter
```
This will use default settings and attempt to auto detect your keyboard. For list of available options use
```
keycounter --help
```
To stop counting keys, simply type `<CTRL>+C` (`^C`) or, if running in the background, send SIGINT to the process. Keys counted will be saved to the output file before exiting.

## Uninstallation

From the command line use
```bash
keycounter --uninstall
```

Alternatively, `sudo julia` and then
```julia-repl
using KeyCounter
uninstall()
```
Then enter the package prompt using `]` and use `remove KeyCounter` to remove this package.

## Credits & License

Copyright 2023 Harry Ray. Licensed under GPLv3.

Keymaps originally from [`logkeys`](https://github.com/kernc/logkeys), used under GPLv3.
