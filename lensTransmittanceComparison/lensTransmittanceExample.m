%% Lens transmittance
% Save some figures demonstrating the application of the lens
% transmittance. 

%% Initialize
ieInit;
close all; clear;

saveDir = fullfile(isetlenseyeRootPath,'outputImages','transmittance');
if(~exist(saveDir))
    mkdir(saveDir);
end

%% Load an optical image

dataDir = ileFetchDir('colorfulScene');
load(fullfile(dataDir,'ColorfulScene.mat'));

%% Get RGB without transmittance
rgb = oiGet(oi,'rgb');

figure(1);
imshow(rgb);

fn = fullfile(saveDir,'rgbNoTrans.png');
imwrite(rgb,fn);

%% Add transmittance
oi_transmit = applyLensTransmittance(oi,1);
rgb_transmit = oiGet(oi_transmit,'rgb');

figure(1);
imshow(rgb_transmit);

fn = fullfile(saveDir,'rgbTrans.png');
imwrite(rgb_transmit,fn);

%% Plot transmittance

[udata, g] = oiPlot(oi, 'lens transmittance');

% Remove title
ax = get(g,'CurrentAxes');
ax.Title = [];

% Change line color
hline = findobj(g, 'type', 'line');
set(hline(1),'Color','k');

set(findall(ax,'-property','FontSize'),'FontSize',40)
set(findall(ax,'-property','LineWidth'),'LineWidth',6)

fn = fullfile(saveDir,'lens_transmittance.png');
NicePlot.exportFigToPNG(fn, gcf, 300); 

