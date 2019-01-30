%% Sanity check on the sampling needed for the slanted edge
%
% Using the Nyquist theorem:
% We know the eye goes out to about 100 cyc/deg
% We know that we need at least 2 pixels per cycle
% So at the very least we need 200 pixels/deg
% So if we take a 2 deg window, we need at least 400x400 pixels
%
% Let's render the slanted edge at various resolutions to check this.

%% Initialize
ieInit;
if ~mcDockerExists, mcDockerConfig; end % check whether we can use docker
if ~mcGcloudExists, mcGcloudConfig; end % check whether we can use google cloud sdk;

%% Initialize save folder
% Since rendering these images often takes a while, we will save out the
% optical images into a folder for later processing.
currDate = datestr(now,'mm-dd-yy_HH_MM');
saveDirName = sprintf('slantedEdgeSanity_%s',currDate);
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

clusterName = 'sctrisha';
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
lqFlag = false;

planeDistance = 50;
scene3d = sceneEye('slantedBar','planeDistance',planeDistance);

scene3d.numBounces = 1;
scene3d.accommodation = 0;
scene3d.pupilDiameter = 4;
scene3d.diffractionEnabled = 0;
scene3d.fov = 2;

if(lqFlag)
    scene3d.numRays = 128;
    scene3d.numCABands = 0;
    resolutions = [128 256];
else
    scene3d.numRays = 2048;
    scene3d.numCABands = 16;
    resolutions = [128 256 512 1024];

end

%% Run for several image resolutions

for ii = 1:length(resolutions)
    
    scene3d.resolution = resolutions(ii);
    
    scene3d.name = sprintf('slantedBar_res%d',...
        resolutions(ii));   
    
%     [oi, results] = scene3d.render();
%     ieAddObject(oi);
%     oiWindow;

    % Upload the zip when we are done with the loop
    if(ii == length(resolutions))
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
