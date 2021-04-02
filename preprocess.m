%---------------------------------------
% Preprocessing of the raw dataset
% Author: Kay Liu
% https://github.com/KayLeonard/DRSleep
%---------------------------------------

addpath(genpath('dataset'));
addpath('lib/eeglab');

data = cell(25, 3);
label = cell(25);
for num = 1:25
    fprintf('Processing (%d/25) file ...\n', num);
    % load dataset
    EEG = pop_biosig(strcat('dataset/raw/', int2str(num), '.rec'), 'importevent', 'off','importannot', 'off');
    
    % select EEG and ECG channels
    EEG = pop_select(EEG, 'channel', {'C3A2', 'C4A1', 'ECG'});

    % remove DC offset of the data
    EEG = pop_rmbase(EEG, [], []);

    % filter the signal
    EEG = pop_eegfiltnew(EEG, 'locutoff', 0.3, 'hicutoff', 35, 'channels', {'C3A2','C4A1'});
    EEG = pop_eegfiltnew(EEG, 'locutoff', 0.3, 'channels', {'ECG'});

    % divid into 30s epochs
    for i = 1:3
        len = size(EEG.data, 2);
        data{num, i} = zeros(ceil(len/3840), 3840);
        t = 1;
        j = 1;
        while t <= len
            for k = 1:3840
                data{num, i}(j, k) = EEG.data(i, t);
                t = t + 1;
                if t > len
                    break
                end
            end
            j = j + 1;
        end
    end
    % load labels
    file = fopen(strcat('dataset/raw/', int2str(num), '.txt'), 'r');
    label{num} = fscanf(file, '%d');
    fclose(file);
end

save('dataset/preprocessed.mat', 'data', 'label');
