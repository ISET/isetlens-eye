function [outputData,r] = cropRetinaBorder(inputData)

% A more general version of oiCropRetinaBorder
% Automatically crop the optical image down so you can no longer see the
% black, circular border. This border arises because we sample the retina
% in a circle.

if(isstruct(inputData))
    res = oiGet(inputData,'rows');
else
    res = size(inputData,1);
end

cropRadius = res/(2*sqrt(2))-10;
oiCenter = res/2;

r = round([oiCenter-cropRadius oiCenter-cropRadius ...
    cropRadius*2 cropRadius*2]);

if(isstruct(inputData))
    outputData = oiCrop(inputData,r);
else
    outputData = imcrop(inputData,r);
end


end

