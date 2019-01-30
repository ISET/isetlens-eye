%% plotEyeModelComparison.m
% Load slanted bar images rendered through three eye models. Calculate the
% MTF from each and compare them.

%% Initialize
clear; close all;
ieInit;

MTFfig = vcNewGraphWin; 

saveDir = fullfile(isetlenseyeRootPath,'outputImages','eyeModelsMTF');
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end

colors = {'r','g','b'};

%% Load the data

dirName = 'slantedBar_eyeModels'; 
dataDir = ileFetchDir(dirName);

pupilDiam = 3;

%% Calculate MTF from each image

modelNames = {'Arizona','LeGrand','Navarro'}; % Used for looping

for ii = 1:length(modelNames)
    
    fn = sprintf('slantedBar%s_diff%d_pupil%dmm.mat',modelNames{ii},1,pupilDiam);
    
    load(fullfile(dataDir,fn));
    
    [freq,mtf] = calculateMTFfromSlantedBar(oi);
    
    % Remove spurious resolution
    index = find(mtf<0.005);
    if(~isempty(index))
        index = index(1);
        mtf(index:end) = [];
        freq(index:end) = [];
    end
    
    figure(MTFfig); hold on;
    h{ii} = plot(freq,mtf,colors{ii});
    
    % Compare with Zemax (debug)
    %{
    fn = sprintf('%s_polychromatic_%dmm_0dpt_cycPermm_diff.txt',modelNames{ii},4);
    data = readZemaxMTF(fullfile(isetlenseyeRootPath,...
        'eyeModelComparison','zemax',fn));
    mmPerDeg = 0.2852;
    freq = data.spatial_frequency*mmPerDeg;
    plot(freq,data.MTF_tangential,colors{ii},'LineStyle',':');
    %}

end

%% Add Thibos data range

% These MTF's have been precalculated in the script:
%   generateMTFfromThibos.m

load(fullfile(isetlenseyeRootPath(),'onaxis_mtf','thibos','ThibosMTF_3mm.mat'));

% Plot
freq = freqAll(1,:); % These should all be the same.
try
    h{end+1} = stdshade(mtfAll,0.15,'k',freq,[]);
catch
    h{end+1} = errorbar(freq,mean(mtfAll),std(mtfAll),...
        'color','k',...
        'LineWidth',3);
end

%% Make plot prettier

figure(MTFfig);
grid on;
box on;
title(sprintf('On-Axis MTF \n (%d mm pupil, polychromatic)',...
    scene3d.pupilDiameter))
xlabel('Spatial Frequency (cycles/deg)');
ylabel('Contrast Reduction (SFR)');
% set(gca, 'YScale', 'log')
% set(gca, 'XScale', 'log')
% xticks([1 2 5 10 20 50 100])
% yticks([0.01 0.02 0.05 0.1 0.2 0.5 1])
% axis([0 100 0.01 1])

% thisAxis = gca;
% thisAxis.MinorGridAlpha = 0.15;

xlim([0 100])
% set(gca, 'YScale', 'log')
% set(gca, 'XScale', 'log')
% xticks([1 2 5 10 20 50 100])
% yticks([0.01 0.02 0.05 0.1 0.2 0.5 1])
% axis([1 100 0.01 1])
% thisAxis = gca;
% thisAxis.MinorGridAlpha = 0.15;

set(findall(gca,'-property','FontSize'),'FontSize',24)
set(findall(gca,'-property','LineWidth'),'LineWidth',3)

% set(MTFfig,'Position',[0.0070    0.3340    0.4629    0.5597]);
% set(gca,'Position',[0.1300    0.1100    0.7750    0.7847]);
% set(gcf,'Position',[0.0070    0.4708    0.2797    0.4389]);
set(gca,'Position',[0.1300    0.1100    0.7750    0.7827]);
set(gcf,'Position',[0.0069    0.2044    0.6356    0.6889]);

modelNames{2} = 'Le Grand';
modelNames{end+1} = 'Thibos (2002)';

legend([h{1} h{2} h{3} h{4}],modelNames,'location','northeast');

% Save out image
fn = fullfile(saveDir,'mtfFig.png');
NicePlot.exportFigToPNG(fn, MTFfig, 300); 



