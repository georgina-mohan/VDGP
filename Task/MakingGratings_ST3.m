%% Code to make gratings for Child Rating Study
% Want 2 SFs, 3 colour-ways (black-white, red-green, blue-green) and 2
% contrasts
% sf in CreateProceduralColorGrating is cycles/pixel - see here: http://psychtoolbox.org/docs/CreateProceduralSineGrating
% But want it specified in cycles/degree. Also want size of image in
% degrees.
%
% ST - 30/09/2025 - added colour separation vals, 3 SFs (but we will choose
% one I think), 3 colours (red-green, red-blue, blue-green) at 2 colour
% separation levels (high and low). Black and white gratings also here.
% Sigma = 0 shows aliasing on laptop - check on here to see if also the
% case. Otherwise Sigma = 0.1 or 0.05 would use hermolite interpolation to
% smooth the edge slightly, but then problems with some stripes slightly
% wider than others at higher spatial frequencies...
%
% Output 
% - ColSepStim = stimuli set up for slideScale_ST12 function
% - also saves images as png files in Images_Gratings folder
clear
sca

%--------------------------------------------------------------------------
% GAMMA CORRECT SCREEN FIRST
%--------------------------------------------------------------------------

% Load in gamma table (if not already in workspace)
cd C:\Users\hannonsc-admin\Documents\Georgina\PsyCalibrator-main\PsyCalibrator
load('Gamma_fitted.mat') % must use Gamma_fitted.mat NOT Gamma.m

% Apply gamma correction to monitor
applyGammaCorrection_APL(1, Gamma.gammaTable, 0); % could this be why the luminance values are so much higher?


% -------------------------------------------------------------------------
% SET UP SCREEN
% -------------------------------------------------------------------------

% Specify some screen stuff so can use angle2pix
display.dist = 60; % 51(distance from screen (cm))
display.width = 54.2; %30.8;  %(width of screen (cm))
display.resolution = 1920; %3840; %1920;  %(number of pixels of display in horizontal direction)- my personal laptop is 3840 x 2160


% Check that pixels are square - check that pixels/cm is same for both
% horizontal and vertical directions.
% display.height = 17.4; %19.3; 
% display.resolutionvert = 1080; %2160;
% Each pixel is CM: .0089 cm, ST: 0.01608 cm wide and tall

% specify grating size
sf_cpd = [0.5 3 9];
gratingwidth_deg = 7.5; % grating size in visual degrees
gratingwidth_pix = angle2pix(display, gratingwidth_deg);

pixperdeg = gratingwidth_pix/gratingwidth_deg;

% If grating is 6 degrees in width and 3 cycles per degree, expect 18 cycles
% within the stimulus - check this by counting on the resulting stimulus
expectedcycles = gratingwidth_deg * sf_cpd;

sf_cpp = sf_cpd / pixperdeg;

sf_ppc = 1 ./ sf_cpp; % pixels per cycle - this should be integer for 
% accurate drawing - nope, still goes weird even when an integer at pix per 
% half cycle... It's in the Procedural drawing... but if we draw manually
% then this has to be an integer at the half cycle or it goes weird


% If set to 2, here we skip sync tests for the screen. We would not do this in a real
% experiment as we would want precise timing. 
Screen('Preference','SkipSyncTests', 0);

% Make sure this is running on OpenGL Psychtoolbox:
AssertOpenGL;

% Setup PTB with some default values
PsychDefaultSetup(2);

% Set the screen number to the external secondary monitor if there is one
% connected
screenNumber = max(Screen('Screens'));

% Define black, white and grey
%white = WhiteIndex(screenNumber);
grey = 128/255; %white / 2;
%black = BlackIndex(screenNumber);

% Colours: [R G B alpha]
blue = [0 28 222 255];
green = [0 51 0 255];
red = [162 7 0 255];

BGblue1 = [0 40 103 255];
BGgreen1 = [0 47 43 255];

RGred1 = [104 21 5 255];
RGgreen1 = [54 36 4 255];

% concatenate vertically for creating stimuli, dividing by 255 so it is in
% correct format for function = between 1 and 0
% BGcolours = vertcat(blue/255, green/255, BGblue1/255, BGgreen1/255);%, ...
BGcolours = vertcat(BGblue1/255, BGgreen1/255, blue/255, green/255);
%BGblue2/255, BGgreen2/255, BGblue3/255, BGgreen3/255);

% RGcolours = vertcat(red/255, green/255, RGred1/255, RGgreen1/255);%, ...
RGcolours = vertcat(RGred1/255, RGgreen1/255, red/255, green/255);
%RGred2/255, RGgreen2/255, RGred3/255, RGgreen3/255);

% RBcolours = vertcat(red/255, blue/255, RBred1/255, RBblue1/255);%, ...
%RBred2/255, RBblue2/255, RBred3/255, RBblue3/255);

angle = 0;

phase = [0 180]; %0; % phase
frequency = sf_cpp; % spatial frequency in cycles per pixel
contrast = 1; %[0.05 0.1 0.4 0.8]; % Tsai et al was 0.05, 0.1, 0.2, 0.4, 0.8
sigma = 0; %0.005; %0.05;%0.1; %0; % sigma < 0 is a sinusoid. 0 is a square wave grating % if sigma is 0 then the squarewave is not smoothed, but if it is > 0 (e.g., 0.1) then
% hermite interpolation smoothing in +-sigma of the edge is performed.

% Open the screen
%PsychImaging('PrepareConfiguration');
%PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey); %[0 0 gratingwidth_pix gratingwidth_pix]); % , 32, 2);
%Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

Priority(MaxPriority(window));

% Flip to clear
Screen('Flip', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

[xDim, yDim]=Screen('WindowSize', screenNumber);
dRect = CenterRectOnPoint([0 0 gratingwidth_pix gratingwidth_pix], xDim/2, yDim/2); % destination rectangle
% as centre of display

% Get the centre coordinate of the window
%[xCenter, yCenter] = RectCenter(windowRect);

%contrast = 0.05;
gaborDimPix = gratingwidth_pix;

row = 0;

for sf = 1:length(sf_cpp)


    even = 0;

    for col = 1:height(BGcolours)
        col2 = col + 1;
        if rem(col2,2) == 0
            even = even + 1;
            row = row + 1;

            for p = 1:length(phase)

                % Parameters
                rsf_ppc = round(sf_ppc(sf));   % pixels per cycle - rounded to nearest integer

                % Switch phase
                if p == 1
                    colourA = BGcolours(col,:);    % blue (normalised RGB)
                    colourB = BGcolours(col2,:);   % green
                elseif p == 2
                    colourA = BGcolours(col2,:);   % green
                    colourB = BGcolours(col,:);    % blue (normalised RGB)
                end

                % X coordinates
                x = 0:(gaborDimPix-1);

                % Compute cycle index
                cycleIndex = floor(mod(x, rsf_ppc) / (rsf_ppc/2)); % rsf_ppc/2 has to
                % be an integer, or there will be aliasing

                % This gives 0 for first half of cycle, 1 for second half
                rowPattern = repmat(cycleIndex, gaborDimPix, 1);

                % Build RGB image
                grating = zeros(gaborDimPix, gaborDimPix, 3);
                for c = 1:3
                    grating(:,:,c) = colourA(c) * (rowPattern == 0) + colourB(c) * (rowPattern == 1);
                end

                %imshow(grating)

                %grating = grating * 255;

                id = Screen('MakeTexture', window, grating);

                % BG grating
                %[id, rect, shader] = CreateProceduralColorGrating(window, gaborDimPix, gaborDimPix, BGcolours(col,:), BGcolours(col2,:));

                Screen('DrawTexture', window, id, [], dRect, angle, [], [], [], [], [], []);
                Screen('Flip', window); %show gabor patch on screen
                WaitSecs(2);

                % To save file
                current_display = Screen('GetImage',window, dRect);
                imwrite(current_display, [cd '/Images_Gratings/Grating_BG' num2str(even) '_' num2str(sf_cpd(sf)) 'cpd_phase' num2str(phase(p)) '.png']);
                ColSepStim{row, p} = grating * 255;
                ColSepStim{row, 3} = sf_cpd(sf);
                % ColSepStim{row, 4} = 0; % N/A spatial frequency bandwidth
                % ColSepStim{row, 5} = 0; % N/A temporal frequency
                % ColSepStim{row, 6} = 0; % dynamic = 0 - static image
                % ColSepStim{row, 7} = 0; % N/A pixels to shift per frame
            end
        end
    end

    for col = 1:height(RGcolours)
        col2 = col + 1;
        if rem(col2,2) == 0 % we only want certain colour pairs (1 and 2, 3 and 4, etc)
            even = even + 1;
            row = row + 1;

            for p = 1:length(phase)


                % Parameters
                rsf_ppc = round(sf_ppc(sf));   % pixels per cycle - rounded to nearest integer

                % Switch phase
                if p == 1
                    colourA = RGcolours(col,:);    % red (normalised RGB)
                    colourB = RGcolours(col2,:);   % green
                elseif p == 2
                    colourA = RGcolours(col2,:);   % green
                    colourB = RGcolours(col,:);    % red (normalised RGB)
                end

                % X coordinates
                x = 0:(gaborDimPix-1);

                % Compute cycle index
                cycleIndex = floor(mod(x, rsf_ppc) / (rsf_ppc/2)); % rsf_ppc/2 has to
                % be an integer, or there will be aliasing

                % This gives 0 for first half of cycle, 1 for second half
                rowPattern = repmat(cycleIndex, gaborDimPix, 1);

                % Build RGB image
                grating = zeros(gaborDimPix, gaborDimPix, 3);
                for c = 1:3
                    grating(:,:,c) = colourA(c) * (rowPattern == 0) + colourB(c) * (rowPattern == 1);
                end

                %imshow(grating)

                %grating = grating * 255;

                id = Screen('MakeTexture', window, grating);

                % RG grating
                %[id, rect, shader] = CreateProceduralColorGrating(window, gaborDimPix, gaborDimPix, RGcolours(col,:), RGcolours(col2,:));

                Screen('DrawTexture', window, id, [], dRect, angle);
                Screen('Flip', window); %show gabor patch on screen
                WaitSecs(2);
                % To save file
                current_display = Screen('GetImage', window, dRect);
                imwrite(current_display, [cd '/Images_Gratings/Grating_RG' num2str(even) '_' num2str(sf_cpd(sf)) 'cpd_phase' num2str(phase(p)) '.png']);
                ColSepStim{row, p} = grating * 255;
                ColSepStim{row, 3} = sf_cpd(sf);
                % ColSepStim{row, 4} = 0; % N/A spatial frequency bandwidth
                % ColSepStim{row, 5} = 0; % N/A temporal frequency
                % ColSepStim{row, 6} = 0; % dynamic = 0 - static image
                % ColSepStim{row, 7} = 0; % N/A pixels to shift per frame
            end
        end
    end


    even = 0;

end


% Stop gamma correction of monitor
applyGammaCorrection_APL(0, Gamma.gammaTable, 0);

save('StimColSep', 'ColSepStim');
fprintf('colour separation stimuli saved in StimColSep.mat and pngs in Images_Gratings folder\n');

sca





