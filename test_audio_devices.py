"""
Test script to enumerate and play a test tone on each available audio output device
using PsychoPy's sounddevice backend.
"""
import sounddevice as sd
from psychopy import prefs
import numpy as np
from psychopy import core  # for timing only

# Use the sounddevice backend in PsychoPy
prefs.hardware['audioLib'] = ['sounddevice']

# List all devices with output capability
print("Available audio output devices:")
output_devices = []
for idx, dev in enumerate(sd.query_devices()):
    if dev['max_output_channels'] > 0:
        output_devices.append((idx, dev['name']))
        print(f"{idx}: {dev['name']}")

choice = input("Enter device index to test (or 'all' to cycle through all): ")

# generate a 440Hz sine wave for 1 second at 44.1kHz
fs = 44100
duration = 1.0
frequency = 440
test_tone = np.sin(2 * np.pi * frequency * np.arange(int(fs * duration)) / fs) * 0.8

if choice.strip().lower() == 'all':
    for idx, name in output_devices:
        print(f"\n-- Testing device {idx}: {name} --")
        sd.play(test_tone, fs, device=idx)
        core.wait(duration + 0.2)
else:
    try:
        idx = int(choice)
        matching = [d for d in output_devices if d[0] == idx]
        if not matching:
            raise ValueError
        name = matching[0][1]
        print(f"Testing device {idx}: {name}")
        sd.play(test_tone, fs, device=idx)
        core.wait(duration + 0.2)
    except ValueError:
        print("Invalid choice. Exiting.")

print("Done.")
