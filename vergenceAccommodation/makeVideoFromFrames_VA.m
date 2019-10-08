%% Write out a series of frames into a video

%% Initialize
clear; close all;

%% Load images

% Create figure

dirName = ileFetchDir('vergenceAccommodation_skymap');

videoname = 'VergenceAccommodation';

allFiles = dir(fullfile(dirName,'*.mat'));

nFiles = length(allFiles);
leftEyeImages = cell(nFiles/2,2);
rightEyeImages = cell(nFiles/2,2);

% Process names specifically for VA folder
kleft = 1; kright = 1;
for ii = 1:length(allFiles)
    clear oi; clear myScene;
    load(fullfile(dirName,allFiles(ii).name))
    
    % Parse filename
    filename = allFiles(ii).name;
    
    % Get distance
    dist = 1/myScene.accommodation;
    
    % Get rgb image
    rgb = oiGet(oi,'rgb');
    
    % Save images and distances
    if(contains(filename,'left'))
        leftEyeImages{kleft,1} = dist;
        leftEyeImages{kleft,2} = rgb;
        kleft = kleft+1;
    else
        rightEyeImages{kright,1} = dist;
        rightEyeImages{kright,2} = rgb;
        kright = kright+1;
    end

end

% Arrange according to distance
leftEyeImages = sortrows(leftEyeImages,1);
rightEyeImages = sortrows(rightEyeImages,1);
leftEyeImages = flipud(leftEyeImages);
rightEyeImages = flipud(rightEyeImages);

%% Write out the video

fid = figure('Position',[1000 1000 1024*2 1024]);

vidObj = VideoWriter(videoname,'MPEG-4'); %
% vidObj.set('Quality',100);

open(vidObj);

nFiles = size(leftEyeImages,1);

for ii = [1:nFiles nFiles:-1:1]
    
    currRGB_left = leftEyeImages{ii,2};
    currRGB_right = rightEyeImages{ii,2};
    
    % Brighten the images
    %currRGB_left = currRGB_left.^(0.6);
    %currRGB_left = hsv2rgb(rgb2hsv(currRGB_left) .* cat(3, 1, 1.2, 1));
    %currRGB_left = currRGB_left.*1.1;
    %currRGB_right = currRGB_right.^(0.6);
    %currRGB_right = hsv2rgb(rgb2hsv(currRGB_right) .* cat(3, 1, 1.2, 1));
    %currRGB_right = currRGB_right.*1.1;
    
    currDistance = leftEyeImages{ii,1};
    
    % Save image directly
    % imwrite(currRGB_left,'')
    
    fid;set(gcf,'color','w');
    
    h1 = subplot(1,2,1);
    imshow(currRGB_left);
    set(h1, 'Units', 'normalized');
    currPosition = get(h1,'Position');
    set(h1, 'Position', currPosition+[0.04 0 0 0]);
    title(sprintf('%0.2f D (Left)',1/currDistance),'FontSize',30)
    
%     ax = gca;
%     outerpos = ax.OuterPosition;
%     ti = ax.TightInset;
%     left = outerpos(1) + ti(1);
%     bottom = outerpos(2) + ti(2);
%     ax_width = outerpos(3) - ti(1) - ti(3);
%     ax_height = outerpos(4) - ti(2) - ti(4);
%     ax.Position = [left bottom ax_width ax_height];
    
    h2 = subplot(1,2,2);
    imshow(currRGB_right);
    set(h2, 'Units', 'normalized');
    currPosition = get(h2,'Position');
    set(h2, 'Position',currPosition-[0.04 0 0 0]);
    title(sprintf('%0.2f dpt (Right)',1/currDistance),'FontSize',30)
 
%     ax = gca;
%     outerpos = ax.OuterPosition;
%     ti = ax.TightInset;
%     left = outerpos(1) + ti(1);
%     bottom = outerpos(2) + ti(2);
%     ax_width = outerpos(3) - ti(1) - ti(3);
%     ax_height = outerpos(4) - ti(2) - ti(4);
%     ax.Position = [left bottom ax_width ax_height];

    for m=1:20 % write m frames - determines speed
        writeVideo(vidObj,getframe(fid));
    end
    
    clf;
end
 
close(vidObj);


