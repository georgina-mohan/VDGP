function [R] = runColourBlock(R, E, window, windowRect, keys, fname_colour, xCenter, yCenter, ST, imtextures2, angle2, sigma2, black, greyCol, white, ncycles, flickerTimeFrames, ifi, allValues2, inLab, pahandle, dRectM2, rect, interest, el, gratingwidth_deg, pixperdeg)
%% Georgina Mohan 
% 18/09/2025
% SPIN Lab 
%
% 28/10/2025 update: adding in GetSecs 

%% --- APERTURE MASK ---
taper_deg = 1.5;
diam_deg = gratingwidth_deg;
stim_pix = round(diam_deg * pixperdeg); 
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
lum_uint8 = uint8(ones(size(alpha_uint8)) * greyCol);
aperture = cat(3, lum_uint8, alpha_uint8);

masktex = Screen('MakeTexture', window, aperture);
% dRectM2  = CenterRectOnPoint([0 0 stim_pix stim_pix], xDim/2, yDim/2);


%% --- PREVIEW ---

HideCursor(window);

Screen('FillRect', window, greyCol);
InstructionTxt = 'You are about to begin the colour section, where the patterns will have different colours. When you press SPACE, we will first show you examples of what these patterns look like.';
DrawFormattedText(window, InstructionTxt, 'center', 'center', white, 60);
Screen('Flip', window);
RestrictKeysForKbCheck(keys.space);
[secs, keyCode, deltaSecs] = KbStrokeWait;

previewtrials2 = Shuffle(allValues2,2);

for trial = 1:length(previewtrials2)
    % show stimuli
    Screen('DrawTexture', window, imtextures2{trial}, [], [], angle2);
    Screen('DrawTexture', window, masktex, [], dRectM2);
    Screen('Flip', window);
    WaitSecs(1); % for .5 seconds

    % grey screen inbetween
    Screen('FillRect', window, greyCol);
    Screen('Flip', window);
    WaitSecs(0.5);
end

%% --- INSTRUCTIONS FOR MAIN TASK ---
Screen('FillRect', window, greyCol);
ExperimentStartTxt  = 'In the main task, these patterns will flicker, and you will rate how uncomfortable they are on a scale from 0 (not uncomfortable) to 100 (extremely uncomfortable). \n \n Please keep your eyes on the fixation dot in the middle of the screen while the flickering image is on the screen. \n \n When you are ready, please press SPACE to begin.';
DrawFormattedText(window, ExperimentStartTxt,  'center', 'center', white, 60);
Screen('Flip', window);
RestrictKeysForKbCheck(keys.space);
[secs, keyCode, deltaSecs] = KbStrokeWait;

%% --- RUN COLOUR TASK ---
blockcomplete2 = 0;
R.response2 = NaN(1, E.ntrials2);
R.rt2 = NaN(1, E.ntrials2);
R.pause2 = NaN(1, E.ntrials2);
R.meanFreq2 = NaN(1, E.ntrials2);
R.eventTime2 = NaN(1, E.ntrials2);

% photodiode rectangle
rectSize = 50; % 50 x 50 pixel square
[screenXpixels, screenYpixels] = Screen('WindowSize', window); % get size of screen - don't think i need this
cornerRect = [screenXpixels - rectSize - 20, 20, screenXpixels - 20, 20 + rectSize];  % add to top right corner

HideCursor(window);

greyColEyeTracker = [greyCol, greyCol, greyCol];

% try

    for T = 1:E.ntrials2
        trigger2 = R.trialrand2(T, 3);
        sf2 = R.trialrand2(T, 1);
        colour = R.trialrand2(T, 2);

        % Progress update
        if T == 24+1 || T == 48+1 || T == 72+1 || T == 96+1 || T == 120+1 % with 10 repetitions
        % if T == 12+1 || T == 24+1 || T == 36+1 || T == 48+1 % with 5
            blockcomplete2 = blockcomplete2 + 1;
            % 3 pauses divide block into quarters
            %X        Screen('TextSize', window, FontSize);
            %X         DrawFormattedText( window, 'Please take a break. Press the space bar to continue.', 400, 400, TextColour);
            %%Screen('DrawText', window, ['Well done! You have completed ' num2str(blockcomplete) ' blocks out of ' num2str(E.blocks) '. \n Please take a break. Press the space bar to continue.'], 0, yCenter);
            DrawFormattedText(window, ['Well done! You have completed ' num2str(blockcomplete2) ' blocks out of ' num2str(E.blocks2) '. \n Please take a break. Press the space bar when you are ready to continue.'],  'center', 'center', white, 60);

            Screen('Flip', window);

            RestrictKeysForKbCheck([keys.calibrate, keys.space]);
            [secs, keyCode, deltaSecs] = KbStrokeWait;

            % ADDED EXTRA 
            Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2);
            Screen('Flip', window);
            WaitSecs(2); % present for 2 seconds

            if (inLab == 2 || inLab == 3) && keyCode(keys.calibrate)
                DrawFormattedText(window, CalibrationStartTxt, 'center', 'center', white); % Start calibration message
                Screen('Flip',window);
                WaitSecs(.5);
                Screen('HideCursorHelper', window);
                Eyelink('command', 'background_color = %d %d %d', greyColEyeTracker(1), greyColEyeTracker(2), greyColEyeTracker(3)); % is this needed?
                EyelinkDoTrackerSetup(el); % Calibrate the eye tracker
                EyelinkDoDriftCorrection(el); % Final calibration check using driftcorrection
                DrawFormattedText(window, CalibrationEndTxt, 'center', 'center', white); % Finish calibration message
                Screen('Flip',window);
                WaitSecs(.5);
            elseif (inLab == 2 || inLab == 3)
                Screen('Flip',window);
                WaitSecs(.5);
                Screen('HideCursorHelper', window);
                EyelinkDoDriftCorrection(el);
                Screen('Flip',window);
                WaitSecs(.5);
            elseif keyCode(keys.space)
            end
        end

        if inLab == 2 || inLab == 3
            % Set up eyetracking to record:
            Eyelink('Message', 'BLOCK %d', blockcomplete2); % block number
            WaitSecs(0.001); % Allow some time between messages. Some messages can be lost if too many are written at the same time
            Eyelink('Message', '!V TRIAL_VAR TrialID %d', T); % trial number - OR E.ntrials2 ???
            WaitSecs(0.001);
            Eyelink('Message', '!V TRIAL_VAR SF %s', sprintf('%.3f', sf2)); % SF
            WaitSecs(0.001);
            Eyelink('Message', '!V TRIAL_VAR Colour %d', colour); % colour
            WaitSecs(0.001);
            Eyelink('Message', '!V TRIAL_VAR Trigger %d', trigger2); % trigger
            WaitSecs(0.001);
            Eyelink('command', 'record_status_message "TRIAL %d/%d"', T, E.ntrials2); % send status message to host PC to show current trial out of total, e.g., "TRIAL 5/60"

            Eyelink('Command', 'set_idle_mode'); % draw to eyetracker display
            Eyelink('Command', 'clear_screen %d', 0); % clear tracker display with black screen

            % Draw stimulus locations onto eye tracker display
            Eyelink('Command', 'draw_cross %d %d 15', xCenter, yCenter); % fixation cross coordinates
            Eyelink('Command', 'draw_box %d %d %d %d 15', dRectM2(1), dRectM2(2), dRectM2(3), dRectM2(4), 15);

            % Interest areas (stimuli) https://www.sr-research.com/support/thread-83.html
            Eyelink('Message', ' !V IAREA ELLIPSE 1 %d %d %d %d circle', interest.x1, interest.y1, interest.x2, interest.y2);

            status = Eyelink('StartRecording');
            WaitSecs(0.05);  % small delay for the recording to kick in

            if status ~= 0
                fprintf('Error starting recording on trial %d\n', T);
                Eyelink('StopRecording');  % Try stopping just in case
                continue;  % Skip to next trial
            end
        end

        % Presents fixation point
        Screen('Flip', window);
        Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2);
        Screen('Flip', window);

        if inLab == 2 || inLab == 3
            Eyelink('Message', 'FixOn');
        end

        WaitSecs(ST.ITI); 
        [vbl] = Screen('Flip', window);

        flipchecks2.vbl1 = []; % when first vbl begins
        flipchecks2.vbl2 = []; % when first vbl begins
        flipchecks2.missed1 = [];
        flipchecks2.missed2 = [];
        flipchecks2.fliptsp1 = [];
        flipchecks2.fliptsp2 = [];

        tic

% %         % start photodiode recording
%         recObj = audiorecorder(pd.fs, 16, 1, pd.deviceID);
%         record(recObj);

        for cycle = 1:ncycles
            Screen('DrawTexture', window, imtextures2{T, 1}, [], [], angle2, [], [], [], [], [], double([0, R.trialrand2(T, 1), R.trialrand2(T, 2), sigma2]));
            Screen('DrawTexture', window, masktex, [], dRectM2);
            Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2);
            Screen('FillRect', window, white, cornerRect); % flickering square for photodiode
            [vbl, ~, FlipTimestamp, Missed, ~] = Screen('Flip', window, vbl + flickerTimeFrames * ifi - 0.5*ifi);
            %Screen('DrawTexture', window, masktex, [], dRectM); % do I need this?

            if cycle == 1
                R.eventTime2(T) = GetSecs;
%                 if inLab == 1 || inLab == 3
%                     trigger_val = R.trialrand2(T, 3); % (T, 3) = stimulus label
%                     send_ns_trigger(trigger_val, port_handle);
%                 end
                if inLab == 2 || inLab == 3
                    Eyelink('Message', 'StimOn');
                end
            end

            flipchecks2.vbl1(cycle) = vbl;
            flipchecks2.missed1(cycle) = Missed;
            flipchecks2.fliptsp1(cycle) = FlipTimestamp;

            Screen('DrawTexture', window, imtextures2{T, 2}, [], [], angle2, [], [], [], [], [], double([180, R.trialrand2(T, 1), R.trialrand2(T, 2), sigma2]));
            Screen('DrawTexture', window, masktex, [], dRectM2);
            Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2);
            Screen('FillRect', window, black, cornerRect); % flickering square for photodiode
            [vbl, ~, FlipTimestamp, Missed, ~] = Screen('Flip', window, vbl + flickerTimeFrames * ifi - 0.5*ifi);

            flipchecks2.vbl2(cycle) = vbl;
            flipchecks2.missed2(cycle) = Missed;
            flipchecks2.fliptsp2(cycle) = FlipTimestamp;

            RestrictKeysForKbCheck([keys.pause, keys.esc]);
            [keyIsDown, secs, keyCode] = KbCheck;
            keyPress = find(keyCode);

            % check for pause or esc
            % PAUSE
            if keyPress == keys.pause
                Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2); % Show fixation during pause
                Screen('Flip',window);
                R.pause2(T) = 1;
                if inLab == 2 || inLab == 3 % Send pause message if eyetracking
                    Eyelink('Message', 'PauseOn');
                end
                RestrictKeysForKbCheck([keys.resume]); % Wait for resume button
                while 1, [keyIsDown, secs, keyCode] = KbCheck;
                    if(keyIsDown)
                        if inLab == 2 || inLab == 3 % Send resume message if eyetracking
                            Eyelink('Message', 'PauseOff');
                        end
                        break;
                    end
                end

            % ESCAPE
            elseif keyPress == keys.esc
                R.allframetimes2{T} = flipchecks2; %store flipchecks into R before exiting
                resp = NaN;
                rt = NaN;
                R.response2(T) = resp; % save rating
                R.rt2(T) = rt; % save response time
                save(fname_colour, 'R', 'E'); % save data to workspace
                if inLab == 2 || inLab == 3
                    Eyelink('Message', 'Aborted');
                end
                sca % close screen
                ListenChar(0)
                ShowCursor
                error('Experiment Aborted')
            end

            if(cycle > ncycles)
                break
            end
        end

%         if inLab == 1 || inLab == 3 % to check
%             trigger_val = 100 + R.trialrand2(T, 3);
%             send_ns_trigger(trigger_val, port_handle);
%         end
        if inLab == 2 || inLab == 3
            Eyelink('Message', 'StimOff');
        end

        if inLab == 2 || inLab == 3
            Eyelink('StopRecording');
            Eyelink('Message', 'TRIAL_RESULT 0');
        end

%         % stop photodiode recording
%         stop(recObj);
%         y = getaudiodata(recObj);
%         pd.photodiodeRaw2{T} = y;

        toc % - can do this to check you have stimulus duration you expect

        % Screen('Close', imtextures2{T, 1});
        % Screen('Close', imtextures2{T, 2});

        R.allframetimes2{T} = flipchecks2;

        % Get stimulus rating
        [resp, rt] = hb_scaleResponse_VAS(window, windowRect, 1, white, black, greyCol, rect); % Continuous scale (0 - 100)

        HideCursor(window);
        
        R.response2(T) = resp; % save rating
        R.rt2(T) = rt; % save response time

    end

%     % --- PHOTODIODE ---
% 
%     % --- Create folder to save plots ---
%     plotDir = fullfile(pwd, 'photodiode_colour_plots', E.IDstr); % Create save folder in current directory
%     if ~exist(plotDir, 'dir')
%         mkdir(plotDir);
%     end

%     % --- Loop to extract photodiode measurements and calc frequency ---
%     for T = 1:E.ntrials2
%     % for T = 1:16 % adjust for how many trials you ran
%         y = pd.photodiodeRaw2{T};
% 
%         y = y - mean(y);  % Remove DC
%         y_smooth = movmean(y, 200);  % Smooth to reduce noise
% 
%         % trimDuration = 0.5;  % seconds to trim from start and end
%         % startIdx = round(trimDuration * pd.fs);
%         % endIdx = length(y_smooth) - startIdx;
%         % 
%         % % Guard against very short signals
%         % if endIdx > startIdx
%         %     y_smooth = y_smooth(startIdx:endIdx);
%         %     y = y(startIdx:endIdx);  % also trim raw if you want to plot it later
%         % end
% 
%         t = (1:length(y_smooth)) / pd.fs;  % Update time vector
% 
%         % --- Convert signal to binary ---
%         threshold = 0.001; % threshold to convert continuous to binary signal. adjust as needed - depends on plot
%         pd.binarySignal2{T} = y_smooth > threshold; % binary "black/white", 1 when signal > threshold (white), and 0 when signal < threshold (black)
%         binarySignal = pd.binarySignal2{T};
% 
%         pd.risingEdges2{T} = find(diff(binarySignal) == 1); % indicies (photodiode sample) of when binary signal goes from 0 - 1, or the rising edge (from black to white)
%         risingEdges = pd.risingEdges2{T};
%         pd.edgeTimes2{T} = risingEdges / pd.fs; % when the rising edge occured: indicies relative to sampling rate of photodiode, therefore converting into time points
% 
%         % --- Calculate frequency ---
%         pd.intervals2{T} = diff(pd.edgeTimes2{T}); % time intervals between each flicker (white -> white)
%         pd.frequencies2{T} = 1 ./ pd.intervals2{T}; % calculates frequency (freq = 1/interval(s))
%         pd.meanFreq2(T) = mean(pd.frequencies2{T}); % average frequency for each trial
%         %pd.trial2(T, 2) = pd.meanFreq2(T);
%         R.meanFreq2(T) = pd.meanFreq2(T);
% 
%         R.photodiodeFreq(T) = meanFreq;
% 
%         % --- Plot photodiode signal ---
%         
%         figure('Visible', 'off');
%         
%         subplot(2,1,1);
%         plot(t, y_smooth);
%         yline(threshold, 'r--', 'Threshold');
%         xlabel('Time (s)');
%         ylabel('Amplitude');
%         title(sprintf('Trial %d - Photodiode Signal (Raw)', T));
%         
%         subplot(2,1,2);
%         edgeTimes = pd.edgeTimes2{T};
%         frequencies = pd.frequencies2{T};
%         plot(edgeTimes(2:end), frequencies, '-o');
%         xlabel('Time (s)');
%         ylabel('Flicker Frequency (Hz)');
%         title(sprintf('Trial %d - Flicker Frequency (Mean: %.2f Hz)', T, pd.meanFreq2(T)));
%         %ylim([0 flickerHz*2]);
%         grid on;
%         
%         % --- Save plots ---
%         filename = fullfile(plotDir, sprintf('Trial_%03d_Photodiode.png', T));
%         saveas(gcf, filename);  % Save figure as PNG
%         close(gcf);  % Close figure to save memory
%     end

    save(fname_colour, 'R', 'E');       % save every trial
%     
%     catch ME
%         disp('Saving due to early exit or error');
%         save(fname_colour, 'R', 'E', 'pd');
%         
%         if exist('inLab', 'var') && (inLab == 2 || inLab == 3)
%             Eyelink('Message', 'Aborted');
%             Eyelink('StopRecording');
%             Eyelink('Shutdown');
%             PsychPortAudio('Close', pahandle);
%         end
%         
%         if (inLab == 1 || inLab == 3)
%             delete(instrfindall)
%         end
%         
% end


%% --- CHECK TIMINGS ---
% flipchecks2 = R.allframetimes2{1}; % number represents trial
% %
% % % plot(diff(flipchecks2.vbl1))
% % % ylabel('Frame duration (ms)')
% % % xlabel('Flip number')
% %
% %     %- % Check timing - can plot difference in timestamps
% %     %- plot(diff(flipchecks2.vbl1));
% %     %- plot(diff(flipchecks2.vbl2));
% %     %- % can also check all missed values are negative
% %     %- find(flipchecks2.missed1>0)
% %     %- find(flipchecks2.missed2>0)
% %
% % % Calculate intervals between consecutive flips of 0 phase stimulus
% durationsA2 = diff(flipchecks2.vbl1);
% 
% % Calculate flicker frequency (Hz)
% flickerFreq_colour = 1 / mean(durationsA2);
% 
% fprintf('Flicker frequency: %.2f Hz\n', flickerFreq_colour) % currently 7.30