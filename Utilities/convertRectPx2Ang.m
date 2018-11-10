function [r_deg, ang_support_crop_x, ang_support_crop_y] = convertRectPx2Ang(r,angularSupport)

% Convert rectangle units from pixel units to angular units.

% If angular support is a 2xn vector assume it's not square, otherwise assume
% the image is square
if(size(angularSupport,1) == 1)
    x = angularSupport;
    y = angularSupport;
elseif(size(angularSupport,1) == 2)
    x = angularSupport(1,:);
    y = angularSupport(2,:);
else
    error('angularSupport size is incorrect.');
end

[X,Y] = meshgrid(x,y);
X = imcrop(X,r);
Y = imcrop(Y,r);
TL = [X(1,1) Y(1,1)];
BR = [X(1,end)-X(1,1) Y(end,1)-Y(1,1)];
r_deg = [TL BR];

ang_support_crop_x = X(1,:);
ang_support_crop_y = Y(:,1)';
        
end

