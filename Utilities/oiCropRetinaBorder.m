function [oi,r] = oiCropRetinaBorder(oi)

% Automatically crop the optical image down so you can no longer see the
% black, circular border. This border arises because we sample the retina
% in a circle.

res = oiGet(oi,'rows');
cropRadius = res/(2*sqrt(2))-5;
oiCenter = res/2;

r = round([oiCenter-cropRadius oiCenter-cropRadius ...
    cropRadius*2 cropRadius*2]);

oi = oiCrop(oi,r);

end

