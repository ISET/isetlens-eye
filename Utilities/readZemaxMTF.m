function data = readZemaxMTF(filename)
%READZEMAXPSF Parse a Zmeax MTF text file.

%% Create structure
data = struct();

%% Read file line by line
% For the MTF, we assume that the first 11 lines are general info

fid = fopen(filename);
tline = fgetl(fid);

inHeader = true;
while inHeader
    
    if(contains(tline,'µm'))
        data.wave_comment = tline;
    end
    
    if(contains(tline,'cycles'))
        data.freq_units = tline;
    end
    
    if(contains(tline,'Field'))
        data.field = tline;
    end
    
    % End of header. Continue on to data.
    if(contains(tline,'Tangential'))
        inHeader = false;
    end
    
    tline = fgetl(fid);
end

%% Read the rest of the file
data_tmp = [];
k = 1;
while ischar(tline) && ~isempty(tline)
    
    tmp = textscan(tline,'%f');
    data_tmp(k,:) = cell2mat(tmp);
    k = k + 1;

    tline = fgetl(fid);    
end

fclose(fid);

%% Split up data matrix
data.spatial_frequency = data_tmp(:,1);
data.MTF_tangential = data_tmp(:,2);
data.MTF_sagittal = data_tmp(:,3);



end

