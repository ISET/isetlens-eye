%% Initialize
clear; close all;

%% Load the data
data_fft = readZemaxMTF('mtf_fft_photopic_4mm_0dpt_cycmm.txt');
data_huygens = readZemaxMTF('mtf_huygens_photopic_4mm_0dpt_cycmm.txt');
data_geometric = readZemaxMTF('mtf_geometric_photopic_4mm_0dpt_cycmm.txt');

%% Plot as cyc/mm

figure(1); hold on; grid on;
plot(data_fft.spatial_frequency,data_fft.MTF_tangential);
plot(data_huygens.spatial_frequency,data_huygens.MTF_tangential);
plot(data_geometric.spatial_frequency,data_geometric.MTF_tangential);
xlabel('cyc/mm');
ylabel('MTF');
legend('FFT','Huygens','Geometric');
title('Zemax Navarro MTF (0 dpt, photopic)');
ylim([0 1]);

%% Plot as cyc/deg using the EFFL

EFFL = 16.4847;

degPerMM = atand(1/EFFL);
mmPerDeg = 1/degPerMM;

MTFfig = figure(); hold on; grid on;
plot(data_fft.spatial_frequency.*mmPerDeg,data_fft.MTF_tangential);
plot(data_huygens.spatial_frequency.*mmPerDeg,data_huygens.MTF_tangential);
plot(data_geometric.spatial_frequency.*mmPerDeg,data_geometric.MTF_tangential);

%% Plot isetBio rendered version

oiName = 'pupilDiam_4.00mm.mat';
load(oiName);

oi = oiSet(oi,'bitDepth',32); % Is this right?

% Illuminance needs to be recalculated (important!)
oi = oiAdjustIlluminance(oi,50);

% Crop oi to get rid of borders
cropRadius = myScene.resolution/(2*sqrt(2))-5;
oiCenter = myScene.resolution/2;
barOI = oiCrop(oi,round([oiCenter-cropRadius oiCenter-cropRadius ...
    cropRadius*2 cropRadius*2]));

% Convert to illuminance
barOI = oiSet(barOI,'mean illuminance',1);
barImage = oiGet(barOI,'illuminance');
    
ieAddObject(oi);
oiWindow;

% Calculate MTF
deltaX_mm = oiGet(oi,'sample spacing')*10^3; % Get pixel pitch
[results, fitme, esf, h] = ISO12233(barImage, deltaX_mm(1),[1/3 1/3 1/3],'none');

% Convert to cycles per degree
% Use the EFFL calculation above instead.
% mmPerDeg = 0.2852; % Approximate (assuming a small FOV and an focal length of 16.32 mm)

figure(MTFfig); 
h2 = plot(results.freq*mmPerDeg,results.mtf);
    
%% Add legend


figure(MTFfig);
xlabel('Spatial Frequency (cycles/deg)'); ylabel('Contrast reduction (SFR)'); grid on;
title('Navarro MTF (Photopic, 4 mm pupil, ~0 dpt)');
legend('Zemax - FFT (Wavefront)','Zemax - Huygens','Zemax - Geometric','isetBio 3D Render');

set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')
xticks([1 2 5 10 20 50 100])
yticks([0.01 0.02 0.05 0.1 0.2 0.5 1])
axis([1 100 0.01 1])
axis = gca;
axis.MinorGridAlpha = 0.15;

set(findall(gca,'-property','FontSize'),'FontSize',24)
set(findall(gca,'-property','LineWidth'),'LineWidth',3)


