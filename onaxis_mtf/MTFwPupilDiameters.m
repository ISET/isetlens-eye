%% MTFwPupilDiameters.m
% Plot the MTF over different pupil diameters. First do it with isetBio ray
% tracing and the Navarro model. Then do it with the Watson model.
% 
% These MTF's are polychromatic and on-axis.

%% Initialize
ieInit;

% Pupil sizes
% Hard coded to match the rendered data we load below
pupilSizes = [1 2 3 4 5 6];

% Setup colormap
colors = cbrewer('div','Spectral',6);

% Map pupil sizes to color so we can keep it consistent in different plots
pupil2color = containers.Map('KeyType','double','ValueType','any');
for i = 1:length(pupilSizes)
    pupil2color(pupilSizes(i)) = colors(i,:);
end

% Setup figure
MTFfig = vcNewGraphWin;

% Setup save directory
saveDir = fullfile(isetlenseyeRootPath,'outputImages');
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end

%% Load the rendered data
% ...if not already loaded

slantedBar_pupilDiam_dir = fullfile(isetlenseyeRootPath,'data',...
    'slantedBar_pupil');
if(~exist(slantedBar_pupilDiam_dir,'dir'))
    fprintf('Fetching data...');
    piPBRTFetch('slantedBar_pupil',...
        'remotedirectory','/resources/isetlensdata',...
        'destinationfolder',fullfile(isetlenseyeRootPath,'data'));
    fprintf('Data fetched!');
end

%% Loop over pupil diameters and plot

for ii = 1:length(pupilSizes)
    
    clear oi myScene
    
    % Hard coded to match the rendered data
    currFileName = sprintf('pupilDiam_%0.2fmm.mat',pupilSizes(ii));
    
    % Load the current pupil diameter
    load(fullfile(isetlenseyeRootPath,'data',...
        'slantedBar_pupil',currFileName));
    
    oi = oiSet(oi,'bitDepth',32); % For isetbio
    
    % Check that pupil diameter matches the one in the sceneEye object (Not
    % really necessary, but just in case we named the file incorrectly.)
    assert(pupilSizes(ii) == myScene.pupilDiameter)
    
    % Check the slanted bar oi
    ieAddObject(oi);
    oiWindow;
    
    % Calculate MTF (polychromatic)
    [freq,mtf] = calculateMTFfromSlantedBar(oi,'cropFlag',true);
    
    % Plot
    figure(MTFfig); hold on;
    plot(freq,mtf,...
        'color',pupil2color(pupilSizes(ii)));       
end

%% Make the plot prettier
figure(MTFfig);
grid on;
title(sprintf('MTF vs Pupil Diameter \n (polychromatic)'))
xlabel('Spatial Frequency (cycles/deg)');
ylabel('Contrast Reduction (SFR)');
% set(gca, 'YScale', 'log')
% set(gca, 'XScale', 'log')
% xticks([1 2 5 10 20 50 100])
% yticks([0.01 0.02 0.05 0.1 0.2 0.5 1])
% axis([1 100 0.01 1])
% ax = gca;
% ax.MinorGridAlpha = 0.10;
% ax.GridAlpha = 0.10;
axis([0 60 0 1])
set(findall(gca,'-property','FontSize'),'FontSize',24)
set(findall(gca,'-property','LineWidth'),'LineWidth',3)
legend(cellstr(num2str(pupilSizes', '%0.2f mm')));

set(gca,'Position',[0.1300    0.1100    0.7750    0.7827]);
set(gcf,'Position',[0.0069    0.2044    0.6356    0.6889]);

%% Save image out
fn = fullfile(saveDir,'mtfFig_pupilDiameter.png');
NicePlot.exportFigToPNG(fn, MTFfig, 300); 