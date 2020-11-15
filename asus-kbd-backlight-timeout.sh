#!/bin/bash
idle=false
idleAfter=10000 #edit this x with the timeout in milliseconds
savedState=0
while true; do
  idleTimeMillis=$(sudo -u dog env DISPLAY=:0.0 xprintidle)
  if [[ $idle = false && $idleTimeMillis -gt $idleAfter ]] ; then
 savedState=$(cat /sys/devices/platform/asus-nb-wmi/leds/asus::kbd_backlight/brightness)
 sudo asus-kbd-backlight 0 #/bin/sh -c "echo 0 >> /sys/devices/platform/asus-nb-wmi/leds/asus::kbd_backlight/brightness"
 idle=true
 echo "Keyboard dimmed."
  fi
  if [[ $idle = true && $idleTimeMillis -lt $idleAfter ]] ; then
 sudo asus-kbd-backlight $savedState #/bin/sh -c "echo $savedState >> /sys/devices/platform/asus-nb-wmi/leds/asus::kbd_backlight/brightness"
 idle=false
 echo "Keyboard brightened."
  fi
  sleep 0.1
done
