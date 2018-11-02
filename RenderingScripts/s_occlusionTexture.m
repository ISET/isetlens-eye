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
% Lastly, we render the above retinal image but with each of the planes
% removed from the scene, so we can test the additivity of the blur.
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
% projectid = 'primal-surfer-140120';
% dockerImage = 'gcr.io/primal-surfer-140120/pbrt-v2-spectral-gcloud';
% cloudBucket = 'gs://primal-surfer-140120.appspot.com';

clusterName = 'occlusion';
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

%% Do a quick local test render first (~20 sec)
%{
topDepth = 0.5;
bottomDepth = 2;

scene3d = sceneEye('slantedBarTexture',...
    'topDepth',topDepth,...
    'bottomDepth',bottomDepth); % in meters

% We'll keep these parameters the same for all cases
scene3d.fov        = 2; % The smaller the fov the more the LCA is visible.
scene3d.numBounces = 3;

scene3d.numCABands = 6; % Can increase to 16 or 32 at the cost of render speed.

scene3d.accommodation = 1/bottomDepth; % Accommodate to the back plane

% Set quality parameters
scene3d.resolution = 128; % Low quality
scene3d.numRays    = 128; % Low quality

% Scene name
scene3d.name = sprintf('test_%0.2f_%0.2f_slantedBar',topDepth,bottomDepth);

[oi, ~] = scene3d.render;
ieAddObject(oi);
oiWindow;
%}

%% Loop over different depths and accommodations

% Render 3 plane depths
topPlaneDepth = [0.5 1 2.5];

% LQ mode flag (for testing)
lqFlag = true;

for tp = 1:length(topPlaneDepth)
    
    % Try different depths
    % Depth to the two textured planes in meters
    topDepth = topPlaneDepth(tp);
    bottomDepth = 2;
    
    scene3d = sceneEye('slantedBarTexture',...
        'topDepth',topDepth,...
        'bottomDepth',bottomDepth); % in meters
    
    % We'll keep these parameters the same for all cases
    scene3d.fov        = 2; % The smaller the fov the more the LCA is visible.
    scene3d.numBounces = 3;
    
    % Render twice, with different accommodations
    accom = [1/topDepth 1/bottomDepth]; % dpt

    %% Set LQ or HQ
    
    scene3d.debugMode = false;
    scene3d.pupilDiameter = 4;
    
    if(lqFlag)
        scene3d.numRays = 128; % LQ
        scene3d.resolution = 128;
        scene3d.numCABands = 6;
    else
        scene3d.numRays = 4096;
        scene3d.resolution = 512;
        scene3d.numCABands = 16;
    end
    
    %% Change light source
    
    oldString = '"infinite"';
    newString = '"distant" "point from" [0 0 0] "point to" [0 0 100]';
    scene3d.recipe = piWorldFindAndReplace(scene3d.recipe,oldString,newString);
    
    oldString = '"integer nsamples" [8]';
    newString = '';
    scene3d.recipe = piWorldFindAndReplace(scene3d.recipe,oldString,newString);
    
    %% Both planes together
    
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
    
    %% Remove each plane and re-render
    
    uploadFlag = false;
    for ii = 1:length(accom)
        
        scene3d.accommodation = accom(ii);
        
        % --------------------
        % Find top plane index
        for jj = 1:length(scene3d.recipe.assets)
            if strcmp(scene3d.recipe.assets(jj).name,'TopPlane')
                topPlaneI = jj;
            end
        end
        
        % Remove Top plane
        assert(strcmp(scene3d.recipe.assets(topPlaneI).name,'TopPlane'));
        topPlaneAsset = scene3d.recipe.assets(topPlaneI);
        scene3d.recipe.assets(topPlaneI) = [];
        scene3d.name = sprintf('occlusion_%0.2f_%0.2f_%0.2fdpt_Bottom',...
            topDepth,bottomDepth,accom(ii));
        
        % Push to cloud
        sendToCloud(gcp,scene3d,'uploadZip',uploadFlag);
        
        % Put Top plane back
        scene3d.recipe.assets(end+1) = topPlaneAsset;
        
        % --------------------
        % Find bottom plane index
        for jj = 1:length(scene3d.recipe.assets)
            if strcmp(scene3d.recipe.assets(jj).name,'BottomPlane')
                bottomPlaneI = jj;
            end
        end
        
        % Remove Bottom plane
        assert(strcmp(scene3d.recipe.assets(bottomPlaneI).name,'BottomPlane'));
        bottomPlaneAsset = scene3d.recipe.assets(bottomPlaneI);
        scene3d.recipe.assets(bottomPlaneI) = [];
        scene3d.name = sprintf('occlusion_%0.2f_%0.2f_%0.2fdpt_Top',...
            topDepth,bottomDepth,accom(ii));
        
        % Push to cloud
        if(ii == length(accom))
            uploadFlag = true;
        end
        [cloudFolder,zipFileName] =  ...
            sendToCloud(gcp,scene3d,'uploadZip',uploadFlag);
        
        % Put Bottom plane back
        scene3d.recipe.assets(end+1) = bottomPlaneAsset;
        
    end
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

