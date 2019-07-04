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

% Global rays/resolution 
globalRays = 32;
globalRes = 128;

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
thisEye.accommodation = 1; % Front text
thisEye.pupilDiameter = 4;
thisEye.numCABands = 8; % Include chromatic aberration

% Rendering parameters
thisEye.debugMode = false;
thisEye.numRays = globalRays;
thisEye.resolution = globalRes;

thisEye.name = 'oiRef';
[oiRef,result] = thisEye.render();
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

%% Convert oiText into an RGB image to put on a display

% The display we use in PBRT is close to an sRGB display, so this should
% work, theoretically. I anticipate needing to debug this in the future...
rgbImage = oiGet(oiText,'rgb');

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
thisEye.accommodation = 1; % Front text
thisEye.pupilDiameter = 4;
thisEye.numCABands = 8; % Include chromatic aberration

% Rendering parameters
thisEye.debugMode = false;
thisEye.numRays = globalRays;
thisEye.resolution = globalRes;

% Render
thisEye.name = 'oiDisplay';
[oiDisplay, result] = thisEye.render();
oiWindow(oiDisplay);






