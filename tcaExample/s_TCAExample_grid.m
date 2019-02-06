%% s_TCAExample_grid.m
%
% We want to show off the effects of TCA in our rendering. We can do this
% two ways, the obvious (but a bit boring) way is to render a grid like we
% often do in ISET. The other way is to use a 3D scene that shows TCA very
% clearly.
%
% We do the first method here. 
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
saveDirName = sprintf('tcaExample_grid_%s',currDate);
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

clusterName = 'tca';
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
lqFlag = true;

% We want a fairly large FOV to capture the effects at large
% eccentricities.
displayFOV = 60;

% Set up the planar texture to match this FOV
distance = 1;
width = 2*tand(displayFOV/2)*distance;
sz = [width width];

% Make an image of grid lines
% (Taken from sceneGridLines.m)
planeRes = 256;
lineSpacing = 16;
d = zeros(planeRes);
d(round(lineSpacing / 2):lineSpacing:planeRes, :) = 1;
d(:, round(lineSpacing / 2):lineSpacing:planeRes) = 1;

% Show the image and then save it
figure(); imshow(d);
imageTexture = fullfile(isetbioRootPath,'local','grid.png');
imwrite(d,imageTexture);

% We load up the textured plane scene with the parameters we calculated
% above:
scene3d = sceneEye('texturedPlane',...
                   'planeDistance',distance,...
                   'planeSize',sz,...
                   'planeTexture',imageTexture,...
                   'useDisplaySPD',1);

scene3d.fov = displayFOV;
scene3d.pupilDiameter = 4;

% Accommodate to the plane
scene3d.accommodation = 1/distance;

if(lqFlag)
    scene3d.numRays = 128; % LQ
    scene3d.resolution = 128;
    scene3d.numCABands = 0;
    
else
    scene3d.numRays = 4096;
    scene3d.resolution = 800;
    scene3d.numCABands = 16;
end

%% Test render the full image
% [oi, ~] = scene3d.render;
% ieAddObject(oi);
% oiWindow;

%% Flatten the retina to see what happens to the grid

% scene3d.retinaRadius = 1000;
% scene3d.name = 'tcaExample-flatRetina';
%     
% [oi, ~] = scene3d.render;
% ieAddObject(oi);
% oiWindow;

%% Set up crop windows
% We crop the image to get specific, high resolution patches showing TCA.

r_zoom(1,:) = [170   590   100   100];
r_zoom(2,:) = [400   401    100    100];

% We need to convert these rectangles to crop windows
cropwindows_all = zeros(size(r_zoom));
for ii = 1:size(r_zoom,1)
    r = r_zoom(ii,:);
    px = [r(1) r(1)+r(3) r(2) r(2)+r(4)];
    cropwindows_all(ii,:) = px./800;
end

% We have to increase the resolution since we're using a cropwindow
scene3d.resolution = 4096;

%% Loop through accommodations

% Loop through the crop windows
for jj = 1:size(cropwindows_all,1)
    
    scene3d.recipe.set('cropwindow',cropwindows_all(jj,:));
    
    % Scene name
    scene3d.name = sprintf('tcaExample_%i',jj);
    
    % Local
%     [oi, ~] = scene3d.render;
%     ieAddObject(oi);
%     oiWindow;
    
    % Cloud
    if(jj == size(cropwindows_all,1))
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