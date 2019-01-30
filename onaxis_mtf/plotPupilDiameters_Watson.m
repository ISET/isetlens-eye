%% plotPupilDiameter.sm

% Plot slanted bars rendered with isetbio/iset3d and the human eye.
% We will compare these plots with results in Watson 2013.

%% Initialize
clear; close all;
ieInit;

% which color map to use
% colormap = cbrewer('div','Spectral',7);
colors = cbrewer('div','Spectral',6);
% Map pupil sizes to color so we can keep that consistent
pupilSizes = [1 2 3 4 5 6];
colorM = containers.Map('KeyType','double','ValueType','any');
for i = 1:length(pupilSizes)
    colorM(pupilSizes(i)) = colors(i,:);
end


%% Load images rendered with diffraction turned off
%{
saveDir = 'noDiffractionData';
allFiles = dir(fullfile(saveDir,'*.mat'));

% Setup figure
diffOff = figure; clf;
hold on; grid on;
title('MTF vs Pupil Diameter (no diffraction)')
xlabel('Spatial Frequency (cycles/deg)');
ylabel('Contrast Reduction (SFR)');
grid on;
axis([0 60 0 1])

% Match Watson 2013
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')
xticks([1 2 5 10 20 50 100])
yticks([0.01 0.02 0.05 0.1 0.2 0.5 1])
colormap = cbrewer('div','Spectral',length(allFiles));
axis([1 100 0.01 1])

pupilDiameters = zeros(length(allFiles),1);
for ii = 1:length(allFiles)
    
    load(fullfile(allFiles(ii).folder,allFiles(ii).name));
    
    ieAddObject(oi);
    oiWindow;
    
    figure(diffOff);
    
    % Get the pupil diameter
    pupilDiameters(ii) = myScene.pupilDiameter;
    
    % Crop the image so we only have the slanted line visible. The ISO12233
    % routine will be confused by the edges of the retinal image if we don't
    % first crop it.
    cropRadius = myScene.resolution/(2*sqrt(2))-5;
    oiCenter = myScene.resolution/2;
    barOI = oiCrop(oi,round([oiCenter-cropRadius oiCenter-cropRadius ...
        cropRadius*2 cropRadius*2]));
    
    % Convert to illuminance
%     oiMonochrome = oiExtractWaveband(barOI,550,1);
%     oiMonochrome = oiAdjustIlluminance(oiMonochrome,50);
%     barImage = oiGet(oiMonochrome,'illuminance');
    
    barOI = oiSet(barOI,'mean illuminance',1);
    barImage = oiGet(barOI,'illuminance');
    
    % Calculate MTF
    deltaX_mm = oiGet(oi,'sample spacing')*10^3; % Get pixel pitch
    [results, fitme, esf, h] = ISO12233(barImage, deltaX_mm(1),[1/3 1/3 1/3],'none');
    
    % Convert to cycles per degree
    mmPerDeg = 0.2852; % Approximate (assuming a small FOV and an focal length of 16.32 mm)
    plot(results.freq*mmPerDeg,results.mtf,'color',colorM(pupilDiameters(ii)));
 
end

 legendCell = cellstr(num2str(pupilDiameters, '%0.2f mm'));
 legend(legendCell)
%}
%% Load images with diffraction turned on

saveDir = '/Users/tlian/Dropbox (Facebook)/Analysis/NavarroMTF/data';
allFiles = dir(fullfile(saveDir,'*.mat'));

% Setup figure
diffOn = figure; clf;
hold on; grid on;
title('MTF vs Pupil Diameter')
xlabel('Spatial Frequency (cycles/deg)');
ylabel('Contrast Reduction (SFR)');
grid on;
axis([0 60 0 1])

% Match Watson 2013
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')
xticks([1 2 5 10 20 50 100])
yticks([0.01 0.02 0.05 0.1 0.2 0.5 1])
% colormap = cbrewer('div','Spectral',length(allFiles));
axis([1 100 0.01 1])

figure(diffOn);
set(findall(gcf,'-property','FontSize'),'FontSize',20)
set(gcf,'Position',[1000 784 631 554])
ax = gca;
ax.MinorGridAlpha = 0.10;
ax.GridAlpha = 0.10;

pupilDiameters = zeros(length(allFiles),1);
for ii = length(allFiles):-1:1
    
    load(fullfile(allFiles(ii).folder,allFiles(ii).name));
    
    oi = oiSet(oi,'bitDepth',32); % For isetbio
    
    % Get the pupil diameter
    pupilDiameters(ii) = myScene.pupilDiameter;
    
    ieAddObject(oi);
    oiWindow;
    
    % Save the optical image as a PNG file
    %     rgb = oiGet(oi,'rgb');
    %     filename = oiGet(oi,'name');
    %     imwrite(rgb,fullfile(saveDir,[filename '.png']));
    
    figure(diffOn)
    
    % Crop the image so we only have the slanted line visible. The ISO12233
    % routine will be confused by the edges of the retinal image if we don't
    % first crop it.
    cropRadius = myScene.resolution/(2*sqrt(2))-5;
    oiCenter = myScene.resolution/2;
    barOI = oiCrop(oi,round([oiCenter-cropRadius oiCenter-cropRadius ...
        cropRadius*2 cropRadius*2]));
    
    % Extract only 550 nm illuminance
    %     oiMonochrome = oiExtractWaveband(barOI,550,1);
    %     oiMonochrome = oiAdjustIlluminance(oiMonochrome,50);
    %     barImage = oiGet(oiMonochrome,'illuminance');
    
    % Convert to illuminance
    barOI = oiSet(barOI,'mean illuminance',1);
    barImage = oiGet(barOI,'illuminance');
    
    % Calculate MTF
    deltaX_mm = oiGet(barOI,'sample spacing')*10^3; % Get pixel pitch
    [results, fitme, esf, h] = ISO12233(barImage, deltaX_mm(1),[1/3 1/3 1/3],'none');
    
    % Convert to cycles per degree
    mmPerDeg = 0.2852; % Approximate (assuming a small FOV and an focal length of 16.32 mm)
    p{ii} = plot(results.freq*mmPerDeg,results.mtf,'color',colorM(pupilDiameters(ii)));
    
    % Plot Watson's model
    % ---------------------------
    d = pupilDiameters(ii); % pupil diameter
    u = results.freq*mmPerDeg; % spatial freq (cyc/deg)
    
    % Diffraction limited MTF
    % Function of spatial frequency, pupil diameter, and wavelength (555 nm for
    % polchromatic)
    u0 = d*pi*10^6/(555.*180); %incoherent cutoff frequency
    uhat = u./(u0);
    D = 2/pi*(acos(uhat)-uhat.*sqrt(1-uhat.^2)).*(uhat<1);
    
    u1 = 21.95 - 5.512*d + 0.3922*d^2;
    
    M_Watson = (1+(u./u1).^2).^(-0.62).*sqrt(D);
    
    plot(u,M_Watson,'color',colorM(pupilDiameters(ii)),'LineStyle','--');
    % ---------------------------
    
    legendCell = cellstr(num2str(pupilDiameters, '%0.2f mm'));
    legend(flipud(legendCell),'Location','southwest')
    set(findall(gcf,'-property','LineWidth'),'LineWidth',3)
    
    % Save out image
    % saveas(gcf,sprintf('%0i.png',pupilDiameters(ii)))
    
end

% legendCell = cellstr(num2str(pupilDiameters, '%0.2f mm'));
% legend(legendCell)
%
% figure(diffOn);
% set(findall(gcf,'-property','FontSize'),'FontSize',20)
% set(findall(gcf,'-property','LineWidth'),'LineWidth',3)
% ax = gca;
% ax.MinorGridAlpha = 0.10;
% ax.GridAlpha = 0.10;

%% Theoretical results using ISET's diffraction limited optics
%{

 apertureDiameters = [1e-3 2e-3]; % 1 mm and 2 mm
 
 for ii = 1:length(apertureDiameters)
     
 % Match the camera parameters with the ones we used above.
sensorWidth = oiGet(oi,'width');
focalLength = 16.32e-3; % Approximately?
filmDistance = myScene.retinaDistance*10^-3;
apertureDiameter = apertureDiameters(ii);

imageRes = oiGet(oi,'cols');
edgeSlope = deg2rad(60); % Hard coded in the pbrt scene
fov = oiGet(oi,'fov');

scene = sceneCreate('slanted edge',imageRes,edgeSlope,fov);
ieAddObject(scene); sceneWindow;

%create optical image
oiT = oiCreate('diffraction');
optics = oiGet(oiT,'optics');
fNumber = focalLength/apertureDiameter;
optics = opticsSet(optics,'fnumber',fNumber);

optics = opticsSet(optics,'focallength',focalLength);   % Meters
oiT = oiSet(oiT,'optics',optics);
oiT = oiCompute(scene,oiT);

% Get 550 nm
% oiT = oiExtractWaveband(oiT,550,1);
% ieAddObject(oiT); oiWindow;

oiSize = oiGet(oiT,'size');
cropRadius = oiSize(1)/(2*sqrt(2))-5;
oiCenter = oiSize(1)/2;
barOI = oiCrop(oiT,round([oiCenter-cropRadius oiCenter-cropRadius ...
    cropRadius*2 cropRadius*2]));
    
% Convert to illuminance
barOI = oiSet(barOI,'mean illuminance',1);
barImage = oiGet(barOI,'illuminance');

% imshow(barImage)

% Calculate MTF
deltaX_mm = oiGet(barOI,'sample spacing')*10^3; % Get pixel pitch
[results, fitme, esf, h] = ISO12233(barImage, deltaX_mm(1),[1/3 1/3 1/3],'none');

% Convert to cycles per degree
mmPerDeg = 0.2852; % Approximate (assuming a small FOV and an focal length of 16.32 mm)
pd = apertureDiameter*10^3;

%{
figure(zmxMTF);
plot(results.freq*mmPerDeg,results.mtf,'color',colorM(pd),'LineStyle',':');
figure(diffOff);
plot(results.freq*mmPerDeg,results.mtf,'color',colorM(pd),'LineStyle',':');
%}

figure(diffOn);
plot(results.freq*mmPerDeg,results.mtf,'color',colorM(pd),'LineStyle',':');

%  legendCell{end+1} =  sprintf('%0.2f mm - Diff. Lim.',pd)
 
 end
%}

%% Make plots more readable

legend(legendCell)

figure(diffOn);
set(findall(gcf,'-property','FontSize'),'FontSize',20)
set(findall(gcf,'-property','LineWidth'),'LineWidth',3)
ax = gca;
ax.MinorGridAlpha = 0.10;
ax.GridAlpha = 0.10;
