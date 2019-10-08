%% Initialize
clear; close all;
ieInit;

%% Load the data
load('edgeOIForConeMosaic_2.mat')

% Load corresponding cone mosaic
dataDir = ileFetchDir('hexMosaic');
cmFileName = fullfile(dataDir,...
    'theHexMosaic0.71degs.mat');
load(cmFileName);

saveDir = fullfile(isetlenseyeRootPath,'outputImages','coneMosaic');
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end

%% Absorbance
%{
wave = theHexMosaic.pigment.wave;
L = theHexMosaic.pigment.absorbance(:,1);
M = theHexMosaic.pigment.absorbance(:,2);
S = theHexMosaic.pigment.absorbance(:,3);

figure(); hold on; grid on;
plot(wave,S,'r');
plot(wave,M,'g');
plot(wave,L,'b');

peakS = wave((S == max(S)));
peakM = wave((M == max(M)));
peakL = wave((L == max(L)));
%}

%% Plot the edge over wavelength
%{
wave = oiGet(currOI,'wave');
photons = oiGet(currOI,'photons');

photonS = photons(:,:,wave == peakS);
photonM = photons(:,:,wave == peakM);
photonL = photons(:,:,wave == peakL);

[m,n] = size(photonS);
midI = round(m/2);

figure(); hold on; grid on;
plot(1:m,photonL(midI,:),'r');
plot(1:m,photonM(midI,:),'g');
plot(1:m,photonS(midI,:),'b');
%}

%% Calculate cone absorptions

% Apply lens transmittance
currOI = applyLensTransmittance(currOI,1.0);

% Show it
rgb = oiGet(currOI,'rgb');
imwrite(rgb,fullfile(saveDir,'rgbEdge.png'))

currOI = oiSet(currOI,'mean illuminance',5);

% For stray light and spontaneous opsin activation (suggested by NC)
theHexMosaic.coneDarkNoiseRate = [250 250 250];

theHexMosaic.compute(currOI);
theHexMosaic.window;

coneExcitations = theHexMosaic.absorptions;

% Use Nicolas' plotting code
coneMosaicActivationVisualize(theHexMosaic, coneExcitations,currOI,saveDir)

%% Add eye movements

em = fixationalEM;              % Instantiate a fixationalEM object
em.microSaccadeType = 'none';   % No microsaccades, just drift

duration = 0.25;   % 0.25 second duration
tStep = 0.01;    % time step: 1 msec
nTrials = 1;
theHexMosaic.integrationTime = tStep;
nEyeMovements = duration / tStep;
em.computeForConeMosaic(theHexMosaic, nEyeMovements, 'nTrials', nTrials);

theHexMosaic.emPositions = squeeze(em.emPos(1,:,:));

theHexMosaic.compute(currOI);

%% Rename variables to match Nicolas'
%{
timeAxis = em.timeAxis;
mosaicActivations = theHexMosaic.absorptions;
emPathsMicrons = em.emPosMicrons;
theMosaic = theHexMosaic;

videoFileName = fullfile(saveDir,'withEyeMovement.mp4');

%% From Nicolas
% Params for mosaic activation plotting
activationRange = prctile(mosaicActivations(:), 50+45*[-1.0 1.0]);
activationColorMap = gray(1024);

% Params for emPath plotting
micronsToArcMin = 60/theMosaic.micronsPerDegree;
emPathArcMin = emPathsMicrons*micronsToArcMin;
emRange = max(abs(emPathArcMin(:)))*[-1 1];
deltaEM = emRange(2)/3;
emTick = emRange(1):deltaEM:emRange(2);
emTickLabel = sprintf('%2.1f\n', emTick);

% Setup figure
hFig = figure(1); clf;
set(hFig, 'Position', [10 10 1100 620], 'Color', [1 1 1]);

% Setup subfig layout
subplotPosVectors = NicePlot.getSubPlotPosVectors(...
    'rowsNum', 1, ...
    'colsNum', 2, ...
    'heightMargin', 0.08, ...
    'widthMargin', 0.08, ...
    'leftMargin', 0.06, ...
    'rightMargin', 0.02, ...
    'bottomMargin', 0.1, ...
    'topMargin', 0.05);
mosaicAxes = subplot('Position', subplotPosVectors(1,1).v);
emAxes = subplot('Position', subplotPosVectors(1,2).v);

% Open video stream
videoOBJ = VideoWriter(videoFileName, 'MPEG-4'); % H264 format
videoOBJ.FrameRate = 20;
videoOBJ.Quality = 100;
videoOBJ.open();

% Which trial to visualize
visualizedTrial = 1;
sz = size(mosaicActivations); nTrials = 1; nCones = sz(1); nTimeBins = sz(3);

% Part of the mosaic to be visualized
visualizedMosaicRangeDegs = 0.5;
visualizedMosaicRange = 0.5*visualizedMosaicRangeDegs*[-1 1] * theMosaic.micronsPerDegree * 1e-6;

% Retrieve data for the visualized trial
theVisualizedActivation = squeeze(mosaicActivations(visualizedTrial, :, :));
theVisualizedEMPath = squeeze(emPathArcMin(visualizedTrial,:,:));

% Go through each time bin
for tBin = 1:nTimeBins
    % Render the instantaneous mosaic activation at this time bin
    theMosaic.renderActivationMap(mosaicAxes, theVisualizedActivation(:,tBin) , ...
        'visualizedConeAperture', 'geometricArea', ...
        'mapType', 'modulated disks', ...
        'signalRange', activationRange, ...
        'colorMap', activationColorMap, ...
        'outlineConesAlongHorizontalMeridian', ~true, ...
        'showXLabel', ~true, ...
        'showYLabel', ~true, ...
        'showXTicks', true, ...
        'showYTicks', true, ...
        'tickInc', 0.1, ...
        'backgroundColor', 0*[0.5 0.5 0.5]);
    % Set visible space
    set(mosaicAxes, 'XLim', visualizedMosaicRange, 'YLim', visualizedMosaicRange);
    
    % Labels
    xlabel(mosaicAxes, '\it space(degs)');
    title(mosaicAxes, 'mosaic activation', 'FontWeight', 'normal');
    
    % render the emPath up to this time point
    plot(emAxes, [-100 100], [0 0 ], 'k-'); hold(emAxes, 'on');
    plot(emAxes, [0 0 ], [-100 100], 'k-');
    plot(emAxes, theVisualizedEMPath(1:tBin,1), -theVisualizedEMPath(1:tBin,2), 'k-', 'LineWidth', 4.0);
    plot(emAxes, theVisualizedEMPath(1:tBin,1), -theVisualizedEMPath(1:tBin,2), 'r-', 'LineWidth', 2.0);
    plot(emAxes, theVisualizedEMPath(tBin,1), -theVisualizedEMPath(tBin,2), 'rs', 'LineWidth', 1.5, 'MarkerFaceColor', [1 0.5 0.5], 'MarkerSize', 12);
    hold(emAxes, 'off');
    set(emAxes, 'XLim', emRange, 'YLim', emRange, 'XTick', emTick, 'YTick', emTick, ...
        'XTickLabel', emTickLabel, 'YTickLabel', emTickLabel, 'FontSize', 18);
    grid(emAxes, 'on'); box(emAxes, 'off'); axis(emAxes, 'square');
    xlabel(emAxes, '\it position (arc min)');
    title(emAxes, sprintf('eye movement path (%2.0f ms)', timeAxis(tBin)*1000), 'FontWeight', 'normal');
    
    
    % Add another video frame
    drawnow;
    videoOBJ.writeVideo(getframe(hFig));
    
end % tBin

% Close the video stream
videoOBJ.close();
fprintf('File saved in %s\n', videoFileName);
%}

%%
function coneMosaicActivationVisualize(theMosaic, spatialActivationMap,oi,saveDir)

% determine plotting ranges and ticks
responseRange = prctile(spatialActivationMap(:), [1 99]);
spaceLimitsDegs = theMosaic.fov/2.*[-1 1]; %0.26*[-1 1];
spaceLimitsMeters = spaceLimitsDegs*theMosaic.micronsPerDegree * 1e-6;
tickDegs = (-1*round(theMosaic.fov/2,1)):0.2:(round(theMosaic.fov/2,1)); %-0.3:0.1:0.3;
tickMeters = tickDegs * theMosaic.micronsPerDegree * 1e-6;

% Start figure
%hFig = figure(); clf;
%set(hFig, 'Color', [1 1 1], 'Position', [10 10 1300 400]);

% Add the optical image
%     subplot(1,4,1);
oiFig = figure();
set(oiFig, 'Color', [1 1 1], 'Position', [10 10 400 400]);
rgb = oiGet(oi,'rgb');
imshow(rgb);
box on;
fn = fullfile(saveDir,'oiRGB.png');
NicePlot.exportFigToPNG(fn, gcf, 300);

% Visualize the cone mosaic
% axHandle = subplot(1,4,2);
figure();
set(gcf, 'Color', [1 1 1],'Position', [10 10 400 400]);
axHandle = gca;
theMosaic.visualizeGrid('axesHandle', axHandle, 'backgroundColor', [1 1 1]);
%     set(gca, 'XTick', tickMeters, 'XTickLabel', sprintf('%2.1f\n', tickDegs), ...
%         'YTick', tickMeters, 'YTickLabel', sprintf('%2.1f\n', tickDegs), ...
%         'XLim', spaceLimitsMeters, 'YLim', spaceLimitsMeters, ...
%         'FontSize', 14);
set(gca, 'XTick', tickMeters, 'XTickLabel', sprintf('%2.1f\n', tickDegs), ...
    'XLim', spaceLimitsMeters,...
    'FontSize', 24);
xlabel('\it space (degs)');
%     ylabel('\it space (degs)');
box on;
% title('cone mosaic');
fn = fullfile(saveDir,'coneMosaic.png');
NicePlot.exportFigToPNG(fn, gcf, 300);

% Visualize the 2D mosaic activation
% axHandle = subplot(1,4,3);
figure();
set(gcf, 'Color', [1 1 1],'Position', [10 10 500 400]);
axHandle = gca;
theMosaic.renderActivationMap(axHandle, spatialActivationMap, ...
    'mapType', 'modulated disks', ...
    'signalRange', responseRange, ...
    'showColorBar', true, ...
    'labelColorBarTicks',true,...
    'showYLabel', false, ...
    'showXLabel', false, ...
    'titleForColorBar', '',...
    'backgroundColor', [0 0 0]);
set(gca, 'XTick', tickMeters, 'XTickLabel', sprintf('%2.1f\n', tickDegs), ...
    'YTick', tickMeters, 'YTickLabel', {}, ...
    'XLim', spaceLimitsMeters, 'YLim', spaceLimitsMeters, ...
    'FontSize', 14);
xlabel('\it space (degs)');
ylabel('');
% title('cone mosaic response');
fn = fullfile(saveDir,'coneMosaicActivation.png');
NicePlot.exportFigToPNG(fn, gcf, 300);

% Find indices of cones along horizontal and vertical meridians
[indicesOfConesAlongXaxis, indicesOfConesAlongYaxis, ...
    xCoordsOfConesAlongXaxis, yCoordsOfConesAlongYaxis] = indicesForConesAlongMeridians(theMosaic);
identitiesOfConesAlongXaxis = theMosaic.pattern(indicesOfConesAlongXaxis);
identitiesOfConesAlongYaxis = theMosaic.pattern(indicesOfConesAlongYaxis);

% Visualize the mosaic activation along the horizontal meridian
%subplot(1,4,4);
figure();
set(gcf, 'Color', [1 1 1],'Position', [10 10 400 400]);
visualizeMosaicResponseAlongMeridian(...
    indicesOfConesAlongXaxis, ...
    identitiesOfConesAlongXaxis, ...
    xCoordsOfConesAlongXaxis, ...
    spatialActivationMap, ...
    tickDegs, spaceLimitsDegs, ...
    sprintf(''));
fn = fullfile(saveDir,'mosaicActivationHorizontal.png');
NicePlot.exportFigToPNG(fn, gcf, 300);

% Visualize the mosaic activation along the vertical meridian
%{
    subplot(1,4,4);
    visualizeMosaicResponseAlongMeridian(...
        indicesOfConesAlongYaxis, ...
        identitiesOfConesAlongYaxis, ...
        yCoordsOfConesAlongYaxis, ...
        spatialActivationMap, ...
        tickDegs, spaceLimitsDegs, ...
        sprintf('response of cones\nalong the vertical meridian'));
%}
end


function visualizeMosaicResponseAlongMeridian(...
    indicesOfConesAlongMeridian, identitiesOfConesAlongMeridian, ...
    coordsOfConesAlongMeridian, ...
    spatialActivationMap, tickDegs, spaceLimitsDegs, figureTitle)

hold on
% Retrieve the indices of L-, M- and S-cones along the vertical meridian
lConeIndices = find(identitiesOfConesAlongMeridian == 2);
mConeIndices = find(identitiesOfConesAlongMeridian == 3);
sConeIndices = find(identitiesOfConesAlongMeridian == 4);

% Drop the edge
lConeIndices = lConeIndices(1:(end-2));

plot(coordsOfConesAlongMeridian(lConeIndices), ...
    spatialActivationMap(indicesOfConesAlongMeridian(lConeIndices)), ...
    'ro', 'MarkerFaceColor', [1 0.5 0.5], 'MarkerSize', 8);
plot(coordsOfConesAlongMeridian(mConeIndices), ...
    spatialActivationMap(indicesOfConesAlongMeridian(mConeIndices)), ...
    'go', 'MarkerFaceColor', [0.5 1 0.5], 'MarkerSize', 8);
plot(coordsOfConesAlongMeridian(sConeIndices), ...
    spatialActivationMap(indicesOfConesAlongMeridian(sConeIndices)), ...
    'bo', 'MarkerFaceColor', [0.5 0.5 1], 'MarkerSize', 8);
box on;
set(gca, 'XTick', tickDegs, 'XTickLabel', sprintf('%2.1f\n', tickDegs), ...
    'XLim', spaceLimitsDegs, 'YLim',...
    [0 max(spatialActivationMap(indicesOfConesAlongMeridian(lConeIndices)))], ...
    'FontSize', 14);
box on; grid on
axis 'square'
xlabel('\it space (degs)');
ylabel('\it cone excitation');
title(figureTitle);
end

