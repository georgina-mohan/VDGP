% VDGP - EEG PRE-PROCESSING SCRIPT
% Author: Georgina Mohan
% Date: 11/03/2026
%
% Pipeline:
% 1. Filter
% 2. Epoch
% 3. Channel rejection
% 4. Epoch rejection
% 5. Re-reference
% 6. ICA
% 7. Interpolate bad channels (epoch-by-epoch)
% 8. FFT
%
% Notes:
% - for ANT system (.cnt files)
% - uses EEGLAB, ICLabel, TBT master, and freqtag toolbox

clear all
close all

%% import data
% set current directory
cd 'C:\Users\gxm449\OneDrive - University of Birmingham\VDGP\Data\Raw\EEG';

ID = input('\nSubject ID? ', 's'); % participant ID number 
dataPath = ['C:\Users\gxm449\OneDrive - University of Birmingham\VDGP\Data\Raw\EEG\VDGP_' ID '.cnt']; % where EEG files will be extracted from

% import EEG
EEG = pop_loadeep_v4(dataPath);

%% channels
EEG = pop_chanedit(EEG, 'lookup','standard_1005.elc'); % add channel locs

%% filter
EEG = pop_eegfiltnew(EEG, 'locutoff', 0.01); % high pass
EEG = pop_eegfiltnew(EEG, 'hicutoff', 30); % low pass

% add notch filter (45 - 55 Hz) **differs from pre-reg**
EEG = pop_eegfiltnew(EEG, 'locutoff', 45, 'hicutoff', 55, 'revfilt', 1);

%% epoch 
% epoch all photodiode triggers
EEG = pop_epoch(EEG, ...
    {  '1'  }, ... 
    [-.5  5], ...
    'newname', 'EEProbe continuous data epochs', ...
    'epochinfo', 'yes');

% identify trigger which corresponds with start of trial
c = 0;
trial = [];

for k = 1:size(EEG.epoch,2) % loop through each epoch (number of columns)
    % reminder: each epoch was between -.5 and 5, but flickering stimuli should produce epochs every 0.1389s, meaning there should be several
    if length(EEG.epoch(k).eventlatency) > 10 % if the epoch has more than three events - remember
        if cell2mat(EEG.epoch(k).eventlatency(1)) == 0 % if the start of the epoch is 0, that is no 1's before it we assume it's the start of our trial
            c = c + 1; % counter
            trial(c) = k; % trial holds all the 'events'  that are the start of your epoch
        end
    end
end

% re-epoch for trials only (rather than each phototiode trigger)
% trial index the EEG.epoch which signals the start of the trial
% take the 1st event inside EEG.epoch and convert from 1 -> 2, and then reepoch
% convert the first trigger of each trial to "2"
for i = 1:length(trial)
    EEG.event(EEG.epoch(trial(i)).event(1)).type = '2';
end

% re-epoch using new trial marker
EEG = pop_epoch(EEG, ...
    {  '2'  }, ... % 2 is the start of the trial!
    [-.5  5], ...
    'newname', 'EEProbe continuous data epochs', ...
    'epochinfo', 'yes');

% plot
EEG = eeg_checkset( EEG );
pop_eegplot(EEG, 1, 1, 1);

%% match epoch to stimulus condition
% so far, the photodiode triggers show the start of each trial but we don't know what stimulus condition was shown. 
% will load the behavioural rating files and use them to assign the condition to the epoch (important for FFT later)

% load & order behavioural data
cd 'C:\Users\gxm449\OneDrive - University of Birmingham\VDGP\Data\Raw\Ratings'; % change directory
colour   = readtable(fullfile('Colour',   [ID '_Colour_.csv'])); % import data
contrast = readtable(fullfile('Contrast', [ID '_Contrast_.csv'])); 
colour   = colour(:,   [4 7]); % keep relevant info only (condition & rating)
contrast = contrast(:, [4 7]);

% merge behavioural datasets in correct order
isEven = mod(ID, 2) == 0;
if isEven % order counterbalanced depending on participantID
    ratings = [contrast; colour];
else 
    ratings = [colour; contrast];
end

% remove trials with no behavioural response
ratings(isnan(ratings.Rating), :) = []; 
ratings.TrialNumber = (1:height(ratings))'; % also adding a trial number so I know which trials are removed after cleaning

% match condition to EEG epochs
for i = 1:height(ratings)
    EEG.epoch(i).eventtype{1} = num2str(ratings.Trigger(i));
    j = EEG.epoch(i).event(1);
    EEG.event(j).type = num2str(ratings.Trigger(i));
end

%% channel rejection
% using a stricter high-pass filter (1 Hz) to identify bad channels to reject from original dataset

% temp version with higher stricter high-pass filter
EEG2 = pop_eegfiltnew(EEG, 'locutoff', 1);

EEG2.data = double(EEG2.data); 
[nChan, nSamples] = size(EEG2.data);

thresh = 30; % µV threshold
pctCutoff = 10; % max % of samples allowed above threshold

% calc % of samples over threshold (per channel)
pctAbove = zeros(nChan,1); % preallocate
for ch = 1:nChan
    pctAbove(ch) = sum(abs(EEG2.data(ch,:)) > thresh) ...
                   / nSamples * 100;
end

% find bad channels
badChanIdx = find(pctAbove > pctCutoff);
badChanLabels = {EEG2.chanlocs(badChanIdx).labels};

% summary of noisiest channels
[sortedPct, idx] = sort(pctAbove, 'descend');
fprintf('\nTop channels by %% of samples > %d µV:\n', thresh);
for k = 1:min(10, nChan)
    fprintf('%s: %.2f%%\n', EEG2.chanlocs(idx(k)).labels, sortedPct(k));
end

% remove bad channels
if ~isempty(badChanLabels)
    EEG2 = pop_select(EEG2, 'nochannel', badChanLabels);
    EEG = pop_select(EEG, 'nochannel', badChanLabels);
end

%% reject very noisy epochs 
% using a stricter high-pass filter (1 Hz) to identify bad epochs (+/- 200 µV) to reject epochs from original dataset

% identify bad epochs on filtered data
EEG2 = pop_eegthresh(EEG2, 1, 1:EEG2.nbchan, -200, 200, 0, 5, 0, 1); % reject epochs

% save which epochs are rejected
badEpochs = find(EEG2.reject.rejthresh);

% reject epochs
if ~isempty(badEpochs)
    EEG2 = pop_rejepoch(EEG2, badEpochs, 0);
    EEG = pop_rejepoch(EEG, badEpochs, 0);
end

%% re-reference
% Add back in reference channel (Cz)
EEG = pop_chanedit(EEG, ...
    'insert', EEG.nbchan + 1, ...
    'changefield', {EEG.nbchan + 1,'labels','Cz'}, ...
    'lookup', 'standard_1005.elc');

if EEG.nbchan == 32 % will throw error if no channels were removed during pre-processing
    EEG = pop_reref(EEG, []);
else
    % re-reference to common average
    EEG = pop_reref( EEG, [],'refloc',struct('labels',{'Cz'},'type',{''},'theta',{177.4959},'radius',{0.029055},'X',{-9.167},'Y',{-0.4009},'Z',{100.244},'sph_theta',{-177.4959},'sph_phi',{84.77},'sph_radius',{100.6631},'urchan',{2},'ref',{''},'datachan',{0}));
end

%% ICA
% temporary high-pass filter (1 Hz) for ICA (following EEGlab guidelines)

EEG3 = pop_eegfiltnew(EEG, 'locutoff', 1); % using a more stringent high-pass filter = better quality ICA
 
EEG3 = pop_runica(EEG3, ... 
    'icatype', 'runica', ...
    'extended', 1);

%% clean ICA
% Using a semi-automatic approach
% 1. scalp topograpy and time course
% 2. ICLabel to classify components

% scalp topogragy
pop_topoplot(EEG3, 0, 1:20, 'IC Maps', []);

% time course
pop_eegplot(EEG3, 0, 1, 1:20); 
pop_viewprops(EEG3, 0, 1:18, ...
    {'freqrange', [2 50]});

% IClabel:
EEG3 = pop_iclabel(EEG3, 'default'); % flags components (1 = brain; 2 = muscle; 3 = eye; 4 = heart; 5 = line noise; 6 = other)

% find components with more than 90% probability of being an artifact
artifactComponents = find(...
    EEG3.etc.ic_classification.ICLabel.classifications(:,2) > 0.9 | ... 
    EEG3.etc.ic_classification.ICLabel.classifications(:,3) > 0.9 | ... 
    EEG3.etc.ic_classification.ICLabel.classifications(:,4) > 0.9 | ... 
    EEG3.etc.ic_classification.ICLabel.classifications(:,5) > 0.9 | ... 
    EEG3.etc.ic_classification.ICLabel.classifications(:,6) > 0.9);     
fprintf('Identified %d bad ICs: %s\n', length(artifactComponents), mat2str(artifactComponents));

% remove components (based on scalp topogragy, time course and ICLabel) 
badComponents = input('Enter components to remove (e.g., [1 3 5]): ');

% apply ICA weights onto original EEG
EEG.icawinv = EEG3.icawinv;
EEG.icasphere = EEG3.icasphere;
EEG.icaweights = EEG3.icaweights;
EEG.icachansind = EEG3.icachansind;

% remove components from original dataset
EEG = pop_subcomp(EEG, badComponents, 0);

%% reject/interpolate bad channels (epoch-by-epoch)

% temp high-pass filter
EEG4 = pop_eegfiltnew(EEG, 'locutoff', 1);

% min-max method:
% flags bad channels within each epoch where amplitude difference is larger than 75 uV
EEG4 = pop_eegmaxmin(EEG4, ...
    'minmaxThresh', '75', ...
    'timeRange', [0  4998] ...
        );

EEG.reject = EEG4.reject;

% trial-by-trial rejection/interpolation (based on flagged channels above)
EEG = pop_TBT(EEG, ...
    EEG.reject.rejmaxminE, ...
    4, ... % max number of bad channel per epoch/trial. If a trial has move than this number of bad channels, the epoch will be removed
    0.3, ... % max % bad epochs/trials per channel. If a channel is bad on more than this percent of the trials, the channel will be removed across the whole dataset.
    0); 

%% save
EEG = pop_saveset(EEG, ...
    'filename', sprintf('%s_cleaned.set', ID),...
    'filepath', 'C:\Users\gxm449\OneDrive - University of Birmingham\VDGP\Data\Processed\cleanedDatasets');

%% extract occipital
EEG = pop_select(EEG, 'channel', {'O1', 'O2'}); 

%% FFT 
triggerlabels = {'10', '11', '12', '14', '18', '20', '21', '22', '24', '28', '30', '31', '32', '34', '38', '41', '42', '43', '44', '51', '52', '53', '54', '61', '62', '63', '64'};

stimFreq = 14.4; % flicker freq in Hz
fs = 500; % sampling rate of EEG

% extract event codes for each epoch
ntrials = size(EEG.data, 3);
events = zeros(1, ntrials);

for i = 1:ntrials
    evt = EEG.epoch(i).eventtype;
    if iscell(evt)
        evt = evt{1};
    end
    events(i) = str2double(evt);
end

%% FREQUENCY RESOLUTION
epoch = 4.8; % full epoch 5.5s, removing 700ms (500ms pre-stimulus, and 200ms for onset)
% calculated based on epoch duration (1/epoch duration(s)
freqres = 1/epoch; % = 0.2083 Hz

% Nyguist Theorem - frequencies up to half the sampling rate are meaningful in EEG time series data
half_fs = fs/2; % 500Hz/2 = 250 Hz

% Between 0 and 250 Hz, in steps of 0.2083 Hz (the frequency resolution)
axis = half_fs / freqres; % 250 Hz / 0.2083 = 1200
% or:
faxisall = 0:freqres:half_fs; % (0 : 1/epoch duration [frequency resolution] : sampling rate/2)
% faxisall = vector from 0 to 250 Hz, in 0.2083 steps (1201 frequency bins)

% SAMPLING RATE
% 1 sample point = 2ms (recording at 500Hz)
% start at 700ms after epoch:
startSamp = 0.7 * fs + 1; % 351 start sample rate (or 700ms)
endSamp = 5.5 * fs; % 5s * fs (500 Hz) = 2750 end sample rate (or 5500ms)

%% --- FREQTAG_FFT (AVERAGE AMPLITUDE & SNR) ---
% Input 2D matrix (channels x time)
% Gets average spectrum per channel

ampmatrix = nan(1, length(triggerlabels));
SNRdb_matrix = nan(1, length(triggerlabels));

for cond = 1:length(triggerlabels) 

    % Select trigger number
    trigger = str2double(triggerlabels{cond});

    % Select only data with the selected trigger
    data = EEG.data(:, :, find(events==trigger));

    % Time-domain average
    ERP = mean(data, 3); % calculate the time domain average across trials (3rd dimension)

    % SSVEP segment
    data_ssvep = data(:, startSamp:endSamp, :); 

    avg_data = mean(data_ssvep, 3); % [channels x time] - averaged across trials

    % FFT
    [amp, phase, freqs, fftcomp] = freqtag_FFT(avg_data, fs);
    [~, f1] = min(abs(freqs - stimFreq));

    % Extract amplitude and SNR
    amp_F1 = mean(amp(:, f1)); % average across O1 and O2
    ampmatrix(cond) = amp_F1; % extracting amp per condition

    [SNRdb, SNRratio] = freqtag_simpleSNR(amp, [f1-3, f1-2, f1+2, f1+3]);
    SNRdb_matrix(cond) = mean(SNRdb(:, f1));

    close all
end

% plot
meanAmpAll = mean(amp, 1);   % average across epochs
figure, plot(freqs, mean(meanAmpAll,1))
xlabel('Frequency (Hz)'), ylabel('Amplitude (μV)')
title('FFT spectrum')

%% save
participantID = repmat({ID}, length(triggerlabels), 1); 
conditionTrigger = str2double(string(triggerlabels))';
EEGAverage = table(participantID, conditionTrigger, ampmatrix', SNRdb_matrix',...
    'VariableNames', {'Participant', 'Trigger', 'Amplitude', 'SNR'});

savePath = 'C:\Users\gxm449\OneDrive - University of Birmingham\VDGP\Data\Processed\EEG\';
writetable(EEGAverage, fullfile(savePath, [ID '_average.xlsx']));