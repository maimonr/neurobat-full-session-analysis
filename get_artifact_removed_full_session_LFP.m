function lfpPower_artifact_removed = get_artifact_removed_full_session_LFP(lfpData,winSize,max_artifact_frac,freq_k)

nBat = length(lfpData);
lfpPower_artifact_removed = cell(1,nBat);

for bat_k = 1:nBat
    artifact_chunks = lfpData(bat_k).n_artifact_times/winSize > max_artifact_frac;
    lfpPower_artifact_removed{bat_k} = lfpData(bat_k).lfpPower(:,:,freq_k);
    lfpPower_artifact_removed{bat_k}(artifact_chunks) = NaN;
end

end