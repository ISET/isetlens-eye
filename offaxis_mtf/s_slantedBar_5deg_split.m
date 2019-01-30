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

% Setup scene
scene3d = sceneEye('slantedBar',...
    'planeDistance',planeDistance);

scene3d.fov= 12;
scene3d.accommodation = 0;
scene3d.pupilDiameter = 6;

sceneResolution = 3072;
scene3d.resolution = sceneResolution;
scene3d.numRays = 1024;
scene3d.numCABands = 16;
scene3d.numBounces = 1;

scene3d.name = sprintf('slantedBar_%ddeg',scene3d.fov);

% Instead of moving the scene, let's just render a large FOV, we can use it
% for future calculations as well. To make the render more efficient, let's
% split the scene into different windows.
n = 4;
assert(mod(sceneResolution/n,1) == 0); % Must be divisible
sceneMosaic = cell(n,n);

% Approximate crop window for 5 degrees

deltaCropWindow = 1/n;
xMin = -deltaCropWindow; xMax = 0;
for x = 1:n
    xMin = xMin+deltaCropWindow;
    xMax = xMax+deltaCropWindow;
    
    yMin = -deltaCropWindow; yMax = 0;
    for y = 1:n
        
        yMin = yMin+deltaCropWindow;
        yMax = yMax+deltaCropWindow;
        
        currScene = copy(scene3d);
        
        currScene.recipe.set('cropwindow',...
            [xMin xMax yMin yMax])
        currScene.name = [scene3d.name sprintf('_%i_%i',y,x)];
        
        if(x == n && y == n)
            uploadFlag = true;
        else
            uploadFlag = false;
        end
        [cloudFolder,zipFileName] =  ...
            sendToCloud(gcp,currScene,'uploadZip',uploadFlag);
        
        fprintf('------------ \n');
        fprintf('(%i,%i) \n',x,y);
        
        sceneMosaic{y,x} = currScene;
        
        % We have to do this to avoid an error. The issue is that when we
        % run "sendToCloud(...currScene)" the output directory is changed.
        % When it is changed, the original scene files are copied from
        % iset3d/local to the new working directory, isetbio/local. However
        % the output directory for scene3d is still iset3d/local even
        % though there's no data in there. 
        % What's the best way to get rid of this issue?
        if(~strcmp(scene3d.recipe.outputFile,currScene.recipe.outputFile))
            % We can't use the recipeSet function here...
            scene3d.recipe.outputFile = currScene.recipe.outputFile;
        end
        
    end
end

% A hack
% Remove the crop window in the scene
% Long story short we have some issues with deep copying the recipe
scene3d.recipe.set('cropwindow',[0 1 0 1]);
scene3d.recipe.camera = currScene.recipe.camera;

%% Render
gcp.render();

%% Check for completion
% Save the gCloud object in case MATLAB closes
gCloudName = sprintf('%s_gcpBackup_%s',mfilename,currDate);
save(fullfile(saveDir,gCloudName),'gcp','saveDir','sceneMosaic','scene3d');

% Pause for user input (wait until gCloud job is done)
x = 'N';
while(~strcmp(x,'Y'))
    x = input('Did the gCloud render finish yet? (Y/N)','s');
end


%% Download the data

[ieAll, seAll] = downloadFromCloud(gcp,'scaleIlluminance',false);

% Recombine pieces
photonsCombined = cell(size(sceneMosaic));
depthMapCombined  = cell(size(sceneMosaic));
for ii=1:length(seAll)
    
    ieObj = ieAll{ii};
    
    ieAddObject(ieObj);
    oiWindow;
    
    myScene = seAll{ii};
    
    % Figure out piece location
    y = str2double(myScene.name(end-2));
    x = str2double(myScene.name(end));
    
    depthMapCombined{y,x} = oiGet(ieObj,'depth map');
    photonsCombined{y,x} = oiGet(ieObj,'photons');
end

% Make a new oi to put everything in
oi = piOICreate(cell2mat(photonsCombined));
oi = setOI(scene3d,oi);
oi = oiSet(oi,'depth map',cell2mat(depthMapCombined));

ieAddObject(oi);
oiWindow;

saveFilename = fullfile(saveDir,[scene3d.name '.mat']);
save(saveFilename,'oi','scene3d');

