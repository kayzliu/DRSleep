%--------------------------------------------
% Classification of sleep stages
% Author: Kay Liu
% https://github.com/KayLeonard/DRSleep
%--------------------------------------------
% Parameters
%--------------------------------------------
data_type = 1;
% 0: EEG+ECG
% 1: EEG
% 2: ECG

classification_type = 0;
% 0: 0,1,2,3,4,5 Six classes
% 1: 0,1-2-3-4-5 Two classes
% 2: 0,1,2-3-4-5 Three classes
% 3: 0,1,2-3,4-5 Four classes
% 4: m,n         Two specified classes

if classification_type == 4
    m = 0; % 1st specified class
    n = 1; % 2nd specified class
end

classifier_type = 2;
% 0: Linear Discriminant Analysis
% 1: Quadratic Discriminant Analysis
% 2: Support Vector Machine
% 3: K Nearest Neighbors
% 4: Naive Bayes
%--------------------------------------------
% Load data
%--------------------------------------------
if ~exist('features_pca', 'var') || isempty(features_pca)
    dimension_reduction;
end
%--------------------------------------------------------
% Conversion of classes according to classification type
%--------------------------------------------------------
% feature = features;
classes = label;
sub_num = size(feature, 1);
cm = zeros(6,6);

switch classification_type
    case 1
        %---- 0,1-2-3-4-5 Two classes
        for pp = 1:sub_num
            for ppp = 1:size(classes{pp}, 1)
                if classes{pp}(ppp) >= 1
                    classes{pp}(ppp) = 1;
                end
            end
        end
    case 2
        %---- 0,1,2-3-4-5 Three classes
        for pp = 1:sub_num
            for ppp = 1:size(classes{pp}, 1)
                if classes{pp}(ppp) >= 2
                    classes{pp}(ppp) = 2;
                end
            end
        end
    case 3
        %---- 0,1,2-3,4-5 Four classes
        for pp = 1:sub_num
            for ppp = 1:size(classes{pp}, 1)
                if classes{pp}(ppp) >= 2 && classes{pp}(ppp) <= 3
                    classes{pp}(ppp) = 2;
                elseif classes{pp}(ppp) >= 3
                    classes{pp}(ppp) = 3;
                end
            end
        end
    case 4
        %---- m,n Two specified classes
        tmp1 = [];
        tmp2 = [];
        for pp = 1:sub_num
            for ppp = 1:size(classes{pp}, 1)
                if classes{pp}(ppp) == m
                    tmp1 = [tmp1; feature(ppp,:)];
                    tmp2 = [tmp2; 0];
                elseif classes{pp}(ppp) == n
                    tmp1 = [tmp1; feature(ppp,:)];
                    tmp2 = [tmp2; 1];
                end
            end
        end
        feature = tmp1;
        classes = tmp2;
end
%--------------------------------------------
% Leave-one-out classification
%--------------------------------------------
tic
for kk = 1:sub_num
    % Testing data
    if data_type == 0
        data_testing = [feature{kk, 1} feature{kk, 2}];
    else
        data_testing = feature{kk, data_type};
    end
    classes_testing = classes{kk};
    % Training data
    data_training    = [];
    classes_training = [];
    
    for kkk = 1:sub_num
        if (kkk ~= kk)
            if data_type == 0
                data_training = [data_training; [feature{kkk, 1} feature{kkk, 2}]];
            else
                data_training = [data_training; feature{kkk, data_type}];
            end
            classes_training = [classes_training; classes{kkk}];
        end
    end
    %--------------------------------------
    % Classification of data of subject kk
    %--------------------------------------
    switch classifier_type
        case 0
            %0:   Linear Discriminant Analysis
            ob = fitcdiscr(data_training, classes_training, 'prior','uniform', 'discrimtype','pseudolinear');
        case 1
            %1:   Quadratic Discriminant Analysis
            ob = fitcdiscr(data_training, classes_training, 'prior','uniform', 'discrimtype','quadratic');
        case 2
            %2:   Support Vector Machine
            if classification_type == 1 || classification_type == 4
                ob = fitcsvm(data_training, classes_training);
            else
                ob = fitcecoc(data_training, classes_training);
            end
        case 3
            %3:   K Nearest Neighbors
            ob = fitcknn(data_training, classes_training);
        case 4
            %4:   Naive Bayes
            ob = fitcnb(data_training, classes_training);
    end          
    [ztest1, stest1] = predict(ob, data_testing);
    scores = stest1(:, 2);
    classes_estim = ztest1;
    %--------------------------------------------
    % Display results for subject kk
    %--------------------------------------------
    cp = classperf(classes_testing,classes_estim1);
    acc = round(cp.CorrectRate*100,2);
    disp(['suj ' num2str(kk) '   accuracy: ' num2str(acc)])
end
toc
