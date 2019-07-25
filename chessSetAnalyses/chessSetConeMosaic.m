%% chessSetConeMosaic.m
% Load up small FOV (~5 deg) version of the chess set optical image. Use it
% to make a video of cone excitations.

%% Initialize
ieInit;
clear; close all;

saveDir = fullfile(isetlenseyeRootPath,'outputImages','ChessSetConeMosaic');
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end

%% Load the data

dirName = 'chessSetSmallFOV'; % far data
dataDir = ileFetchDir(dirName);

load(fullfile(dataDir,'chessSet5deg.mat'));

% Crop it
oi = oiCropRetinaBorder(oi);

% Set to reasonable illuminance
oi = oiSet(oi,'mean illuminance',30);

% Take a look
ieAddObject(oi);
oiWindow;

%% Load the cone mosaic

dirName = 'hexMosaic'; % far data
dataDir = ileFetchDir(dirName);

load(fullfile(dataDir,'theHexMosaic3deg.mat'));
if(~exist('hexMosaic','var'))
    hexMosaic = theHexMosaic;
end

%% Compute cone excitations

% For stray light and spontaneous opsin activation (suggested by NC)
hexMosaic.coneDarkNoiseRate = [250 250 250];

hexMosaic.integrationTime = 0.005*0.5;

nEmSamples = 200;
totalTimeSampled = nEmSamples.*hexMosaic.integrationTime; 
hexMosaic.emGenSequence(100,'microsaccadetype','stats based');

hexMosaic.compute(oi);
hexMosaic.window;

% --- Try using a fixationalEM object --
%{
% fixational eye movements that include drift and microsaccades.
fixEMobj = fixationalEM();

% Generate microsaccades with a mean interval of  150 milliseconds
% Much more often than the default, just for video purposes.
fixEMobj.microSaccadeMeanIntervalSeconds = 0.05; % 0.150;

% Compute nTrials of emPaths for this mosaic
% Here we are fixing the random seed so as to reproduce identical eye
% movements whenever this script is run.
nTrials = 2;
trialLengthSecs = 0.05; %0.15;
eyeMovementsPerTrial = trialLengthSecs / hexMosaic.integrationTime;
fixEMobj.computeForConeMosaic(hexMosaic, eyeMovementsPerTrial, ...
    'nTrials', nTrials, 'rSeed', 857);

fixationalEM.generateEMandMosaicComboVideo(...
    fixEMobj, hexMosaic, ...
    'visualizedFOVdegs', 0.5, ...
    'showMovingMosaicOnSeparateSubFig', true, ...
    'displaycrosshairs', true);
%}
% ----------------------------------------

% Use Nicolas' plotting code
% coneMosaicActivationVisualize(hexMosaic,coneExcitations,oi,saveDir)