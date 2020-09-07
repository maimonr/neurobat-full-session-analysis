function all_session_lfp_corr = batch_get_pairwise_all_sessin_lfp_corr(baseDir,varargin)

pnames = {'winSize','overlap','max_artifact_frac','freq_k','smoothSpan','chunk_size_s','fs'};
dflts  = {500,250,0.01,2,100,10,2083};
[winSize,overlap,max_artifact_frac,freq_k,smoothSpan,chunk_size_s,fs] = internal.stats.parseArgs(pnames,dflts,varargin{:});

lfp_power_fs = round(fs/(winSize - overlap));
chunkSize = chunk_size_s*lfp_power_fs;

lfp_fnames = dir(fullfile(baseDir,'lfp_data','*all_session_lfp_results.mat'));
lfp_file_strs = arrayfun(@(x) strsplit(x.name,'_'),lfp_fnames,'un',0);
expDates = cellfun(@(x) datetime(x{2},'InputFormat','yyyyMMdd'),lfp_file_strs,'un',0);

expDates = unique([expDates{:}]);
expDates = num2cell(expDates);
nExp = length(expDates);

all_session_lfp_corr = struct('pairwiseCorr',[],'timestamps',[],'expDate',expDates);

for exp_k = 1:nExp
    expDate = expDates{exp_k};
    exp_date_str = datestr(expDate,'yyyymmdd');
    lfp_data_fnames = dir(fullfile(baseDir,'lfp_data',['*' exp_date_str '_all_session_lfp_results.mat']));
    for k = 1:length(lfp_data_fnames)
        lfpData(k) = load(fullfile(lfp_data_fnames(k).folder,lfp_data_fnames(k).name));
    end
    
    lfpPower_artifact_removed = get_artifact_removed_full_session_LFP(lfpData,winSize,max_artifact_frac,freq_k);
    lfpPower_timestamps = {lfpData.lfp_power_timestamps};
    [all_session_lfp_corr(exp_k).pairwiseCorr, all_session_lfp_corr(exp_k).timestamps] =...
        get_pairwise_all_session_lfp_corr(lfpPower_artifact_removed,lfpPower_timestamps,smoothSpan,chunkSize);
    
end


end