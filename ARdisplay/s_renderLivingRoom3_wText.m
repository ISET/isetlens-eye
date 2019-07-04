%% Render the living-room-3 scene 
%
% This scene has been manually ported into C4D and then converted back to
% PBRT. Having a C4D analog to the PBRT scene is very beneficial since
% ISET3d can parse the assets correctly. In addition, with the C4D scene on
% hand it becomes easier to place the camera or additional new objects into
% the scene.
%
% The original PBRT source for this scene can be found here:
% https://benedikt-bitterli.me/resources/
%
% TL has the C4D scene at the moment, but we can probably push it up
% somewhere public at some point.
%
% TL 2019

%% Initialize
ieInit;
clear; close all;

if ~piDockerExists, piDockerConfig; end
if isempty(which('RdtClient'))
    error('You must have the remote data toolbox on your path'); 
end

%% Read the pbrt files

% sceneName = 'living-room-3'; sceneFileName = 'living-room-3.pbrt';

% "Custom" scene
sceneName = 'living-room-3-text'; sceneFileName = 'living-room-3.pbrt';
inFolder = fullfile(isetlenseyeRootPath,'ARdisplay');

%{
% The output directory will be written here to inFolder/sceneName
inFolder = fullfile(piRootPath,'local','scenes');

if(~exist(fullfile(inFolder,sceneName),'dir'))
    % Get the PBRT scene from the database
    dest = piPBRTFetch(sceneName,'pbrtversion',3,...
        'destinationFolder',inFolder,...
        'delete zip',true);
end
%}

% This is the PBRT scene file inside the output directory
inFile = fullfile(inFolder,sceneName,sceneFileName);
thisR  = piRead(inFile);

%% Set quality

thisR.set('film resolution',round([640 640]*0.5));  
thisR.set('pixel samples',64);  
thisR.set('bounces',5);

% Cropped render of vases on table top
%r = [0.4281    0.5375    0.6000    0.8167];
%thisR.set('cropwindow',r);

% Cropped render of the corner of the carpet
%r = [0.6 0.75 0.75 1];
%thisR.set('cropwindow',r);

%% Set output

outFolder = fullfile(piRootPath,'local',sceneName);
outFile   = fullfile(outFolder,[sceneName,'.pbrt']);
thisR.set('outputFile',outFile);

%% Write
piWrite(thisR);

%% Render

%depth = piRender(thisR,'renderType','depth');
%imagesc(depth); 

[scene, result] = piRender(thisR);
sceneWindow(scene);

vcNewGraphWin();
depthMap = sceneGet(scene,'depth map');
imagesc(depthMap);
