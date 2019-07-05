
%% s_LCAExample.m
%
% Render the letters at depth scene through the eye. We will use it to
% demonstrate the effect of longitudinal chromatic aberration in our
% modeling tools. 
% 
% ISETBIO Team, 2018
%
% See also
%   iset3d, isetbio, Docker, RemoteDataToolbox

%% Initialize 
ieInit;
if ~mcDockerExists, mcDockerConfig; end % check whether we can use docker
if ~mcGcloudExists, mcGcloudConfig; end % check whether we can use google cloud sdk;

%% Initialize save folder
% Since rendering these images often takes a while, we will save out the
% optical images into a folder for later processing. 
currDate = datestr(now,'mm-dd-yy_HH_MM');
saveDirName = sprintf('lcaExample_%s',currDate);
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

clusterName = 'lca';
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

%% Setup scene

% LQ mode flag (for testing)
lqFlag = false;

distm = 1./[1.8 1.2 0.6];

scene3d = sceneEye('lettersAtDepth',...
    'Adist',distm(1),...
    'Bdist',distm(2),...
    'Cdist',distm(3)); % in meters

scene3d.debugMode = false;
scene3d.fov = 20;
scene3d.pupilDiameter = 4;

if(lqFlag)
    scene3d.numRays = 128; % LQ
    scene3d.resolution = 128;
    scene3d.numCABands = 6;
    
else
    scene3d.numRays = 8192;
    scene3d.resolution = 800;
    scene3d.numCABands = 16;
end

%% Set up crop windows
% We crop the image to get specific, high resolution patches to run through
% our cone mosaic.
% These windows are used in lcaExample/lcaExample.m

%{
r_zoom(1,:) = [121   240    56    56];
r_zoom(2,:) = [317   293    56    56];
r_zoom(3,:) = [560   335    56    56];
%}

% Temp
% only render a small strip to plot the irradiance profile in the paper.
r_zoom(1,:) = [121   240+56/2    56    6];
r_zoom(2,:) = [317   293+56/2    56    6];
r_zoom(3,:) = [560   335+56/2    56    6];

% We need to convert these rectangles to crop windows
cropwindows_all = zeros(size(r_zoom));
for ii = 1:3
    r = r_zoom(ii,:);
    px = [r(1) r(1)+r(3) r(2) r(2)+r(4)];
    cropwindows_all(ii,:) = px./800;
end

% We have to increase the resolution since we're using a cropwindow
scene3d.resolution = 8192;

%% Loop through accommodations

for ii = 1:length(distm)
    
    scene3d.accommodation = 1/distm(ii); % Accommodate to each letter
    
    % Loop through the crop windows
    for jj = 2 %1:size(cropwindows_all,1)
        
        scene3d.recipe.set('cropwindow',cropwindows_all(jj,:));
        
        % Scene name
        scene3d.name = sprintf('lettersAtDepth_%0.2fdpt_%i',...
            scene3d.accommodation,jj);
        
        % Local
%         [oi, ~] = scene3d.render;
%         ieAddObject(oi);
%         oiWindow;

        % Cloud
        if(ii == length(distm))
            uploadFlag = true;
        else
            uploadFlag = false;
        end
        [cloudFolder,zipFileName] =  ...
            sendToCloud(gcp,scene3d,'uploadZip',uploadFlag);
        
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