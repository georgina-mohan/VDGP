function [textureHandles, angle, gratingwidth_pix, radius, sf_cpp, phase, colourPairs, sigma, imgMatrix2, soothtex, tVals, masktex, dRectM, gratingwidth_deg, pixperdeg] = ColourStimuli3(window, xDim, yDim, display)
%% Georgina Mohan 
% 18/09/2025
% SPIN Lab 
%
% ColourStimuli - Create sine wave gratings that vary in chromatic separation and SF
% Requires MakingGratings_ST3 output - was having issues with CreateProceduralGratings so had to do pixel by pixel 

% --- Gratings: spatial frequency ---
sf_cpd = [0.5 3 9]; % define SF 
gratingwidth_deg = 7.5; % size of grating in degrees
gratingwidth_pix = angle2pix(display, gratingwidth_deg); % calc grating size in pixels using angle2pix
pixperdeg = gratingwidth_pix / gratingwidth_deg; % pixels per degree
sf_cpp = sf_cpd / pixperdeg; % SF in cycles per pixel

% --- Grating: other appearance settings ---
angle = 0;
phase = [0 180];
sigma = 0; % -1 for sine wave (1 would be square)
radius = floor(gratingwidth_pix / 2); % makes stimuli circular (rather than square)

% --- Load colours ---
coloursTable = {
    [0; 40; 103]; % BG lowBlue
    [0; 47; 43]; % BG lowGreen
    [0; 28; 222]; % BG highBlue
    [0; 51; 0]; % BG highGreen
    [104; 21; 5]; % RG lowRed
    [54; 36; 5]; % RG lowGreen
    [162; 7; 0]; % RG highRed
    [0; 51; 0]; % RG highGreen
    };

colourPairs = reshape(coloursTable, 2, []).';

for i = 1:numel(colourPairs)
    rgb = max(double(colourPairs{i}(:)'), 0) / 255; % change any negative numbers to 0, and change from 255 to 0-1 RGB colour values
    colourPairs{i} = rgb;
    % colourPairs2{i} = [rgb, 1]; % add 1 for alpha 
end


% Get screen parameters from the passed-in window
%screenNumber = Screen('WindowScreenNumber', window);
% grey = WhiteIndex(window) / 2; % try changing to grey
grey = 128;

% Set alpha blending for anti-aliasing
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
Screen('Flip', window); % clear old screen/display
WaitSecs(1);

soothtex = Screen('GetImage', window);
gaborDimPix = gratingwidth_pix;


%% --- APERTURE MASK ---

taper_deg = 1.5;
diam_deg = gratingwidth_deg;
stim_pix = round(diam_deg * pixperdeg); % CHECK THIS NOW PRODUCES RIGHT VA
% stim_pix = gratingwidth_pix;  % old replacement code for above which fixed VA
taper_pix = round(taper_deg * pixperdeg);

[x, y] = meshgrid(linspace(-1,1, stim_pix), linspace(-1, 1, stim_pix));
r = sqrt(x.^2 + y.^2);

inner = r <= (1 - taper_pix/stim_pix);
outer = r >= 1;
blend = ~inner & ~outer;

cosine = ones(size(r));
cosine(outer) = 0;
cosine(blend) = 0.5 * (1 + cos(pi * (r(blend) - (1 - taper_pix/stim_pix)) / (taper_pix/stim_pix)));

% imagesc(cosine);
% axis image;
% colourmap gray;

alpha_uint8 = uint8(255 * (1 - cosine));
lum_uint8 = uint8(ones(size(alpha_uint8)) * grey);
aperture = cat(3, lum_uint8, alpha_uint8);

masktex = Screen('MakeTexture', window, aperture);
dRectM  = CenterRectOnPoint([0 0 stim_pix stim_pix], xDim/2, yDim/2);


%% --- CREATE TEXTURES ---

stim = 0; % total number of stimuli (including phase)
stimcathy = 0; % number of stimuli combinations (SF x colour pair), regardless of phase

[offscreen, ~] = Screen('OpenOffscreenWindow', window, grey);
Screen('BlendFunction', offscreen, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

cd C:\Users\gxm449\Documents\PsyCalibrator-main\PsyCalibrator
load('StimColSep.mat', 'ColSepStim'); % load pre-generated textures from MakingGratings_ST3.m script 

% for sf = 1:length(sf_cpp)
%     for pair = 1:size(colourPairs, 1)
%         stimcathy = stimcathy + 1;
%         for p = 1:length(phase)
%         stim = stim + 1;
% 
%         colour1 = colourPairs{pair, 1}; % this may need changing to 3 and 4 - if i include labels
%         colour2 = colourPairs{pair, 2};
% 
%         colour1 = colour1(:)';
%         colour2 = colour2(:)'; % change to row vector as keep getting error msg
% 
%         % Create procedural color grating
%         % [id] = CreateProceduralColorGrating(window, gratingwidth_pix, gratingwidth_pix, colour1, colour2, radius);
%         [id] = CreateProceduralColorGrating(window, gaborDimPix, gaborDimPix, colour1, colour2, radius);
% 
%         auxParams = [phase(p), sf_cpp(sf), 1, sigma]; % decide contrast
% 
%         Screen('DrawTexture', offscreen, id, [], dRectM, angle, [], [], [], [], [], auxParams); 
%         %Screen('DrawTexture', offscreen, id, [], dRectM, angle, [], [], grey, [], [], auxParams); % commented this out because setting as grey doesn't work - need to account for luminance differences when defining the colours
% 
%         Screen('DrawTexture', offscreen, masktex, [], dRectM);
% 
%         % Save last frame and trial values
%         current_display = Screen('GetImage', offscreen); % this is where i would grab rendered image from screen, but instead I am
% 
%         %imgMatrix2{stimcathy,p, :} = current_display;
% 
%         current_display = ColSepStim{stimcathy,p}; % overriding with pre-loaded version (StimColSep)
% 
%         imgMatrix2{stimcathy,p, :} = current_display; % stores image matrix (from ColSepStim) not process above
% 
%         textureHandles{stimcathy,p} = Screen('MakeTexture', window, current_display); % store texture handle from this image matrix
% 
%         tVals(stim, 1) = sf_cpp(sf);
%         tVals(stim, 2) = pair;
%         tVals(stim, 3) = phase(p);
% 
%         % Close grating texture
%         Screen('Close', id);
% 
%         end
%     end
% end

nSF = length(sf_cpp);              % number of spatial frequencies
nColourPairs = size(colourPairs,1); 
nPhases = length(phase);

stim = 0;
stimcathy = 0;

for sf_idx = 1:nSF
    for pair_idx = 1:nColourPairs
        stimcathy = stimcathy + 1;
        for phase_idx = 1:nPhases
            stim = stim + 1;

            % Extract stimulus image
            current_display = ColSepStim{stimcathy, phase_idx};

            % Save image and texture
            imgMatrix2{stimcathy, phase_idx, :} = current_display;
            textureHandles{stimcathy, phase_idx} = Screen('MakeTexture', window, current_display);

            % Save condition values
            tVals(stim, 1) = sf_cpp(sf_idx);       % spatial frequency
            tVals(stim, 2) = pair_idx;             % colour pair index
            tVals(stim, 3) = phase(phase_idx);     % phase (e.g. 0 or 180)

            % Optional: save actual colour values and other properties
            conditionDetails(stim).sf_cpp = sf_cpp(sf_idx);
            conditionDetails(stim).colour1 = colourPairs{pair_idx, 1};
            conditionDetails(stim).colour2 = colourPairs{pair_idx, 2};
            conditionDetails(stim).phase = phase(phase_idx);
        end
    end
end


%%

Sam1 = imgMatrix2{4,1}(:,:,1);
Sam2 = imgMatrix2{4,1}(:,:,2);
Sam3 = imgMatrix2{4,1}(:,:,3);