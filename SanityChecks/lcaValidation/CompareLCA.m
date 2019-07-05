%% Plot the chromatic difference of refraction
% In this script, we compare the chromatic difference of refraction between
% (1) Experimental data (Fig 1. Atchinson 2005) and (2) the Navarro eye
% rendered through PBRT.
%
% For all of the above, we assume the eye is emmetropic and the object is
% distant.
%
% For (2), we shift the retina plane back and forth. We then compute the
% MTF for each wavelength, and find the wavelength with the highest
% frequency HWHM. This gives us the retina distance that gives us the best
% focus for each wavelength. This is almost equivalent to Zemax's chromatic
% focal shift data, except we define BFL with the distance between the lens
% and the retina. This is calculated in the script "AnalyzeLCA.m"

%% Initialize
clear; close all;
ieInit;

legendCell = {};

%% Plot experimental data

load('chromaticDifferenceOfRefraction_Experimental.mat');

figure(1); clf; hold on; grid on;
title('LCA Comparison');
xlabel('Wavelength (nm)')
ylabel('Chromatic difference of refraction (D)')
axis([400 900 -2.5 1]);

plot(wave,diffRefraction,'b--');

legendCell{end+1} = 'Wald & Griffin';

%% Setup constant parameters

% To calculate the "chromatic difference of refraction," we follow
% Atchinson et al. 2005 eq. 2a We use 589 nm as our reference wavelength,
% as they do in the paper.
refWave = 0.589;
% This is the distance from the back of the lens to the focus point at a
% wavelength of 589 nm (in Zemax) We have to be careful, since the actual
% BFL is defined differently in Zemax since most of our media/materials are
% not air.
refBFL = 16.236; 
refPower = 1/(refBFL*10^-3);
vitreousIORat589nm = 1.3360493;

%% Plot PBRT Data for 0 diopters

load(fullfile(isetlenseyeRootPath,'SanityChecks','lcaValidation',...
    'LCA_bestWavelength_vs_retinaDistance.mat'));

BFL = retinaDistances;
power = 1./(BFL*10^-3);
R = -(power - refPower)/vitreousIORat589nm;

figure(1);
scatter(bestWavelength(2:end-4),R(2:end-4),100,'k*');
legendCell{end+1} = 'ISETBio (Navarro)';

%% Set plot parameters

fig = figure(1);
xlim([400 750])
set(findall(fig,'-property','FontSize'),'FontSize',20)
set(findall(fig,'-property','LineWidth'),'LineWidth',3)
legend(legendCell,'location','best');