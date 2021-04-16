%--------------------------------------------
% Dimension reduction of feature vector
% Author: Kay Liu
% https://github.com/KayLeonard/DRSleep
%--------------------------------------------
% Parameters
%--------------------------------------------
num_comp_eeg = 2; %Number of components EEG
num_comp_ecg = 3; %Number of components ECG
weighted = 1;
%--------------------------------------------
% load data
%--------------------------------------------
addpath('dataset');

if ~exist('features', 'var') || isempty(features)
    try
        load('features.mat');
    catch
        feature_extraction;
    end
end
%--------------------------------------------
% PCA estimation
%--------------------------------------------
warning('off')
features_pca = {};
explained_eeg = [];
explained_ecg = [];
sub_num = size(features, 1);

for kk = 1:sub_num
    if weighted
        [~, score, ~, ~, explained, ~] = pca(features{kk, 1}, 'VariableWeights','variance');
    else
        [~, score, ~, ~, explained, ~] = pca(features{kk, 1});
    end
    explained_eeg = [explained_eeg; explained'];
    features_pca{kk, 1} = score(:, 1:num_comp_eeg);
    if weighted
        [~, score, ~, ~, explained, ~] = pca(features{kk, 2}, 'VariableWeights','variance');
    else
        [~, score, ~, ~, explained, ~] = pca(features{kk, 2});
    end
    explained_ecg = [explained_ecg; explained'];
    features_pca{kk, 2} = score(:, 1:num_comp_ecg);
end

%-------------------------------------------------------
% Estimate the explained variace for all the experiment
%-------------------------------------------------------
var_eeg = [];
var_ecg = [];
for kk = 1:sub_num
    var_eeg = [var_eeg; cumsum(explained_eeg(kk, 1:num_comp_eeg))];     
    var_ecg = [var_ecg; cumsum(explained_ecg(kk, 1:num_comp_ecg))];
end

disp (['mean of explained variance of EEG : ' num2str(mean(var_eeg(:, num_comp_eeg)))...
        '  ' num2str(num_comp_eeg) '/' num2str(size(features{1, 1}, 2)) ' components'])
disp (['mean of explained variance of ECG : ' num2str(mean(var_ecg(:, num_comp_ecg)))...
        '  ' num2str(num_comp_ecg) '/' num2str(size(features{1, 2}, 2)) ' components'])
warning('on')
