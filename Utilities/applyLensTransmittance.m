function oi = applyLensTransmittance(oi,lensDensity)
%APPLYLENSTRANSMITTANCE Multiply the optical image photons by given lens
%transmittance. 
%
% Some of the optical images did not have the lens transmittance applied to
% the photons before being saved. Here we apply it and return the optical
% image.

oi = oiSet(oi, 'lens density', lensDensity);

irradiance = oiGet(oi, 'photons');
wave = oiGet(oi, 'wave');

if isfield(oi.optics, 'lens')
    transmittance = opticsGet(oi.optics, 'transmittance', 'wave', wave);
else
    transmittance = opticsGet(oi.optics, 'transmittance', wave);
end

if any(transmittance(:) ~= 1)
    % Do this in a loop to avoid large memory demand
    transmittance = reshape(transmittance, [1 1 length(transmittance)]);
    irradiance = bsxfun(@times, irradiance, transmittance);
end

oi = oiSet(oi,'photons',irradiance);

end

