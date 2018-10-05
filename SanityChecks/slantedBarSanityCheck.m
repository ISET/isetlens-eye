%% Do a sanity check on calculating MTF from the slanted bar (ISO1223)
% We want to be sure that our method of rendering a slanted bar, converting
% to illuminance, and then using ISO1223 is producing the correct MTF. 
%
% To check this let's:
% Render a slanted bar using ISETBio optics (e.g. Marimont-Wandell).
% Run ISO1223 on the retinal image.
% Compare the MTF from ISO1223 with the one calculated from the PSF.
%
% TL 2018

%% Initialize
ieInit;

%% Calculate the retinal image from a slanted bar scene

oi = oiCreate(); % Created with default WM optics

% Check the spread of the PSF for these optics. We want to calculate with
% an optical image size that can capture this blur.
% oiPlot(oi,'ls wavelength');
% From the plot, spread of around 120 um should be enough to capture the
% largest blur. Let's make is slightly larger, just in case.
requiredSize = 120*2; % um

res = 800;
scene = sceneCreate('slantedbar',res);
scene = sceneSet(scene,'fov',1.5);

% Remove lens transmittance
% (We don't model this in PBRT)
wave = oi.optics.lens.get('wave');
oi.optics.lens.set('unitdensity',ones(size(wave)));

oi = oiCompute(scene,oi);

% Crop the OI to get rid of the extra padding
oi = oiCropBorder(oi,0.25*res);

% Make sure the oi is still large enough to capture the blur
width = oiGet(oi,'width');
assert(width*10^6 > requiredSize)

% Check the optical image
ieAddObject(oi);
oiWindow;

% Check the sample size
ss = oiGet(oi,'sample spacing');
fprintf('Sample spacing is %f um. \n',ss(1)*10^6);

% Check Nyquist frequency
ss_mm = ss(1)*10^3;
nyquist_cycperdeg = 0.5*1/(ss_mm)*0.285; 
fprintf('Nyquist frequency is %f cyc/deg. \n',nyquist_cycperdeg);

% Check the FOV
newFOV = oiGet(oi,'fov');
fprintf('FOV is %f deg. \n',newFOV);
% For our slanted bar calculations, the FOV should not be smaller than
% this.

%% Calculate the MTF from the oi

mtfFig = figure(); clf;
hold on; grid on;

[freq,mtf] = calculateMTFfromSlantedBar(oi,'targetWavelength',550,...
    'cropFlag',false);
plot(freq,mtf,'g--');

[freq,mtf] = calculateMTFfromSlantedBar(oi,'targetWavelength',450,...
    'cropFlag',false);
plot(freq,mtf,'b--');

[freq,mtf] = calculateMTFfromSlantedBar(oi,'targetWavelength',650,...
    'cropFlag',false);
plot(freq,mtf,'r--');

[freq,mtf] = calculateMTFfromSlantedBar(oi,'cropFlag',false);
plot(freq,mtf,'k--');

%% Calculate the MTF from the optics data

data = oiPlot(oi,'otf wavelength');

% Convert fsupport from cyc/mm to cyc/deg
freq = data.fSupport*0.285;

% Only take one side
I = find(freq>=0);
freq = freq(I);
data.otf = data.otf(I,:);

ind550 = find(data.wavelength == 550);
ind470 = find(data.wavelength == 470);
ind650 = find(data.wavelength == 650);

mtf550 = data.otf(:,ind550);
mtf470 = data.otf(:,ind470);
mtf650 = data.otf(:,ind650);

figure(mtfFig);
h1 = plot(freq,mtf550,'g-');
h2 = plot(freq,mtf470,'b-');
h3 = plot(freq,mtf650,'r-');

%% Weigh MTF's with luminance curve to get polychromatic MTF

% Use photopic weights (these are directly from Zemax.) We could
% probably calculate it based on luminosity function as well.
% [wave weight]
wave_weights = [470 0.01;
    510 0.503;
    550 1;
    610 0.503;
    650 0.107];

% Normalize the weights
wave_weights(:,2) = wave_weights(:,2)./sum(wave_weights(:,2));

mtf_weighted = zeros(size(mtf550));
for ii = 1:size(wave_weights,1)
    currI = find(data.wavelength == wave_weights(ii,1));
    currmtf = data.otf(:,currI);
    mtf_weighted = mtf_weighted + currmtf.*wave_weights(ii,2);
end

h4 = plot(freq,mtf_weighted,'k-');

%% Make plot prettier
figure(mtfFig);

title('Slanted Bar Sanity Check');
xlabel('Spatial Frequency (cycles/deg)');
ylabel('Contrast Reduction (SFR)');

h5 = plot(nan,nan,'k-');
h6 = plot(nan,nan,'k--');

legend([h1 h2 h3 h4 h5 h6],...
    '550 nm','450 nm','650 nm','Polychromatic','From PSF','From ISO1223');
xlim([0 60])

set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')
xticks([1 2 5 10 20 50 100])
yticks([0.01 0.02 0.05 0.1 0.2 0.5 1])
axis([1 100 0.01 1])
thisAxis = gca;
thisAxis.MinorGridAlpha = 0.15;

set(findall(gcf,'-property','FontSize'),'FontSize',18)
set(findall(gcf,'-property','LineWidth'),'LineWidth',2)


