%% chessSetOverhead.m
% Load up the overhead view of the chessboard. Save out images at different
% wavelengths. Primarily for the overview figure in the paper.

%% Initialize
ieInit;
clear; close all;

%% Load the data

dirName = 'chessSetOverhead'; % far data
dataDir = ileFetchDir(dirName);

load(fullfile(dataDir,'chessSetOverhead.mat'));

% Take a look
ieAddObject(oi);
oiWindow;

%% Save RGB images

outputDir = fullfile(isetlenseyeRootPath,'outputImages');
if(~exist(outputDir,'dir'))
    mkdir(outputDir);
end

photons = oiGet(oi,'photons');
wave = oiGet(oi,'wave');

rgb = oiGet(oi,'rgb');
imwrite(rgb,fullfile(outputDir,'chessSetOverhead_RGB.png'));

% Save a couple of wavelengths
wls = [450 510 550 640];
for ii = 1:length(wls)
    currPhotons = photons(:,:,wave == wls(ii));
    currPhotons = currPhotons./max(currPhotons(:));
    currRGB = repmat(currPhotons,[1 1 3]);
    imwrite(currRGB,fullfile(outputDir,...
        sprintf('chessSetOverhead_%inm.png',wls(ii))));
end

%% Load/save the second version (with different materials)

load(fullfile(dataDir,'chessSetOverhead-2.mat'));

% Take a look
ieAddObject(oi);
oiWindow;

photons = oiGet(oi,'photons');
wave = oiGet(oi,'wave');

rgb = oiGet(oi,'rgb');
imwrite(rgb,fullfile(outputDir,'chessSetOverhead2_RGB.png'));
