# PsychoPy Categorization Task
# -----------------------------------------
from psychopy import visual, core, data, event, gui, sound
import os
import random
from datetime import datetime
import numpy as np  # For noise generation
from scipy.io.wavfile import write  # For saving white noise

# Set the speaker to the main speaker selected for the device
from psychopy.sound import backend_sounddevice
backend_sounddevice.defaultOutputDevice = 'default'  # Use the default output device

# ============================
# 1. EXPERIMENT SETTINGS
# ============================
exp_name = 'Categorization_Task'
exp_info = {
    'participant': '',
    'session': '001',
}

dlg = gui.DlgFromDict(dictionary=exp_info, title=exp_name)
if not dlg.OK:
    core.quit()

# Replace invalid characters in the filename for Windows compatibility
exp_info['date'] = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")

# Create a valid filename
filename = os.path.join('data', f"{exp_info['participant']}_{exp_name}_{exp_info['date']}")

# ============================
# 2. WINDOW SETUP
# ============================
win = visual.Window(
    size=(1024, 768),
    fullscr=True,
    color=[0, 0, 0],
    units='height'
)

# ============================
# 3. STIMULI
# ============================
# Instructions
instructions = visual.TextStim(
    win=win,
    text="Categorization Task\n\n"
         "In this task, you will see a square or a circle.\n"
         "Press 'Z' for a square and 'M' for a circle.\n"
         "Respond as quickly and accurately as possible.\n\n"
         "Press SPACE to begin.",
    height=0.05,
    color='white'
)

# Feedback text
feedback = visual.TextStim(
    win=win,
    text='',
    height=0.05,
    color='white'
)

# Stimuli
square = visual.Rect(win, width=0.2, height=0.2, fillColor='white', lineColor='white')
circle = visual.Circle(win, radius=0.1, fillColor='white', lineColor='white')

# === Generate white noise and save as WAV ===
white_noise_array = np.random.uniform(-1, 1, int(44100 * 0.5))  # 0.5 seconds
white_noise_pcm = (white_noise_array * 32767).astype(np.int16)  # Convert to 16-bit PCM
noise_path = "white_noise.wav"
write(noise_path, 44100, white_noise_pcm)

# === Load the white noise using PsychoPy's sound module ===
try:
    noise = sound.Sound(noise_path)
except Exception as e:
    print(f"WARNING: Failed to load white noise sound: {e}")
    noise = None

# Fixation cross
fixation = visual.TextStim(win, text='+', height=0.1, color='white')

# ============================
# 4. FUNCTIONS
# ============================
def run_trial(stimulus, correct_key, with_noise=False):
    """Run a single trial."""
    event.clearEvents()

    fixation.draw()
    win.flip()
    core.wait(0.5)

    if with_noise and noise is not None:
        noise.play()
    stimulus.draw()
    win.flip()

    clock = core.Clock()
    keys = event.waitKeys(maxWait=2.0, keyList=['z', 'm', 'escape'], timeStamped=clock)

    if keys and keys[0] is not None:
        key, rt = keys[0]
        if key == 'escape':
            core.quit()
        correct = (key == correct_key)
    else:
        key, rt, correct = None, None, False

    if correct:
        feedback.text = 'Correct!'
        feedback.color = 'green'
    else:
        feedback.text = 'Incorrect!'
        feedback.color = 'red'
    feedback.draw()
    win.flip()
    core.wait(1.0)

    return correct, rt

def run_block(n_trials, phase='training'):
    correct_responses = 0
    trials = []

    for _ in range(n_trials):
        if random.random() < 0.5:
            stimulus, correct_key = square, 'z'
        else:
            stimulus, correct_key = circle, 'm'

        with_noise = (phase == 'testing' and random.random() < 0.5)

        correct, rt = run_trial(stimulus, correct_key, with_noise)
        if correct:
            correct_responses += 1

        trials.append({
            'stimulus': 'square' if stimulus == square else 'circle',
            'correct_key': correct_key,
            'response': correct,
            'reaction_time': rt,
            'with_noise': with_noise
        })

    return correct_responses / n_trials, trials

# ============================
# 5. EXPERIMENT FLOW
# ============================
instructions.draw()
win.flip()
event.waitKeys(keyList=['space'])

training_accuracy, training_data = run_block(10, phase='training')
while training_accuracy < 0.7:
    feedback.text = "Training failed. You did not reach the required accuracy.\nPlease try again."
    feedback.color = 'red'
    feedback.draw()
    win.flip()
    core.wait(3.0)
    training_accuracy, training_data = run_block(10, phase='training')

# ============================
# 6. VOLUME ADJUSTMENT SCREEN
# ============================
# Volume adjustment screen after training phase and before testing phase
volume_slider = visual.Slider(
    win=win,
    ticks=(0, 0.25, 0.5, 0.75, 1.0),
    labels=['0%', '25%', '50%', '75%', '100%'],
    granularity=0.01,
    style='rating',
    size=(1.0, 0.1),
    pos=(0, -0.2),
    color='white'
)

volume_text = visual.TextStim(
    win=win,
    text="Adjust the noise volume using the slider below.\nPress 'P' to play the noise and SPACE to confirm.",
    height=0.05,
    color='white',
    pos=(0, 0.2)
)

# Show the volume adjustment screen
while True:
    volume_text.draw()
    volume_slider.draw()
    win.flip()

    keys = event.getKeys(keyList=['p', 'space'])
    if 'p' in keys and noise is not None:
        noise_volume = volume_slider.getRating()
        if noise_volume is not None:
            noise.setVolume(noise_volume)
        noise.play()
    if 'space' in keys:
        noise_volume = volume_slider.getRating()
        if noise_volume is not None:
            break

# Set the final noise volume
if noise is not None:
    noise.setVolume(noise_volume)

testing_instructions = visual.TextStim(
    win=win,
    text="Great job!\n\nNow you will do the same task, but sometimes there will be noise.\n\n"
         "Press SPACE to continue.",
    height=0.05,
    color='white'
)
testing_instructions.draw()
win.flip()
event.waitKeys(keyList=['space'])

testing_accuracy, testing_data = run_block(80, phase='testing')

# ============================
# 7. SAVE DATA
# ============================
# Save data
with open(f"{filename}.csv", 'w') as f:
    f.write('phase,stimulus,correct_key,response,reaction_time,with_noise\n')
    for trial in training_data:
        f.write(f"training,{trial['stimulus']},{trial['correct_key']},{trial['response']},{trial['reaction_time']},{trial['with_noise']}\n")
    for trial in testing_data:
        f.write(f"testing,{trial['stimulus']},{trial['correct_key']},{trial['response']},{trial['reaction_time']},{trial['with_noise']}\n")

feedback.text = "Experiment completed. Thank you!"
feedback.color = 'white'
feedback.draw()
win.flip()
event.waitKeys()

win.close()
core.quit()
