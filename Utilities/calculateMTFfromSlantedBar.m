function [freq,mtf] = calculateMTFfromSlantedBar(oi,varargin)
% Calculate the MTF given an optical image with a slanted
%             bar. This is specifically for the eye. We use ISO1223. and
%             provide options to calculate specific wavelength or weight
%             the curves over luminance.
%
% Required input:
%   oi - optical image of a slanted bar scene. Rendered from a sceneEye
%        object or created in ISETBio. Borders will be cropped
%
% Optional inputs:
%   'targetWavelength'  - calculate MTF for this wavelength. Otherwise we
%                         will calculate the "polychromatic" MTF
%   'cropFlag'          - Crop the image. When we render in PBRT, we get a
%                         circular border due to the way we sampel the
%                         retina. This border interferes with ISO1223, so
%                         we crop it automatically.
%
% Outputs:
%   freq - in cyc/deg using the small angle approximation
%   mtf -  contrast reduction

%% Parse inputs
p = inputParser;

% Forces optional inputs to lower case
for ii=1:2:length(varargin)
    varargin{ii} = ieParamFormat(varargin{ii});
end

p.addRequired('oi');

p.addParameter('targetwavelength',[],@isnumeric);
p.addParameter('cropflag',true,@islogical);

p.parse(oi,varargin{:});
targetwavelength   = p.Results.targetwavelength;
cropflag           = p.Results.cropflag;


%% Crop
% Crop the image so we only have the slanted line visible. The ISO12233
% routine will be confused by the edges of the retinal image if we don't
% first crop it.
if(cropflag)
    res = oiGet(oi,'rows');
    cropRadius = res/(2*sqrt(2))-5;
    oiCenter = res/2;
    barOI = oiCrop(oi,round([oiCenter-cropRadius oiCenter-cropRadius ...
        cropRadius*2 cropRadius*2]));
else
    barOI = oi;
end

%% Spectral calculations

if(isempty(targetwavelength))
    % TODO: How should we convert from photons over wavelength to RGB values to
    % be passed into the ISO12233 routine?  Here we are essentically weighting
    % the spectrum according to the luminosity function, thus producing a
    % grayscale image to pass into ISO2233. 
    barOI = oiSet(barOI,'mean illuminance',1);
    
    barImage = oiGet(barOI,'illuminance');
else
    % Take specific wavelength
    
    % Find the closest matching sampled wavelength
    sampledWavelengths = oiGet(barOI,'wave');
    diff = sampledWavelengths-targetwavelength;
    [~,closestIndex] = min(abs(diff));
    closestWavelength = sampledWavelengths(closestIndex);
    
    % Alert the user if we are approximating
    if(closestWavelength ~= targetwavelength)
        fprintf(['Target wavelength of %0.2f nm not sampled, '... 
            'using %0.2f nm instead. \n'],targetwavelength,closestWavelength);
    end
    
    % Zero out all wavelengths aside from the ones we're interested in.
    photons = oiGet(barOI,'photons');
    removeThese = (sampledWavelengths ~= closestWavelength);
    [n,m,w] = size(photons);
    photons(:,:,removeThese) = zeros(n,m,w-1);
    barOI = oiSet(barOI,'photons',photons);
    
    % Illuminance needs to be recalculated (important!)
    barOI = oiSet(barOI, 'illuminance', []);
    barOI = oiSet(barOI,'mean illuminance',1);
    
    % Get image (ISO12233 needs an 2D image)
    % TODO: Is this the right thing to do?
    barImage = oiGet(barOI,'illuminance');
        
end

%% Calculate MTF
deltaX_mm = oiGet(barOI,'sample spacing')*10^3; % Get pixel pitch
[results, ~, ~, ~] = ISO12233(barImage, deltaX_mm(1),[1/3 1/3 1/3],'none');

%%  Convert to cycles per degree

% Approximate (assuming a small FOV)
mmPerDeg = 0.2852; 

freq = results.freq*mmPerDeg;
mtf = results.mtf;

end

