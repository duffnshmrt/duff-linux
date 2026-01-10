#!/usr/bin/sh
curl https://wttr.in/?format="%t+(%l)+%C" | awk '{ print }'
