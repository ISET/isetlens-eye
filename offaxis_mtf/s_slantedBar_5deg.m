%% s_slantedBar_5deg.m
% Render the slanted bar but at 5 degree eccentricity

%% Initialize
ieInit;
if ~mcDockerExists, mcDockerConfig; end % check whether we can use docker
if ~mcGcloudExists, mcGcloudConfig; end % check whether we can use google cloud sdk;

%% Initialize save folder
% Since rendering these images often takes a while, we will save out the
% optical images into a folder for later processing.
currDate = datestr(now,'mm-dd-yy_HH_MM');
saveDirName = sprintf('slantedEdge5deg_%s',currDate);
saveDir = fullfile(isetbioRootPath,'local',saveDirName);
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end

%% Initialize cluster
tic

dockerAccount= 'tlian';
projectid = 'renderingfrl';
dockerImage = 'gcr.io/renderingfrl/pbrt-v3-spectral-gcloud';
cloudBucket = 'gs://renderingfrl';
% projectid = 'primal-surfer-140120';
% dockerImage = 'gcr.io/primal-surfer-140120/pbrt-v2-spectral-gcloud';
% cloudBucket = 'gs://primal-surfer-140120.appspot.com';

clusterName = 'trisha-fd';
zone         = 'us-central1-a';
instanceType = 'n1-highcpu-32';

gcp = gCloud('dockerAccount',dockerAccount,...
    'dockerImage',dockerImage,...
    'clusterName',clusterName,...
    'cloudBucket',cloudBucket,...
    'zone',zone,...
    'instanceType',instanceType,...
    'projectid',projectid,...
    'maxInstances',20);
toc

% Render depth
gcp.renderDepth = true;

% Clear the target operations
gcp.targets = [];

%% Load scene

planeDistance = 50;

% Instead of moving the scene, let's just render a large FOV, we can use it
% for future calculations as well. To make the render more efficient, let's
% split the scene into different windows. 
ecc = [0];

for ii = 1:length(ecc)
    
    scene3d = sceneEye('slantedBar',...
        'planeDistance',planeDistance,...
        'eccentricity',ecc(ii));
    
    scene3d.fov= 12;
    scene3d.accommodation = 0;
    scene3d.pupilDiameter = 4;
    
    scene3d.resolution = 3072;
    scene3d.numRays = 1024;
    scene3d.numCABands = 16;
    scene3d.numBounces = 1;
    
    scene3d.name = sprintf('slantedBar_%ddeg',ecc(ii));
    
    % Local render
%     [oi,results] = scene3d.render();
%     ieAddObject(oi);
%     oiWindow;
    
    % Cloud render
    if(ii == length(ecc))
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
