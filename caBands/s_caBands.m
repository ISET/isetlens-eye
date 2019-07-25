%% Chromatic aberration
% How many CA Bands do we need?

%% Initialize
ieInit; clear; close all;

%% Load the scene

% The plane is placed at 3 meters
thisScene = sceneEye('slantedBar',...
                   'planeDistance',1);
                   
thisScene.fov = 1.5;
thisScene.resolution = 256;
thisScene.numRays = 1024;
thisScene.numCABands = 0;
thisScene.accommodation = 1/1; % Accommodate to the plane

% r = [8     8     4     4];
% cropwindow_px = [r(1) r(1)+r(3) r(2) r(2)+r(4)];
% cropwindow_norm = cropwindow_px./thisScene.resolution;
% thisScene.recipe.set('cropwindow',cropwindow_norm);

% No lens transmittance
thisScene.lensDensity = 0.0;

%% Loop over CA Bands

ca = [0 2 4 8 16];
oiCA = cell(length(ca),1);
renderingTime = zeros(length(ca),1);

figIrradiance = vcNewGraphWin();
for ii = 1:length(ca)
    
    thisScene.numCABands = ca(ii); 
    
    %{
    t = tic;
    oi = thisScene.render();
    renderingTime(ii) = toc(t);
        
%     % Plot irradiance of this patch
    rgb = oiGet(oi,'rgb');
    vcNewGraphWin(); imshow(rgb);
    % getrect();
    r = [152    77    50    50];
    rectangle('Position',r,'EdgeColor','r');
    
    % Crop
%     res = oiGet(oi,'rows');
%     cropRadius = res/(2*sqrt(2))-5;
%     centerPixel = res/2;
%     oi = oiCrop(oi,round([centerPixel-cropRadius centerPixel-cropRadius ...
%         cropRadius*2 cropRadius*2]));
    
    oi = oiSet(oi,'name',sprintf('CABands_%d',ii));
    oiWindow(oi);
    
    oiCA{ii} = oi;
        %}
    
    figure(figIrradiance);
    hold on;
    wave = oiGet(oi,'wave');
    croppedOI = oiCrop(oi,r);
    photons = oiGet(croppedOI,'photons');
    % photons = oiGet(oi,'photons');
    photons = squeeze(mean(mean(photons,1),2));
    plot(wave,photons);
    
    % Save OI along the way
    fn = fullfile(isetlenseyeRootPath,'caBands',...
        sprintf('oi_%dcaBands.mat',ca(ii)));
    save(fn,'oi','thisScene');
    
end

figure(figIrradiance);
xlabel('Wavelength (nm)');
ylabel('Quanta');
grid on;
legendCell = cellstr(num2str(ca', 'CA Bands = %d'));
legend(legendCell);

% Print time to render
for ii = 1:length(ca)
    fprintf('Num Bands = %d | Time to render %0.2f sec \n',...
        ca(ii),renderingTime(ii));
end

%% 
% Results for 256 resolution and 1024 rays. 
% ----
% Num Bands = 0 | Time to render 59.78 sec 
% Num Bands = 2 | Time to render 106.59 sec 
% Num Bands = 4 | Time to render 199.69 sec 
% Num Bands = 8 | Time to render 389.66 sec 
% Num Bands = 16 | Time to render 762.86 sec 
 
 
