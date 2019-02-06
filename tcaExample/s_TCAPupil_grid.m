%% s_TCAPupil_grid.m
%
% Play with effect of TCA when we move the pupil along the z-axis.
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
saveDirName = sprintf('tcaPupil_grid_%s',currDate);
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
    'projectid',projectid,...
    'maxInstances',20);
toc

% Render depth
gcp.renderDepth = true;

% Clear the target operations
gcp.targets = [];

%% Setup scene

% LQ mode flag (for testing)
lqFlag = false;

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
d(lineSpacing:lineSpacing:(planeRes-lineSpacing), :) = 1;
d(:, lineSpacing:lineSpacing:(planeRes-lineSpacing)) = 1;

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
scene3d.numBounces = 1;

% Accommodate to the plane
scene3d.accommodation = 1/distance;


%% Fast test render for full grid
% [oi, ~] = scene3d.render;
% ieAddObject(oi);
% oiWindow;

%% Move the pupil

% First generate a lens file
lensDir = fullfile(isetlenseyeRootPath,...
    'tcaExample','tmpLensData');
if(~exist(lensDir,'dir'))
    mkdir(lensDir);
end
tmpFilename = fullfile(lensDir,'tmpNavarroLens.dat');
writeNavarroLensFile(scene3d.accommodation,tmpFilename);

% Read into a matrix
lensMatrix = readRealisticEyeLensFile(tmpFilename);

% Calculate axial position for each surface
thickness = lensMatrix(:,3);
axialPositions = zeros(size(thickness));
tmp = 0;
for ii = 1:length(thickness)
    axialPositions(ii) = tmp;
    tmp = tmp + thickness(ii);
end

% The axialPositions vector should correspond to the axial position
% relative to the anterior cornea for the surfaces:
% 1. anterior_cornea
% 2. posterior_cornea
% 3. pupil_plane
% 4. anterior_lens
% 5. posterior_lens

% Move the pupil
deltaPupil = [0 1.5];
lensFilenames = cell(length(deltaPupil),1);
for ii = 1:length(deltaPupil)
    
    % Shift the axial positions
    % We are moving the pupil toward the scene/cornea
    currAxialPositions = axialPositions;
    currAxialPositions(3) = currAxialPositions(3) - deltaPupil(ii);
    
    % Recalculate the thickness
    currAxialPositions(end+1) = currAxialPositions(end);
    currThickness = currAxialPositions(2:end) - currAxialPositions(1:(end-1));
    
    % Write out a new lens files
    currLensMatrix = lensMatrix;
    currLensMatrix(:,3) = currThickness;
    
    lensFilenames{ii} = fullfile(lensDir,...
        sprintf('navarroAccommodated_%0.2f_pupilShift_%0.2f.dat',...
        scene3d.accommodation,deltaPupil(ii)));
    writeRealisticEyeLensFile(currLensMatrix,...
        lensFilenames{ii},...
        scene3d.accommodation)
   
end

%% Take windows along the horizontal and vertical meridian

%{
window_width_deg = 2;
fov_max = scene3d.fov/2;
ecc = [20 15 10 5];

x = scene3d.angularSupport;

for ii = 1:length(ecc)
    
    x_min = ecc-window_width_deg/2;
    x_max = ecc+window_width_deg/2;
    
    diff = x - x_min;
    indx_min = (diff == min(diff));
    
    diff = x - x_max;
    indx_max = (diff == min(diff));
    
    window_width_px = indx_max - indx_min;
    
end
%}

% Let's select the points manually so we can get the cross points on the
% grid

% Show rectangles?
showRectFlag = true;

% Determines window resolution
fullResolution = 8192;

% Render a quick draft image to find the points
% Takes around 30 sec
if(showRectFlag)
    scene3d.resolution = 512;
    scene3d.numRays = 128;
    scene3d.numCABands = 0;
    [oi, ~] = scene3d.render;
    rgb = oiGet(oi,'rgb');
    H = figure();
    imshow(rgb); hold on;
end

% sz = size(rgb);
% sz = round(sz/2);
% hold on; plot(sz(1),sz(2),'rx');
% [xi,yi] = getpts(H);

% Output from the above
% xi = [216,175,132,256,256,257];
% yi = [256,257,256,218,177,132];
xi = [256 196 131];
yi = [256,256,256];

% How many samples is roughly 4 degrees for this 512x512 image?
% Answer: Roughly 30
xi_min = xi - 10;
yi_min = yi - 10;

% Make crop windows and draw rectangles on test image
cropWindows_all = cell(length(xi_min),1);
for ii = 1:length(xi_min)
    
    curr_r = [xi_min(ii) yi_min(ii) 20 20];
    
    if(showRectFlag)
%         figure(H);
%         rectangle('Position',curr_r,'EdgeColor','r');
        rgb = insertShape(rgb, 'rectangle', curr_r,...
            'LineWidth', 6,'Color','r'); 
        if(ii == 1 || ii == 2 || ii == 3 )
            numberPos = curr_r(1:2) - [30 60];
        else
            numberPos = curr_r(1:2) - [20 20];
        end
        rgb = insertText(rgb, numberPos, num2str(ii),...
            'TextColor','r',...
            'FontSize',30,...
            'BoxColor',[1 1 1],...
            'BoxOpacity',0.8);
        figure(H);
        imshow(rgb);
    end
    
    curr_cropwindow = rect2cropwindow(curr_r,512,512);
    
    % Calculate the window resolution, given the current full resolution
    windowResolution = fullResolution*(curr_cropwindow(2)-curr_cropwindow(1));
    
    cropWindows_all{ii} = curr_cropwindow;
    
end

%% Reset scene parameters
if(lqFlag)
    scene3d.numRays = 256; % LQ
    scene3d.resolution = 512;
    scene3d.numCABands = 8;
    
else
    scene3d.numRays = 4096;
    scene3d.resolution = fullResolution;
    scene3d.numCABands = 16;
end

%% Get rid of empty black space
% r = [72    63   369   387]; % for 512 by 512 image
% cropwindow = rect2cropwindow(r,512,512);
% scene3d.recipe.set('cropwindow',cropwindow);

%% Render with the new lens files and for each crop window

% Loop through the new lens files
for ii = 1:length(deltaPupil)
    
    % Switch lens file
    scene3d.lensFile = lensFilenames{ii};
    
    for jj = 1:length(cropWindows_all)
        
        % Add crop window
        scene3d.recipe.set('cropwindow',cropWindows_all{jj});
    
        % Scene name
        scene3d.name = sprintf('tcaPupilShift_%0.2f_%d',deltaPupil(ii),jj);
        
        % Local
        %     [oi, ~] = scene3d.render;
        %     ieAddObject(oi);
        %     oiWindow;
        
        % Cloud
        if(ii == length(deltaPupil) &&...
                jj == length(cropWindows_all))
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