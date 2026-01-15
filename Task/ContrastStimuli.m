function [textureHandles, angle, gratingwidth_pix, radius, sf_cpp, phase, contrast, sigma, imgMatrix, soothtex, tVals, masktex, dRectM] = ContrastStimuli(window, xDim, yDim, display)
%% Georgina Mohan 
% 18/09/2025
% SPIN Lab 
%
% ContrastStimuli - create sine wave gratings at different spatial frequencies and contrasts
%
% INPUT:
%   window - Psychtoolbox window pointer (already opened)
%
% OUTPUTS:
%   textureHandles - cell array of texture handles
%   angle, gratingwidth_pix, sf_cpp, phase, contrast, sigma - stimulus parameters
%   practice - matrix of SF and contrast for practice trials
%   imgMatrix - cell array of stimulus images
%   soothtex - screenshot of the screen at the beginning
%   tVals - trial values for SF, contrast, phase

% Spatial frequencies (cycles per degree)
sf_cpd = [0.5 3 9];
gratingwidth_deg = 7.5; % Size of grating in degrees
gratingwidth_pix = angle2pix(display, gratingwidth_deg); % Calculate grating size in pixels using angle2pix
pixperdeg = gratingwidth_pix / gratingwidth_deg; % Pixels per degree
sf_cpp = sf_cpd / pixperdeg; % Spatial frequency in cycles per pixel

% --- Grating appearance settings ---
angle = 0;
phase = [0 180];
contrast = [0.05 0.1 0.2 0.4 0.8];
sigma = -1; % -1 for sine wave (1 would be square)
radius = floor(gratingwidth_pix / 2); % makes stimuli circular (rather than square)

% Get screen parameters from the passed-in window
screenNumber = Screen('WindowScreenNumber', window);
% grey = WhiteIndex(window) / 2; % try changing to grey
grey = 128;

% Set alpha blending for anti-aliasing
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Clear screen and flip
Screen('Flip', window);
WaitSecs(2);

% Get initial screen image for soothtex
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

stim = 0;
stimcathy = 0;

[offscreen, ~] = Screen('OpenOffscreenWindow', window, grey);
Screen('BlendFunction', offscreen, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

for sf = 1:length(sf_cpp)
    for c = 1:length(contrast)
        stimcathy = stimcathy + 1;
        for p = 1:length(phase)
            stim = stim + 1;

            % Create procedural grating texture
            [id, ~, ~] = CreateProceduralColorGrating(window, gaborDimPix, gaborDimPix, [0 0 0 1], [1 1 1 1], radius);

            % Draw the grating texture with given parameters
            %Screen('DrawTexture', offscreen, id, [], dRectM, 0, [], [], [], [], [], [phase(p), sf_cpp(sf), contrast(c), sigma]);
            Screen('DrawTexture', offscreen, id, [], dRectM, 0, [], [], grey, [], [], [phase(p), sf_cpp(sf), contrast(c), sigma]);

            % Draw aperture mask on top of grating
            Screen('DrawTexture', offscreen, masktex, [], dRectM);

            % Grab the image of the stimulus
            current_display = Screen('GetImage', offscreen);

            imgMatrix{stimcathy,p,:} = current_display;
            textureHandles{stimcathy,p} = Screen('MakeTexture', window, current_display);

            % save trial values corresponding to image textures - should
            % this be changed to tVals(stimcathy, p, 1) etc?
            tVals(stim, 1) = sf_cpp(sf);
            tVals(stim, 2) = contrast(c);
            tVals(stim, 3) = phase(p);

            %tVals(stim, :) = [sf_cpp(sf), contrast(c), phase(p)]; % would
            %this work?

            % Save image file as PNG
            % filename = sprintf('stim_sf%.2f_c%.2f_p%d.png', sf_cpp(sf), contrast(c), phase(p));
            % if ~isa(current_display, 'uint8')
            %     current_display = uint8(current_display);
            % end
            % imwrite(current_display, filename);

            % Close procedural grating texture
            Screen('Close', id);
        end
    end
end



