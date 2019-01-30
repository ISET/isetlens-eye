function data = readZemaxMTF(filename)
%READZEMAXPSF Parse a Zemax Ray Trace Data text file.

%% Check that file exists
if(~exist(filename,'file'))
    error('Cannot find file.');
end

%% Create structure
data = struct();

%% Read file line by line
% For this file, we assume that the first 23 lines are general info

fid = fopen(filename);
tline = fgetl(fid);

inHeader = true;
while inHeader
    
    if(contains(tline,'µm'))
        data.wave = tline;
    end
    
    if(contains(tline,'Units'))
        data.units = tline;
    end
    
    if(contains(tline,'Coordinates'))
        data.coordinates = tline;
    end
    
    % End of header. Continue on to data.
    if(contains(tline,'OBJ'))
        inHeader = false;
    end
    
    tline = fgetl(fid);
end

%% Read the rest of the file
data_tmp = [];
surface_names = {};
k = 1;
while ischar(tline) && ~isempty(tline)
    
    C = strsplit(tline,'\s\s',...
    'DelimiterType','RegularExpression');
    surface_names{k} = C(end);
    C = C(2:(end-1));
    
    % Remove extra zeros, convert to mat
    for ii = 1:length(C)
        C{ii} = strtrim(C{ii});
        data_tmp(k,ii) = str2num(C{ii});
        
    end
    
    k = k + 1;
    tline = fgetl(fid);    
end

fclose(fid);

%% Split up data matrix
data.surface_names = surface_names;
data.surface_number = data_tmp(:,1);
data.intersection = data_tmp(:,2:4);
data.normal = data_tmp(:,8:10);

end

