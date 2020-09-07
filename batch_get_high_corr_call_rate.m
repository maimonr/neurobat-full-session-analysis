function high_corr_call_rate = batch_get_high_corr_call_rate(baseDir,all_session_lfp_corr)

max_top_peaks = 100;
high_corr_call_rate = struct('corr_call_rate',[],'session_call_rate',[],'callCorr',[],'non_call_corr',[],'nCall',[]);
for k = 1:length(all_session_lfp_corr)
    [corr_call_rate, session_call_rate, callCorr, non_call_corr, nCall] = get_high_corr_call_rate(baseDir,all_session_lfp_corr(k),'max_top_peaks',max_top_peaks);
    high_corr_call_rate(k).corr_call_rate = corr_call_rate;
    high_corr_call_rate(k).session_call_rate = session_call_rate;
    high_corr_call_rate(k).nCall = nCall;
    high_corr_call_rate(k).callCorr = callCorr;
    high_corr_call_rate(k).non_call_corr = non_call_corr;
end

end