from time import sleep
from pynq.overlays.base import BaseOverlay

base = BaseOverlay("base.bit")

for led in base.leds:
	led.on()  
sleep(4)
for led in base.leds:
	led.off()
