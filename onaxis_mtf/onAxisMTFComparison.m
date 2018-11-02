%% Compare on-axis, polychromatic, 3 mm MTF using different models
% (1) PBRT rendering with ISETBio
% (2) Thibos data set (statistical model)
% (3) Zemax calculation (with Navarro eye)
% (4) Watson calculation

%% Initialize
ieInit;
rng(1);

MTFfig = vcNewGraphWin;

% Setup plot color
lineColor = cbrewer('qual','Set1',4);

%% Load and plot Thibos MTF's
% These MTF's have been precalculated in the script:
%   generateMTFfromThibos.m

load(fullfile(isetlenseyeRootPath(),'onaxis_mtf','thibos','ThibosMTF.mat'));

% Plot
freq = freqAll(1,:); % These should all be the same.
try
    h1 = stdshade(mtfAll,0.25,lineColor(1,:),freq,[]);
catch
    h1 = errorbar(freq,mean(mtfAll),std(mtfAll),'color',lineColor(1,:));
end

%% Compare with Watson's model (2013)
% Note: I can't tell how Watson calculates his "polychromatic" MTF. The
% following equation is for a "polychromatic" one. I have always just
% weighted things with the luminosity function.
% At one point I think he says the MTF is for "white light" in focus at 555
% nm. 
% Page 5:
% "...been developed for the mean human polychromatic (white light) optical
% MTF for as a function of pupil daimeter. In Figure 6 we compare those two
% formulas with ours, at pupil diameters of 2 and 6 mm."

d = 3; % pupil diameter
u = freq; % spatial freq (cyc/deg)

% Diffraction limited MTF
% Function of spatial frequency, pupil diameter, and wavelength (555 nm for
% polchromatic)
u0 = d*pi*10^6/(555.*180); %incoherent cutoff frequency
uhat = u./(u0);
D = 2/pi*(acos(uhat)-uhat.*sqrt(1-uhat.^2)).*(uhat<1);

u1 = 21.95 - 5.512*d + 0.3922*d^2;
u = freq;

M_Watson = (1+(u./u1).^2).^(-0.62).*sqrt(D);

figure(MTFfig); hold on;
h2 = plot(u,M_Watson,'color',lineColor(2,:));

%% Load PBRT rendered slanted line
% We load a rendered image of a slanted bar. We use ISO12233 to calculate
% the MTF from this image. 

% The rendered data is located on the RemoteDataToolbox because it is a
% large file. If it doesn't already exist, we download it here and put it
% into a local data folder.
slantedBar3mm_fn = fullfile(isetlenseyeRootPath,'data',...
    'slantedBar_pupil','pupilDiam_3.00mm.mat');
if(~exist(slantedBar3mm_fn,'file'))
    fprintf('Fetching data...');
    piPBRTFetch('slantedBar_pupil',...
        'remotedirectory','/resources/isetlensdata',...
        'destinationfolder',fullfile(isetlenseyeRootPath,'data'));
    fprintf('Data fetched!');
end
load(slantedBar3mm_fn);

oi = oiSet(oi,'bitDepth',32); 

% Check optical image
ieAddObject(oi);
oiWindow;

% Calculate MTF (polychromatic)
[freq,mtf] = calculateMTFfromSlantedBar(oi,'cropFlag',true);

figure(MTFfig); hold on;
h3 = plot(freq,mtf,'color',lineColor(3,:));

%% Load Zemax data
% The Zemax data has been saved out as a text file. We read in the text
% files and load up the MTF's.

% We have data for the fft, huygens, and geometric method. We use the
% geometric now since it's functionally the same as ray-tracing.
data_geometric = readZemaxMTF('mtf_geometric_photopic_3mm_0dpt_cycmm.txt');

% Thed ata is given in cyc/mm but we want cyc/deg. We convert it the same
% way we do in the previous section. 
mmPerDeg = 0.2881; % Approximate

figure(MTFfig); hold on;
h4 = plot(data_geometric.spatial_frequency.*mmPerDeg,...
    data_geometric.MTF_tangential,'color',lineColor(4,:));

%% Add legend

figure(MTFfig);
grid on;
title(sprintf('On-Axis MTF \n (3 mm pupil, polychromatic)'))
xlabel('Spatial Frequency (cycles/deg)');
ylabel('Contrast Reduction (SFR)');
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')
xticks([1 2 5 10 20 50 100])
yticks([0.01 0.02 0.05 0.1 0.2 0.5 1])
axis([1 100 0.01 1])
thisAxis = gca;
thisAxis.MinorGridAlpha = 0.15;

set(findall(gca,'-property','FontSize'),'FontSize',24)
set(findall(gca,'-property','LineWidth'),'LineWidth',3)

legend([h1 h2 h3 h4],...
    {'Thibos (2002)',...
    'Watson (2013)'...
    'ISETbio-3d',...
    'Zemax (geometric)'},...
    'location','best')

oiWindow;

%%
