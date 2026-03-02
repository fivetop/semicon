from time import sleep
from pynq.overlays.base import BaseOverlay

base = BaseOverlay("base.bit")

color = 0

while (base.buttons[3].read()==0):
	if (base.buttons[0].read()==1):
		color = (color+1) % 8
		base.rgbleds[4].write(color)
