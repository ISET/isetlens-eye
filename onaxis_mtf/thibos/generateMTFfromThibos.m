%% generateMTFfromThibos
% Generate a set of wavefront data using Thibos' virtual eyes. Calculate
% MTF from each virtual eye, and save output as a mat file. The 1D MTF is
% calculated by taking the radial average and weighting by luminosity.
%
% TL 2018

%% Initialize
ieInit;
rng(1); % Set random seed

%% Create a set of virtual eyes

nSbj = 100; % Create 100 virtual eyes

measPupilMM = 4.5; % 4.5 mm pupil size (load from Thibos data)
R = VirtualEyes(nSbj,measPupilMM);

% Do our calculations with these parameters
calcPupilMM = 3; % 3 mm pupil size 
wave = 450:10:650; % nm

%% Loop through the subjects and calculate MTF

for sbj = 1:nSbj
    
    fprintf('Calculating subject #%i \n',sbj);
    currZ = R(sbj,:); % Current Zernike coefficients
    
    % Allocate space and fill in the lower order Zernicke coefficients
    % Why do we do this? (from s_wvfThibosModel)
    z = zeros(65,1);
    z(1:13) = currZ(1:13);
    
    sbjWvf = wvfCreate;                                     % Initialize
    sbjWvf = wvfSet(sbjWvf,'zcoeffs',z);                    % Set Zernike coefficients
    
    % Give wvf object info about which Thibos dataset we used
    sbjWvf = wvfSet(sbjWvf,'measured pupil',measPupilMM);   
    sbjWvf = wvfSet(sbjWvf,'measured wavelength',550);
    
    % This is what we will actually calculate with
    sbjWvf = wvfSet(sbjWvf,'calculated pupil',calcPupilMM); 
    sbjWvf = wvfSet(sbjWvf,'calc wave',[wave]');    
    
    % Calculate the PSF
    sbjWvf = wvfComputePSF(sbjWvf);
    
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
    
    % Note: I don't use wvfGet(sbjWvf,'otf') here because we have multiple
    % wavelengths and wvfGet only allows single wavelengths. Looping over
    % wavelengths and summing things up have proven to be complicated, due
    % to the returned OTF changing size. What's easier is to get the OTF
    % from an optical image object. 
    oi = wvf2oi(sbjWvf);
    optics = oiGet(oi, 'optics');
    otf = opticsGet(optics, 'otf data', wave_weights(:,1)');
    
    % Add up the OTF over different wavelengths, taking into account the
    % photopic weighting.
    otf = otf.*reshape(wave_weights(:,2),[1 1 size(wave_weights,1)]);
    otf = sum(otf,3);
    
    % Get frequency support
    s = opticsGet(optics, 'otfSupport'); % cyc/mm
    fx = s{1};
    fy = s{2};
    [FX,FY] = meshgrid(fx,fy);
    
    % Convert to cyc/deg
    fx = fx / (1 / (296.71 * 1e-3));
    
    % Only take positive spatial frequency
    posI = (fx >= 0);
    fx = fx(posI);
    
    % Radially average the MTF
    [mtf, ~] = radialavg(abs(fftshift(otf)),length(fx));
    
    % Store the frequency support and mtf
    freqAll(sbj,:) = fx;
    mtfAll(sbj,:) = mtf;
end

%% Save the output
%scriptPath = fileparts(mfilename('fullpath'));
%save(fullfile(scriptPath,'ThibosMTF.mat'),'freqAll','mtfAll');

%% Take a look at the data
% stdshade plots the mean and one standard deviation

figure(); 
freq = freqAll(1,:); % These should all be the same.
h1 = stdshade(mtfAll,0.25,'r',freq,[]);

set(gca, 'YScale', 'log')
set(gca, 'XScale', 'log')
xticks([1 2 5 10 20 50 100])
yticks([0.01 0.02 0.05 0.1 0.2 0.5 1])
axis([1 100 0.01 1])
grid on;
xlabel('Frequency (cyc/deg)')
ylabel('Contrast Reduction')