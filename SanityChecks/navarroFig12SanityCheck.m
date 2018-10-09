%% Compare out rendered calculations with Fig 12 in Navarro's paper:
% Escudero-Sanz, Isabel, and Rafael Navarro. "Off-axis aberrations of a
% wide-angle schematic eye model." JOSA A 16.8 (1999): 1881-1891.

%% Initialize
ieInit;

%% Fetch data
% Prerendered data is saved on RDT. This data was generated using
% s_Fig12Navarro.m
dataDir = fullfile(isetlenseyeRootPath,'data',...
    'navarroFig12Validate');
if(~exist(dataDir,'dir'))
    fprintf('Fetching data...\n');
    piPBRTFetch('navarroFig12Validate',...
        'remotedirectory','/resources/isetlensdata',...
        'destinationfolder',fullfile(isetlenseyeRootPath,'data',...
        'navarroFig12Validate'),...
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
figure(1); clf; hold on;
h1 = plot(freqNoAccom,mtfNoAccom,'-');
h2 = plot(freqAccom,mtfAccom,':');
axis([0 60 0 1])
xlabel('Spatial Frequency (cyc/deg)')
ylabel('MTF')
legend([h1 h2],'rendered 0 dpt','rendered 0.15 dpt');
grid on;
set(findall(gca,'-property','FontSize'),'FontSize',24)
set(findall(gca,'-property','LineWidth'),'LineWidth',3)





