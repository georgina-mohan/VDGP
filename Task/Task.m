%% -------- TASK SCRIPT --------
% Georgina Mohan 
% 18/09/2025
% SPIN Lab 
% Main experimental script for contrast and colour discomfort task
% 28/10/2025 update: fixed eyelink calibration (row 413)
% 20/11/2025 update: commented out photodiode code as using stim tracker(if wanting photodiode code, must add back in "pd" as input and outputs for runColourBlock & runContrastBlock

% TO DO:
% - add code to re-start next section if script aborts
% - if eyelink fails: keep running
% - check GetSecs?

% applyGammaCorrection_APL(0, Gamma.gammaTable, 0);
% delete(instrfindall)

%% --- ORGANISE WORKSPACE ---
% -- CLEAN WORKSPACE --
clear all; 
close; % clear workspace
sca; % clear screen

Screen('Preference', 'ConserveVRAM', 4096);
vtotal = 1157; % NVIDIA control panel > change resolution > customise > create custom resolution > vertical total pixels 
Screen('Preference', 'VBLEndlineOverride', vtotal); % VBL fix for custom resolution

% -- EXPERIMENT MODE --
% 0 = ratings only
% 1 = EEG only
% 2 = eyetracking only
% 3 = full set-up (EEG + eyetracking)
% 4 = troubleshooting - small screen + ratings only
inLab = 0;

% -- SET PATH -- 
E.exptpath = 'C:\Users\gxm449\Documents\Data\VDGP'; % default path
pwd = 'C:\Users\gxm449\Documents\Data\VDGP'; % set directory
addpath 'C:\Users\gxm449\Documents\VDGP\Task'
addpath 'C:\Users\gxm449\Documents\PsyCalibrator-main\PsyCalibrator'

% -- PARTICIPANT ID --
E.IDstr = input('\nSubject ID? ', 's'); % participant ID - string (for saving data)
E.ID = str2double(E.IDstr); % convert to numeric for counterbalancing blocks
fileName = ['data/' E.IDstr]; % filename for saving 
fprintf('Saving data to %s\n\n', fileName);

isEven = mod(E.ID, 2) == 0; % check if participant ID is even or odd (to counterbalance blocks and set grey background)

%% --- INITIALISE ---
rng('shuffle'); % initialise random number generator (random order for stimuli)
KbName('UnifyKeyNames') % standardise key naming

% -- DEFINE KEYS --
keys.esc = KbName('ESCAPE'); % quit task
keys.pause = KbName('p'); % pause task
keys.resume = KbName('r'); % resume task
keys.space = KbName('space'); % continue
keys.calibrate = KbName('E'); % trigger eyetracking calibration

%% --- PHOTODIODE ---
% pd.fs = 44100; % sampling frequency for photodiode recording
% pd.deviceID = 1; % audio device ID (check with 'audiodevinfo')

%% --- DISPLAY PARAMETERS ---
AssertOpenGL;

display.dist = 60; % distance in screen in cm
display.width = 54.2; % physical screen width in cm
display.screenNum = max(Screen('Screens'));
display.tmp=Screen('Resolution', display.screenNum); % check - CM's had "0"

% -- SYNC & PERFORMANCE SETTINGS --
Screen('Preference', 'SkipSyncTests', 0); % set depending on precision needed (0 = default, most rigorous; 1 = skips some tests but faster setup; 2 = disables all synchronisation tests. Least accurate timing)
Screen('Preference', 'Verbosity', 5); % max level of detail/info 
Screen('Preference', 'VBLTimestampingMode', 2); % more precise VBL timestamping
Priority(MaxPriority(display.screenNum)); % priority for performance

settings.flags.debug= false; % false for real one
%temppp hack to only display half the screenppr
if settings.flags.debug
    display.tmp.height = display.tmp.height/2;
end

% -- DISPLAY INFO --
display.rect = [0 0 display.tmp.width display.tmp.height];
display.resolution=[display.tmp.width]; % CM does only width? 
display.frameRate=display.tmp.hz; % may do same as ifi?
display.halfframe = 1/display.tmp.hz/2; % Set so when flip screen, always set time to half a flip before you want it - to ensure it appears on the next flip and doesn't get missed!
display.update = 1; % every frame

xDim = display.tmp.width; % store screen dimensions
yDim = display.tmp.height;

%% --- GAMMA CORRECTION -- 
% cd C:\Users\hannonsc-admin\Documents\Georgina\PsyCalibrator-main\PsyCalibrator
load('Gamma_fitted.mat') % must use Gamma_fitted.mat NOT Gamma.m
applyGammaCorrection_APL(1, Gamma.gammaTable, 0); % apply gamma correction

%% --- CONTRAST SENSITIVITY TEST ---
% display.CSFdist = display.dist*10; % save distance in mm (CSF expects mm)
% 
% % -- TASK PARAMETERS --
% trialsPerBlock = 25;
% blockCount = 4;
% gaborSize = 7; % must be integer
% interStimulusInterval = 1;
% orientation = 90;
% 
% % -- OUTPUT FILE --
% csfSubfolder = fullfile(E.exptpath, 'CSF');
% if ~exist(csfSubfolder, 'dir') % make sure folder exists
%     mkdir(csfSubfolder);
% end
% outputFile = fullfile(csfSubfolder, 'QuickCSF-results.csv'); % add filename to folder path
% 
% % -- PYTHON COMMAND --
% % cmd = 'python -m QuickCSF.app --help';
% % system([py37 ' -m QuickCSF.app --help'])
% py37 = '"C:\Users\gxm449\AppData\Local\Programs\Python\Python37\python.exe"';
% cmd = sprintf('%s -m QuickCSF.app --sessionID %s --distance_mm %.1f --interStimulusInterval %.1f --trialsPerBlock %d --blockCount %d --size %d --orientation %d --outputFile "%s"', ...
%     py37, E.IDstr, display.CSFdist, interStimulusInterval, trialsPerBlock, blockCount, gaborSize, orientation, outputFile);
% 
% % cmd = sprintf('python -m QuickCSF.app --sessionID %s --distance_mm %.1f --interStimulusInterval %.1f --trialsPerBlock %d --blockCount %d --size %d --orientation %d --outputFile "%s"', ...
% %     E.IDstr, display.CSFdist, interStimulusInterval, trialsPerBlock, blockCount, gaborSize, orientation, outputFile);
% 
% status = system(cmd);  % Or: dos(cmd);

%% --- STIMULUS PARAMETERS ---
ST.duration = 5;   % trial duration (s)
ST.ITI = 1;         % inter-trial interval (ITI), (s) - always leave a few seconds between trials
ST.TF1 = 7.2; % target temporal frequency (Hz) - might be worth us setting this in multiples of the ifi
ST.aperture_deg = 7.5; % size of stimulus aperture in degrees
ST.aperture_pix = angle2pix(display, ST.aperture_deg); % size of stimulus aperture in pixels
ST.npixelsperdegree = ST.aperture_pix/ST.aperture_deg;

white = WhiteIndex(display.screenNum);
greyBW = 128; % keep as grey = 128 and put into matrix afterwards (in blocks)
greyCol = 35;
black = BlackIndex(display.screenNum);

% -- OPEN WINDOW --
if inLab == 4
    rect = [0 0 ST.aperture_pix ST.aperture_pix]; % small screen for debugging
else
    rect = []; % full size screen
end

[window, windowRect] = Screen('OpenWindow',display.screenNum,greyBW,rect);
[xCenter, yCenter] = RectCenter(windowRect); % get center coordinates
Screen('TextSize', window, 50); % set text size

% Query the frame duration
[width, height] = Screen('WindowSize', window);
ifi=Screen('GetFlipInterval', window); % ifi is frame duration in seconds
% if ifi<0.01         % if using the viewpixx, double the ifi because at 120Hz and the computer drops frames at this speed
%     ifi = ifi*2;
% end

%% --- SET UP FRAME TIMINGS ---%%
% fixTimeFrames = round(ST.ITI/ifi); % find time equivalent in frames
presTimeFrames = round(ST.duration/ifi); % find time equivalent in frames
flickerTimeSecs = (1 / ST.TF1) / 2; % ST.TF1 is target temporal frequency for a whole cycle - converting to seconds. Then halving duration for a half-cycle (i.e., 15 Hz)
%flickerTimeSecs = (1 / ST.TF) / 2;
flickerTimeFrames = round(flickerTimeSecs/ifi); % ifi is frame duration in seconds, so here getting how many frames each flip (each half-cycle) should be on for?
nflips = round(presTimeFrames/flickerTimeFrames); % How many flips there will be in the whole stimulus
ncycles = nflips/2; % 36 cycles of the stimulus

% -- SCREEN FLIP --
if isEven
    backgroundGrey = greyBW;
else
    backgroundGrey = greyCol;
end

Screen('FillRect', window, backgroundGrey);
lastflip = Screen('Flip', window);
trialoffset = lastflip; % last trial was an infinitely long time ago

%% --- CONTRAST STIMULI ---
% -- LOAD TEXTURES --
[textureHandles, angle, gratingwidth_pix, radius, sf_cpp, phase, contrast, sigma, imgMatrix, soothtex, tVals, masktex, dRectM] = ContrastStimuli(window, xDim, yDim, display);
phase_cycle = [zeros(flickerTimeFrames,1); repmat( 180, flickerTimeFrames,1)]; % phase cycle: alternate between 0 and 180
phase_cycle_expanded = repmat(phase_cycle, ceil(presTimeFrames/length(phase_cycle)),1);

[X,Y] = meshgrid(sf_cpp,contrast);
allValues = [X(:) Y(:)]; % X and Y get overridden with colour stimuli below, but when running alone, no issues

% Specify EEG markers for each condition
% allValues(:,3) = [10, 20, 30, 11, 21, 31, 12, 22, 32, 14, 24, 34, 18, 28, 38];

% 
allValues(:, 3) = [10; 11; 12; 14; 18; 20; 21; 22; 24; 28; 30; 31; 32; 34; 38];
% First digit = SF (1 = LF, 2 = MF, 3 = HF)
% Second digit = contrast:
% 0 (0.05)
% 1 (0.1)
% 2 (0.2)
% 4 (0.4)
% 8 (0.8)

% --- TRIAL STRUCTURE ---
E.nconds = 5; % contrasts (0.05, 0.1, 0.2, 0.4, 0.8)
E.nlevels = 3; % spatial frequencies
E.nrepetitions = 1;
E.ntrialsperblock = 30; % how many trials in each block
E.nstimuli = E.nconds*E.nlevels;
E.ntrials = E.nstimuli*E.nrepetitions;
E.blocks = E.ntrials/E.ntrialsperblock;

% -- RANDOMISE TRIALS --
imtextures = cell(E.ntrials, 2); % creates cell array, with number of trials x 2
imagelist = cell(E.ntrials, 2);
R.trialrand = [];
R.trialIndices = zeros(E.ntrials, 1);
trial = 0;

all_trlorders = zeros(E.nrepetitions, E.nstimuli);

for rep = 1:E.nrepetitions
    % randomise order of stimuli
    trlorder = randperm(E.nstimuli);
    all_trlorders(rep, :) = trlorder;

    shuffled_allValues = allValues(trlorder, :);
    R.trialrand = [R.trialrand; shuffled_allValues];

    for stimulus = 1:E.nstimuli % for each repetition:
        trial = trial + 1; % save "trial" index
        stimIndex = trlorder(stimulus);

        % Assign textures for this trial
        imtextures{trial, 1} = textureHandles{stimIndex,1};  % Phase 1 (e.g. 0°)
        imtextures{trial, 2} = textureHandles{stimIndex,2};  % Phase 2 (e.g. 180°)

        % Save trial conditions
        imagelist{trial, 1} = tVals(stimIndex, :); 
        imagelist{trial, 2} = tVals(stimIndex, :);

        % Save stim index for later reference
        R.trialIndices(trial) = stimIndex;
    end
end

%% --- CREATE FILE ---
fname_contrast = fullfile(E.exptpath, 'Ratings', [E.IDstr '_VDS1_contrast.mat']);

saveattempt = 1;
while exist(fname_contrast, "file") > 0 % checks if file already exists
    fname_contrast = fullfile(E.exptpath, 'Ratings', [E.IDstr '_VDS1_contrast', num2str(saveattempt) '.mat']); % add new number to end of filename?
    saveattempt = saveattempt+1; % loop until no file is found
end
   
R.response = nan(1,E.ntrials); % stores response for each trial
R.allframetimes = cell(1,E.ntrials);
R.subj = E.ID;

%% --- COLOUR STIMULI ---
[textureHandles2, angle2, gratingwidth_pix2, radius2, sf_cpp2, phase2, colourPairs, sigma2, imgMatrix2, soothtex2, tVals2, masktex2, dRectM2, gratingwidth_deg, pixperdeg] = ColourStimuli(window, xDim, yDim, display);
phase_cycle2 = [zeros(flickerTimeFrames,1); repmat( 180, flickerTimeFrames,1)];
phase_cycle_expanded2 = repmat(phase_cycle2, ceil(presTimeFrames/length(phase_cycle2)),1);

nColours = length(colourPairs);
[X,Y] = meshgrid(sf_cpp2,1:nColours);
allValues2 = [X(:) Y(:)];

% -- SPECIFY EEG MARKERS --
% allValues2(:, 3) = [11, 12, 13, 14, 21, 22, 23, 24, 31, 32, 33, 34];
% First digit = SF (1 = LF, 5 = MF, 6 = HF)
allValues2(:, 3) = [41, 42, 43, 44, 51, 52, 53, 54, 61, 62, 63, 64];
% First digit = SF (4 = LF, 5 = MF, 6 = HF)
% Second digit = colour: 
% 1 (BG lowBlue - lowGreen)
% 2 (BG highBlue - highGreen)
% 3 = (RG lowRed - lowGreen)
% 4 = (RG highRed - highGreen)

% --- TRIAL STRUCTURE ---
E.nconds2 = 4; % colour pairs
E.nlevels2 = 3; % spatial frequencies
E.ntrialsperblock2 = 24; % how many trials in each if trial== 30+1 || trial == 60+1 || trial == 90+1 || trial == 120+1 || trial == 150+1block
E.stimuli2 = E.nconds2 * E.nlevels2;
E.nrepetitions2 = 1;
E.ntrials2 = E.stimuli2*E.nrepetitions2;
E.blocks2 = E.ntrials2/E.ntrialsperblock2;

% --- RANDOMISE TRIALS ---
imtextures2 = cell(E.ntrials2, 2);
imagelist2 = cell(E.ntrials2, 2);
R.trialrand2 = [];
R.trialIndices2 = zeros(E.ntrials2, 1);  % pre-allocate for all trials
trial2 = 0;

all_trlorders2 = zeros(E.nrepetitions2, E.stimuli2); % pre-allocate to store all orders if multiple reps

for rep = 1:E.nrepetitions2
    % Generate random permutation ONCE per repetition
    trlorder2 = randperm(E.stimuli2);
    all_trlorders2(rep, :) = trlorder2;  % save for later use

    shuffled_allValues2 = allValues2(trlorder2, :);
    R.trialrand2 = [R.trialrand2; shuffled_allValues2];

    for stimulus2 = 1:E.stimuli2    
        trial2 = trial2 + 1;
        stimIndex = trlorder2(stimulus2);

        % Assign textures for this trial
        imtextures2{trial2, 1} = textureHandles2{stimIndex, 1};  % Phase 1
        imtextures2{trial2, 2} = textureHandles2{stimIndex, 2};  % Phase 2

        % Save trial conditions (labels)
        imagelist2{trial2, 1} = tVals2(stimIndex, :);
        imagelist2{trial2, 2} = tVals2(stimIndex, :);

        % Save stim index for later reference
        R.trialIndices2(trial2) = stimIndex;
    end
end


%% --- CREATE FILE ---
fname_colour = fullfile(E.exptpath, 'Ratings', [E.IDstr '_VDS1_colour.mat']);

saveattempt = 1;
while exist(fname_colour, "file") > 0 % checks if file already exists
    fname_colour = fullfile(E.exptpath, 'Ratings', [E.IDstr '_VDS1_colour', num2str(saveattempt) '.mat']); % add new number to end of filename?
    saveattempt = saveattempt+1; % loop until no file is found
end

R.response2 = nan(1,E.ntrials2); %stores response for each trial
R.allframetimes2 = cell(1,E.ntrials2);
R.subj2 = E.ID;

%% --- EEG PORT SETUP ---
% 1. Find port number:
%    Windows: Device Manager -> Ports (COM & LPT)
%    Mac/Linux: Use "serialportlist" in MATLAB
% 
% Lab computer: COM1, COM2 & COM7
% Personal laptop: COM3 & COM4

% LAB 2: COM3 & COM6 -> current in COM6 (I think???)

% 2. Define correct port number (don't include "COM" part)
% port_nb = 3; 
% 
% % 3. Open the port:
% if inLab == 1 || inLab == 3
%     port_handle = open_ns_port(port_nb);
% else
%     port_handle = [];
% end

% s = serialport("COM6",9600); % alternative way to set serialport
% delete(instrfindall) % manually close serial port when having code issues

%% --- WELCOME MESSAGE ---
if inLab == 2 || inLab == 3
    WelcomeTxt = 'Welcome! \n\n When you are ready, press SPACE to set up the eye tracker';
    DrawFormattedText(window, WelcomeTxt, 'center', 'center', white, 60);
    Screen('Flip', window);
    WaitSecs(0.1); % ** is this needed?
    RestrictKeysForKbCheck(keys.space);
    [secs, keyCode, deltaSecs] = KbStrokeWait;

else 
    WelcomeTxt = 'Welcome! \n\n When you are ready, press SPACE to begin';
    DrawFormattedText(window, WelcomeTxt, 'center', 'center', white, 60);
    Screen('Flip', window);
    WaitSecs(0.1); % ** is this needed?
    RestrictKeysForKbCheck(keys.space);
    [secs, keyCode, deltaSecs] = KbStrokeWait;
end

%% --- EYELINK CALIBRATION ---
% -- INTEREST CIRCLE --
interest.x1 = round(xCenter - radius);
interest.y1 = round(yCenter - radius);
interest.x2 = round(xCenter + radius);
interest.y2 = round(yCenter + radius);

if inLab == 2 || inLab == 3

    % Optional: Set IP address of eyelink tracker computer to connect to.
    % Call this before initializing an EyeLink connection if you want to use a non-default IP address for the Host PC.
    %Eyelink('SetAddress', '10.10.10.240')c
    el = EyelinkInitDefaults(window); % provides EyeLink with some defaults, which are returned in the structure "el"

    % Set background & target colourspr

    if isEven
        el.backgroundcolour = greyBW;  % background colour should be similar to stimuli (to reduce luminance-based pupil size change & drifting)
    else
        el.backgroundcolour = greyCol;
    end

    el.msgfontcolour = white;
    el.calibrationtargetcolour = black;
    el.msgfont = 'Arial';
    el.msgfontsize = 30;

    InitializePsychSound(1); % gives warning rather than error 
    pahandle = PsychPortAudio('Open', [], 1, 1, 44100, 2); % do I need all of these arguments? [] = defult audio device, 1 = playback mode, 1 = low-latency mode (matching InitialisePsychSound(1)), 44100 = sample rate (standard audio rate), 2 = number of audio channels (stereo)?
    el.ppa_pahandle = pahandle;
    
    % Set calibration/drift-check size**
    % el.calibrationtargetsize = 3; % Outer target size as percentage of the screen
    % el.calibrationtargetwidth = 0.7; % Inner target size as percentage of the screen

    % Set calibration beeps (0 = sound off, 1 = sound on)
    el.targetbeep = 1;  % sound a beep when a target is presented
    el.feedbackbeep = 1;  % sound a beep after calibration or drift check/correction

    EyelinkUpdateDefaults(el); % call this function to apply the changes made to the el structure above

    % Initialization of the connection exit program if this fails.
    if ~EyelinkInit(0)
        fprintf('Eyelink Init aborted.\n');
        cleanup;  % cleanup function
        return;
    end

    % Screem params & calibration (defalt 9-point)
    % display coordinates: recording resolution - map x,y to display
    Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, width, height); % set left, top, right and bottom coordinates in screen pixels
    Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, width, height); % write display coordinates to EDF file/DataViewer

    % Set number of calibration/validation dots and spread: horizontal-only(H) or horizontal-vertical(HV) as H3, HV3, HV5, HV9 or HV13
    % Eyelink('command', 'calibration_type = HV9'); % horizontal-vertical 9-points
    Eyelink('command', 'calibration_type = HV5');

    % Hide mouse cursor
    HideCursor(display.screenNum);

    % make sure that we get gaze data from the Eyelink
    Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON'); % sets which types of events will be written to EDF file
    Eyelink('command', 'file_sample_data  = LEFT, RIGHT, GAZE, HREF, AREA, SACCADE, BLINK, MESSAGE'); % sets data in samples written to EDF file
    %
    % FIX SAMPLING RATE!
    Eyelink('command', 'sample_rate = %d',1000);  % important for analysis *

    % open file to record data to
    edfFilename = [E.IDstr];
    edfFile = [edfFilename, '.edf'];
    Eyelink('Openfile', edfFile);

    % Calibration message
    CalibrationStartTxt = 'Calibrating';
    %Screen('FillRect', display, grey, window);
    DrawFormattedText(window, CalibrationStartTxt, 'center', 'center', white);
    Screen('Flip',window);
    WaitSecs(.5);

    % % Extra EL stuff**
    % Eyelink('Command', 'button_function 5 "accept_target_fixation"');
    % ListenChar(-1); % Start listening for keyboard input. Suppress keypresses to Matlab windows.
    % Eyelink('Command', 'clear_screen 0'); % Clear Host PC display from any previus drawing

    % Calibrate the eye tracker
    Screen('HideCursorHelper', window);
    EyelinkDoTrackerSetup(el);

    % do a final check of calibration using driftcorrection
    EyelinkDoDriftCorrection(el);

    CalibrationEndTxt = 'Calibration complete';
    DrawFormattedText(window, CalibrationEndTxt, 'center', 'center', white);
    Screen('Flip',window);
    WaitSecs(.5);
end 

if inLab == 0 || inLab == 1 || inLab == 4 %setting pahandle as something for the function even if not doing eyetracking1
    pahandle = 1;
    el = NaN;
end


%% --- INSTRUCTIONS PT 1: DISCOMFORT ---
InstructionTxt1 = 'In this task, you will see different patterns and be asked to rate how uncomfortable they are to look at. \n\n By “discomfort”, we do not mean whether the pattern looks unpleasant, ugly, or is not your preference. \n\n Instead, we mean any physical sensations the pattern may cause, for example eye strain, headache, nausea, dizziness, or a strong urge to look away. It may also include visual effects, like seeing the pattern flicker, shimmer or move. \n\n Please press SPACE to continue.';
DrawFormattedText(window, InstructionTxt1, 'center', 'center', white, 60);
Screen('Flip', window);          
RestrictKeysForKbCheck(keys.space);         
[secs, keyCode, deltaSecs] = KbStrokeWait; 

%% --- INSTRUCTIONS PT 2: BLOCKS ---
InstructionTxt2 = 'This task has two sections, each with different patterns. After finishing the first section, you will move onto the next. \n\n There will be several scheduled breaks throughout the task. However, if you need an extra break, press P on the keyboard to pause. To stop the experiment at any time, press ESC and let the researcher know. \n\n When you are ready, please press SPACE to see which section you will start with.';
DrawFormattedText(window, InstructionTxt2, 'center', 'center', white, 60);
Screen('Flip', window);          
RestrictKeysForKbCheck(keys.space);         
[secs, keyCode, deltaSecs] = KbStrokeWait; 

%% --- RUN TASKS ---

if isEven
    % try
    % -- CONTRAST BLOCK --
    [R] = runContrastBlock(R, E, window, windowRect, keys, fname_contrast, xCenter, yCenter, ST, imtextures, angle, sigma, black, greyBW, white, ncycles, flickerTimeFrames, ifi, allValues, inLab, pahandle, dRectM, rect, interest, el);

    % Transition to second task message
    ContrastBlockFinishedTxt = 'You have finished the black and white task. Please take a break, and when you are ready, please press SPACE to start eye-tracking calibration for the second task.';

    if Screen('Windows')
        DrawFormattedText(window, ContrastBlockFinishedTxt, 'center', 'center', white, 60);
        Screen('Flip', window);
        RestrictKeysForKbCheck(keys.space);
        [secs, keyCode, deltaSecs] = KbStrokeWait;
    end

    % change background grey for next block
    backgroundGrey = [greyCol, greyCol, greyCol];
    Screen('FillRect', window, backgroundGrey);
    Screen('Flip', window);

    % -- CALIBRATION --
    if (inLab == 2 || inLab == 3) 
        el.backgroundcolour = backgroundGrey;
        EyelinkUpdateDefaults(el);
        DrawFormattedText(window, CalibrationStartTxt, 'center', 'center', white); % Start calibration message
        Screen('Flip',window);
        WaitSecs(.5);
        Screen('HideCursorHelper', window);
        Eyelink('command', 'background_color = %d %d %d', backgroundGrey(1), backgroundGrey(2), backgroundGrey(3));
        EyelinkDoTrackerSetup(el); % Calibrate the eye tracker
        EyelinkDoDriftCorrection(el); % Final calibration check using driftcorrection
        DrawFormattedText(window, CalibrationEndTxt, 'center', 'center', white); % Finish calibration message
        Screen('Flip',window);
        WaitSecs(.5);
    end

    % catch ME
    %     rethrow(ME);
    % end

    % -- COLOUR BLOCK --
    if Screen('Windows')
        [R] = runColourBlock(R, E, window, windowRect, keys, fname_colour, xCenter, yCenter, ST, imtextures2, angle2, sigma2, black, greyCol, white, ncycles, flickerTimeFrames, ifi, allValues2, inLab, pahandle, dRectM2, rect, interest, el, gratingwidth_deg, pixperdeg);
    end

else
    % -- COLOUR BLOCK --
    [R] = runColourBlock(R, E, window, windowRect, keys, fname_colour, xCenter, yCenter, ST, imtextures2, angle2, sigma2, black, greyCol, white, ncycles, flickerTimeFrames, ifi, allValues2, inLab, pahandle, dRectM2, rect, interest, el, gratingwidth_deg, pixperdeg);

    % transition to second task
    ColourBlockFinishedTxt = 'You have finished the colour task. Please take a break, and when you are ready, please press SPACE to start eye-tracking calibration for the second task. ';

    if Screen('Windows')
        DrawFormattedText(window, ColourBlockFinishedTxt, 'center', 'center', white, 60);
        Screen('Flip', window);
        RestrictKeysForKbCheck(keys.space);
        [secs, keyCode, deltaSecs] = KbStrokeWait; % waits for key press to continue
    end

    % change background grey for next block
    backgroundGrey = [greyBW, greyBW, greyBW];
    Screen('FillRect', window, backgroundGrey);
    Screen('Flip', window);

    % -- CALIBRATION --
    if (inLab == 2 || inLab == 3) 
        el.backgroundcolour = backgroundGrey;
        EyelinkUpdateDefaults(el);
        DrawFormattedText(window, CalibrationStartTxt, 'center', 'center', white); % Start calibration message
        Screen('Flip',window);
        WaitSecs(.5);
        Screen('HideCursorHelper', window);
        Eyelink('command', 'background_color = %d %d %d', backgroundGrey(1), backgroundGrey(2), backgroundGrey(3));
        EyelinkDoTrackerSetup(el); % Calibrate the eye tracker
        EyelinkDoDriftCorrection(el); % Final calibration check using driftcorrection
        DrawFormattedText(window, CalibrationEndTxt, 'center', 'center', white); % Finish calibration message
        Screen('Flip',window);
        WaitSecs(.5);
    end

    % -- CONTRAST BLOCK --
    if Screen('Windows')
        [R] = runContrastBlock(R, E, window, windowRect, keys, fname_contrast, xCenter, yCenter, ST, imtextures, angle, sigma, black, greyBW, white, ncycles, flickerTimeFrames, ifi, allValues, inLab, pahandle, dRectM, rect, interest, el);
    end
end

%% --- FINISH MESSAGE ---
FinishTxt = 'You are all finished. Thanks so much for your help!';
if Screen('Windows')
    DrawFormattedText(window, FinishTxt, 'center', windowRect(4)*0.5, white, 60);
    Screen('Flip', window);
    WaitSecs(0.1);
    RestrictKeysForKbCheck(keys.space);
    [secs, keyCode, deltaSecs] = KbStrokeWait;
end

%% --- CLOSE EEG PORT ---
% if inLab == 1 || inLab == 3
%     close_ns_port(port_handle);
% end

%% --- SAVE EDF FILE ---
if inLab == 2 || inLab == 3
    WaitSecs(0.5); % Allow some time before closing and transferring file

    Eyelink('StopRecording')
    Eyelink('CloseFile'); %
    % Eyelink('Shutdown'); % Close & shutdown EDF file on EyeLink Host PC
    PsychPortAudio('Close', pahandle); % close audio channel

    try 
        fprintf('Receiving data file ''%s''\n', edfFile );

        targetFolder = fullfile('C:\Users\gxm449\Documents\Data\VDGP\EyeTracking');

        if ~exist(targetFolder, 'dir')
            mkdir(targetFolder);
        end

        targetEDF = fullfile(targetFolder, edfFile);

        status=Eyelink('ReceiveFile', edfFile, targetEDF, 1); % Transfer EDF file from EyeLink Host PC to computer under pwd (current working directory)

        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end

        if exist(targetEDF, 'file') == 2
            fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, targetFolder);
        end

    catch
        fprintf('Problem receiving data file ''%s''\n', edfFile );
    end

    if ~exist('data', 'dir') % Finds/creates 'data' folder, and moved EDF file into it
        mkdir('data');
    end

    % movefile(targetEDF, fullfile('data', edfFile);
end


%% --- CLOSE SCREEN AND SAVE ---
sca;
Screen('CloseAll');

applyGammaCorrection_APL(0, Gamma.gammaTable, 0); % remove gamma correction

% Contrast results
if isfield(R, 'rt') && isfield(R, 'response')
    nTrials = length(R.trialrand);
    participantID = repmat(E.ID, nTrials, 1);
    contrastResults = array2table([participantID, R.trialrand, R.eventTime(:), R.meanFreq(:), R.response(:), R.rt(:)], ...
        'VariableNames', {'ParticipantID', 'SF', 'Contrast', 'Trigger', 'Time', 'Measured Freq', 'Rating', 'Reaction Time'});
    writetable(contrastResults, fullfile(E.exptpath, 'Ratings', [E.IDstr '_Contrast_.csv']));
end

% Colour results 
if isfield(R, 'rt2') && isfield(R, 'response2')
    nTrials2 = length(R.trialrand2);
    participantID2 = repmat(E.ID, nTrials2, 1);
    colourResults = array2table([participantID2, R.trialrand2, R.eventTime2(:), R.meanFreq2(:), R.response2(:), R.rt2(:)], ...
        'VariableNames', {'ParticipantID','SF', 'Colour', 'Trigger', 'Time', 'Measured Freq', 'Rating', 'Reaction Time'});
    writetable(colourResults, fullfile(E.exptpath, 'Ratings', [E.IDstr '_Colour_.csv']));
end

% Photodiode results
% participantID = E.IDstr;
% saveDir = fullfile(pwd, 'Photodiode');
% 
% if ~exist(saveDir, 'dir')
%     mkdir(saveDir);
% end
% 
% filename = fullfile(saveDir, ['pd_', participantID, '.mat']);
% save(filename, 'pd');  % Save the structure


%% --- EXTRA ---

% -- TESTING --
% TimingTest % measures IFI and missed frames
% VBLSyncTest % measures accuracy of vbl timestamps (is the graphics card + display giving accurate synch signals)
% PerceptualVBLSyncTest % visual correctness test 