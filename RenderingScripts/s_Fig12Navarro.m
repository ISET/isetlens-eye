%% s_Fig12Navarro.m
%
% Check our rendering with Fig. 12a in:
% Isabel Escudero-Sanz and Rafael Navarro, "Off-axis aberrations of a
% wide-angle schematic eye model," J. Opt. Soc. Am. A 16, 1881-1891 (1999)
%
% We do this by rendering a slanted bar at 0 dpt and then 0.15 dpt, and
% calculating the MTF for each.
%
% Depends on: ISET3d, ISETBIO, Docker, ISET
%
% TL ISETBIO Team, 2017

%% Initialize ISETBIO
ieInit;
if ~mcDockerExists, mcDockerConfig; end % check whether we can use docker
if ~mcGcloudExists, mcGcloudConfig; end % check whether we can use google cloud sdk;

%% Initialize save folder
% Since rendering these images often takes a while, we will save out the
% optical images into a folder for later processing.
currDate = datestr(now,'mm-dd-yy_HH_MM');
saveDirName = sprintf('fig12validate_%s',currDate);
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

clusterName = 'validate';
zone         = 'us-central1-a';    
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

%% Render a slanted bar

% Scene is far away
myScene = sceneEye('slantedBar','planeDistance',10); 
myScene.numRays = 4096;
myScene.pupilDiameter = 4;
myScene.numCABands = 16;
sceneNavarro.numBounces = 1;

% From slantedBarSanityCheck.m we have an idea of what the minimum sampling
% rate and size our rendered optical image should be, in order to capture
% the spread of the PSF as well as have high enough sampling.
myScene.fov = 2;
myScene.resolution = 800;

% LQ
myScene.resolution = 128;
myScene.numCABands = 0;
myScene.numRays = 128;

accomm = [0 0.15];
for ii = 1:length(accomm)
    
    myScene.accommodation = accomm(ii);
    myScene.name = sprintf('validate%0.2f',accomm(ii));
    
%     if(ii == length(accomm))
%         uploadFlag = true;
%     else
%         uploadFlag = false;
%     end
%     
%     [cloudFolder,zipFileName] =  ...
%     sendToCloud(gcp,myScene,'uploadZip',uploadFlag);
    
    % Normal rendering
    oi = myScene.render;
    ieAddObject(oi);
    oiWindow;

    
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
    
    oi = oiAll{ii};
    ieAddObject(oi);
    oiWindow;
    
    myScene = seAll{ii};
    
    saveFilename = fullfile(saveDir,[myScene.name '.mat']);
    save(saveFilename,'oi','myScene');
    
end
