%% lcaExample.m
% Plot a scene that shows the effect of LCA in the retinal image. The scene
% consists of three letters at different distances. We accommodate the eye
% at each distance.

%% Initialize
ieInit;

%% Load the data
% We have two sets of data, one where the letters are placed at 1.8 1.2 0.6
% dpt.

accom = [1.8 1.2 0.6];
r_Azoom_px = [121   240    56    56];
r_Bzoom_px = [317   293    56    56];
r_Czoom_px = [560   335    56    56];

dirName = 'lcaExample_far'; % far data
dataDir = ileFetchDir(dirName);

if(strcmp(dirName,'lcaExample_far'))
    
    for ii = 1:length(accom)
        
        fullImages{ii} = load(fullfile(dataDir,...
            sprintf('lettersAtDepth_%0.2fdpt.mat',accom(ii))));
        
        % We've rendered the zoomed in rectangles defined above (e.g.
        % r_Azoom_px) with a higher resolution, so we'll load those directly
        % instead of cropping the full image.
        for jj = 1:3
            cropImages{ii,jj} = load(fullfile(dataDir,...
                sprintf('lettersAtDepth_%0.2fdpt_%i.mat',accom(ii),jj)));
            % Note: the angular support on these cropped optical images is
            % not correct. This is a bug that needs to be fixed; it wasn't
            % set correctly during rendering.
        end
        
        % Show the optical images
        % ieAddObject(fullImages{ii});
        % oiWindow;
        
    end
    
end

saveDir = fullfile(isetlenseyeRootPath,'outputImages','lca');
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end

%% Plot figures
%{
% Should be the same for all images
full_angSupport = fullImages{1}.scene3d.angularSupport;

% Convert the "rect" (e.g. from getrect) from pixels to angular units
[r_Azoom_deg, Azoom_x, Azoom_y] = convertRectPx2Ang(r_Azoom_px,full_angSupport);
[r_Bzoom_deg, Bzoom_x, Bzoom_y] = convertRectPx2Ang(r_Bzoom_px,full_angSupport);
[r_Czoom_deg, Czoom_x, Czoom_y] = convertRectPx2Ang(r_Czoom_px,full_angSupport);

% Put into vectors for looping purposes
r_zoom_inDeg = [r_Azoom_deg; r_Bzoom_deg; r_Czoom_deg];
r_zoom_angSupport_x = [Azoom_x; Bzoom_x; Czoom_x];
r_zoom_angSupport_y = [Azoom_y; Bzoom_y; Czoom_y];

fullFig = figure(); clf;
cropFig = figure(); clf;
fullImage = figure();

for ii = 1:length(accom)
    
    fullRGB = oiGet(fullImages{ii}.oi,'rgb');
    
    % Save the full image 
    figure(fullImage); clf;
    image(full_angSupport,full_angSupport,fullRGB);
    axis image; xlabel('degrees');
    rectangle('Position',r_Azoom_deg,'EdgeColor','r','LineWidth',4)
    rectangle('Position',r_Bzoom_deg,'EdgeColor','g','LineWidth',4)
    rectangle('Position',r_Czoom_deg,'EdgeColor','m','LineWidth',4)
    set(gca,'ytick',[]); % don't need y-axis for this one
    set(findall(gcf,'-property','FontSize'),'FontSize',16)
    fullImagefn = fullfile(saveDir,...
        sprintf('fullImage_%i.png',ii));
    saveas(fullImage,fullImagefn);
    
    % Save one with just the green box
    figure(fullImage); clf;
    image(full_angSupport,full_angSupport,fullRGB);
    axis image; xlabel('degrees');
    rectangle('Position',r_Bzoom_deg,'EdgeColor','g','LineWidth',4)
    set(gca,'ytick',[]); % don't need y-axis for this one
    set(findall(gcf,'-property','FontSize'),'FontSize',16)
    fullImagefn = fullfile(saveDir,...
        sprintf('fullImage_%i_onlyGreen.png',ii));
    saveas(fullImage,fullImagefn);
    
    rectColors = {'r','g','m'};
 
    for jj = 1:3
        
        cropRGB = oiGet(cropImages{ii,jj}.oi,'rgb');

        % We have to resample the angular support because when we rendered
        % with crop windows, we didn't set the angular support correctly.
        % This is kind of hack.
        curr_angSupport_x = r_zoom_angSupport_x(jj,:);
        x1 = linspace(0,1,length(curr_angSupport_x));
        x2 = linspace(0,1,size(cropRGB,2));
        curr_angSupport_x = interp1(x1,curr_angSupport_x,x2);
        
        curr_angSupport_y = r_zoom_angSupport_y(jj,:);
        y1 = linspace(0,1,length(curr_angSupport_y));
        y2 = linspace(0,1,size(cropRGB,1));
        curr_angSupport_y = interp1(y1,curr_angSupport_y,y2);
        
        % Save the cropped RGB images
        figure(cropFig); clf;
        image(curr_angSupport_x,curr_angSupport_y,cropRGB);
        rectangle('Position',r_zoom_inDeg(jj,:),...
            'EdgeColor',rectColors{jj},...
            'LineWidth',6)
        axis image; xlabel('degrees');
        set(findall(gcf,'-property','FontSize'),'FontSize',16)
        
        cropFigfn = fullfile(saveDir,...
            sprintf('cropRGB_%i_%i.png',ii,jj));
        saveas(cropFig,cropFigfn);
        
        % Save the angular support for use in the next section
        angSupportCropped_x{ii,jj} = curr_angSupport_x;
        angSupportCropped_y{ii,jj} = curr_angSupport_y;
        
    end
    
end
%}

%% Save the cropped angular support so we can just load it later
% save('angSupportCropped.mat','angSupportCropped_x','angSupportCropped_y');

%% Plot horizontal edge so that we can see the LCA effect more clearly
% TEMP
%{
for ii = 1:3 % over accommodation
    for jj = 2 % the "B"
        
        oi = cropImages{ii,jj}.oi;
        oi = oiSet(oi,'mean illuminance',10);
        
        rgb = oiGet(oi,'rgb');
        x = angSupportCropped_x{ii,jj};
        y = angSupportCropped_y{ii,jj};
        
        % Zoom in on the edge
        r = [130   225   200   200];
        % Convert rectangle to degrees
        [r_deg, x_edge, y_edge] = convertRectPx2Ang(r,[x; y]);
        
        oi_edge = oiCrop(oi,r);
        photons = oiGet(oi_edge,'photons');
        wave = oiGet(oi_edge,'wave');
        
        edgeFig = figure(); clf;
        hold on; grid on;
        
        % Pick out a couple of wavelengths
        wls = [450 500 550 600 650];
        color = {'b','c','g','y','r'}; % Corresponding approx for color
        for w = 1:length(wls)
            currPhotons = photons(round(r(2)/2),:,wave == wls(w));
            plot(x_edge,currPhotons,color{w});
        end
        axis([min(x_edge) max(x_edge) 0 11.5e14])
              
        % Increase font size and line width
        set(findall(gcf,'-property','FontSize'),'FontSize',18)
        set(findall(gca,'-property','LineWidth'),'LineWidth',3)
        
        xlabel('Position (deg)','FontSize',20);
        ylabel('Irradiance (q/s/m^2/nm)','FontSize',20)
        
        % Save the figure directly
        cropFigfn = fullfile(saveDir,...
            sprintf('edgePlot_%i.png',ii));
        saveas(edgeFig,cropFigfn);
        
    end
end
%}

%% Bring cropped images to the cone mosaic (rectangular)
%{
k = 1;
cmfig = figure();
for ii = 2 %1:3 % For each focus
    for jj = 1:3 % For each letter
        
        currAngSupport_x = angSupportCropped_x{ii,jj};
        currAngSupport_y = angSupportCropped_y{ii,jj};
        
        % Halve the image so we can see the individual cones better
        currOI = cropImages{ii,jj}.oi;
        sz = oiGet(currOI,'size');
        r = [round(sz(1)/4) round(sz(2)/4) round(sz(1)/2) round(sz(2)/2)];
        currOI = oiCrop(currOI,r);
        currRGB = oiGet(currOI,'rgb');
        % ieAddObject(currOI)
        % oiWindow;
        
        % Also halve the angular support
        [X, Y] = meshgrid(currAngSupport_x,currAngSupport_y);
        X = imcrop(X,r);
        Y = imcrop(Y,r);
        currAngSupport_x = X(1,:);
        currAngSupport_y = Y(:,1)';

        % Right now we use the on-axis cone mosaic, but maybe we can input
        % eccentricity somewhere?
        
        % Create the coneMosaic object
        cMosaic = coneMosaic;
        
        % Set size of the mosaic
        cMosaic.setSizeToFOV(oiGet(currOI, 'fov'));
        
        cMosaic.compute(currOI);
        cMosaic.window;
        
        cmAbsorptions = cMosaic.absorptions;
        
        % Plot OI in figure
        figure(cmfig);
        subplot(3,3,k); k = k +1;
        image(currAngSupport_x,...
            currAngSupport_y,...
            currRGB);
        axis image; xlabel('deg');
        
        % Plot cone mosaic in figure
        % These lines are mostly taken from coneMosaic.plot - I haven't
        % figured out the best way to use plot directly in a subplot. Need
        % to ask DB/BW.
        support = [4, 4];
        spread = 2;
        maxCones = 5e4;
        nCones = size(cMosaic.coneLocs, 1);
        locs = cMosaic.coneLocs;
        pattern = cMosaic.pattern(:);
        [uData.support, uData.spread, uData.delta, uData.mosaicImage] = ...
            conePlot(locs * 1e6, pattern, support, spread);
        subplot(3,3,k); k = k + 1;
        imagesc(uData.mosaicImage);
        axis off;
        axis image;
        
        % Plot cone absorptions in figure
        subplot(3,3,k); k = k + 1;
        imagesc(cmAbsorptions); colormap(gray); colorbar;
        title('Absorptions per integration time');
        axis image; axis off;
        
        % Increase font size
        set(findall(gcf,'-property','FontSize'),'FontSize',14)

         
    end
end
%}

%% Bring cropped images to the cone mosaic (hex)
% Since we can only do parafoveal region right now, only take the cropped
% image near the fovea.

load('angSupportCropped.mat');

k = 1;
cmfig = figure();
for ii = 2 %1:3 % For each focus
    for jj = 2 % For each letter
        
        currAngSupport_x = angSupportCropped_x{ii,jj};
        currAngSupport_y = angSupportCropped_y{ii,jj};
        
        currOI = cropImages{ii,jj}.oi;
        
        % Halve the image so we can see the individual cones better
        %sz = oiGet(currOI,'size');
        %r = [round(sz(1)/4) round(sz(2)/4) round(sz(1)/2) round(sz(2)/2)];
        %currOI = oiCrop(currOI,r);
        
        currRGB = oiGet(currOI,'rgb');
        % ieAddObject(currOI)
        % oiWindow;
        
        % Also halve the angular support
        %{
        [X, Y] = meshgrid(currAngSupport_x,currAngSupport_y);
        X = imcrop(X,r);
        Y = imcrop(Y,r);
        currAngSupport_x = X(1,:);
        currAngSupport_y = Y(:,1)';
        
        rgb = oiGet(currOI,'rgb');
        figure();
        image(currAngSupport_x,currAngSupport_y,rgb);
        set(findall(gcf,'-property','FontSize'),'FontSize',14)
        axis image;
        xlabel('\it space (degs)')
        ylabel('\it space (degs)')
        
        % Save the figure
        fn = fullfile(saveDir,...
            sprintf('coneMosaicRGB_%i_%i.tif',ii,jj));
        saveas(gcf,fn);
        %}
        
        % Right now we use the on-axis cone mosaic, but maybe we can input
        % eccentricity somewhere?
        
        fov = oiGet(currOI, 'fov');
        
        % Load corresponding cone mosaic
        dataDir = ileFetchDir('hexMosaic');
        cmFileName = fullfile(dataDir,...
            'theHexMosaic0.71degs.mat');
        load(cmFileName);
        
        %theHexMosaic.setSizeToFOV(0.5*oiGet(currOI, 'fov'));
        theHexMosaic.compute(currOI);
        theHexMosaic.window;
        
        coneExcitations = theHexMosaic.absorptions;
        
        % Use Nicolas' plotting code
        coneMosaicActivationVisualize(theHexMosaic, coneExcitations,currOI)
        
        % Save the figure
         fn = fullfile(saveDir,...
             sprintf('coneMosaic_%i_%i.png',ii,jj));
%         saveas(gcf,fn);
        NicePlot.exportFigToPNG(fn, gcf, 300); 
        
        %{
        
        % Plot OI in figure
        figure();
        H = image(currAngSupport_x,...
            currAngSupport_y,...
            currRGB);
        axis image; xlabel('deg');
        
        % Increase font size
        set(findall(gcf,'-property','FontSize'),'FontSize',14)
        
        % Save figure individually
        fn = fullfile(isetlenseyeRootPath,'outputImages',...
            sprintf('LCA_cropped_%i_%i.png',ii,jj));
        saveas(H,fn);
        
        theHexMosaic.window;
        %}
        
        % Plot cone mosaic in figure
        % These lines are mostly taken from coneMosaic.plot - I haven't
        % figured out the best way to use plot directly in a subplot. Need
        % to ask DB/BW.
        %{
        support = [4, 4];
        spread = 2;
        maxCones = 5e4;
        nCones = size(cMosaic.coneLocs, 1);
        locs = cMosaic.coneLocs;
        pattern = cMosaic.pattern(:);
        [uData.support, uData.spread, uData.delta, uData.mosaicImage] = ...
            conePlot(locs * 1e6, pattern, support, spread);
        subplot(3,3,k); k = k + 1;
        imagesc(uData.mosaicImage);
        axis off;
        axis image;
        %}
        
        % Plot cone absorptions in figure
        %{
        subplot(3,2,k); k = k + 1;
        imagesc(cmAbsorptions); colormap(gray); colorbar;
        title('Absorptions per integration time');
        axis image; axis off;
        %}
        
        
        
    end
end

%% 

function coneMosaicActivationVisualize(theMosaic, spatialActivationMap,oi)
    
    % determine plotting ranges and ticks
    responseRange = prctile(spatialActivationMap(:), [1 99]);
    spaceLimitsDegs = theMosaic.fov/2.*[-1 1]; %0.26*[-1 1];
    spaceLimitsMeters = spaceLimitsDegs*theMosaic.micronsPerDegree * 1e-6;
    tickDegs = (-1*round(theMosaic.fov/2,1)):0.1:(round(theMosaic.fov/2,1)); %-0.3:0.1:0.3;
    tickMeters = tickDegs * theMosaic.micronsPerDegree * 1e-6;
    
    % Start figure
    hFig = figure(); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [10 10 1300 400]);
    
    % Add the optical image
    subplot(1,4,1);
    rgb = oiGet(oi,'rgb');
    imshow(rgb);
    box on;
    
    % Visualize the cone mosaic
    axHandle = subplot(1,4,2);
    theMosaic.visualizeGrid('axesHandle', axHandle, 'backgroundColor', [1 1 1]);
    set(gca, 'XTick', tickMeters, 'XTickLabel', sprintf('%2.1f\n', tickDegs), ...
        'YTick', tickMeters, 'YTickLabel', sprintf('%2.1f\n', tickDegs), ...
        'XLim', spaceLimitsMeters, 'YLim', spaceLimitsMeters, ...
        'FontSize', 14);
    xlabel('\it space (degs)');
    ylabel('\it space (degs)');
    box on;
    % title('cone mosaic');
    
    % Visualize the 2D mosaic activation
    axHandle = subplot(1,4,3);
    theMosaic.renderActivationMap(axHandle, spatialActivationMap, ...
                'mapType', 'modulated disks', ...
                'signalRange', responseRange, ...
                'showColorBar', false, ...
                'showYLabel', false, ...
                'showXLabel', false, ...
                'titleForColorBar', 'R*/cone/tau',...
                'backgroundColor', [0 0 0]);
    set(gca, 'XTick', tickMeters, 'XTickLabel', sprintf('%2.1f\n', tickDegs), ...
             'YTick', tickMeters, 'YTickLabel', {}, ...
             'XLim', spaceLimitsMeters, 'YLim', spaceLimitsMeters, ...
             'FontSize', 14);
    xlabel('\it space (degs)');
    ylabel('');
    % title('cone mosaic response');
    
    % Find indices of cones along horizontal and vertical meridians
    [indicesOfConesAlongXaxis, indicesOfConesAlongYaxis, ...
        xCoordsOfConesAlongXaxis, yCoordsOfConesAlongYaxis] = indicesForConesAlongMeridians(theMosaic);
    identitiesOfConesAlongXaxis = theMosaic.pattern(indicesOfConesAlongXaxis);
    identitiesOfConesAlongYaxis = theMosaic.pattern(indicesOfConesAlongYaxis);
    
    % Visualize the mosaic activation along the horizontal meridian
    subplot(1,4,4);
    visualizeMosaicResponseAlongMeridian(...
        indicesOfConesAlongXaxis, ...
        identitiesOfConesAlongXaxis, ...
        xCoordsOfConesAlongXaxis, ...
        spatialActivationMap, ...
        tickDegs, spaceLimitsDegs, ...
        sprintf(''));
    
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