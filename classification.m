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
feature = features;
classes = label;
acc_sum = 0;

switch classification_type
    case 1
        %---- 0,1-2-3-4-5 Two classes
        for pp = 1:sub_num
            if classes(pp) >= 1
                classes(pp) = 1;
            end
        end
    case 2
        %---- 0,1,2-3-4-5 Three classes
        for pp = 1:sub_num
            if classes(pp) >= 2
                classes(pp) = 2;
            end
        end
    case 3
        %---- 0,1,2-3,4-5 Four classes
        for pp = 1:sub_num
            if classes(pp) >= 2 && classes(pp) <= 3
                classes(pp) = 2;
            elseif classes(pp) >= 3
                classes(pp) = 3;
            end
        end
    case 4
        %---- m,n Two specified classes
        tmp1 = [];
        tmp2 = [];
        for pp = 1:sub_num
            if classes(pp) == m
                tmp1 = [tmp1; feature(pp,:)];
                tmp2 = [tmp2; 0];
            elseif classes(pp) == n
                tmp1 = [tmp1; feature(pp,:)];
                tmp2 = [tmp2; 1];
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
    cp = classperf(classes_testing, classes_estim);
    acc = round(cp.CorrectRate*100,2);
    disp (['suj ' num2str(kk) '   accuracy: ' num2str(acc)])
    
    % Plot hypnogram
%     figure; plot(classes_testing+0.1, 'b.'); hold on; plot(classes_estim-0.1, 'r.');
%     axis([-10 760 -0.3 5.9]);
%     xlabel('Epochs');
%     yticklabels({'Wake','REM','S1','S2','S3','S4'});
%     legend('Real hypnogram', 'Estimated hypnogram');
%     title('NB');
    
    acc_sum = acc_sum + acc;
end

disp(['mean acc: ' num2str(acc_sum / sub_num)]);
toc