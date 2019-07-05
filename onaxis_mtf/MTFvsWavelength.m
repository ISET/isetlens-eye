%% Compare on-axis, polychromatic, 3 mm MTF across different wavelengths

%% Initialize
ieInit;
rng(1);

MTFfig = vcNewGraphWin;

% Setup plot color
wls = [450 500 550 600 650];

n = length(wls);
energy = eye(n,n);
xyz = ieXYZFromEnergy(energy, wls);
xyz = XW2RGBFormat(xyz,n,1);
rgb = xyz2srgb(xyz);
lineColor = RGB2XWFormat(rgb);
% lineColor = rgb./repmat(max(rgb,[],2),[1 3]);

%% Load PBRT rendered slanted line
% We load a rendered image of a slanted bar. We use ISO12233 to calculate
% the MTF from this image. 
%
% Let's use the newly rendered eye model data, since it has the plane
% further away (20 m) then previous versions and therefore is closer to a
% point at infinity.
%
dataDir = ileFetchDir('slantedBar_eyeModels');
slantedBar4mm_fn = fullfile(dataDir,'slantedBarNavarro_diff1_pupil4mm.mat');
load(slantedBar4mm_fn);

oi = oiSet(oi,'bitDepth',32); 

% Check optical image
% ieAddObject(oi);
% oiWindow;

mtfFig = figure(); hold on;

% Calculate MTF for each wavelength
for ii = 1:length(wls)
    
    [freq,mtf,barImage] = calculateMTFfromSlantedBar(oi,...
                                            'cropFlag',true,...
                                            'targetWavelength',wls(ii));
    % figure();
    % imshow(barImage);
    % title(sprintf('%d nm',wls(ii)))
    
    figure(mtfFig);
    h{ii} = plot(freq,mtf,'color',lineColor(ii,:));
    
end

%% Compare with Watson's model (2013)
%{
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
%}

%% Load Zemax data
% The Zemax data has been saved out as a text file. We read in the text
% files and load up the MTF's.

% We use the geometric now since it's functionally the same as ray-tracing.
zmx_wave = [450 500 550 600 650];

n = length(zmx_wave);
energy = eye(n,n);
xyz = ieXYZFromEnergy(energy, zmx_wave);
xyz = XW2RGBFormat(xyz,n,1);
rgb = xyz2srgb(xyz);
lineColor_zmx = RGB2XWFormat(rgb);

for ii = 1:length(zmx_wave)
    
%     fn = fullfile(isetlenseyeRootPath,'onaxis_mtf',...
%         'zemax_wave','noDiffraction',...
%         sprintf('mtf_navarro_0dpt_%dnm_4mm_cycpermm_noDiff.txt',zmx_wave(ii)));
    
    fn = fullfile(isetlenseyeRootPath,'onaxis_mtf',...
        'zemax_wave','diffractionLimited',...
        sprintf('mtf_navarro_0dpt_%dnm_4mm_cycpermm.txt',zmx_wave(ii)));
    
    data_geometric = readZemaxMTF(fn);
    
    % The data is given in cyc/mm but we want cyc/deg. We convert it the same
    % way we do in the previous section.
    % mmPerDeg = 0.2881; % Approximate
    mmPerDeg = 0.2852;
    
    figure(mtfFig); hold on;
    h4 = plot(data_geometric.spatial_frequency.*mmPerDeg,...
        data_geometric.MTF_tangential,...
        'color',lineColor_zmx(ii,:),...
        'LineStyle',':');
end

%% Add legend

figure(mtfFig);
grid on;

% legend(cellstr(num2str(wls', '%d nm')));

title(sprintf('On-Axis MTF \n (4 mm pupil)'))
xlabel('Spatial Frequency (cycles/deg)');
ylabel('Contrast Reduction (SFR)');

axis([0 100 0 1])
set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')
xticks([1 2 5 10 20 50 100])
yticks([0.01 0.02 0.05 0.1 0.2 0.5 1])
axis([1 100 0.01 1])
thisAxis = gca;
thisAxis.MinorGridAlpha = 0.15;

set(findall(gca,'-property','FontSize'),'FontSize',24)
set(findall(gca,'-property','LineWidth'),'LineWidth',3)

%%
