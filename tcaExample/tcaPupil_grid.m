%% tcaExample.m
% Plot a scene that shows the effect of TCA in the retinal image as we move
% the pupil along the z-axis. 

%% Initialize
ieInit;
clear; close all;

%% Load the data
        
dirName = 'tcaPupil'; % far data
dataDir = ileFetchDir(dirName);

saveDir = fullfile(isetlenseyeRootPath,'outputImages','tcaPupil');
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end

%% Loop through and write out the images

% Unfortunately the cropwindow wasn't save correctly in scene3d due
% to the pointer nature of the class. I've saved it separately in a
% MAT file to fix this for now.
load(fullfile(dataDir,'cropwindows.mat'));
        
for pupilShift = [0 1.50] % pupil shift
    for cropwindow_indx = 1:3 % cropwindow
        
        fn = sprintf('tcaPupilShift_%0.2f_%d.mat',pupilShift,cropwindow_indx);
        load(fullfile(dataDir,fn));
        
        rgb = oiGet(oi,'rgb');
        x_full = scene3d.angularSupport;
        y_full = x_full; % Image is square
        [x_crop,y_crop] = ...
            calculateCropWindowAngularSupport(x_full,y_full,...
            cropwindows{cropwindow_indx},...
            rgb);
        
        %fprintf([fn '\n'])
        %fprintf('x-axis (full): %0.2f to %0.2f \n',x_full(1),x_full(end));
        %tmp = cropwindows{cropwindow_indx};
        %fprintf('Crop window: [%0.2f %0.2f %0.2f %0.2f] \n',tmp);
        %fprintf('x-axis: %0.2f to %0.2f \n',x_crop(1),x_crop(end));
        
        % Plot
        fontSize = 18;
        H = figure(1); clf;
        set(gcf, 'Color', [1 1 1])
        imshow(rgb); hold on; axis on;
        xticklabels = linspace(x_crop(1),x_crop(end),5);
        xticks = linspace(1, size(rgb, 2), numel(xticklabels));
        set(gca, 'XTick', xticks,...
            'XTickLabel', sprintf('%2.1f\n', xticklabels),...
            'FontSize', fontSize)
        yticklabels = linspace(y_crop(1),y_crop(end),5);
        yticks = linspace(1, size(rgb, 1), numel(yticklabels));
        set(gca, 'YTick', yticks,...
            'YTickLabel', sprintf('%2.1f\n', yticklabels),...
            'FontSize', fontSize)
        box(gca,'off')
        xlabel('\it space (degs)','FontSize', fontSize);
        set(gcf,'Position',[31 6 611 577]);

        % Save out the figure
        outputfn = fullfile(saveDir,...
            sprintf('tcaPupilShift_%0.2f_%d.png',pupilShift,cropwindow_indx));
        NicePlot.exportFigToPNG(outputfn, gcf, 300); 

    end
end

