%% plotCABands
% We've rendered a series of slanted bar optical images using a different
% number of "chromatic aberration bands." We want to analyze the effect of
% band sampling on the chromatic aberration.

%% Initialize
ieInit; clear; close all;

% Download the pre-rendered data
dataDir = ileFetchDir('numCABandsAnalysis');

% The various numCABands we rendered with
cabands = [0 2 4 8 16];

saveDir = fullfile(isetlenseyeRootPath,'outputImages','CABands');
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end

%% Plot horizontal irradiance

for ii = 1:length(cabands)
    
    load(fullfile(dataDir,sprintf('numCABands_%d.mat',cabands(ii))));
    
    % Save the image
    %{
    x_ang = scene3d.angularSupport;
    img = oiGet(oi,'rgb');
    figHandle = plotWithAngularSupport(x_ang,x_ang,img,...
        'FontSize',18,...
        'axesSelect','yaxis');
    % title(sprintf('%d "Chromatic Aberration" Bands',cabands(ii)),'FontSize',16);
    set(gcf,'Position',[1087         965         386         327]);
    fn = fullfile(saveDir,sprintf('slantedBar_%dCABands.png',cabands(ii)));
    NicePlot.exportFigToPNG(fn,figHandle,150);
    %}
    
    oiCropped = oiCropRetinaBorder(oi);
    rgb = oiGet(oiCropped,'rgb');
    fn = fullfile(saveDir,sprintf('slantedBarCropped_%dCABands.png',cabands(ii)));
    imwrite(rgb,fn);
    
    % Plot horizontal irradiance
    H = vcNewGraphWin(); hold on; grid on;

    x_deg = scene3d.angularSupport;
    photons = oiGet(oi,'photons');
    wave = oiGet(oi,'wave');
    
    midPt = round(size(photons,1)/2);
    
    % Pick out a couple of wavelengths
    wls = [450 500 550 600 650];
    color = {'b','c','g','y','r'}; % Corresponding approx for color
    
    for w = 1:length(wls)
        currPhotons = photons((midPt-2:midPt+2),:,wave == wls(w));
        currPhotons = mean(currPhotons,1);
        plot(x_deg,currPhotons,color{w});
    end
    axis([-0.4 0.4 0 7.5e15])
    
    if(ii == 1)
        legendCell = cellstr(num2str(wls','%d nm'));
        legend(legendCell,'Location','best');
    end
    
    xlabel('\it space (degs)','FontSize',20);
    ylabel('Irradiance (q/s/m^2/nm)','FontSize',20)
    title(sprintf('%d Bands',cabands(ii)),...
        'FontSize',26);
    
    % Increase font size and line width
    set(findall(gcf,'-property','FontSize'),'FontSize',22)
    set(findall(gca,'-property','LineWidth'),'LineWidth',4)
    set(gcf,'Position',[0.1160    0.3382    0.2539    0.3215]);
    
    % Save the figure directly
    set(H,'color','w');
    fn = fullfile(saveDir,...
        sprintf('edgePlot_%dCABands.png',cabands(ii)));
    NicePlot.exportFigToPNG(fn,H,150);
    

end

