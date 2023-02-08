#!/bin/bash
#

RSS_URL="https://feeds.macrumors.com/MacRumors-All"
INTERVAL="5m"

function read_rss {
  say=$( curl --silent "$RSS_URL" | \
  grep -E '(title>|description>)' | \
  tail -n +4 | \
  sed -e 's/^[ \t]*//' | \
  sed -e 's/<title>//' -e 's/<\/title>//' -e 's/<description>/  /' -e 's/<\/description>//' | head -n 1 | sed -e 's/.*CDATA\[//g' -e 's/<br\/>//g' | tr -dc '[[:print:]]\n' )
  say=$( echo -e "<n><b><u>+++ Macrumors Breaking News +++</u></b><br>""$say""</n>" )
}

while true
do
  now="$(curl "$RSS_URL" 2> /dev/null | grep pubDate | head -1)"
  
  if [ -f rss.brain ]; then
    check=$( cat rss.brain | grep -v grep | grep "$now" )
  fi
  
  if  [ "$check" != "" ]; then
    echo "War schon"
  else
      read_rss
      screen -S wirebot -p0 -X stuff "$say"^M
      echo "$now" >> rss.brain
  fi

  sleep "$INTERVAL"
done
