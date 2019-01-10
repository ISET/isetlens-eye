%% plotEyeModelComparison.m
% Load slanted bar images rendered through three eye models. Calculate the
% MTF from each and compare them.

%% Initialize
clear; close all;
ieInit;

saveDir = fullfile(isetlenseyeRootPath,'outputImages','eyeModelsMTF');
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end

colors = {'r','g','b'};

%% Load the data

dirName = 'slantedBar_eyeModels'; 
dataDir = ileFetchDir(dirName);

%% Calculate MTF from each image

mtfFig = figure(); hold on; grid on;
set(mtfFig, 'Color', [1 1 1], 'Position', [520 282 601 516]);

modelNames = {'Arizona','LeGrand','Navarro'}; % Used for looping

for ii = 1:length(modelNames)
    
    fn = sprintf('slantedBar%s_diff%d_pupil%dmm.mat',modelNames{ii},1,4);
    
    load(fullfile(dataDir,fn));
    
    [freq,mtf] = calculateMTFfromSlantedBar(oi);
    
    % Remove spurious resolution
    index = find(mtf<0.005);
    if(~isempty(index))
        index = index(1);
        mtf(index:end) = [];
        freq(index:end) = [];
    end
    
    figure(mtfFig);
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

%% Make plot prettier

% modelNames{2} = 'Le Grand';
legend([h{1} h{2} h{3}],modelNames,'location','southwest');

box on;
title(sprintf('On-Axis MTF \n (%d mm pupil, polychromatic)',...
    scene3d.pupilDiameter))
xlabel('Spatial Frequency (cycles/deg)');
ylabel('Contrast Reduction (SFR)');
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')
xticks([1 2 5 10 20 50 100])
yticks([0.01 0.02 0.05 0.1 0.2 0.5 1])
axis([1 100 0.01 1])

thisAxis = gca;
thisAxis.MinorGridAlpha = 0.15;

set(findall(gca,'-property','FontSize'),'FontSize',24)
set(findall(gca,'-property','LineWidth'),'LineWidth',3)

% Save out image
saveas(mtfFig,fullfile(saveDir,'modelComparisonMTF.png'));
