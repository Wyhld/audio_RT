# Categorization Task with Reaction Times

## Project Overview
This project is designed as a course task to teach students how to create and analyze experiments using PsychoPy. The task involves measuring reaction times during categorization tasks, with an additional focus on the impact of noise interference. The project also includes a web-based implementation for online data collection.

## Objectives
1. **Primary Objective**: Measure reaction times during categorization tasks and analyze the effect of noise interference.
2. **Optional Goal**: Provide a web-based implementation using JavaScript to enable online data collection via Pavlovia.
3. **Educational Goal**: Teach students how to design, implement, and analyze psychological experiments.

## Project Structure
- **`analysis_script/`**: Contains scripts for cleaning and analyzing the collected data.
  - `cleaning.R`: R script for preprocessing and analyzing the data.
- **`data/`**: Directory for storing collected data from the experiments.
  - Example files: `test 1_Categorization_Task_2025-06-16_18_37_26.csv`, etc.
- **`task_scripts/`**: Contains the main task implementation and resources.
  - `task.py`: PsychoPy implementation of the categorization task.
  - `task.js`: JavaScript implementation for the web-based version.
  - `index.html`: HTML file for running the web-based experiment.
  - `white_noise.wav`: Audio file used for noise interference.
- **`audio_RT.Rproj`**: R project file for organizing the analysis workflow.
- **`README.md`**: Documentation for the project.

## How to Run
### PsychoPy Version
1. Install PsychoPy using `pip install psychopy`.
2. Run `task.py` using Python.
3. Data will be saved in the `data/` directory.

### Web-Based Version
1. Open `index.html` in a browser.
2. Ensure `task.js` is loaded correctly.
3. Data will be collected online via Pavlovia.

## Dependencies
### PsychoPy Version
- Python
- PsychoPy
- NumPy
- SciPy

### Web-Based Version
- PsychoJS
- Browser with JavaScript support

## Future Work
- Enhance the web-based version to include noise generation.
- Optimize timing precision in the browser.
- Add participant information dialog for the web-based version.

## Educational Context
This project is part of a course on experimental psychology and programming. It provides students with practical experience in:
- Designing experiments using PsychoPy.
- Implementing tasks in Python and JavaScript.
- Analyzing experimental data using R.

## Contact
For questions or collaboration, please contact [Your Name] at [Your Email].
