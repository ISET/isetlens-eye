%% s_colorfulScene.m
%
% Depends on: iset3d, isetbio, Docker, isetcloud
%
% TL ISETBIO Team, 2017

%% Initialize ISETBIO
ieInit;
clear; close all;
if ~mcDockerExists, mcDockerConfig; end % check whether we can use docker
if ~mcGcloudExists, mcGcloudConfig; end % check whether we can use google cloud sdk;

%% Initialize save folder
% Since rendering these images often takes a while, we will save out the
% optical images into a folder for later processing.
currDate = datestr(now,'mm-dd-yy_HH_MM');
saveDirName = sprintf('colorfulScene_%s',currDate);
saveDir = fullfile(isetbioRootPath,'local',saveDirName);
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end

%% Initialize your cluster
tic

dockerAccount= 'tlian';
projectid = 'renderingfrl';
dockerImage = 'gcr.io/renderingfrl/pbrt-v3-spectral-gcloud';
cloudBucket = 'gs://renderingfrl';

clusterName = 'colorfulscene';
zone         = 'us-central1-b';
instanceType = 'n1-highcpu-32';

gcp = gCloud('dockerAccount',dockerAccount,...
    'dockerImage',dockerImage,...
    'clusterName',clusterName,...
    'cloudBucket',cloudBucket,...
    'zone',zone,...
    'instanceType',instanceType,...
    'projectid',projectid);
toc

% Render depth
gcp.renderDepth = true;

% Clear the target operations
gcp.targets = [];

%% Load scene
scene3d = sceneEye('colorfulScene');

% Fixed parameters
scene3d.fov = 35;
scene3d.accommodation = 1/1.3; 
scene3d.lensDensity = 0.0; % No lens transmittance

lqFlag = true;

%% Select windows to render

% Show rectangles?
showRectFlag = true;

% Determines window resolution
if(lqFlag)
    fullResolution = 512;
else
    fullResolution = 10000;
end

% Load a draft image
if(showRectFlag)
    
    dataDir = ileFetchDir('colorfulScene');
    draftImage = load(fullfile(dataDir,'ColorfulScene.mat'));
   
    rgb = oiGet(draftImage.oi,'rgb');
    H = figure();
    imshow(rgb); hold on;
end

% User selects rectangles
% r = getrect(H)

% Output from the above
% rectanglesAll{1} = [40   371   30    30];
% rectanglesAll{2} = [58   180   30    30];
% rectanglesAll{3} = [448  354   30    30];
% rectanglesAll{4} = [316  467   30    30];
% rectanglesAll{5} = [358  37    30    30];

rectanglesAll{1} = [59 96 20 20];
rectanglesAll{2} = [252 20 20 20];
rectanglesAll{3} = [25 133 20 20];

% Make crop windows and draw rectangles on test image
cropWindows_all = cell(length(rectanglesAll),1);
for ii = 1:length(rectanglesAll)
    
    curr_r = rectanglesAll{ii};
    
    if(showRectFlag)
        rgb = insertShape(rgb, 'rectangle', curr_r,...
            'LineWidth', 6,'Color','r');
        numberPos = curr_r(1:2) - [40 40];
        rgb = insertText(rgb, numberPos, num2str(ii),...
            'TextColor','r',...
            'FontSize',26,...
            'BoxColor',[1 1 1],...
            'BoxOpacity',0.8);
        figure(H);
        imshow(rgb);
    end
    
    curr_cropwindow = rect2cropwindow(curr_r,512,512);
    
    % Calculate the window resolution, given the current full resolution
    windowResolution = fullResolution*(curr_cropwindow(2)-curr_cropwindow(1));
    
    cropWindows_all{ii} = curr_cropwindow;
    
end

% Not sure why the crop windows aren't saved properly in the scene...
save(fullfile(saveDir,'cropwindows.mat'),'cropWindows_all');

%% Set parameters

if(lqFlag)
    scene3d.resolution = fullResolution;
    scene3d.numRays = 256;
    scene3d.numCABands = 0;
    scene3d.numBounces = 1;
else
    scene3d.resolution = fullResolution;
    scene3d.numRays = 2048;
    scene3d.numCABands = 16;
    scene3d.numBounces = 6;
end

%% Render each crop window

for ii = 1:length(cropWindows_all)
    
    % Add crop window
    scene3d.recipe.set('cropwindow',cropWindows_all{ii});
        
    % Scene name
    scene3d.name = sprintf('ColorfulScene_%d',ii);
    
    if(ii  == length(cropWindows_all))
        uploadFlag = true;
    else
        uploadFlag = false;
    end
    [cloudFolder,zipFileName] =  ...
        sendToCloud(gcp,scene3d,'uploadZip',uploadFlag);
end

%% Render
gcp.render();

%% Check for completion

% Save the gCloud object in case MATLAB closes
gCloudName = sprintf('%s_gcpBackup_%s',mfilename,currDate);
save(fullfile(scene3d.workingDir,gCloudName),'gcp','saveDir');
    
% Pause for user input (wait until gCloud job is done)
x = 'N';
while(~strcmp(x,'Y'))
    x = input('Did the gCloud render finish yet? (Y/N)','s');
end

%% Download the data

[oiAll, seAll] = downloadFromCloud(gcp);

for ii=1:length(oiAll)
    
    oi = oiAll{ii};
    ieAddObject(oi);
    oiWindow;
    
    scene3d = seAll{ii};
    
    saveFilename = fullfile(saveDir,[scene3d.name '.mat']);
    save(saveFilename,'oi','scene3d');
    
end