%% Chromatic aberration
% How many CA Bands do we need when rendering through the lens?

%% Initialize 
ieInit;
if ~mcDockerExists, mcDockerConfig; end % check whether we can use docker
if ~mcGcloudExists, mcGcloudConfig; end % check whether we can use google cloud sdk;

%% Initialize save folder
% Since rendering these images often takes a while, we will save out the
% optical images into a folder for later processing. 
currDate = datestr(now,'mm-dd-yy_HH_MM');
saveDirName = sprintf('numCABands_%s',currDate);
saveDir = fullfile(isetbioRootPath,'local',saveDirName);
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end

%% Setup cloud rendering

dockerAccount= 'tlian';
projectid = 'primal-surfer-140120';
dockerImage = 'gcr.io/primal-surfer-140120/pbrt-v3-spectral-gcloud';
cloudBucket = 'gs://primal-surfer-140120.appspot.com';

clusterName = 'trisha';
zone         = 'us-central1-a';    
instanceType = 'n1-highcpu-32';
maxInstances = 20;

gcp = gCloud('dockerAccount',dockerAccount,...
    'dockerImage',dockerImage,...
    'clusterName',clusterName,...
    'cloudBucket',cloudBucket,...
    'zone',zone,...
    'instanceType',instanceType,...
    'projectid',projectid,...
    'maxInstances',maxInstances);
toc

% Render depth
gcp.renderDepth = true;

% Clear the target operations
gcp.targets = [];

%% Load the scene

% The plane is placed at 3 meters
thisScene = sceneEye('slantedBar',...
                   'planeDistance',1);
                   
thisScene.fov = 1.5;
thisScene.resolution = 256;
thisScene.numRays = 1024;
thisScene.numCABands = 0;
thisScene.accommodation = 1/1; % Accommodate to the plane

% No lens transmittance
thisScene.lensDensity = 0.0;

%% Loop over CA Bands

ca = [0 2 4 8 16];
oiCA = cell(length(ca),1);
renderingTime = zeros(length(ca),1);

for ii = 1:length(ca)
    
    thisScene.name = sprintf('numCABand_%d',ca(ii));
    thisScene.numCABands = ca(ii); 
    
    if(ii == length(ca))
        uploadFlag = true;
    else
        uploadFlag = false;
    end
    
    sendToCloud(gcp,thisScene,'uploadZip',uploadFlag);
    
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
 
