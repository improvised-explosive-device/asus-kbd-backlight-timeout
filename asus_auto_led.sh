#!/bin/bash

# ASUS lcd/keyboard backlight auto brightness battery thing
# keyboard backlight timeout in ms
timeout_bat=5000
timeout_ac=10000

# stuff
lcd_value=/sys/class/backlight/amdgpu_bl0/brightness # where the lcd panel backlight brightness value is stored
kbd_value=/sys/class/leds/asus::kbd_backlight/brightness # where the keyboard backlight brightness value is stored
ac_status="cat /sys/class/power_supply/AC0/online" # ac-adapter on/off status
bat_status="cat /sys/class/power_supply/BAT0/status" # battery charge/discharge status
bat_level="cat /sys/class/power_supply/BAT0/capacity" # battery charge percentage
bat_level_max="cat /sys/class/power_supply/BAT0/charge_control_end_threshold" # battery max charge percentage
lcd_status="cat /sys/class/backlight/amdgpu_bl0/brightness" # lcd backlight level
lcd_status_max="cat /sys/class/backlight/amdgpu_bl0/max_brightness" # lcd backlight max level
kbd_status="cat /sys/class/leds/asus::kbd_backlight/brightness" # keyboard backlight level
kbd_status_max="cat /sys/class/leds/asus::kbd_backlight/max_brightness" # keyboard backlight max level
stapm_bat="sudo ryzenadj --stapm-limit=10000"
stapm_ac="sudo ryzenadj --stapm-limit=25000"
lcd_value_saved=$(cat $lcd_value)
kbd_value_saved=$(cat $kbd_value)
lcd_dim=false
kbd_dim=false
timeout=$timeout_bat

# la script
while true; do
  if [ $($ac_status) = 1 ] && [ $lcd_dim = true ]; then
    lcd_value_saved=$(cat $lcd_value) # save lcd brightness
    timeout=$timeout_ac
    lcd_dim=false; kbd_dim=false
    stapm2=$($stapm_ac | sed 1d); $stapm_ac
    echo 255 | tee $lcd_value
    echo 3 | tee $kbd_value
    notify-send "$($bat_status) ($($bat_level)/$($bat_level_max)%)" "lcd-led: $($lcd_status)/$($lcd_status_max)\nkbd-led: $($kbd_status)/$($kbd_status_max)\nkbd-timeout: $(($timeout / 1000))s\nAC: $($ac_status)\n$stapm2" -u normal -t 10000
  elif [ $($ac_status) != 1 ] && [ $lcd_dim = false ]; then
    timeout=$timeout_bat
    lcd_dim=true; kbd_dim=false #reset keyboard led to avoid it getting stuck on
    stapm2=$($stapm_bat | sed 1d); $stapm_bat
    echo $lcd_value_saved | tee $lcd_value
    echo $kbd_value_saved | tee $kbd_value
    notify-send "$($bat_status) ($($bat_level)/$($bat_level_max)%)" "lcd-led: $($lcd_status)/$($lcd_status_max)\nkbd-led: $($kbd_status)/$($kbd_status_max)\nkbd-timeout: $(($timeout / 1000))s\nAC: $($ac_status)\n$stapm2" -u normal -t 10000
  elif [ $(xprintidle) -gt $timeout ] && [ $kbd_dim = false ]; then
    if [ $timeout = $timeout_bat ]; then # dont save backlight state if ac plugged in
      kbd_value_saved=$(cat $kbd_value); fi 
    kbd_dim=true
    echo 0 | tee $kbd_value
  elif [ $(xprintidle) -le $timeout ] && [ $kbd_dim = true ]; then
    kbd_dim=false
    echo $kbd_value_saved | tee $kbd_value
  fi
  sleep 1
done