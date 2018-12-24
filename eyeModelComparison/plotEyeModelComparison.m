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

% Gullstrand eye
load(fullfile(dataDir,'gullstrand.mat'));
oiGullstrand = oi;
xGullstrand = scene3d.angularSupport;

% Arizona eye
load(fullfile(dataDir,'navarro.mat'));
oiNavarro = oi;
xNavarro = scene3d.angularSupport;

%% Save RGB images of the three optical images

fontSize = 20;

rgbArizona = oiGet(oiArizona,'rgb');
rgbGullstrand = oiGet(oiGullstrand,'rgb');
rgbNavarro = oiGet(oiNavarro,'rgb');

% Plot and save
H1 = figure(1); clf;
image(xArizona,xArizona,rgbArizona);
axis image;
ax = gca;
ax.FontSize = fontSize; 
set(ax,'ytick',[])
xlabel('degrees','FontSize',fontSize);
saveas(H1,fullfile(saveDir,'arizona.pdf'))

H2 = figure(2); clf;
image(xGullstrand,xGullstrand,rgbGullstrand);
axis image;
ax = gca;
ax.FontSize = fontSize; 
set(ax,'ytick',[])
xlabel('degrees','FontSize',fontSize);
saveas(H2,fullfile(saveDir,'gullstrand.pdf'))

H3 = figure(3); clf;
image(xNavarro,xNavarro,rgbNavarro);
axis image;
ax = gca;
ax.FontSize = fontSize; 
set(ax,'ytick',[])
xlabel('degrees','FontSize',fontSize);
saveas(H3,fullfile(saveDir,'navarro.pdf'))



