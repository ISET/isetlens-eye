function artifacts = listFiles()
% List names of files on rdt, in the isetlens-eye data folder. 

remotedirectory = '/resources/isetlensdata';

%%
rdt = RdtClient('isetbio');
rdt.crp(remotedirectory);
artifacts = rdt.listArtifacts('print',true);

end