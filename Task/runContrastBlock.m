function [R] = runContrastBlock(R, E, window, windowRect, keys, fname_contrast, xCenter, yCenter, ST, imtextures, angle, sigma, black, greyBW, white, ncycles, flickerTimeFrames, ifi, allValues, inLab, port_handle, pahandle, dRectM, rect, interest, el)
%% Georgina Mohan 
% 18/09/2025
% SPIN Lab 
%
% 28/10/2025 update: adding in GetSecs 
%% --- PREVIEW INSTRUCTIONS ---
HideCursor(window);
Screen('FillRect', window, greyBW);
InstructionTxt = 'You are about to begin the black and white section, where the patterns will all be black and white. When you press SPACE, we will first show you examples of what these patterns look like.';
DrawFormattedText(window, InstructionTxt, 'center', 'center', white, 60);
Screen('Flip', window);
RestrictKeysForKbCheck(keys.space);
[secs, keyCode, deltaSecs] = KbStrokeWait;

previewtrials = Shuffle(allValues,2);

for trial = 1:length(previewtrials)
    Screen('DrawTexture', window, imtextures{trial}, [], [], angle);
    Screen('Flip', window);
    WaitSecs(1);

    % grey screen inbetween
    Screen('FillRect', window, greyBW);
    Screen('Flip', window);
    WaitSecs(0.5);
end

%% --- INSTRUCTIONS FOR MAIN TASK ---
Screen('FillRect', window, greyBW);
ExperimentStartTxt = 'In the main task, these patterns will flicker, and you will rate how uncomfortable they are on a scale from 0 (not uncomfortable) to 100 (extremely uncomfortable). \n \n Please keep your eyes on the fixation dot in the middle of the screen while the flickering image is on the screen. \n \n When you are ready, please press SPACE to begin.';
DrawFormattedText(window, ExperimentStartTxt,  'center', 'center', white, 60);
Screen('Flip', window);
RestrictKeysForKbCheck(keys.space);
[secs, keyCode, deltaSecs] = KbStrokeWait;

%% --- RUN CONTRAST TASK ---
blockcomplete = 0;
R.response = NaN(1, E.ntrials);
R.rt = NaN(1, E.ntrials);
R.pause = NaN(1, E.ntrials);
R.meanFreq = NaN(1, E.ntrials);
R.eventTime = NaN(1, E.ntrials);

% photodiode rectangle
rectSize = 50; % 50 x 50 pixel square
[screenXpixels, screenYpixels] = Screen('WindowSize', window); % get size of screen - don't think i need this
cornerRect = [screenXpixels - rectSize - 20, 20, screenXpixels - 20, 20 + rectSize];  % add to top right corner

HideCursor(window);

greyBWEyeTracker = [greyBW, greyBW, greyBW];

% try

    for T = 1:E.ntrials
        trigger = R.trialrand(T, 3);
        sf = R.trialrand(T, 1);
        contrast = R.trialrand(T, 2);

        % Progress update
        if T== 30+1 || T == 60+1 || T == 90+1 || T == 120+1 || T == 150+1 % for 10 repetitions
        % if T== 15+1 || T == 30+1 || T == 45+1 || T == 60+1 || T == 75+1 % for 5 repetitions
            blockcomplete = blockcomplete + 1;
            DrawFormattedText(window, ['Well done! You have completed ' num2str(blockcomplete) ' blocks out of ' num2str(E.blocks) '. \n Please take a break. Press the space bar when you are ready to continue'],  'center', 'center', white, 60);

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
                Eyelink('command', 'background_color = %d %d %d', greyBWEyeTracker(1), greyBWEyeTracker(2), greyBWEyeTracker(3));
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
            Eyelink('Message', 'BLOCK %d', blockcomplete); % block number
            WaitSecs(0.001); % Allow some time between messages. Some messages can be lost if too many are written at the same time
            Eyelink('Message', '!V TRIAL_VAR TRIALID %d', T); % trial number
            WaitSecs(0.001);
            Eyelink('Message', '!V TRIAL_VAR SF %s', sprintf('%.3f', sf)); % SF
            WaitSecs(0.001);
            Eyelink('Message', '!V TRIAL_VAR Contrast %s', sprintf('%.3f', contrast)); % contrast
            WaitSecs(0.001);
            Eyelink('Message', '!V TRIAL_VAR Trigger %d', trigger); % trigger
            WaitSecs(0.001);
            Eyelink('command', 'record_status_message "TRIAL %d/%d"', T, E.ntrials); % send status message to host PC to show current trial out of total, e.g., "TRIAL 5/60"

            Eyelink('Command', 'set_idle_mode'); % draw to eyetracker display
            Eyelink('Command', 'clear_screen %d', 0); % clear tracker display with black screen

            % Draw stimulus locations onto eye tracker display - NEW
            Eyelink('Command', 'draw_cross %d %d 15', xCenter, yCenter); % fixation cross coordinates
            Eyelink('Command', 'draw_box %d %d %d %d 15', dRectM(1), dRectM(2), dRectM(3), dRectM(4)); % stimuli coordinates - eyelink doesn't have a draw circle option, so have drawn a box around it instead

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

        % -- FIXATION POINT --
        Screen('Flip', window);
        Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2);
        Screen('Flip', window);

        if inLab == 2 || inLab == 3
            Eyelink('Message', 'FixOn');
        end

        WaitSecs(ST.ITI);
        [vbl] = Screen('Flip', window);

        flipchecks.vbl1 = []; % when first vbl begins
        flipchecks.vbl2 = []; % when first vbl begins
        flipchecks.missed1 = []; % how late flip was compared to requested time. Positive number = frame was missed. Negative or zero is ideal
        flipchecks.missed2 = [];
        flipchecks.fliptsp1 = []; %* should be close to vbl unless something has delayed the flip
        flipchecks.fliptsp2 = [];

        tic

%         % -- PHOTODIODE RECORDING: START --
%         recObj = audiorecorder(pd.fs, 16, 1, pd.deviceID); 
%         record(recObj);

        for cycle = 1:ncycles % for each cycle of the stimulus - could change "flip" to "cycle" (just to make it easier to understand?)

            Screen('DrawTexture', window, imtextures{T, 1}, [], [], angle, [], [], [], [], [], double([0, R.trialrand(T, 1), R.trialrand(T, 2), sigma]));
            Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2);
            Screen('FillRect', window, white, cornerRect); % flickering square for photodiode
            [vbl, ~, FlipTimestamp, Missed, ~] = Screen('Flip', window, vbl + flickerTimeFrames * ifi - 0.5*ifi);
            %Screen('DrawTexture', window, masktex, [], dRectM); % do I need this?


            if cycle == 1
                R.eventTime(T) = GetSecs;
                if inLab == 1 || inLab == 3
                    trigger_val = R.trialrand(T, 3); % (T, 3) = stimulus label
                    send_ns_trigger(trigger_val, port_handle);
                end
                if inLab == 2 || inLab == 3
                    Eyelink('Message', 'StimOn');
                end
            end

            % if (inLab == 1 || inLab == 3) && cycle == 1
            %     trigger_val = R.trialrand(T, 3); % (T, 3) = stimulus label
            %     send_ns_trigger(trigger_val, port_handle);
            % elseif inLab == 2 || inLab == 3
            %     Eyelink('Message', 'StimOn');
            % end

            flipchecks.vbl1(cycle) = vbl;
            flipchecks.missed1(cycle) = Missed;
            flipchecks.fliptsp1(cycle) = FlipTimestamp;

            Screen('DrawTexture', window, imtextures{T, 2}, [], [], angle, [], [], [], [], [], double([180, R.trialrand(T, 1), R.trialrand(T, 2), sigma]));
            Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2);
            Screen('FillRect', window, black, cornerRect); % photodiode measurement
            [vbl, ~, FlipTimestamp, Missed, ~] = Screen('Flip', window, vbl+ flickerTimeFrames * ifi - 0.5*ifi);

            flipchecks.vbl2(cycle) = vbl;
            flipchecks.missed2(cycle) = Missed;
            flipchecks.fliptsp2(cycle) = FlipTimestamp;

            RestrictKeysForKbCheck([keys.pause, keys.esc]);
            [keyIsDown, secs, keyCode] = KbCheck;
            keyPress = find(keyCode);

            % -- CHECK KEYS -- 
            % PAUSE
            if keyPress == keys.pause
                Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2); % Show fixation during pause
                Screen('Flip',window);
                R.pause(T) = 1;
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
                R.allframetimes{T} = flipchecks; %store flipchecks into R before exiting
                resp = NaN;
                rt = NaN;
                R.response(T) = resp; % save rating
                R.rt(T) = rt; % save response time
                save(fname_contrast, 'R', 'E'); % save data to workspace
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

%         % -- PHOTODIODE RECORDING: STOP --
%         stop(recObj);
%         y = getaudiodata(recObj); 
%         pd.photodiodeRaw{T} = y;

        toc % - can do this to check you have stimulus duration you expect

        if inLab == 1 || inLab == 3
            trigger_val = 100 + R.trialrand(T, 3);
            send_ns_trigger(trigger_val, port_handle);
        end
        if inLab == 2 || inLab == 3
            Eyelink('Message', 'StimOff');
        end

        if inLab == 2 || inLab == 3
            Eyelink('StopRecording');
            Eyelink('Message', 'TRIAL_RESULT 0');
        end

        % Screen('Close', imtextures{T, 1});
        % Screen('Close', imtextures{T, 2});

        R.allframetimes{T} = flipchecks;

        % Get stimulus rating
        [resp, rt] = hb_scaleResponse_VAS(window, windowRect, 1, white, black, greyBW, rect); % Continuous scale (0 - 100)

        HideCursor(window);

        R.response(T) = resp; % save rating
        R.rt(T) = rt; % save response time
    end

    % -- PHOTODIODE: EXTRACT MEASUREMENTS --
    % 
    % -- Create folder --
%     plotDir = fullfile(pwd, 'photodiode_contrast_plots', E.IDstr); % Create save folder in current directory
%     if ~exist(plotDir, 'dir')
%         mkdir(plotDir);
%     end

%     % --- Loop to extract photodiode measurements and calc frequency ---
%     for T = 1:E.ntrials
%         y = pd.photodiodeRaw{T};
% 
%         y = y - mean(y);  % Remove DC
%         y_smooth = movmean(y, 200);  % Smooth to reduce noise
% 
%         % % if you want to trim (first cycle is sometimes off): 
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
%         pd.binarySignal{T} = y_smooth > threshold; % binary "black/white", 1 when signal > threshold (white), and 0 when signal < threshold (black)
%         binarySignal = pd.binarySignal{T}; 
% 
%         pd.risingEdges{T} = find(diff(binarySignal) == 1); % indicies (photodiode sample) of when binary signal goes from 0 - 1, or the rising edge (from black to white)
%         risingEdges = pd.risingEdges{T};
%         pd.edgeTimes{T} = risingEdges / pd.fs; % when the rising edge occured: indicies relative to sampling rate of photodiode, therefore converting into time points
% 
%         % --- Calculate frequency ---
%         pd.intervals{T} = diff(pd.edgeTimes{T}); % time intervals between each flicker (white -> white)
%         pd.frequencies{T} = 1 ./ pd.intervals{T}; % calculates frequency (freq = 1/interval(s))
%         pd.meanFreq(T) = mean(pd.frequencies{T}); % average frequency for each trial
%         %pd.trial(T, 2) = pd.meanFreq(T);
%         R.meanFreq(T) = pd.meanFreq(T);
% 
%         % R.photodiodeFreq(T) = meanFreq;
% 
%         % --- Plot photodiode signal ---
%         %
%         % figure('Visible', 'off');
%         % 
%         % subplot(2,1,1);
%         % plot(t, y_smooth);
%         % yline(threshold, 'r--', 'Threshold'); 
%         % xlabel('Time (s)');
%         % ylabel('Amplitude');
%         % title(sprintf('Trial %d - Photodiode Signal (Raw)', T));
%         % 
%         % subplot(2,1,2);
%         % edgeTimes = pd.edgeTimes{T};
%         % frequencies = pd.frequencies{T};
%         % plot(edgeTimes(2:end), frequencies, '-o');
%         % xlabel('Time (s)');
%         % ylabel('Flicker Frequency (Hz)');
%         % title(sprintf('Trial %d - Flicker Frequency (Mean: %.2f Hz)', T, pd.meanFreq(T)));
%         % %ylim([0 flickerHz*2]);
%         % grid on;
%         % 
%         % % --- Save plots ---
%         % filename = fullfile(plotDir, sprintf('Trial_%03d_Photodiode.png', T));
%         % saveas(gcf, filename);  % Save figure as PNG
%         % close(gcf);  % Close figure to save memory
%     end

    save(fname_contrast, 'R', 'E');       % save every trial


% catch ME
%     disp('Saving due to early exit or error');
%     save(fname_contrast, 'R', 'E', 'pd');
% 
%     if exist('inLab', 'var') && (inLab == 2 || inLab == 3)
%         Eyelink('Message', 'Aborted');
%         Eyelink('StopRecording');
%         Eyelink('Shutdown');
%         PsychPortAudio('Close', pahandle);
%     end
% 
%     if (inLab == 1 || inLab == 3)
%         delete(instrfindall)
%     end
% end

%% --- CHECK TIMINGS ---

% flipchecks = R.allframetimes{2}; % number represents trial
% % % %
% plot(diff(flipchecks.vbl1))
% ylabel('Frame duration (ms)')
% xlabel('Flip number')
% % % %
% % % %     - % Check timing - can plot difference in timestamps
% % % %     - plot(diff(flipchecks.vbl1));
% % % %     - plot(diff(flipchecks.vbl2));
% % % %     - % can also check all missed values are negative
% find(flipchecks.missed1>0)
% % % %     - find(flipchecks.missed2>0)
% % %
% % % % Calculate intervals between consecutive flips of 0 phase stimulus
% durationsA = diff(flipchecks.vbl1);
% % %
% % % % Calculate flicker frequency (Hz)
% flickerFreq_contrast = 1 / mean(durationsA);
% % %
% fprintf('Flicker frequency: %.2f Hz\n', flickerFreq_contrast) % currently 7.30