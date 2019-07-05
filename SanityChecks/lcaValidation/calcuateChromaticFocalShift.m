%% Calculate chromatic focal shift
% This script calculates the chromatic focal shift for the lens model using
% PBRT renderings
%
% Frist we load in the renders from PBRT. Each of these renders shifts the
% retina plane closer and further away from the back of the lens. We
% calculate the MTF for each wavelength and for every plane distance. For
% each plane distance, we then find the wavelength with the best MTF (the
% wavelength with the HWHM located at the highest frequency.) This gives us
% the focal distance for each wavelength, which is equivalent to the
% chromatic focal shift in zEMAX.

%% Initialize
clear; close all;
ieInit;
mmPerDeg = 0.2852; % Estimate, assuming small FOV and eye focal length is 16.32 mm

%% Load rendered images

dataDir = ileFetchDir('lcaValidation');

files=dir(fullfile(dataDir,'*.mat'));
nFiles = length(files);
oiNames = cell(1,nFiles);

% Map retina distance to an oi 
oiMap = cell(nFiles,2);
for k=1:nFiles
    clear oi; clear myScene;
    load(fullfile(dataDir,files(k).name));
    oiMap{k,1} = myScene.retinaDistance;
    oiMap{k,2} = oi;
    
    vcAddAndSelectObject(oi);
end

oiWindow;
    
% Get wavelength sampling
wave = oiGet(oi,'wave');

%% Plot 0.5 MTF for each wavelength vs retina distance
    
% Reduce the number of wavelength samples for speed purposes
wave = wave(1:2:end);

bestWavelength = zeros(1,nFiles);
retinaDistances = zeros(1,nFiles);

for k = 1:nFiles
    
    fprintf('At file number %i/%i \n',k,nFiles);
    
    %{
    figRetDist = figure; clf; hold on;
    figBarImage = figure('Position',[-22 -468 1731 1273]); clf; hold on; 
    
    numSubPlots = ceil(sqrt(length(wave)));
    sindx = 1;
    %}
    
    spectralMap = flipud(cbrewer('div','Spectral',length(wave)));
    HWHMfreq = zeros(1,length(wave));
    
    for tt = 1:length(wave)
        
        fprintf('At wave number %i/%i \n',tt,length(wave));

        % Reload the oi
        clear oi;
        oi = oiMap{k,2};
        retinaDistances(k) = oiMap{k,1};
        
         oi = oiSet(oi,'bitDepth',32);
         
        %{
        % Isolate a single wavelength, set all other wavelengths in the
        % multispectral image to zero.
        targetWavelength = wave(tt);
        badI = (oi.spectrum.wave ~= targetWavelength);
        goodI = (oi.spectrum.wave == targetWavelength);
        [n,m,w] = size(oi.data.photons);
        oi.data.photons(:,:,badI) = zeros(n,m,w-1);
        
        % Illuminance needs to be recalculated (important!)
%         oi = oiSet(oi,'bitDepth',32);
%         oi.data = rmfield(oi.data,'illuminance');
%         illuminance = oiCalculateIlluminance(oi);
%         oi = oiSet(oi, 'illuminance', illuminance);
%         oi = oiAdjustIlluminance(oi,50);

        % Crop to center
        width = oiGet(oi,'rows');
        cropRadius = width/(2*sqrt(2))-5;
        oiCenter = width/2;
        barOI = oiCrop(oi,round([oiCenter-cropRadius oiCenter-cropRadius ...
            cropRadius*2 cropRadius*2]));
        
        % Get illuminance
        barImage = oiGet(barOI,'illuminance');
        
        % Calculate MTF
        deltaX_mm = oiGet(barOI,'sample spacing')*10^3;
        [results, fitme, esf, h] = ISO12233(barImage, deltaX_mm(1),[1/3 1/3 1/3],'none'); 
        %}
        
        [freq,MTF,~] = calculateMTFfromSlantedBar(oi,...
            'cropFlag',true,...
            'targetWavelength',wave(tt));
       
        %{
        figure(figBarImage); subplot(numSubPlots,numSubPlots,sindx);
        colorImage = oiGet(oi,'rgb');
        imshow(colorImage); title(num2str(targetWavelength))
        sindx = sindx + 1;
        
        % Plot MTF for each wavelength (DEBUG)
        figure(figRetDist);
        plot(results.freq*mmPerDeg,results.mtf,'color',spectralMap(tt,:));
        %}
            
        % Don't search at high frequencies, since there are occasional
        % numerical issues
        goodI = (freq < 100);
        freq = freq(goodI);
        MTF = MTF(goodI);
        
        [~, hwhmIndex] = min(abs(MTF-0.5));
        HWHMfreq(tt) = freq(hwhmIndex);
    end
    
    %{
    % Plot MTF for each wavelength (DEBUG)
    figure(figRetDist);
    legendCell = cellstr(num2str(wave, '%d'));
    legend(legendCell);
    xlim([0,60])
    
    % Save figures
    saveas(figRetDist,[num2str(retinaDistances(k)) 'mm_MTF.png'])
    saveas(figBarImage,[num2str(retinaDistances(k)) 'mm_barImages.png'])
    oi = oiMap{k,2};
    rgbImage = oiGet(oi,'rgb');
    imwrite(rgbImage,[num2str(retinaDistances(k)) 'mm_rgb.png'])
    %}
    
    % Find the distance with the highest HWHMfreq
    bestWavelength(k) = mean(wave(HWHMfreq == max(HWHMfreq)));
    
end

%% Save
save('LCA_bestWavelength_vs_retinaDistance.mat','bestWavelength','retinaDistances');


