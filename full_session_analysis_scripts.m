fs = 2083;
chunkSize = 10*fs;
max_artifact_frac = 0.01;
freq_k = 2;

expDate = datetime(2019,5,7);
exp_date_str = datestr(expDate,'yyyymmdd');
baseDir = 'E:\ephys\adult_operant_recording\lfp_data\';
lfp_data_fnames = dir([baseDir '\*' exp_date_str '*all_session_lfp_results.mat']);
for k = 1:length(lfp_data_fnames)
    lfpData(k) = load(fullfile(lfp_data_fnames(k).folder,lfp_data_fnames(k).name));
end

lfpPower_artifact_removed = get_artifact_removed_full_session_LFP(lfpData,chunkSize,max_artifact_frac,freq_k);

%%
smoothSpan = 200;
pairwiseCorr = get_pairwise_all_session_lfp_corr(lfpPower_artifact_removed,smoothSpan);

%%

