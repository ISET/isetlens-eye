%% plotEyeModelComparison.m
% Load three images from three different schematic eye models. Plot them
% for the paper.

%% Initialize
clear; close all;
ieInit;

saveDir = fullfile(isetlenseyeRootPath,'outputImages','eyeModels');
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end

%% Load the data

dirName = 'eyeModelComparison_5deg'; 
dataDir = ileFetchDir(dirName);

% Arizona eye
load(fullfile(dataDir,'arizona.mat'));
oiArizona = oi;
xArizona = scene3d.angularSupport;

% Le Grand eye
load(fullfile(dataDir,'LeGrand.mat'));
oiLeGrand = oi;
xLeGrand = scene3d.angularSupport;

% Arizona eye
load(fullfile(dataDir,'navarro.mat'));
oiNavarro = oi;
xNavarro = scene3d.angularSupport;

%% Apply lens transmittance

oiArizona = applyLensTransmittance(oiArizona,1.0);
oiLeGrand = applyLensTransmittance(oiLeGrand,1.0);
oiNavarro = applyLensTransmittance(oiNavarro,1.0);

%% Save RGB images of the three optical images

fontSize = 20;

rgbArizona = oiGet(oiArizona,'rgb');
rgbGullstrand = oiGet(oiLeGrand,'rgb');
rgbNavarro = oiGet(oiNavarro,'rgb');

% Better axes labels this way
xArizona(1) = round(xArizona(1),1);
xLeGrand(1) = round(xLeGrand(1),1);
xNavarro(1) = round(xNavarro(1),1);

% Plot and save
H1 = plotWithAngularSupport(xArizona,xArizona,rgbArizona,...
    'axesSelect','xaxis','FontSize',30);
NicePlot.exportFigToPNG(fullfile(saveDir,'arizona.png'),H1,300)

H2 = plotWithAngularSupport(xLeGrand,xLeGrand,rgbGullstrand,...
    'axesSelect','xaxis','FontSize',30);
NicePlot.exportFigToPNG(fullfile(saveDir,'gullstrand.png'),H2,300)

H3 = plotWithAngularSupport(xNavarro,xNavarro,rgbNavarro,...
    'axesSelect','xaxis','FontSize',30);
NicePlot.exportFigToPNG(fullfile(saveDir,'navarro.png'),H3,300)



