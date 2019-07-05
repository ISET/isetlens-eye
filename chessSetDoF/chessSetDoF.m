%% chessSetDoF
% Load the chess set depth of field renders and put the images together
% into a video to show the DoF effect.

%% Initialize
clear; close all;
ieInit;

outputDir = fullfile(isetlenseyeRootPath,'outputImages','chessSetDoF');
if(~exist(outputDir,'dir'))
    mkdir(outputDir);
end

%% Load the data

dirName = 'chessSetDoF_skymap'; % far data
dataDir = ileFetchDir(dirName);
    
pupilDiameters = [2 4 6];
rgbData = [];
k = 1;
for ii = [1:length(pupilDiameters) length(pupilDiameters):-1:1]
    
    load(fullfile(dataDir,...
        sprintf('DoF%0.2fmm.mat',pupilDiameters(ii))));
    
    % Apply lens transmittance
    oi = applyLensTransmittance(oi,1.0);
    
    % Scale the mean illuminance to pupil size 
    % Not sure why this wasn't applied automatically when we initially
    % rendered
    lensArea = pi*(pupilDiameters(ii)/2)^2;
    meanIlluminance = 5*lensArea; % 5 lux per mm^2
    oi        = oiAdjustIlluminance(oi,meanIlluminance);
    oi.data.illuminance = oiCalculateIlluminance(oi);
    
    ieAddObject(oi);
    
    % Get the RGB image
    rgb = oiGet(oi,'rgb');
    rgbData = cat(4, rgbData, rgb);
    
    titles{k} = sprintf('%0.1f mm',pupilDiameters(ii));
    k = k + 1;
end

oiWindow;
    
%% Write out the video
%{
fn = fullfile(outputDir,'chessSetDoF_movie.mp4');

% The quality for this isn't great for some reason.
% ieMovie(rgbData,'vname',fn,'FrameRate',2,'titles',titles);

vidObj = VideoWriter(fn,'Uncompressed AVI'); %
open(vidObj);

nFiles = size(rgbData,4);

fid = figure();

for ii = [1:nFiles nFiles:-1:1]
    
    currRGB = rgbData(:,:,:,ii);
    
    figure(fid); imshow(currRGB);
    set(fid,'color','w');
    set(fid,'Position',[1704 572 651 700]);
    title(titles{ii},'FontSize',24)
    pause(0.5);
    
    for m=1:15 % write m frames - determines speed
        writeVideo(vidObj,getframe(fid));
    end

end

close(vidObj);
%}

%% Write out frames

pd_writeOut = [2 4 6];
% midPt = round(length(pupilDiameters)/2);

for ii = 1:length(pd_writeOut)
    idx = find(pupilDiameters == pd_writeOut(ii));
    singleFrame = rgbData(:,:,:,idx);
    fn = fullfile(outputDir,sprintf('chessSetDoF_%dmm.png',pd_writeOut(ii)));
    imwrite(singleFrame,fn);
end