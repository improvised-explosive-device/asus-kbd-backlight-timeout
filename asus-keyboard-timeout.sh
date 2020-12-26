#!/bin/bash

# super simple ASUS keyboard led auto timeout script
timeout_bat=5000 # timeout in ms, battery
timeout_ac=10000 # AC power

# get values
kb="/sys/class/leds/asus::kbd_backlight/brightness"
kb_status="cat $kb" # keyboard led state 
ac_status="cat /sys/class/power_supply/AC0/online" # ac-adapter state
if [ $($kb_status) == 0 ];then dim=true;else dim=false; fi
if [ $($ac_status) == 1 ];then ac=true;timeout=$timeout_ac; else ac=false;timeout=$timeout_bat; fi

osd(){
  printf -- '\rled: '"$($kb_status)"' timeout: '"$timeout"' ms AC:'"$($ac_status)"' '
}

osd

# poll
while true; do
  event=0
  if [ $($ac_status) == 1 ] && [ $ac = false ]; then
    timeout=$timeout_ac
    ac=true
    event=1
  elif [ $($ac_status) != 1 ] && [ $ac = true ]; then
    timeout=$timeout_bat
    ac=false
    event=1
  fi

  if [ $(xprintidle) -gt $timeout ] && [ $dim = false ]; then
    kb_status_saved=$($kb_status) # store backlight brightness value
    dim=true
    echo 0 | tee $kb > /dev/null
    event=1
  elif [ $(xprintidle) -le $timeout ] && [ $dim = true ]; then
    dim=false
    echo $kb_status_saved | tee $kb > /dev/null
    event=1
  fi

  if [ $event -gt 0 ]; then
    osd
  fi

  sleep 1
done
