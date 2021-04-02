%-----------------------------------------------
% Feature extraction from the preprocessed data
% Author: Kay Liu
% https://github.com/KayLeonard/DRSleep
%-----------------------------------------------
if ~exist('data', 'var') || isempty(data)
    try
        load('preprocessed.mat');
    catch
        preprocess;
    end
end

my_feat1 = zeros(749,3);
my_feat1(:,1) = features_sub{1}(:,8);
opts.fs = 128;
for i = 1:749
my_feat1(i,3) = jfeeg('hc', block2(i,:), opts);
end
my_feat1(:,2) = my_feat1(:,3) - my_feat1(:,1);