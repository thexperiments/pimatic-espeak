pimatic-espeak
=======================

A plugin for using espeak tts in pimatic.
Requires espeak and aplay installed and configured on your machine:


Configuration
-------------
You can load the backend by editing your `config.json` to include:

    {
      "plugin": "espeak"
    }

in the `plugins` section. For all configuration options see 
[play-config-schema](play-config-schema.coffee)

Currently you can use tts via action handler within rules.

Example:
--------

    if it is 08:00 say "Good morning Dave"

in general: if X then say "blah"