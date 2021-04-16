%-----------------------------------------------------------------------
% (DRSleep) Dimension Reduction Methods Applied in Sleep Stage Analysis
% Author: Zekuan Liu
% https://github.com/KayLeonard/DRSleep
%-----------------------------------------------------------------------
disp('Preprocessing the data ...');
preprocessing;

disp('Extracting the feature ...');
feature_extraction;

disp('Reducing dimension ...');
dimension_reduction;

disp('Classifying');
classification;