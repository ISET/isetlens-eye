%% Initialize
clear; close all;
ieInit;

%% Load the data
load('edgeOIForConeMosaic.mat')

% Load corresponding cone mosaic
dataDir = ileFetchDir('hexMosaic');
cmFileName = fullfile(dataDir,...
    'theHexMosaic0.71degs.mat');
load(cmFileName);

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

currOI = oiSet(currOI,'mean illuminance',5);

theHexMosaic.compute(currOI);
theHexMosaic.window;

coneExcitations = theHexMosaic.absorptions;

% Use Nicolas' plotting code
coneMosaicActivationVisualize(theHexMosaic, coneExcitations,currOI)
        
%% 
function coneMosaicActivationVisualize(theMosaic, spatialActivationMap,oi)
    
saveDir = fullfile(isetlenseyeRootPath,'outputImages','coneMosaic');
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end

    % determine plotting ranges and ticks
    responseRange = prctile(spatialActivationMap(:), [1 99]);
    spaceLimitsDegs = theMosaic.fov/2.*[-1 1]; %0.26*[-1 1];
    spaceLimitsMeters = spaceLimitsDegs*theMosaic.micronsPerDegree * 1e-6;
    tickDegs = (-1*round(theMosaic.fov/2,1)):0.1:(round(theMosaic.fov/2,1)); %-0.3:0.1:0.3;
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
        'FontSize', 14);
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

