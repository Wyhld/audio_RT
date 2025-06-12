// PsychoJS Categorization Task
// JavaScript implementation for Pavlovia

// === GLOBAL SETUP ===
// Wait for PsychoJS to load
window.onload = function() {
  // Correct initialization of PsychoJS
  const { PsychoJS } = core;
  const psychojs = new PsychoJS({ debug: true });

  // Clocks & window
  let win, globalClock, trialClock;

  // Stimuli
  let instructions, feedback, square, circle, fixation, noise;
  let trainingData = [], testingData = [];

  // Access PsychoJS components from the global scope
  const { TrialHandler, MultiStairHandler } = psychojs.data;
  const { Scheduler } = psychoJS.util;
  const { Window, TextStim, Rect, Circle } = psychoJS.visual;
  const { Sound } = psychoJS.sound;
  const { Clock } = psychoJS.util;
  const { Color } = psychoJS.util;

  // Some handy aliases as in the psychopy scripts
  const { abs, sin, cos, PI: pi, sqrt } = Math;

  // === EXPERIMENT LOGIC ===
  async function initExperiment() {
    // Create window
    win = new Window({
      fullscr: true,
      color: new Color('black'),
      units: 'height'
    });
    globalClock = new Clock();
    trialClock = new Clock();

    // Prepare stimuli
    instructions = new TextStim({
      win,
      text:
        "Categorization Task\n\n" +
        "Press 'Z' for square, 'M' for circle.\n" +
        "Be quick and accurate.\n\n" +
        "Press SPACE to begin.",
      height: 0.05,
      color: new Color('white')
    });
    
    feedback = new TextStim({
      win,
      text: '',
      height: 0.05,
      color: new Color('white')
    });
    
    square = new Rect({
      win,
      width: 0.2,
      height: 0.2,
      fillColor: new Color('white')
    });
    
    circle = new Circle({
      win,
      radius: 0.1,
      fillColor: new Color('white')
    });
    
    fixation = new TextStim({
      win,
      text: '+',
      height: 0.1,
      color: new Color('white')
    });
    
    noise = new Sound({
      win,
      value: 'white_noise.wav',
      secs: 0.5
    });
    // Run phases
    await showInstructions();
    await runTraining();
    await showTestingInstructions();
    await runTesting();
  }

  async function showInstructions() {
    instructions.draw();
    await win.flip();
    await psychojs.eventManager.getKeys({ keyList: ['space'] });
  }

  async function runTrial(isSquare, withNoise = false) {
    psychojs.eventManager.clearEvents();
    fixation.draw();
    await win.flip();
    await psychoJS.util.wait(0.5);

    if (withNoise) noise.play();
    (isSquare ? square : circle).draw();
    await win.flip();

    trialClock.reset();
    const keys = await psychojs.eventManager.getKeys({
      maxWait: 2.0,
      keyList: ['z', 'm', 'escape'],
      timeStamped: trialClock
    });

    let correct = false, rt = null;
    if (keys && keys.length) {
      const key = keys[0].key;
      rt = keys[0].rt;
      if (key === 'escape') psychojs.quit();
      correct = (isSquare && key === 'z') || (!isSquare && key === 'm');
    }

    feedback.text = correct ? 'Correct!' : 'Incorrect!';
    feedback.color = correct
      ? new Color('green')
      : new Color('red');
    feedback.draw();
    await win.flip();
    await psychoJS.util.wait(1.0);    return { correct, rt };
  }

  async function runBlock(nTrials, phase) {
    let correctCount = 0, data = [];
    for (let i = 0; i < nTrials; i++) {
      const isSquare = Math.random() < 0.5;
      const withNoise = phase === 'testing' && Math.random() < 0.5;
      const result = await runTrial(isSquare, withNoise);
      if (result.correct) correctCount++;
      data.push({
        phase,
        stimulus: isSquare ? 'square' : 'circle',
        correct: result.correct,
        rt: result.rt,
        withNoise
      });
    }
    return { accuracy: correctCount / nTrials, data };
  }

  async function runTraining() {
    let acc;
    do {
      const { accuracy, data } = await runBlock(10, 'training');
      acc = accuracy;
      trainingData = trainingData.concat(data);
      if (acc < 0.7) {
        feedback.text = 'Training failed. Try again.';
        feedback.color = new Color('red');
        feedback.draw();
        await win.flip();
        await psychoJS.util.wait(2.0);
      }
    } while (acc < 0.7);
  }

  async function showTestingInstructions() {
    const testInstr = new TextStim({
      win,
      text:
        "Great job! Now the same task but with noise sometimes.\n\n" +
        "Press SPACE to continue.",
      height: 0.05,
      color: new Color('white')
    });
    testInstr.draw();
    await win.flip();
    await psychojs.eventManager.getKeys({ keyList: ['space'] });
  }

  async function runTesting() {
    const { data } = await runBlock(80, 'testing');
    testingData = testingData.concat(data);
  }

  // === SCHEDULE EVERYTHING ===
  psychojs.schedule(initExperiment);

  // Final thank-you + save + quit
  psychojs.schedule(async () => {
    feedback.text = 'Experiment completed. Thank you!';
    feedback.color = new Color('white');
    feedback.draw();
    await win.flip();
    await psychojs.eventManager.getKeys({ keyList: ['space'] });
  });

  psychojs.schedule(async () => {
    psychojs.experiment.save({
      fileName: `${psychojs.experiment.expInfo['participant']}_data`
    });
  });

  psychojs.schedule(() => psychojs.quit());

  // === START THE EXPERIMENT ===
  psychojs.start({
    expName: 'Categorization_Task',
    expInfo: { participant: '', session: '001' },
    resources: [
      { name: 'white_noise.wav', path: 'white_noise.wav' }
    ]
  });
};
