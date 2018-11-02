%% occlusionComparisonwWVF.m
% Compare the blur at an occlusion boundary between:
% (1) a 3D scene rendered with ISET3d and the human eye 
% with
% (2) The same scene blurred using 2D PSF generated in ISETbio.
%
% TL 2018

%% Initialize
ieInit;

%% Fetch data
% Prerendered data is saved on RDT. This data was generated using
% s_occlusionTexture.m
dataDir = fullfile(isetlenseyeRootPath,'data',...
    'occlusionBoundary');

if(~exist(dataDir,'dir'))
    fprintf('Fetching data...\n');
    piPBRTFetch('occlusionBoundary',...
        'remotedirectory','/resources/isetlensdata',...
        'destinationfolder',fullfile(isetlenseyeRootPath,'data'),...
        'delete zip', true);
    fprintf('Data fetched! \n');
end

%% Load 2D scene
% The 2D scene files was generated by rendering through a pinhole camera. 

% Take a look at the 2D scene and it's depth map
load(fullfile(dataDir,'occlusion_1.00_2.00_pinhole.mat'));
ieAddObject(scene);
sceneWindow;

depthMap = sceneGet(scene,'depth map');
vcNewGraphWin(); axis off;
imagesc(depthMap); colorbar; colormap(gray);
title('Depth Map')

%% Calculate correct PSF to blur the checkerboard

% We use the Navarro PSF, to match the 3D render. To do this, we extract
% Zernike coefficients in Zemax and then use them with the ISET3d wvf
% tools. 
zmxData = readZemaxZernike(fullfile(isetlenseyeRootPath,...
    'occlusionBoundary','Zemax_Zernike_Navarro_4mm_550nm.txt'),...
    'returnAsANSI',true);

% The following coeffs are for a 4 mm pupil (not listed in Zemax file).
measuredWls = zmxData.wavelength_um; % um 
measPupilMM = 4; % mm

% We multiply by the wavelength because coefficients from Zemax are in
% units of waves. We convert to um (ANSI standard) for ISETbio.
% "readZemaxZernike.m" will take care of the conversion from Zemax
% indices to ANSI indices.
z = zmxData.coeffList .* measuredWls; 
% (We ignore aberrations higher than ANSI index 20).

% Initialize
sbjWvf = wvfCreate;  

% Set the zernike coefficients
sbjWvf = wvfSet(sbjWvf,'zcoeffs',z);    

sbjWvf = wvfSet(sbjWvf,'measured pupil',measPupilMM);   
sbjWvf = wvfSet(sbjWvf,'measured wavelength',measuredWls*10^3); % nm

% We want to calculate the PSF with these parameters.
calcPupilMM = 4; % 4 mm
calcWls = 400:10:700;
sbjWvf = wvfSet(sbjWvf,'calculated pupil',calcPupilMM); 
sbjWvf = wvfSet(sbjWvf,'calc wave',calcWls');     

sbjWvf = wvfComputePSF(sbjWvf);

% Let's check and see what the PSF looks like for a couple of wavelengths
for wls = [450 550 650]
    
    tmpWvf = wvfSet(sbjWvf,'calc wave',wls);
    tmpWvf = wvfComputePSF(tmpWvf);
    uData = wvfPlot(tmpWvf,'psf');
    close gcf;
    
    % Plot cross section computed by ISETBio and normalized to a peak
    % intensity of 1
    figure(); hold on;
    [m,n] = size(uData.z);
    intensity = uData.z(round(m/2),:);
    intensity_normalized = intensity./max(intensity);
    plot(uData.x*10^3,intensity_normalized,'b');
    xlabel('Position (um)')
    ylabel('Intensity (Normalized)')
    title(sprintf('%0.2f nm',wls))
    
    % Compare with PSF exported from Zemax
    [x_um,y] = readZemaxPSFtxt(sprintf('psfcross_%inm_4mm_0dpt.txt',wls));
    y_normalized = y./max(y);
    plot(x_um,y_normalized,'r');
    
    legend('ISETbio - wvf','Zemax');
    
    % Note: The slight difference between Zemax and ISETbio for 450 nm and
    % 650 nm might be explained in the following way: In ISETbio we
    % calculate different PSF's using the 550 nm aberration data, while in
    % Zemax we are recalculating the aberrations with new wavelengths.
    
    % Are these PSF's close enough?
    
end

%% Load the rendered retinal image
load(fullfile(dataDir,'occlusion_1.00_2.00_1.00dpt.mat'));
ieAddObject(oi); oiWindow;

accom = scene3d.accommodation;

%% Adjust the PSF's depending on the depths

% Maybe we can infer this from the depth map, but for now let's hard code
% it
topDepth = 1;
bottomDepth = 2;

% I'm not sure if this is the right way to do this
topWvf = wvfSet(sbjWvf,'zcoeffs',{'defocus',topDepth-accom});

%%

