
%% Initialize
ieInit;

%% Load data

[posAccom,psfAccom] = readZemaxPSFtxt(fullfile(isetlenseyeRootPath,...
    'SanityChecks','navarroFig12Data','psfcross_632nm_4mm_0.15dpt.txt'));
[pos,psf] = readZemaxPSFtxt(fullfile(isetlenseyeRootPath,...
    'SanityChecks','navarroFig12Data','psfcross_632nm_4mm_0dpt.txt'));

% Normalize peaks
psfAccom = psfAccom./max(psfAccom(:));
psf = psf./max(psf(:));

%% Plot

figure(); hold on;
grid on;

h1 = plot(pos,psf);
h2 = plot(posAccom,psfAccom);
legend([h1 h2],'0 dpt','0.15dpt');
title('PSF Cross Section (Zemax)')
xlabel('Position (um)');
ylabel('Intensity')

set(findall(gca,'-property','FontSize'),'FontSize',24)
set(findall(gca,'-property','LineWidth'),'LineWidth',3)