function rd = pushFile(fnameZIP,varargin)
% Push a zip file to the RDT web site, specifically into the isetlensdata
% folder. You must have permission/access to the server in order to push. 

%% Parse inputs
p = inputParser;
for ii=1:2:length(varargin)
    varargin{ii} = ieParamFormat(varargin{ii});
end

% varargin = ieParamFormat(varargin);
p.addRequired('fnameZIP',@ischar);
p.addParameter('artifactname','',@ischar);
p.addParameter('rd',[],@(x)(isa(x,'RdtClient')));

p.parse(fnameZIP,varargin{:});

artifactName = p.Results.artifactname;
rd           = p.Results.rd;

%% Check given file


% Check zip file existence
if(~exist(fnameZIP,'file')), error('Cannot find %s.',fnameZIP); end

% fnameZIP should be an absolute path
% True, but I think this is handled in the publish command now.
% if(isempty(p)), fnameZIP = which(fnameZIP); end

% Check that it is a zip file using the extension
[~,fname,ext] = fileparts(fnameZIP);
if(~strcmp(ext,'.zip'))
    error('Given file does not seem to be a zip file.')
end

%% Get the file from the RDT
% To upload requires that you have a password on the Remote Data site.
% Login here, if rd is not yet passed in.
if isempty(rd)
    rd = RdtClient('isetbio');
    rd.credentialsDialog();
end

%% Set the RDT archive upload destination
rd.crp('/resources/isetlensdata');

%% Do the upload (publish)

fprintf('Uploading... \n');
archivaVersion = '1';   
if(isempty(artifactName))
    % Use the file name as the artifact name
    rd.publishArtifact(fnameZIP,...
        'version',archivaVersion,...
        'name',fname);
else
    % The user seems to want another name for the artifact
    rd.publishArtifact(fnameZIP,'artifactId',artifactName);
end
 
%% Update status
fprintf('Upload complete. \n');

end
