function drgb = getDisplayRGB(ieObject,gamma)
%GETDISPLAYRGB Instead of the usual sRGB value we calculate from oiGet,
%let's calculate the display RGB.
% By default we assume it's the lcd-apple default display in ISET. That's
% the display we implement within PBRT.

d = displayCreate(); % We (can) use these primaries in PBRT
d = displaySet(d,'wave',400:10:700);

rgb2xyz = displayGet(d,'rgb2xyz');
%xyz2rgb = inv(rgb2xyz).*(1/0.0088); % Scaling to match xyz2srgb scaling? Still confused about why I need this. 
xyz2rgb = inv(rgb2xyz);

% Following steps from imageSPD and xyz2srgb
XYZ = oiGet(ieObject,'xyz');

% Scale?
% Y = XYZ(:,:,2);
% XYZ = XYZ/max(XYZ(:)); 

lrgb = imageLinearTransform(XYZ, xyz2rgb);
lrgb = max(lrgb,0);
drgb = real(lrgb.^(1/gamma));

end

