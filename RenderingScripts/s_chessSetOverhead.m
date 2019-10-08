%% s_chessSetOverhead
% Render an overhead retinal image of the chess set. To be used in the main
% figure for the ray-tracing optics paper.

% We render two versions of the chess set, the latter is to show that we
% can switch out materials in the scene.

%% Initialize
ieInit;
if ~mcDockerExists, mcDockerConfig; end % check whether we can use docker
if ~mcGcloudExists, mcGcloudConfig; end % check whether we can use google cloud sdk;

%% Initialize save folder

% Since rendering these images often takes a while, we will save out the
% optical images into a folder for later processing. 
currDate = datestr(now,'mm-dd-yy_HH_MM');
saveDirName = sprintf('chessSetOverhead_%s',currDate);
saveDir = fullfile(isetbioRootPath,'local',saveDirName);
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end

%% Initialize cluster
tic

dockerAccount= 'tlian';
% projectid = 'renderingfrl';
% dockerImage = 'gcr.io/renderingfrl/pbrt-v3-spectral-gcloud';
% cloudBucket = 'gs://renderingfrl';
projectid = 'primal-surfer-140120';
dockerImage = 'gcr.io/primal-surfer-140120/pbrt-v2-spectral-gcloud';
cloudBucket = 'gs://primal-surfer-140120.appspot.com';

clusterName = 'trisha';
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

%% Load the first scene
scene3d = sceneEye('chessSet');

origPos = scene3d.eyePos;
origTo = scene3d.eyeTo;

% Move the camera
scene3d.eyePos = origPos + [0 0.2 -0.1] + [0 0 0.1];
scene3d.eyeTo = origTo + [0 0 -0.65];

% Accommodate to the pawn
scene3d.accommodation = 2;

%% Local test render
%{
scene3d.resolution = 256;
scene3d.numRays = 256;
scene3d.numCABands = 0;

oi = scene3d.render;
ieAddObject(oi);
oiWindow;
%}

%% Setup scene

% LQ mode flag (for testing)
lqFlag = false;

if(lqFlag)
    scene3d.numRays = 256; % LQ
    scene3d.resolution = 256;
    scene3d.numCABands = 1;
    
else
    % scene3d.numRays = 4096;
    scene3d.numRays = 1024;
    scene3d.resolution = 800;
    scene3d.numCABands = 1;
end

r = [426   532    41    37];
cw = rect2cropwindow(r,scene3d.resolution,scene3d.resolution);
scene3d.recipe = recipeSet(scene3d.recipe,'cropwindow',cw);

oi = scene3d.render;
ieAddObject(oi);
oiWindow;

%% Send to cloud
scene3d.name = 'chessSetOverhead';
sendToCloud(gcp,scene3d,'uploadZip',true);

%{
%% Load the second scene
scene3d = sceneEye('chessSet-2');

origPos = scene3d.eyePos;
origTo = scene3d.eyeTo;

% Move the camera
scene3d.eyePos = origPos + [0 0.2 -0.1] + [0 0 0.1];
scene3d.eyeTo = origTo + [0 0 -0.65];

% Accommodate to the pawn
scene3d.accommodation = 2;

%% Setup scene

if(lqFlag)
    scene3d.numRays = 256; % LQ
    scene3d.resolution = 256;
    scene3d.numCABands = 1;
    
else
    scene3d.numRays = 4096;
    scene3d.resolution = 800;
    scene3d.numCABands = 16;
end

%% Local test render
%{
scene3d.resolution = 256;
scene3d.numRays = 256;
scene3d.numCABands = 0;

oi = scene3d.render;
ieAddObject(oi);
oiWindow;
%}

%% Send to cloud

% Scene name
scene3d.name = 'chessSetOverhead-2';

[cloudFolder,zipFileName] =  ...
    sendToCloud(gcp,scene3d,'uploadZip',true);
%}

%% Render
gcp.render();

%% Check for completion
% Save the gCloud object in case MATLAB closes
gCloudName = sprintf('%s_gcpBackup_%s',mfilename,currDate);
save(fullfile(saveDir,gCloudName),'gcp','saveDir');

% Pause for user input (wait until gCloud job is done)
x = 'N';
while(~strcmp(x,'Y'))
    x = input('Did the gCloud render finish yet? (Y/N)','s');
end

%% Download the data
[oiAll, seAll] = downloadFromCloud(gcp);

for ii=1:length(oiAll)
    
    ieObj = oiAll{ii};
    ieAddObject(ieObj);
    
    scene3d = seAll{ii};
    
    saveFilename = fullfile(saveDir,[scene3d.name '.mat']);
    
    % Save as scene or oi
    if(strcmp(ieObj.type,'scene'))
        scene = ieObj;
        save(saveFilename,'scene','scene3d');
        sceneWindow;
    else
        oi = ieObj;
        oiWindow
        save(saveFilename,'oi','scene3d');
        
    end
    
end

