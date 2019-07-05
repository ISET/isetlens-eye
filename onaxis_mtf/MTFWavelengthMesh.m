%% Plot the MTF over Wavelength in the Form of a Mesh

%% Initialize
ieInit;

saveDir = fullfile(isetlenseyeRootPath,'outputImages','mtfMesh');
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end

MTFfig = vcNewGraphWin;

% Setup plot color
wls = [450:10:650];

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

dataDir = ileFetchDir('slantedBar_eyeModels');
diff = 1;
slantedBar4mm_fn = fullfile(dataDir,'highWlsSampling',...
    sprintf('slantedBarNavarro_diff%d_pupil3mm.mat',diff));
load(slantedBar4mm_fn);

oi = oiSet(oi,'bitDepth',32); 

% Check optical image
% ieAddObject(oi);
% oiWindow;

% Calculate MTF for each wavelength
mtfWls = cell(1,length(wls));
for ii = 1:length(wls)
    
    fprintf('Wavelength: %d nm \n',wls(ii));
    
    [freq,mtf,barImage] = calculateMTFfromSlantedBar(oi,...
                                            'cropFlag',true,...
                                            'targetWavelength',wls(ii));
    % figure();
    % imshow(barImage);
    % title(sprintf('%d nm',wls(ii)))
    
    % Crop spatial frequencies 
    goodI = (freq <= 30);
    freq = freq(goodI); 
    mtfWls{ii} = mtf(goodI);
    
%     figure(mtfFig);
%     plot(freq,mtfWls{ii},'color',lineColor(ii,:));
    
    
end

%% Plot mesh

% Convert from cell to matrix
mtfWlsMat = cell2mat(mtfWls); % spatial frequency x wavelengths

mtfFig = vcNewGraphWin(); hold on;
mesh(wls,freq,mtfWlsMat,'edgecolor', 'k')
% xlabel('Wavelength (nm)')
% ylabel('Spatial Frequency (cpd)')
set(gca, 'YDir','reverse')
set(gca,'View',[35.6 26]);

zlim([-0.2 1])

% Get the z-tick marks right
numTicks = 6;
zticklabels = linspace(0,1,numTicks);
zticks = linspace(1, size(mtfWlsMat, 3), numel(zticklabels));
set(gca, 'ZTick', zticklabels,...
    'ZTickLabel', sprintf('%2.1f\n', zticklabels),...
    'FontSize', 20)

set(findall(gca,'-property','FontSize'),'FontSize',20)
set(findall(gca,'-property','LineWidth'),'LineWidth',1)

fn = fullfile(saveDir,sprintf('mtfMeshFig_diff%d.png',diff));
NicePlot.exportFigToPNG(fn,mtfFig,300);


