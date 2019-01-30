%% tcaExample.m
% Plot a scene that shows the effect of TCA in the retinal image. The scene
% consists of a large white grid. We plot specific parts of it to show TCA.

%% Initialize
ieInit;

%% Load the data
        
dirName = 'tcaExample'; % far data
dataDir = ileFetchDir(dirName);

% The whole image
load(fullfile(dataDir,'tcaExample.mat'));
oiFull = oi;
sceneFull = scene3d;
rgbFull = oiGet(oiFull,'rgb');

% Rendered crop windows
load(fullfile(dataDir,'tcaExample_1.mat'));
oiCrop_1 = oi;
sceneCrop_1 = scene3d;
rgbCrop_1 = oiGet(oiCrop_1,'rgb');

load(fullfile(dataDir,'tcaExample_2.mat'));
oiCrop_2 = oi;
sceneCrop_2 = scene3d;
rgbCrop_2 = oiGet(oiCrop_2,'rgb');

%% Convert rectangles for plotting

% From s_TCAExample_grid.m
r_1_px = [170   590   100   100];
r_2_px = [400   401    100    100];

% Convert from pixels to visual angle
x = sceneFull.angularSupport;
[r_1_deg, x_1, y_1] = convertRectPx2Ang(r_1_px,x);
[r_2_deg, x_2, y_2] = convertRectPx2Ang(r_2_px,x);

% We have to resample the axes to match the higher resolution crop window
% images
[x_1, y_1] = resampleCropWindowAxes(x_1,y_1,rgbCrop_1);
[x_2, y_2] = resampleCropWindowAxes(x_2,y_2,rgbCrop_2);

%% Plot

% Crop the full image a bit
r = [101 65 591 660];
[X,Y] = meshgrid(x,x);
rgbFull = imcrop(rgbFull,r);
X = imcrop(X,r);
Y = imcrop(Y,r);
x = X(1,:);
y = Y(:,1)';

% Full image 
% subplot(1,3,1);
H = figure();
image(x,y,rgbFull);
axis image; xlabel('deg');
rectangle('Position',r_1_deg,'EdgeColor','r','LineWidth',4)
rectangle('Position',r_2_deg,'EdgeColor','g','LineWidth',4)

% Save figure
set(findall(gcf,'-property','FontSize'),'FontSize',24)
fn = fullfile(isetlenseyeRootPath,'outputImages',...
    'tcaFull.png');
saveas(H,fn);

% Zoomed in pieces
% subplot(1,3,2);
H = figure(); 
image(x_1,y_1,rgbCrop_1);
axis image; xlabel('deg');
rectangle('Position',r_1_deg,...
    'EdgeColor','r',...
    'LineWidth',8)
% Save figure
set(findall(gcf,'-property','FontSize'),'FontSize',24)
fn = fullfile(isetlenseyeRootPath,'outputImages',...
    'tcaCrop1.png');
saveas(H,fn);

% subplot(1,3,3);
H = figure();
image(x_2,y_2,rgbCrop_2);
axis image; xlabel('deg');
rectangle('Position',r_2_deg,...
    'EdgeColor','g',...
    'LineWidth',8)
% Save figure
set(findall(gcf,'-property','FontSize'),'FontSize',24)
fn = fullfile(isetlenseyeRootPath,'outputImages',...
    'tcaCrop2.png');
saveas(H,fn);


%% Function for resampling the axes
function [x_new,y_new] = resampleCropWindowAxes(x_orig,y_orig,cropRGB)

x1 = linspace(0,1,length(x_orig));
x2 = linspace(0,1,size(cropRGB,2));
x_new = interp1(x1,x_orig,x2);

y1 = linspace(0,1,length(y_orig));
y2 = linspace(0,1,size(cropRGB,1));
y_new = interp1(y1,y_orig,y2);

end
