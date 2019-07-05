%% s_renderEyeModels
% Render the same scene using a couple of different eye models.

%% Initialize 
ieInit;
if ~mcDockerExists, mcDockerConfig; end % check whether we can use docker
if ~mcGcloudExists, mcGcloudConfig; end % check whether we can use google cloud sdk;

%% Initialize save folder
% Since rendering these images often takes a while, we will save out the
% optical images into a folder for later processing. 
currDate = datestr(now,'mm-dd-yy_HH_MM');
saveDirName = sprintf('models_%s',currDate);
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

clusterName = 'scenemodels';
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

%% Load up a scene
% Since the gullstrand model doesn't have accommodation, let's pick a scene
% that has objects that are far away and drop the FOV (potentially). 

% LQ mode flag (for testing)
lqFlag = false;

scene3d = sceneEye('lettersAtDepth',...
                    'Adist',1/1.4,...
                    'Bdist',1/1,...
                    'Cdist',1/0.6,...
                    'Adeg',1.5,...
                    'Cdeg',1,...
                    'nchecks',[128 64]);

% Try to shrink the size of the letters so we can drop the FOV
for ii = 1:length(scene3d.recipe.assets)
    if (strcmp(scene3d.recipe.assets(ii).name,'A') || ...
       strcmp(scene3d.recipe.assets(ii).name,'B') || ...
       strcmp(scene3d.recipe.assets(ii).name,'C'))
        scene3d.recipe.assets(ii).scale = [0.5;0.5;0.5];
    end
end

scene3d.fov = 5; 

if(lqFlag)
    scene3d.resolution = 256;
    scene3d.numRays = 128;
    scene3d.numCABands = 0;
else
    scene3d.numRays = 2048;
    scene3d.resolution = 800;
    scene3d.numCABands = 16;
end

% Turn off transmission, we can add it in later.
scene3d.lensDensity = 0.0;

%% Try the Navarro eye model
%{
% This tell isetbio which model to use.
scene3d.modelName = 'Navarro';

% The Navarro model has accommodation, but let's set it to infinity for now
% since other models may not have accommodation modeling.
scene3d.accommodation = 0;
scene3d.name = 'navarro'; % The name of the optical image

% oiNavarro = scene3d.render(); 
% ieAddObject(oiNavarro);
% oiWindow;

sendToCloud(gcp,scene3d,'uploadZip',false);

%% Try Arizona eye model

scene3d.modelName = 'Arizona';
scene3d.accommodation = 0;

scene3d.name = 'arizona'; % The name of the optical image

% oiArizona = scene3d.render();
% ieAddObject(oiArizona);
% oiWindow;

[cloudFolder,zipFileName] =  ...
    sendToCloud(gcp,scene3d,'uploadZip',false);
%}

%% Try the Gullstrand-LeGrand Model

% The gullstrand has no accommodation modeling. 
scene3d.modelName = 'LeGrand';
scene3d.name = 'LeGrand'; % The name of the optical image

% oiGullstrand = scene3d.render();
% ieAddObject(oiGullstrand);
% oiWindow;

sendToCloud(gcp,scene3d,'uploadZip',true);

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