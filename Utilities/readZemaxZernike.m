function [data] = readZemaxZernike(filename,varargin)
% Read a Zernike output file from Zemax. We need to be careful, since Zemax
% standard coefficients are "Noll sequential index" form 
% (see https://en.wikipedia.org/wiki/Zernike_polynomials) while ISETBio
% wants them in OSA/ANSI standard form.
%
% The data structure will contain parameter information as well as the
% actual z coefficients. 

%% Prase input

p = inputParser;

% Forces optional inputs to lower case
for ii=1:2:length(varargin)
    varargin{ii} = ieParamFormat(varargin{ii});
end

p.addRequired('filename');

p.addParameter('returnasansi',true,@islogical);

p.parse(filename,varargin{:});
returnasansi   = p.Results.returnasansi;

%% Check that file exists
if(~exist(filename,'file'))
    error('Cannot find file.');
end

%% Create structure
data = struct();

%% Read file line by line
% For the Zemax file, we assume that the first 38 lines are general info

fid = fopen(filename);
tline = fgetl(fid);

inHeader = true;
data.format = '';
while inHeader
    
    if(contains(tline,'Using Zernike Standard polynomials.'))
        data.format = 'Noll Index';
    end
    
    if(contains(tline,'Wavelength'))
        C = strsplit(tline,':');
        tmp = textscan(C{2},'%f');
        data.wavelength_um = cell2mat(tmp);
    end
    
    if(contains(tline,'Field'))
        C = strsplit(tline,':');
        tmp = textscan(C{2},'%f');
        data.field_deg = cell2mat(tmp);
    end
    
    % End of header. Continue on to data.
    if(contains(tline,'Maximum fit error'))
        inHeader = false;
    end
    
    tline = fgetl(fid); % A blank line
end

%% Read the rest of the file
tline = fgetl(fid); % Now data starts
k = 1;
while ischar(tline) && ~isempty(tline)
    
    % Split the line between the Zernike coefficient + index and the actual
    % polynomial.
    C = strsplit(tline,':');
    currPoly = C{2};
    data.polyList{k} = strtrim(currPoly); % Remove empty spaces
    
    % Read the coefficient and index
    tmp = textscan(C{1},'%s %d %f');
    data.indexList(k) = double(tmp{2});
    data.coeffList(k) = tmp{3};
    
    k = k + 1;
    tline = fgetl(fid);    
end

fclose(fid);

%% Ignore indices past 20
if(strcmp(data.format,'Noll Index') && returnasansi)
    keepInd = (data.indexList <= 21);
    data.indexList = data.indexList(keepInd);
    data.coeffList = data.coeffList(keepInd);
    data.polyList = data.polyList(keepInd);
end
    
%% If the format is Noll, let's convert to OSA/ANSI
% These are all from:
% From https://en.wikipedia.org/wiki/Zernike_polynomials

if(strcmp(data.format,'Noll Index') && returnasansi)

warning('Converting Zernike coefficients to ANSI format.');

nm_noll = {'0,0',...
    '1,1','1,-1',...
    '2,0','2,-2','2,2',...
    '3,-1','3,1','3,-3','3,3',...
    '4,0','4,2','4,-2','4,4','4,-4',...
    '5,1','5,-1','5,3','5,-3','5,5','5,-5'};

% Map for Noll indices
nollMap_Indx2NM = containers.Map(num2cell(1:21),nm_noll);

nm_ansi = {'0,0',...
    '1,-1','1,1',...
    '2,-2','2,0','2,2',...
    '3,-3','3,-1','3,1','3,3',...
    '4,-4','4,-2','4,0','4,2','4,4',...
    '5,-5','5,-3','5,-1','5,1','5,3','5,5'};
ansiMap_NM2Indx = containers.Map(nm_ansi,num2cell(0:20));

% First find the corresponding n,m values for the Noll indices
% Then find the corresponding ansi index value.
indexList_ANSI = [];
for ii = 1:length(data.indexList)
    % Can't seem to figure out how to pass the entire list correctly into
    % the map, so let's just loop through for now.
    tmp = nollMap_Indx2NM(data.indexList(ii));
    indexList_ANSI(ii)= ansiMap_NM2Indx(tmp);
end

% Rearrange coefficients and polynomials 
[data.indexList, Y] = sort(indexList_ANSI);
data.coeffList = data.coeffList(Y);
data.polyList = data.polyList(Y);
data.format = 'ANSI';

end

end

