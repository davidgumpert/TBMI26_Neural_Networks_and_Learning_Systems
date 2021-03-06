%% Hyper-parameters

% Number of randomized Haar-features
nbrHaarFeatures = 200;
% Number of training images, will be evenly split between faces and
% non-faces. (Should be even.)
nbrTrainImages = 700;
% Number of weak classifiers
nbrWeakClassifiers = 50;

%% Load face and non-face data and plot a few examples
load faces;
load nonfaces;
faces = double(faces(:,:,randperm(size(faces,3))));
nonfaces = double(nonfaces(:,:,randperm(size(nonfaces,3))));

figure(1);
colormap gray;
for k=1:25
    subplot(5,5,k), imagesc(faces(:,:,10*k));
    axis image;
    axis off;
end

figure(2);
colormap gray;
for k=1:25
    subplot(5,5,k), imagesc(nonfaces(:,:,10*k));
    axis image;
    axis off;
end

%% Generate Haar feature masks
haarFeatureMasks = GenerateHaarFeatureMasks(nbrHaarFeatures);

figure(3);
colormap gray;
for k = 1:25
    subplot(5,5,k),imagesc(haarFeatureMasks(:,:,k),[-1 2]);
    axis image;
    axis off;
end

%% Create image sets (do not modify!)

% Create a training data set with examples from both classes.
% Non-faces = class label y=-1, faces = class label y=1
trainImages = cat(3,faces(:,:,1:nbrTrainImages/2),nonfaces(:,:,1:nbrTrainImages/2));
xTrain = ExtractHaarFeatures(trainImages,haarFeatureMasks);
yTrain = [ones(1,nbrTrainImages/2), -ones(1,nbrTrainImages/2)];

% Create a test data set, using the rest of the faces and non-faces.
testImages  = cat(3,faces(:,:,(nbrTrainImages/2+1):end),...
                    nonfaces(:,:,(nbrTrainImages/2+1):end));
xTest = ExtractHaarFeatures(testImages,haarFeatureMasks);
yTest = [ones(1,size(faces,3)-nbrTrainImages/2), -ones(1,size(nonfaces,3)-nbrTrainImages/2)];

% Variable for the number of test-data.
nbrTestImages = length(yTest);

%% Implement the AdaBoost training here
%  Use your implementation of WeakClassifier and WeakClassifierError
T = ones(nbrWeakClassifiers, 1);
P = ones(nbrWeakClassifiers, 1);
D = ones(nbrTrainImages, 1)/nbrTrainImages;
a = ones(nbrWeakClassifiers, 1);
har = ones(nbrWeakClassifiers, 1);
best_error_ARR = ones(nbrWeakClassifiers, nbrHaarFeatures);
for i = 1:nbrWeakClassifiers
    T_har = ones(nbrHaarFeatures, 1);
    best_error = 10000;
    for r = 1:nbrHaarFeatures
        best_error_har = 10000;
        P_har = 1;
        for e = 1:nbrTrainImages
            C = WeakClassifier(xTrain(r, e), P_har, xTrain(r, :));
            E = WeakClassifierError(C, D, yTrain);
            if E > 0.5
                C = WeakClassifier(xTrain(r, e), -P_har, xTrain(r, :));
                E = WeakClassifierError(C, D, yTrain);
                if E < best_error_har
                    P_har = -P_har;
                    T_har(r) = xTrain(r , e);
                    best_error_har = E;
                    P_har_arr(r) = P_har;
                end
            else
                if E < best_error_har
                    T_har(r) = xTrain(r , e);
                    best_error_har = E;
                    P_har_arr(r) = P_har;
                end
            end
        end
        best_error_ARR(i, r) = best_error_har;
        if best_error_har < best_error
            best_error = best_error_har;
            har(i) = r;
            T(i) = T_har(r);
            P(i) = P_har_arr(r);
        end
    end
    C = WeakClassifier(T(i), P(i), xTrain(har(i), :));
    best_error_aft =  WeakClassifierError(C, D, yTrain);
    a(i) = log((1-best_error)/best_error)/2;
    for w = 1:nbrTrainImages
        if C(w) == yTrain(w)
            D(w) = D(w)*exp(-a(i));
        else
            D(w) = D(w)*exp(a(i));
        end
    end
    D = D/sum(D);
    
end



%% Evaluate your strong classifier here
%  Evaluate on both the training data and test data, but only the test
%  accuracy can be used as a performance metric since the training accuracy
%  is biased.
C_all_train = zeros(nbrWeakClassifiers, nbrTrainImages);
C_all_test = zeros(nbrWeakClassifiers, nbrTestImages);
for i = 1:nbrWeakClassifiers
    C_all_train(i, :) = a(i)*WeakClassifier(T(i), P(i), xTrain(har(i), :));
    C_all_test(i, :) = a(i)*WeakClassifier(T(i), P(i), xTest(har(i), :));    
end

ones_train = ones(1, nbrWeakClassifiers);


test_C =  sign(ones_train*C_all_test);
train_C = sign(ones_train*C_all_train);

D_test = ones(nbrTestImages, 1)/nbrTestImages;
D_train = ones(nbrTrainImages, 1)/nbrTrainImages;

strong_error_test = WeakClassifierError(test_C, D_test, yTest)
strong_error_train = WeakClassifierError(train_C, D_train, yTrain)


%% Plot the error of the strong classifier as a function of the number of weak classifiers.
%  Note: you can find this error without re-training with a different
%  number of weak classifiers.
for q = 1:nbrWeakClassifiers
    C_all_train = zeros(nbrWeakClassifiers, nbrTrainImages);
    C_all_test = zeros(nbrWeakClassifiers, nbrTestImages);
    for i = 1:nbrWeakClassifiers-q
        C_all_train(i, :) = a(i)*WeakClassifier(T(i), P(i), xTrain(har(i), :));
        C_all_test(i, :) = a(i)*WeakClassifier(T(i), P(i), xTest(har(i), :));    
    end

    ones_train = ones(1, nbrWeakClassifiers);


    test_C =  sign(ones_train*C_all_test);
    train_C = sign(ones_train*C_all_train);

    D_test = ones(nbrTestImages, 1)/nbrTestImages;
    D_train = ones(nbrTrainImages, 1)/nbrTrainImages;

    strong_error_test(q) = WeakClassifierError(test_C, D_test, yTest);
    strong_error_train(q) = WeakClassifierError(train_C, D_train, yTrain);
end
figure(4);
plot(strong_error_test);
hold on
plot(strong_error_train);
xlabel('number of weak classifiers');
ylabel('accuracy')
legend('test accuracy', 'train accuracy');
%% Plot some of the misclassified faces and non-faces
%  Use the subplot command to make nice figures with multiple images.

for i = 1:nbrWeakClassifiers-q
    C_all_train(i, :) = a(i)*WeakClassifier(T(i), P(i), xTrain(har(i), :));
    C_all_test(i, :) = a(i)*WeakClassifier(T(i), P(i), xTest(har(i), :));
end

ones_train = ones(1, nbrWeakClassifiers);

test_C =  sign(ones_train*C_all_test);

wrong_classified_faces = zeros(24, 24, 25);
wrong_classified_non_faces = zeros(24, 24, 25);
count_faces = 1;
count_non_faces = 1;
for q = 1:nbrTestImages
    if test_C(q) ~= yTest(q)
        if yTest(q) == 1
            wrong_classified_faces(:, :, count_faces) = testImages(:, :, q);
            count_faces = count_faces + 1;
        else
            wrong_classified_non_faces(:, :, count_non_faces) = testImages(:, :, q);
            count_non_faces = count_non_faces + 1;
        end
        
    end
end

figure(1);
colormap gray;
for k=1:25
    subplot(5,5,k), imagesc(wrong_classified_faces(:, :, k));
    axis image;
    axis off;
end

figure(2);
colormap gray;
for k=1:25
    subplot(5,5,k), imagesc(wrong_classified_non_faces(:, :, k));
    axis image;
    axis off;
end

%% Plot your choosen Haar-features
%  Use the subplot command to make nice figures with multiple images.
har_fetures = unique(har);
figure(5);
for k = 1:min(length(har_fetures), 25)
    subplot(5,5,k),imagesc(haarFeatureMasks(:,:,har_fetures(k)),[-1 2]);
    axis image;
    axis off;
end

