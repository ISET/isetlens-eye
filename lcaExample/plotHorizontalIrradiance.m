% Plot the horizontal irradiance over different wavelengths

%% Initialize
ieInit;
clear; close all;

dataDir = ileFetchDir('lcaExample_far');

saveDir = fullfile(isetlenseyeRootPath,'outputImages','lca');
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end

%%

% Load crop windows
load(fullfile(dataDir,'horizontalLineOnly','cropwindows_all.mat'));

accom = [0.60 1.20 1.80];

for ii = 1:3 % over accommodation
    
    fn = sprintf('lettersAtDepth_%0.2fdpt_2.mat',accom(ii));
    load(fullfile(dataDir,'horizontalLineOnly',fn))
    
    oi = oiSet(oi,'mean illuminance',10);
    
    % Calculate support
    rgb = oiGet(oi,'rgb');
    x_full = scene3d.angularSupport;
    [x_crop,y_crop] = calculateCropWindowAngularSupport(x_full,x_full,...
        cropwindows_all(2,:),rgb);
    
    photons = oiGet(oi,'photons');
    wave = oiGet(oi,'wave');
    
    ieAddObject(oi);
    oiWindow;
    
    edgeFig = figure();
    hold on; grid on; box on;
    
    sz = size(rgb);
    
    % Pick out a couple of wavelengths
    wls = [450 500 550 600 650];
    color = {'b','c','g','y','r'}; % Corresponding approx for color
    
    for w = 1:length(wls)
        currPhotons = photons(:,:,wave == wls(w));
        currPhotons = mean(currPhotons,1);
        plot(x_crop,currPhotons,color{w});
    end
    % axis([min(x_crop) max(x_crop) 0 12e14])
    
    if(ii == 2)
        legendCell = cellstr(num2str(wls','%d nm'));
        legend(legendCell,'Location','best');
    end
    
    axis([-1.8 -1.3 0 9e14])
    
    % Increase font size and line width
    set(findall(gcf,'-property','FontSize'),'FontSize',22)
    set(findall(gca,'-property','LineWidth'),'LineWidth',4)
    
    xlabel('\it space (degs)','FontSize',20);
    ylabel('Irradiance (q/s/m^2/nm)','FontSize',20)
    
    % Save the figure directly
    set(edgeFig,'color','w');
    cropFigfn = fullfile(saveDir,...
        sprintf('edgePlot_%i.png',ii));
    NicePlot.exportFigToPNG(cropFigfn,edgeFig,300);
    
end