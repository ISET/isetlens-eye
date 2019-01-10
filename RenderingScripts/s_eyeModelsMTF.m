%% s_eyeModelsMTF
% Render the slanted bar through the different eye models so that we can
% compare their on-axis performance

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

clusterName = 'models';
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
lqFlag = true;

planeDistance = 50;
scene3d = sceneEye('slantedBar','planeDistance',planeDistance);

scene3d.numBounces = 1;
scene3d.accommodation = 0;

if(lqFlag)
    scene3d.resolution = 256;
    scene3d.numRays = 128;
    scene3d.numCABands = 0;
else
    scene3d.numRays = 2048;
    scene3d.resolution = 1024;
    scene3d.numCABands = 16;
end

%% Run for several pupil diameters, models, and diffraction on/off

pupilDiameters = [4 6]; % [2 4 6];
fov = [2 3]; % we have to increase the FOV for the larger pupil diameter
diffFlag = 1; % [0 1]
modelNames = {'Navarro','LeGrand','Arizona'};

for ii = 1:length(diffFlag)
    for jj = 1:length(pupilDiameters)
        for kk = 1:length(modelNames)
            
            scene3d.diffractionEnabled = diffFlag(ii);
            scene3d.pupilDiameter = pupilDiameters(jj);
            
            % If the pupil diameter is small, we need to use more rays
            if(scene3d.pupilDiameter == 2 && ~lqFlag)
                scene3d.numRays = 8192;
            elseif(~lqFlag)
                scene3d.numRays = 2048;
            end
            
            % If the pupil diameter is larger, we increase the FOV since
            % we need to capture the spread of the PSF
            scene3d.fov = fov(jj);
           
            scene3d.modelName = modelNames{kk};
            scene3d.accommodation = 0;
            
            scene3d.name = sprintf('slantedBar%s_diff%d_pupil%dmm',...
                modelNames{kk},...
                diffFlag(ii),...
                pupilDiameters(jj));
            
%             oi = scene3d.render();
%             ieAddObject(oi);
%             oiWindow;
            
            % Upload the zip when we are done with the loop
            if(jj == length(pupilDiameters) &&...
               ii == length(diffFlag) && ...
               kk == length(modelNames))
                uploadFlag = true;
            else
                uploadFlag = false;
            end
            
            [cloudFolder,zipFileName] =  ...
                sendToCloud(gcp,scene3d,'uploadZip',uploadFlag);
            
        end
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