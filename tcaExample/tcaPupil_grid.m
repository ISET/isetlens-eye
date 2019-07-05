%% tcaExample.m
% Plot a scene that shows the effect of TCA in the retinal image as we move
% the pupil along the z-axis. 

%% Initialize
ieInit;
clear; close all;

%% Load the data
        
dirName = 'tcaPupilACD'; % far data
dataDir = ileFetchDir(dirName);

saveDir = fullfile(isetlenseyeRootPath,'outputImages','tcaPupilACD');
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end

%% Loop through and write out the images

% Unfortunately the cropwindow wasn't saved correctly in scene3d due
% to the pointer nature of the class. I've saved it separately in a
% MAT file to fix this for now.
load(fullfile(dataDir,'cropwindows.mat'));
        
for acd = [2.57 3.29] % ACD shift
    for cropwindow_indx = 1:3 % cropwindow
        
        fn = sprintf('navarroAccommodated_1.00_acd_%0.2f_%d.mat',acd,cropwindow_indx);
        load(fullfile(dataDir,fn));
        
        % oi = applyLensTransmittance(oi,1.0);
        
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
        H = figure(1); 
        H = plotWithAngularSupport(x_crop,y_crop,rgb,...
            'NumTicks',3,...
            'FontSize',24);
        
%         set(gcf, 'Color', [1 1 1])
%         imshow(rgb); hold on; axis on;
%         xticklabels = linspace(x_crop(1),x_crop(end),5);
%         xticks = linspace(1, size(rgb, 2), numel(xticklabels));
%         set(gca, 'XTick', xticks,...
%             'XTickLabel', sprintf('%2.1f\n', xticklabels),...
%             'FontSize', fontSize)
%         yticklabels = linspace(y_crop(1),y_crop(end),5);
%         yticks = linspace(1, size(rgb, 1), numel(yticklabels));
%         set(gca, 'YTick', yticks,...
%             'YTickLabel', sprintf('%2.1f\n', yticklabels),...
%             'FontSize', fontSize)
%         box(gca,'off')
%         xlabel('\it space (degs)','FontSize', fontSize);
%         set(gcf,'Position',[31 6 611 577]);

        % Save out the figure
        outputfn = fullfile(saveDir,...
            sprintf('tcaACDLength_%0.2f_%d.png',acd,cropwindow_indx));
        NicePlot.exportFigToPNG(outputfn, H, 300); 

    end
end

