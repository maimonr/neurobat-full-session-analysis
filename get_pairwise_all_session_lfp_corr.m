function [pairwiseCorr, corrTimestamps] = get_pairwise_all_session_lfp_corr(lfpPower,lfpPower_timestamps,smoothSpan,chunkSize)

nBat = length(lfpPower);
batPairs = combnk(1:nBat,2);
nPair = size(batPairs,1);

tsRange = cellfun(@(ts) [min(ts) max(ts)],lfpPower_timestamps,'un',0);
tsRange = vertcat(tsRange{:});
tsRange = [max(tsRange(:,1)) min(tsRange(:,2))];

tIdx = cellfun(@(ts) ts > tsRange(1) & ts < tsRange(2),lfpPower_timestamps,'un',0);
lfpPower = cellfun(@(lfp,idx) lfp(:,idx),lfpPower,tIdx,'un',0);
timestamps = cellfun(@(ts,idx) ts(idx), lfpPower_timestamps, tIdx,'un',0);

L = min(cellfun(@(x) size(x,2),lfpPower));
lfpPower = cellfun(@(x) x(:,1:L),lfpPower,'un',0);
timestamps = cellfun(@(x) x(:,1:L),timestamps,'un',0);
timestamps = vertcat(timestamps{:});
timestamps = mean(timestamps,1);

sliding_win_idx = slidingWin(L,chunkSize,0);
nChunk = size(sliding_win_idx,1);

corrTimestamps = mean(timestamps(sliding_win_idx),2);

pairwiseCorr = cell(1,nPair);
for pair_k = 1:nPair
    X = lfpPower{batPairs(pair_k,1)};
    Y = lfpPower{batPairs(pair_k,2)};
    nChannel_pairs = size(X,1)*size(Y,1);
    pairwiseCorr{pair_k} = nan(nChunk,nChannel_pairs);
    for chunk_k = 1:nChunk
        chunkIdx = sliding_win_idx(chunk_k,:);
        
        
        
        chunkX = X(:,chunkIdx)';
        chunkY = Y(:,chunkIdx)';
        if smoothSpan > 0
            R = corr(smoothdata(chunkX,'movmean',smoothSpan),smoothdata(chunkY,'movmean',smoothSpan));
        else
            R = corr(chunkX,chunkY);
        end
        pairwiseCorr{pair_k}(chunk_k,:) = R(:);
    end
end

end