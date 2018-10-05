function oi = oiCropBorder(oi,numPixels)

% numPixels = number of pixels to remove on all sides.

res = oiGet(oi,'size');
cropSize = res(1)-2*numPixels;
cropSizeH = cropSize/2;
oiCenter = round(res(1)/2);
oi = oiCrop(oi,round([oiCenter-cropSizeH oiCenter-cropSizeH ...
    cropSizeH*2 cropSizeH*2]));

end

