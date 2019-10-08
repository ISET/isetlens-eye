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
% ieInit;
% clear; close all;

if ~piDockerExists, piDockerConfig; end
if isempty(which('RdtClient'))
    error('You must have the remote data toolbox on your path'); 
end

%% Read the pbrt files

sceneName = 'living-room-3-mini'; sceneFileName = 'living-room-3.pbrt';
% sceneName = 'living-room-3'; sceneFileName = 'living-room-3.pbrt';

%{
% The output directory will be written here to inFolder/sceneName
inFolder = fullfile(piRootPath,'local','scenes');

if(~exist(fullfile(inFolder,sceneName),'dir'))
    % Get the PBRT scene from the database
    dest = piPBRTFetch(sceneName,'pbrtversion',3,...
        'destinationFolder',inFolder,...
        'delete zip',true);
end

% This is the PBRT scene file inside the output directory
inFile = fullfile(inFolder,sceneName,sceneFileName);
%}

% Read the scene into a ISET3d recipe
inFolder = fullfile(isetlenseyeRootPath,'ARdisplay');
inFile = fullfile(inFolder,sceneName,'PBRT',sceneFileName);

thisR  = piRead(inFile);

%% Set quality

thisR.set('film resolution',round([640 360]*0.2));  
thisR.set('pixel samples',32);  
thisR.set('bounces',0);

% Cropped render of the corner of the carpet
% r = [0.6625    0.7375    0.7389    0.8611];
% thisR.set('cropwindow',r);

% Temp
% r = [0.3719    0.4188    0.5556    0.6278];
% thisR.set('cropwindow',r);

%% Set output

outFolder = fullfile(piRootPath,'local',sceneName);
outFile   = fullfile(outFolder,[sceneName,'.pbrt']);
thisR.set('outputFile',outFile);

%% Write
piWrite(thisR);

%% Render

[coordMap, result] = piRender(thisR,'renderType','coordinates');
vcNewGraphWin();
subplot(1,3,1); imagesc(coordMap(:,:,1)); axis image; colorbar; title('x-axis')
subplot(1,3,2); imagesc(coordMap(:,:,2)); axis image; colorbar; title('y-axis')
subplot(1,3,3); imagesc(coordMap(:,:,3)); axis image; colorbar; title('z-axis')

% [scene, result] = piRender(thisR);
% sceneWindow(scene);
%  
% vcNewGraphWin();
% depthMap = sceneGet(scene,'depth map');
% imagesc(depthMap);
% colorbar;

