%---------------------------------------
% Preprocessing of the raw dataset
% Author: Kay Liu
% https://github.com/KayLeonard/DRSleep
%---------------------------------------
% environment setup
if exist('dataset') == 0
    mkdir('dataset');
end
addpath('dataset');
if exist('lib') == 0
    mkdir('lib');
end
if exist('lib/eeglab') == 0
    system('wget https://github.com/sccn/eeglab/archive/refs/heads/eeglab2021.0.zip');
    system('unzip eeglab2021.0.zip');
    system('mv eeglab-eeglab2021.0 eeglab');
end
addpath('lib/eeglab');

% load data
sub_num = 25;
if ~isfile('dataset/files/ucddb002.rec')
    disp('Downloading dataset ...');
    system('curl -L https://physionet.org/static/published-projects/ucddb/st-vincents-university-hospital-university-college-dublin-sleep-apnea-database-1.0.0.zip -o  dataset/dataset.zip');
    system('unzip -o dataset/dataset.zip -d dataset');
end

data = cell(sub_num, 2); % number of files * number of channels
label = cell(sub_num, 1);
name_list = {'02', '03', '05', '06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28'};

for num = 1:sub_num
    fprintf('Processing (%d/25) file ...\n', num);

    % EEGLAB initialization
    eeglab nogui;

    % load dataset
    EEG = pop_biosig(strcat('dataset/files/ucddb0', name_list{num}, '.rec'), 'importevent', 'off','importannot', 'off');
    
    % load labels
    file = fopen(strcat('dataset/files/ucddb0', name_list{num}, '_stage.txt'), 'r');
    l = fscanf(file, '%d');
    fclose(file);
    
    % reject bad segment
    temp = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion','off','LineNoiseCriterion','off','Highpass','off','BurstCriterion',20,'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian','WindowCriterionTolerances',[-Inf 7]);
    mask = temp.etc.clean_sample_mask;
    
    % select EEG and ECG channels
    EEG = pop_select(EEG, 'channel', {'C3A2', 'ECG'});

    % remove DC offset of the data
    EEG = pop_rmbase(EEG, [], []);

    % filter the signal
    EEG.data(1, :) = bandpass(EEG.data(1, :), [0.3 35], 128);
    EEG.data(2, :) = highpass(EEG.data(2, :), 0.3, 128);
    
    % ica is not used due to inconsistency
    % divid into 30s epochs
    len = size(EEG.data, 2);
    label{num} = [];
    data{num} = [];
    
    t = 1;
    j = 1;
    jj = 1;
    while t <= (ceil(len/3840)-1)*3840
        % reject bad segments and 0s
        if sum(mask(t:t+3839)) >= 3800 && var(EEG.data(1, t:t+3839)) >= 1e-2
            data{num, 1} = [data{num, 1}; EEG.data(1, t:t+3839)];
            data{num, 2} = [data{num, 2}; EEG.data(2, t:t+3839)];
            t = t + 3840;
            if l(jj) <= 5
                label{num} = [label{num}; l(jj)];
            else
                label{num} = [label{num}; 0];
            end
            j = j + 1;
            jj = jj + 1;
        else
            t = t + 3840;
            jj = jj + 1;
        end
    end
end

for num = sub_num:-1:1
    if size(label{num}, 1) < 50
        label(num,:) = [];
        data(num,:) = [];
    end
end

save('dataset/preprocessed.mat', 'data', 'label');
