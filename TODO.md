Pre 1.0
=======

* install within Julia works
* commandline operation works
* uninstall within Julia works
* commandline uninstall works
* run as separate process works
* update readme

Post 1.0
========

* check it works as stand-alone process
* keymaps
    - translate from codes to keys
* installation script / instructions
    - improve README
* backup log upon opening
* change to `keycounter cmd [options]` style usage
    - `start`
    - `install`
        - allow unattended and/or quiet installation
        - guided configuration during install including interactive eventN detection
    - `uninstall`
    - `translate`
        - convert summary to key names (.md format?)
    - `config`
* implement configuration file
    - auto config and allow during installation