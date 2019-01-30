function plotCodeForTrisha
    load('testDataForTrisha.mat', 'theMosaic', 'coneExcitations', 'coneExcitations90');
    trialNo = 1;
    coneMosaicActivationVisualize(theMosaic, squeeze(coneExcitations(trialNo,:,:)));
    coneMosaicActivationVisualize(theMosaic, squeeze(coneExcitations90(trialNo,:,:)));
end

function coneMosaicActivationVisualize(theMosaic, spatialActivationMap)
    
    % determine plotting ranges and ticks
    responseRange = prctile(spatialActivationMap(:), [1 99]);
    spaceLimitsDegs = 0.26*[-1 1];
    spaceLimitsMeters = spaceLimitsDegs*theMosaic.micronsPerDegree * 1e-6;
    tickDegs = -0.3:0.1:0.3;
    tickMeters = tickDegs * theMosaic.micronsPerDegree * 1e-6;
    
    % Start figure
    hFig = figure(); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [10 10 1530 345]);
    
    % Visualize the cone mosaic
    axHandle = subplot(1,4,1);
    theMosaic.visualizeGrid('axesHandle', axHandle, 'backgroundColor', [1 1 1]);
    set(gca, 'XTick', tickMeters, 'XTickLabel', sprintf('%2.1f\n', tickDegs), ...
             'YTick', tickMeters, 'YTickLabel', sprintf('%2.1f\n', tickDegs), ...
             'XLim', spaceLimitsMeters, 'YLim', spaceLimitsMeters, ...
             'FontSize', 14);
    xlabel('\it space (degs)');
    ylabel('\it space (degs)');
    box on;
    title('cone mosaic');
    
    % Visualize the 2D mosaic activation
    axHandle = subplot(1,4,2);
    theMosaic.renderActivationMap(axHandle, spatialActivationMap, ...
                'mapType', 'modulated disks', ...
                'signalRange', responseRange, ...
                'showColorBar', false, ...
                'showYLabel', false, ...
                'showXLabel', false, ...
                'titleForColorBar', 'R*/cone/tau');
    set(gca, 'XTick', tickMeters, 'XTickLabel', sprintf('%2.1f\n', tickDegs), ...
             'YTick', tickMeters, 'YTickLabel', {}, ...
             'XLim', spaceLimitsMeters, 'YLim', spaceLimitsMeters, ...
             'FontSize', 14);
    xlabel('\it space (degs)');
    ylabel('');
    title('cone mosaic response');
    
    
    % Find indices of cones along horizontal and vertical meridians
    [indicesOfConesAlongXaxis, indicesOfConesAlongYaxis, ...
        xCoordsOfConesAlongXaxis, yCoordsOfConesAlongYaxis] = indicesForConesAlongMeridians(theMosaic);
    identitiesOfConesAlongXaxis = theMosaic.pattern(indicesOfConesAlongXaxis);
    identitiesOfConesAlongYaxis = theMosaic.pattern(indicesOfConesAlongYaxis);
    
    % Visualize the mosaic activation along the horizontal meridian
    subplot(1,4,3);
    visualizeMosaicResponseAlongMeridian(...
        indicesOfConesAlongXaxis, ...
        identitiesOfConesAlongXaxis, ...
        xCoordsOfConesAlongXaxis, ...
        spatialActivationMap, ...
        tickDegs, spaceLimitsDegs, ...
        sprintf('response of cones\nalong the horizontal meridian'));
    
    % Visualize the mosaic activation along the vertical meridian
    subplot(1,4,4);
    visualizeMosaicResponseAlongMeridian(...
        indicesOfConesAlongYaxis, ...
        identitiesOfConesAlongYaxis, ...
        yCoordsOfConesAlongYaxis, ...
        spatialActivationMap, ...
        tickDegs, spaceLimitsDegs, ...
        sprintf('response of cones\nalong the vertical meridian'));
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
             'XLim', spaceLimitsDegs, 'YLim', [0 max(spatialActivationMap(:))*1.2], ...
             'FontSize', 14);
    box on; grid on
    axis 'square'
    xlabel('\it space (degs)');
    title(figureTitle);
end
