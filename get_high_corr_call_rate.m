function [high_corr_call_rate, session_call_rate, callCorr, non_call_corr, nCall] = get_high_corr_call_rate(baseDir,session_lfp_corr,varargin)

pnames = {'max_top_peaks','minPeaks'};
dflts  = {300,100};
[max_top_peaks,minPeaks] = internal.stats.parseArgs(pnames,dflts,varargin{:});

[call_t, callIdx, nonCallIdx] = get_session_call_t(baseDir,session_lfp_corr.expDate,session_lfp_corr.timestamps);
if any(isnan([call_t, callIdx, nonCallIdx]))
    [high_corr_call_rate, session_call_rate, callCorr, non_call_corr, nCall] = deal(NaN);
    return
end

nPair = length(session_lfp_corr.pairwiseCorr);
allLocs = cell(1,nPair);
[callCorr, non_call_corr] = deal(nan(1,nPair));
for pair_k = 1:nPair
    
    callCorr(pair_k) = nanmedian(session_lfp_corr.pairwiseCorr{pair_k}(callIdx,:),'all');
    non_call_corr(pair_k) = nanmedian(session_lfp_corr.pairwiseCorr{pair_k}(nonCallIdx,:),'all');
    
    [pks,locs] = findpeaks(nanmean(session_lfp_corr.pairwiseCorr{pair_k},2));
    [~,peakIdx] = sort(pks,'descend');
    locs = locs(peakIdx);
    nPks = length(locs);
    if nPks < minPeaks
        allLocs{pair_k} = NaN;
    elseif nPks > max_top_peaks
        allLocs{pair_k} = locs(1:max_top_peaks);
    else
        allLocs{pair_k} = locs;
    end
end

nanIdx = cellfun(@(x) any(isnan(x)),allLocs);
high_corr_call_rate = cellfun(@(locs) length(intersect(locs,callIdx))/nT,allLocs);
high_corr_call_rate(nanIdx) = NaN;
session_call_rate = (length(callIdx)*cellfun(@length,allLocs))/(nT^2);
nCall = length(call_t);
end