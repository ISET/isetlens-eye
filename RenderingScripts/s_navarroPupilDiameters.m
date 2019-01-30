%% s_eyeModelsMTF
% Render the slanted bar through the different eye models so that we can
% compare their on-axis performance

%% Initialize
ieInit;
if ~mcDockerExists, mcDockerConfig; end % check whether we can use docker
if ~mcGcloudExists, mcGcloudConfig; end % check whether we can use google cloud sdk;

%% Initialize save folder
% Since rendering these images often takes a while, we will save out the
% optical images into a folder for later processing.
currDate = datestr(now,'mm-dd-yy_HH_MM');
saveDirName = sprintf('pupil_%s',currDate);
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

clusterName = 'pupil';
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

%% Load up the slantedBar scene

% LQ mode flag (for testing)
lqFlag = true;

planeDistance = 50;
scene3d = sceneEye('slantedBar','planeDistance',planeDistance);

scene3d.fov = 2;
scene3d.numBounces = 1;
scene3d.accommodation = 0;

pupilDiameters = [6 5 4 3 2];

if(lqFlag) 
    scene3d.resolution = 128;
    scene3d.numCABands = 0;
    % This needs to change with pupil diameter
    numRays = [128 128 128 128 128];
    
else
    scene3d.numRays = 2048;
    scene3d.resolution = 1024;
    scene3d.numCABands = 16;
    % This needs to change with pupil diameter
    numRays = [2048 2048 2048 4096 8192 8192]; 
end

if(length(numRays) ~= length(pupilDiameters))
    error('numRays and pupilDiameters length need to match!')
end


%% Loop over pupil diameters

for ii = 1:length(pupilDiameters)
    
    currPupilDiam = pupilDiameters(ii);
    currNumRays = numRays(ii);
    
    scene3d.pupilDiameter = currPupilDiam;
    scene3d.numRays = currNumRays;
    
    scene3d.name = sprintf('pupilDiam_%dmm',currPupilDiam);
    
    if(ii == length(pupilDiameters))
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

for jj=1:length(oiAll)
    
    ieObj = oiAll{jj};
    ieAddObject(ieObj);
    
    scene3d = seAll{jj};
    
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