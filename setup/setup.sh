#!/usr/bin/env bash
set -e

function led_turnon () {
    gpio -g mode 21 out
    gpio -g write 21 1
    sleep $1
    gpio -g write 21 0
}

function led_blynk () {
    for i in {1..10};do $(led_turnon $1; sleep $1);done;
    echo setup failed.
}

# when an error occurs, blynk a led 10 times
trap 'led_blynk 0.2' ERR

echo 'Setup start.'

DEBIAN_FRONTEND=noninteractive sudo apt-get update
DEBIAN_FRONTEND=noninteractive sudo -E apt-get -y upgrade

# when a setup complete successfully, a LED is turned on for 5 seconds.
led_turnon 5

echo 'Setup completed.'
exit 0

