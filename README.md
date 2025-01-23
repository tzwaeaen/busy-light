
# busy-light

My journey to building a busy light with a Raspberry Pi.

[Full guide in my blog](https://blog.tzwaeaen.de)


## Summary

I set out to build a presence indicator for the office, all while navigating the challenges of a pretty restrictive IT environment. The presence detection relies on Teams log files (yes, it works with the new Teams) and a PowerShell script handles the extraction. The Raspberry Pi is connected via USB, which provides power and exposes the Pi as a drive. The PowerShell script updates the status file on this drive, while a Python script running on the Pi monitors the file for changes and adjusts the LED colors accordingly.


![](https://blog.tzwaeaen.de/content/images/size/w2400/2025/01/IMG_5200.jpeg)
## Inspiration

 - [DIY: Building a busy light to show your Microsoft Teams presence](https://www.eliostruyf.com/diy-building-busy-light-show-microsoft-teams-presence/)
 - [Simple server for Raspberry Pi with Pimoroni Unicorn hat](https://github.com/estruyf/unicorn-busy-server/)
 - [PiUSB – How to Make a Wifi Memory Stick Using Pi Zero W](https://www.makerhacks.com/piusb-wifi-memory-stick/)


## Hardware

- Raspberry Pi Zero WH
- Waveshare Full True Color RGB LED HAT

## Software

- DietPi
- [Unicorn Busy Server](https://github.com/estruyf/unicorn-busy-server/)

## Case

[Model on Printables](https://www.printables.com/model/1160385-busy-light-raspberry-pi-zero)

- 4x M3 Ruthex inserts
- 4x M3x16 screws
- 8x 6x2mm magnets
