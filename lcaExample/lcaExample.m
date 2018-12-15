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

%% Put figure together
% Each row is a different focus/accommodation. Each column is a different
% zoomed in portion fo the scene.

% Should be the same for all images
full_angSupport = fullImages{1}.scene3d.angularSupport;

[r_Azoom_deg, Azoom_x, Azoom_y] = convertRectPx2Ang(r_Azoom_px,full_angSupport);
[r_Bzoom_deg, Bzoom_x, Bzoom_y] = convertRectPx2Ang(r_Bzoom_px,full_angSupport);
[r_Czoom_deg, Czoom_x, Czoom_y] = convertRectPx2Ang(r_Czoom_px,full_angSupport);
r_zoom_inDeg = [r_Azoom_deg; r_Bzoom_deg; r_Czoom_deg];
r_zoom_angSupport_x = [Azoom_x; Bzoom_x; Czoom_x];
r_zoom_angSupport_y = [Azoom_y; Bzoom_y; Czoom_y];

fullFig = figure(); clf;
cropFig = figure(); clf;
fullImage = figure();
k = 1;
for ii = 1:length(accom)
    
      fullRGB = oiGet(fullImages{ii}.oi,'rgb');
      
%     subplot(length(accom),4,k); k = k+1;
%     image(full_angSupport,full_angSupport,fullRGB);
%     axis image; xlabel('deg');
%     rectangle('Position',r_Azoom_deg,'EdgeColor','r','LineWidth',2)
%     rectangle('Position',r_Bzoom_deg,'EdgeColor','g','LineWidth',2)
%     rectangle('Position',r_Czoom_deg,'EdgeColor','m','LineWidth',2)
    
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
        
%         figure(fullFig);
%         subplot(length(accom),4,k); k = k+1;
        
        % We have to resample this because when we rendered we didn't set
        % the angular support correctly. This is kind of hack.
        curr_angSupport_x = r_zoom_angSupport_x(jj,:);
        x1 = linspace(0,1,length(curr_angSupport_x));
        x2 = linspace(0,1,size(cropRGB,2));
        curr_angSupport_x = interp1(x1,curr_angSupport_x,x2);
        
        curr_angSupport_y = r_zoom_angSupport_y(jj,:);
        y1 = linspace(0,1,length(curr_angSupport_y));
        y2 = linspace(0,1,size(cropRGB,1));
        curr_angSupport_y = interp1(y1,curr_angSupport_y,y2);
        
%         image(curr_angSupport_x,curr_angSupport_y,cropRGB);
%         axis image; xlabel('deg');
%         rectangle('Position',r_zoom_inDeg(jj,:),...
%             'EdgeColor',rectColors{jj},...
%             'LineWidth',6)
        
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
        
        % Save the angular support for the next section
        angSupportCropped_x{ii,jj} = curr_angSupport_x;
        angSupportCropped_y{ii,jj} = curr_angSupport_y;
        
    end
    
end


%% Plot edge of image over wavelength to show LCA more clearly

lcaEdgeFig = figure();
k = 1;
for ii = 1:3 % over accommodation
    for jj = 2 % the "B"
        
        oi = cropImages{ii,jj}.oi;
        oi = oiSet(oi,'mean illuminance',10);
        
        rgb = oiGet(oi,'rgb');
        x = angSupportCropped_x{ii,jj};
        y = angSupportCropped_y{ii,jj};
        
        % Only plot the edge
        r = [130   225   200   200];
        % Convert rectangle to degrees
        [r_deg, x_edge, y_edge] = convertRectPx2Ang(r,[x; y]);
        
        %{
        figure(lcaEdgeFig);
        subplot(3,2,k); k = k+1;
        image(x,y,rgb); axis image;
        xlabel('deg');
        rectangle('Position',r_deg,'EdgeColor','r','LineWidth',2)
        
        subplot(3,2,k); k = k+1; hold on;
        grid on;
        %}
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
        
        fov = oiGet(currOI, 'fov');
        
        % Load corresponding cone mosaic
        cmFileName = fullfile(isetlenseyeRootPath,'data',...
            'theHexMosaic0.71degs.mat');
        if(exist(cmFileName,'file'))
            load(cmFileName);
        else
            error('Cone mosaic doesn''t exist! Need to regenerate.');
        end
        
        theHexMosaic.compute(currOI);
        theHexMosaic.window;
        
        cmAbsorptions = theHexMosaic.absorptions;
        
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
