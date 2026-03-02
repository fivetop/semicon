from time import sleep
from pynq.overlays.base import BaseOverlay

base = BaseOverlay("base.bit")

print("Start!")

while (base.buttons[3].read()==0):
    if (base.buttons[1].read()==1):
        for led in base.leds:
            led.off()
            sleep(0.5)
        for led in base.leds:
            led.toggle()
            sleep(0.5)
            
    elif (base.buttons[2].read()==1):
        for led in reversed(base.leds):
            led.off()
            sleep(0.5)
        for led in reversed(base.leds):
            led.toggle()
            sleep(0.5)                  
    
print('End of this demo ...')
for led in base.leds:
    led.off()
