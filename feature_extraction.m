%-----------------------------------------------
% Feature extraction from the preprocessed data
% Author: Kay Liu
% https://github.com/KayLeonard/DRSleep
%-----------------------------------------------
addpath('dataset');

if ~exist('data', 'var') || isempty(data)
    try
        load('preprocessed.mat');
    catch
        preprocessing;
    end
end

fs = 128; % sample frequency (Hz)
sub_num = size(data,1);

features = cell(sub_num, 2);
for i = 1:sub_num
    % EEG
    X = data{i,1};
    len = size(data{i, 1}, 1);
    feature_eeg = zeros(len, 8);
    feature_eeg(:, 1) = zscore(bandpower(transpose(X), fs, [0, 4]));
    feature_eeg(:, 2) = zscore(bandpower(transpose(X), fs, [5, 7]));
    feature_eeg(:, 3) = zscore(bandpower(transpose(X), fs, [8, 12]));
    feature_eeg(:, 4) = zscore(bandpower(transpose(X), fs, [13, 15]));
    feature_eeg(:, 5) = zscore(bandpower(transpose(X), fs, [16, 30]));
    for j = 1:len
        feature_eeg(j,6) = std(X(j,:)) ^ 2;
        % First derivative
        x0  = X(j,:).';
        x1  = diff([0; x0]); 
        % Standard deviation 
        sd0 = std(x0); 
        sd1 = std(x1);
        feature_eeg(j,7) = sd1 / sd0;
        % First & second derivative
        x0  = X(j,:).';
        x1  = diff([0; x0]);
        x2  = diff([0; x1]);
        % Standard deviation of first & second derivative 
        sd0 = std(x0);
        sd1 = std(x1);
        sd2 = std(x2); 
        % Complexity
        feature_eeg(j,8) = (sd2 / sd1) / (sd1 / sd0);
    end
    features{i,1} = feature_eeg;
    
    % ECG
    X = data{i, 2};
    temp = arburg(X', 4);
    feature_eeg(:, 1:4) = temp(:, 2:5);
    
    feature_ecg = zeros(len, 8);
    features{i,2} = feature_ecg;
end

save('dataset/features.mat', 'features', 'label');