%% s_chessSetSmallFOV.m
% 
% Render the scaled chess set using a very small FOV. To get the entire
% chess set in the frame, we move the camera very far away. 
%
% Depends on: iset3d, isetbio, Docker, isetcloud
%
% TL ISETBIO Team, 2017 

%% Initialize ISETBIO
if isequal(piCamBio,'isetcam')
    fprintf('%s: requires ISETBio, not ISETCam\n',mfilename); 
    return;
end
ieInit;
if ~mcDockerExists, mcDockerConfig; end % check whether we can use docker
if ~mcGcloudExists, mcGcloudConfig; end % check whether we can use google cloud sdk;

%% Initialize save folder
% Since rendering these images often takes a while, we will save out the
% optical images into a folder for later processing.
currDate = datestr(now,'mm-dd-yy_HH_MM');
saveDirName = sprintf('chessSet_smallfov_%s',currDate);
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

%% Load scene

% The "chessSetScaled" is the chessSet scene but scaled and shifted in a
% way that emphasizes the depth of field of the eye. The size of the chess
% pieces and the board may no longer match the real world.
myScene = sceneEye('chessSetScaled');

%% Set fixed parameters
myScene.accommodation = 1/0.28; 
myScene.fov = 5;

myScene.numCABands = 8;
myScene.diffractionEnabled = false;
myScene.numBounces = 3;

myScene.resolution = 128;
myScene.numRays = 64;

%% Move the camera back

toVector = myScene.eyeTo - myScene.eyePos;
myScene.eyePos = myScene.eyePos - toVector.*1.6;

myScene.eyePos(2) = myScene.eyePos(2) + 0.15;
myScene.eyeTo(2) = myScene.eyeTo(2) - 0.05;

updatedToVector = myScene.eyeTo - myScene.eyePos;
dist = sqrt(sum(updatedToVector.^2));
myScene.accommodation = 1/dist;

%% Change to a brighter environment map
% myScene.recipe = piWorldFindAndReplace(myScene.recipe,...
%    '20060807_wells6_hd.exr','20060807_wells6_hd_brighter.exr');

%% Render a test version
% [oi, results] = myScene.render();
% oiWindow(oi);

%% Upload to cloud

myScene.resolution = 512;
myScene.numRays = 4096;

uploadFlag = true;
[cloudFolder,zipFileName] =  ...
    sendToCloud(gcp,myScene,'uploadZip',uploadFlag);


%% Render
gcp.render();

%% Check for completion

% Save the gCloud object in case MATLAB closes
gCloudName = sprintf('%s_gcpBackup_%s',mfilename,currDate);
save(fullfile(myScene.workingDir,gCloudName),'gcp','saveDir');
    
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
    
    myScene = seAll{ii};
    
    saveFilename = fullfile(saveDir,[myScene.name '.mat']);
    save(saveFilename,'oi','myScene');
    
end






