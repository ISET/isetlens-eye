%% Compare out rendered calculations with Fig 12 in Navarro's paper:
% Escudero-Sanz, Isabel, and Rafael Navarro. "Off-axis aberrations of a
% wide-angle schematic eye model." JOSA A 16.8 (1999): 1881-1891.

%% Initialize
ieInit;
mtfFig = figure(); clf; hold on;

%% Fetch data
% Prerendered data is saved on RDT. This data was generated using
% s_Fig12Navarro.m
dataDir = fullfile(isetlenseyeRootPath,'data',...
    'navarroFig12Validate');

if(~exist(dataDir,'dir'))
    fprintf('Fetching data...\n');
    piPBRTFetch('navarroFig12Validate',...
        'remotedirectory','/resources/isetlensdata',...
        'destinationfolder',fullfile(isetlenseyeRootPath,'data'),...
        'delete zip', true);
    fprintf('Data fetched! \n');
end

%% Plot data
% Two MTF's, one at 0 dpt accommodation and the other at 0.15 dpt. 
% In the paper, calculations were carried out at 632.8 nm and with a 4 mm
% pupil diameter. 

load(fullfile(dataDir,'validate0.00.mat'));
sceneNoAccom = myScene;
oiNoAccom = oi;

load(fullfile(dataDir,'validate0.15.mat'));
sceneAccom = myScene;
oiAccom = oi;

% Take a look at the optical images
ieAddObject(oiNoAccom);
ieAddObject(oiAccom);
oiWindow;

% Check that we rendered with a 4 mm pupil
assert(sceneNoAccom.pupilDiameter == 4)
assert(sceneAccom.pupilDiameter == 4)

% Get MTF for 632.8 nm
testWl = 632.8;
[freqNoAccom,mtfNoAccom] = calculateMTFfromSlantedBar(oiNoAccom,...
    'targetWavelength',testWl);
[freqAccom,mtfAccom] = calculateMTFfromSlantedBar(oiAccom,...
    'targetWavelength',testWl);

% Plot the two MTF's
figure(mtfFig);
h1 = plot(freqNoAccom,mtfNoAccom,'-');
% h2 = plot(freqAccom,mtfAccom,':');

%% Compare with Zemax output (geometric only)

zemaxFile = fullfile(isetlenseyeRootPath,...
    'SanityChecks','navarroFig12Data',...
    'geometric_632nm_cycPermr_4mm_100mObj_noDiff.txt');

data = readZemaxMTF(zemaxFile);

mrPerDeg= 1/0.0572958; 
freq = data.spatial_frequency*mrPerDeg;

h4 = plot(freq,data.MTF_sagittal,'g-');

%% Compare with Zemax output (geometric + diffraction)

zemaxFile = fullfile(isetlenseyeRootPath,...
    'SanityChecks','navarroFig12Data',...
    'geometric_632nm_cycPermr_4mm_100mObj.txt');

data = readZemaxMTF(zemaxFile);
 
mrPerDeg= 1/0.0572958; 
freq = data.spatial_frequency*mrPerDeg;

h3 = plot(freq,data.MTF_sagittal,'k:');

%% Compare with Zemax output (fft)

zemaxFile = fullfile(isetlenseyeRootPath,...
    'SanityChecks','navarroFig12Data',...
    'fftModulation_632nm_cycPermr_4mm_100mObj.txt');

data = readZemaxMTF(zemaxFile);

mrPerDeg= 1/0.0572958; 
freq = data.spatial_frequency*mrPerDeg;

h5 = plot(freq,data.MTF_sagittal,'m');

%% Compare with points directly from the paper

load(fullfile(isetlenseyeRootPath,...
    'SanityChecks','navarroFig12Data',...
    'navarroFig12Points.mat'));

h6 = plot(navarroFig12Points(:,1),navarroFig12Points(:,2),'bx');

%% Make plot prettier

legend([h1 h3 h4 h5 h6],...
    'rendered 0 dpt',...
    'Zemax(geometric+diff)',...
    'Zemax(geometric)',...
    'Zemax(fft)',...
    'Fig 12 (paper)');

axis([0 60 0 1])
xlabel('Spatial Frequency (cyc/deg)')
ylabel('MTF')
grid on;
set(findall(gca,'-property','FontSize'),'FontSize',24)
set(findall(gca,'-property','LineWidth'),'LineWidth',3)

%% Check for 0.15 dpt

figure(); clf; hold on;

% Directly from paper
load(fullfile(isetlenseyeRootPath,...
    'SanityChecks','navarroFig12Data',...
    'navarroFig12Points_0.15dpt.mat'));
h1 = plot(navarroFig12Points(:,1),navarroFig12Points(:,2),'bx-');

% From Zemax (FFT)
zemaxFile = fullfile(isetlenseyeRootPath,...
    'SanityChecks','navarroFig12Data',...
    'fftModulation_632nm_cycPermr_4mm_0.15dpt.txt');
data = readZemaxMTF(zemaxFile);
mrPerDeg= 1/0.0572958; 
freq = data.spatial_frequency*mrPerDeg;

h2 = plot(freq,data.MTF_sagittal,'m');

% From Zemax (Geometric)
zemaxFile = fullfile(isetlenseyeRootPath,...
    'SanityChecks','navarroFig12Data',...
    'geometric_632nm_cycPermr_4mm_0.15dpt.txt');
data = readZemaxMTF(zemaxFile);
mrPerDeg= 1/0.0572958; 
freq = data.spatial_frequency*mrPerDeg;

h3 = plot(freq,data.MTF_sagittal,'r');

% From PBRT rendering
h4 = plot(freqAccom,mtfAccom,'k');

% Make plot prettier
legend([h1 h2 h3 h4],...
    'Fig 12 (paper)',...
    'Zemax FFT',...
    'Zemax Geometric',...
    'isetBio-3D');

axis([0 60 0 1])
title('0.15 diopter accommodation');
xlabel('Spatial Frequency (cyc/deg)')
ylabel('MTF')
grid on;
set(findall(gca,'-property','FontSize'),'FontSize',24)
set(findall(gca,'-property','LineWidth'),'LineWidth',3)