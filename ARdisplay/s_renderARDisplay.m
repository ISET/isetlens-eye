%% s_renderARDisplay.m
%
% We have a 3D background model (this represents the "real" world within
% the simulation) + and object we want to project (this represent a
% "virtual" object within the simulation) using the AR display
%
% Step 1: Render an the background + the object through the eye. This is
% the REFERENCE retinal irradiance.
%
% Step 2: Render only the background through the eye. These are the photons
% coming from the "real" world.
%
% Step 3: Render the object only through a pinhole/perspective camera. This
% is the RGB image that will be put on the display.
%
% Step 4: Render a flat 2D plane, at a certain focal distance, through the
% eye. Texture the plane (properly) using the RGB image. These are the
% photons coming from the display.
%
% Step 5: Add the photons from Step 4 and Step 2 together. This is the TEST
% retinal irradiance. 

%% Initialize
ieInit; clear; close all;

saveDir = fullfile(isetlenseyeRootPath,'ARdisplay','output');
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end
saveFlag = true;

% Global rays/resolution 
globalRays = 64;
globalRes  = 128;

% Global eye parameters
accomm    = 1;
pupilDiam = 4;
caBands    = 8;
fov       = 40;

%% Step 1
% Render an the background + the object through the eye. This is the
% REFERENCE retinal irradiance.

% Read the scene into a ISET3d recipe
sceneName = 'living-room-3-text'; sceneFileName = 'living-room-3.pbrt';
inFolder = fullfile(isetlenseyeRootPath,'ARdisplay');
inFile = fullfile(inFolder,sceneName,sceneFileName);

% Load with sceneEye
thisEye = sceneEye(inFile);

% Do a quick render to get an idea of what things look like
% ~1 min on an 8 core machine
%{
thisEye.numBounces = 5;
thisEye.numRays = 64;
thisEye.resolution = 256;
thisEye.accommodation = 1;
thisEye.fov = 40;

thisEye.debugMode = true; % Use a pinhole camera
thisEye.name = 'testRender';
[scene,output] = thisEye.render();
sceneWindow(scene);
%}

% Set eye parameters
thisEye.accommodation = accomm; 
thisEye.pupilDiameter = pupilDiam;
thisEye.numCABands = caBands; 
thisEye.fov = fov;

% Rendering parameters
thisEye.debugMode = false;
thisEye.numRays = globalRays;
thisEye.resolution = globalRes;

thisEye.name = 'oiRef';
[oiRef,result] = thisEye.render();
oiRef = oiSet(oiRef,'mean illuminance',100);
oiWindow(oiRef);

%% Step 2
% Render only the background through the eye. These are the photons
% coming from the "real" world.

thisRecipe = thisEye.recipe;
thisRecipeNoText = thisRecipe.copy();

% Remove text objects from assets
numAssets = length(thisRecipeNoText.assets);
textAssetsIndex = [];
for ii = 1:numAssets
    if(piContains(thisRecipeNoText.assets(ii).name,'Text'))
        textAssetsIndex = [textAssetsIndex ii];
    end
end   
thisRecipeNoText.assets(textAssetsIndex) = [];

% Render again
thisEye.recipe = thisRecipeNoText;

thisEye.name = 'oiBG';
[oiBG,result] = thisEye.render();

% Set a reasonable illuminance from the background
oiBG = oiSet(oiBG,'mean illuminance',100);
oiWindow(oiBG);

%% Step 3
% Render the object only through a pinhole/perspective camera. This is the
% RGB image that will be put on the display.

thisRecipeTextOnly = thisRecipe.copy();
thisRecipeTextOnly.assets = [];
thisRecipeTextOnly.assets = thisRecipe.assets(textAssetsIndex);

% We have to remove the fuzz on the rug manually since it's a PBRT file
% that's not a part of the geometry.
oldString = 'Include "models/unhidden.pbrt"';
newString = '# Include "models/unhidden.pbrt"';
thisRecipeTextOnly = piWorldFindAndReplace(thisRecipeTextOnly,oldString,newString);

% Render with a pinhole camera
pinholeCamera = thisEye.copy();
pinholeCamera.recipe = thisRecipeTextOnly;
pinholeCamera.debugMode = true; % Perspective
pinholeCamera.accommodation = 0; % Is this right?
pinholeCamera.numCABands = 0;

pinholeCamera.name = 'oiText';
[sceneText,result] = pinholeCamera.render();
sceneWindow(sceneText);

%% Step 4:
% Render a flat 2D plane, at a certain focal distance, through the eye.
% Texture the plane (properly) using the RGB image. These are the photons
% coming from the display.

% The display we use in PBRT is close to an sRGB display, so this should
% work, theoretically. I anticipate needing to debug this in the future...
rgbImage = oiGet(sceneText,'rgb');

% Write it out
imageTexturePath = fullfile(saveDir,'rgbImage.png');
imwrite(rgbImage,imageTexturePath);

% Calculate plane size
% We have to be careful about this to get things to line up right. I
% anticipate debugging here as well.
desiredFOV = thisEye.fov;
vDist = 1; % meters
displayWidth = 2*vDist*tand(desiredFOV/2); % meters

% Make a planar scene
thisEye = sceneEye('texturedPlane',...
                   'planeDistance',vDist,...
                   'planeSize',[displayWidth displayWidth],...
                   'planeTexture',imageTexturePath,...
                   'gamma','true',...
                   'useDisplaySPD','true');

% Set eye parameters
thisEye.accommodation = accomm; 
thisEye.pupilDiameter = pupilDiam;
thisEye.numCABands = caBands; 
thisEye.fov = fov;

% Rendering parameters
thisEye.debugMode = false;
thisEye.numRays = globalRays;
thisEye.resolution = globalRes;

% Render
thisEye.name = 'oiDisplay';
[oiDisplay, result] = thisEye.render();

% Set a reasonable illuminance from the display
oiDisplay = oiSet(oiDisplay,'mean illuminance',50);
oiWindow(oiDisplay);

%% Save OI
if(saveFlag)
    formatOut = 'mm_dd_HH_MM';
    timestamp = datestr(now,formatOut);
    fn = fullfile(saveDir,sprintf('Output_%s.mat',timestamp));
    save(fn,'oiRef','oiDisplay','oiBG','oiText','rgbImage',...
        'thisEye');
end

%% Step 5:
% Add the photons from Step 4 and Step 2 together. This is the TEST retinal
% irradiance.

photonsDisplay = oiGet(oiDisplay,'photons');
photonsBG = oiGet(oiBG,'photons');

% Find scaling for display photons

%{
rgb = oiGet(oiARdisplay,'rgb');
vcNewGraphWin();
imshow(rgb);
title(sprintf('Select point on object. Hit ENTER when finished.'));
[X,Y] = getpts();
X = round(X); Y = round(Y);
%}
X = 119; Y = 181; % For 256x256 resolution

ptPhotonsDisplay = squeeze(photonsDisplay(Y,X,:));
ptPhotonsBG = squeeze(photonsBG(Y,X,:));
photonsRef = oiGet(oiRef,'photons');
ptPhotonsRef = squeeze(photonsRef(Y,X,:));

vcNewGraphWin();
subplot(1,2,1);
wave = oiGet(oiARdisplay,'wave');
plot(wave,ptPhotonsDisplay); hold on;
plot(wave,ptPhotonsRef);
plot(wave,ptPhotonsBG);
xlabel('Wave'); ylabel('Photons')
legend('Display','Ground Truth','Background');

scalingFactor = (ptPhotonsRef - ptPhotonsBG)./ptPhotonsDisplay;
subplot(1,2,2);
plot(wave,scalingFactor);
title('Ratio: Ref/Display')

minRatio = min(scalingFactor);
vcNewGraphWin();
plot(wave,ptPhotonsDisplay.*minRatio); hold on;
plot(wave,ptPhotonsRef);
xlabel('Wave'); ylabel('Photons')
legend('Display (scaled)','Ground Truth');

testRatio = max(scalingFactor);
% Sum up, but with scaling
photonsTotal = photonsDisplay.*testRatio + photonsBG;

oiARdisplay = oiBG; % Make a copy
oiARdisplay = oiSet(oiARdisplay,'photons',photonsTotal); % Set photons
oiARdisplay = oiSet(oiARdisplay,'name','oiARdisplay');

oiWindow(oiARdisplay);

%% Plot background vs text photons
% Debugging
% Background is actually lighter than the object (text). There no way an
% addition of photons will result in something similar in luminance to the
% reference.

rgb = oiGet(oiRef,'rgb');
vcNewGraphWin();
imshow(rgb.^(0.5)); 
% [X, Y] = getpts();
textPt = [118 167]; % for 256 res
sofaPt = [122 168]; % for 256 res

% Check color
textRGB = rgb(textPt(2),textPt(1),:).^(0.5);
sofaRGB = rgb(sofaPt(2),sofaPt(1),:).^(0.5);
textRGB = repmat(textRGB,[100 100 1]);
sofaRGB = repmat(sofaRGB,[100 100 1]);
vcNewGraphWin();
subplot(1,2,1);
imshow(textRGB);
subplot(1,2,2);
imshow(sofaRGB);

% Plot
textPhotonsRef = squeeze(photonsRef(textPt(2),textPt(1),:));
sofaPhotonsRef = squeeze(photonsRef(sofaPt(2),sofaPt(1),:));
vcNewGraphWin();
plot(wave,textPhotonsRef); hold on;
plot(wave,sofaPhotonsRef);
legend('Text (object)','Sofa (background)')
grid on;
xlabel('Wavelength (nm)');
ylabel('Photons');








