function [r_deg, ang_support_crop_x, ang_support_crop_y] = convertRectPx2Ang(r,angularSupport)

% Convert rectangle units from pixel units to angular units.
% Assuming square image

[X,Y] = meshgrid(angularSupport,angularSupport);
X = imcrop(X,r);
Y = imcrop(Y,r);
TL = [X(1,1) Y(1,1)];
BR = [X(1,end)-X(1,1) Y(end,1)-Y(1,1)];
r_deg = [TL BR];

ang_support_crop_x = X(1,:);
ang_support_crop_y = Y(:,1);
        
end

