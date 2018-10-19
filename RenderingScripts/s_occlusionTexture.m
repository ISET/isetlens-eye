%% s_occlusionTexture.m
%
% Render a slanted bar where there  are two planes at depth depths,
% and each plane has a texture. This creates an edge where there is a
% depth discontinuity.
%
% We would like to compare the ray-traced rendering with a simpler
% version in which we simply convolve the two images with different
% blur functions and then add them. We will have the eye accommodate to
% either plane. 
%
% First we render with a pinhole to create an ISET scene. We will then use
% this scene and it's depth map to convolve with a 2D PSF created in
% ISETbio.
%
% Next we will render the 3D scene with the Navarro eye model. We will
% compare the retinal image between these two methods.
% 
% ISETBIO Team, 2018
%
% See also
%   iset3d, isetbio, Docker
%

%% Initialize ISETBIO
ieInit;
if ~mcDockerExists, mcDockerConfig; end % check whether we can use docker
if ~mcGcloudExists, mcGcloudConfig; end % check whether we can use google cloud sdk;

%% Initialize save folder
% Since rendering these images often takes a while, we will save out the
% optical images into a folder for later processing. 
currDate = datestr(now,'mm-dd-yy_HH_MM');
saveDirName = sprintf('occlusionTexture_%s',currDate);
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

%% Create the scene

% Try different depths
% Depth to the two textured planes in meters
topDepth = 1;
bottomDepth = 2;

scene3d = sceneEye('slantedBarTexture',...
    'topDepth',topDepth,...
    'bottomDepth',bottomDepth); % in meters

% We'll keep these parameters the same for all cases
scene3d.fov        = 2; % The smaller the fov the more the LCA is visible.
scene3d.numBounces = 3; 

% LQ mode flag (for testing)
lqFlag = false;

%% Do a quick local test render first (~20 sec)

%{
scene3d.numCABands = 6; % Can increase to 16 or 32 at the cost of render speed.

scene3d.accommodation = 1/topDepth; % Accommodate to top plane

% Set quality parameters
scene3d.resolution = 128; % Low quality
scene3d.numRays    = 128; % Low quality

% Scene name
scene3d.name = sprintf('test_%0.2f_%0.2f_slantedBar',topDepth,bottomDepth);

[oi, ~] = scene3d.render;
ieAddObject(oi);
oiWindow;
%}

%% Setup with a pinhole camera

%{
% Automatically uses a pinhole or perspective camera (see next line)
scene3d.debugMode = true; 

% If these are not zero, PBRT will use a simple perspective/thin lens model
% instead of a pinhole.
scene3d.accommodation = 0; 
scene3d.pupilDiameter = 0;

% Because it's a pinhole, we don't have to use as many rays
if(lqFlag)
    scene3d.numRays = 128; % LQ
    scene3d.resolution = 128;
else
    scene3d.numRays = 2048; % HQ
    scene3d.resolution = 800;
end

scene3d.name = sprintf('occlusion_%0.2f_%0.2f_pinhole',...
    topDepth,bottomDepth);

[cloudFolder,zipFileName] =  ...
    sendToCloud(gcp,scene3d,'uploadZip',true);
%}

%% Now setup with the Navarro eye

scene3d.debugMode = false; 
scene3d.pupilDiameter = 4;

% Because it's a pinhole, we don't have to use as many rays
if(lqFlag)
    scene3d.numRays = 128; % LQ
    scene3d.resolution = 128;
else
    scene3d.numRays = 8192; % HQ - may need to be even higher
    scene3d.resolution = 800;
end

% Render twice, with different accommodations
accom = [1/topDepth 1/bottomDepth]; % dpt
for ii = 1:length(accom)
    
    scene3d.accommodation = accom(ii);
    scene3d.name = sprintf('occlusion_%0.2f_%0.2f_%0.2fdpt',...
        topDepth,bottomDepth,accom(ii));

        % Cloud rendering
    if(ii == length(accom))
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

