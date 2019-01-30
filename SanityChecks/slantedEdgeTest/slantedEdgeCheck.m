%% slantedEdgeCheck.m
% Check the MTF calculation over different resolutions of the slanted edge
% scene. 
%
% Using the Nyquist theorem:
% We know the eye goes out to about 100 cyc/deg
% We know that we need at least 2 pixels per cycle
% So at the very least we need 200 pixels/deg
% So if we take a 2 deg window, we need at least 400x400 pixels
%
%% Initialize
ieInit;
close all; clear;

% Load the data
% Data was rendered from script: s_slantedEdgeCheck.m
dataDir = ileFetchDir('slantedBar_sanityCheck');

mtfFig = figure(); hold on;

%% Load the ground truth (from Zemax)

data = readZemaxMTF(fullfile(isetlenseyeRootPath,'onaxis_mtf',...
    'zemax','mtf_geometric_photopic_4mm_0dpt_cycmm_nodiff.txt'));

figure(mtfFig);

mmPerDeg = 0.2881; % Approximate
plot(data.spatial_frequency.*mmPerDeg,...
    data.MTF_tangential,'k:');

%% Loop through resolutions, calculate MTF


resolutions = [128 256 512 1024];

for ii = 1:length(resolutions)
    
    load(fullfile(dataDir,'nodiffraction',...
        sprintf('slantedBar_res%d.mat',resolutions(ii))))
    
    [freq,mtf] = calculateMTFfromSlantedBar(oi);
    
    % Plot
    figure(mtfFig);
    plot(freq,mtf);
    
end

%% Clean up the figure
grid on;
title(sprintf('On-Axis MTF \n (4 mm pupil, polychromatic)'))
xlabel('Spatial Frequency (cycles/deg)');
ylabel('Contrast Reduction (SFR)');

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

legend('Zemax','128x128','256x256','512x512','1024x1024');

