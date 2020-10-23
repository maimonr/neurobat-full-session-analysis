function [lfpPower, timestamps, n_artifact_times] = calculate_all_session_lfp_power(lfpData,timestamps,notchFilters,varargin)

pnames = {'fs','freqBands','winSize','overlap','artifact_nStd_factor'};
dflts  = {2083,[70 150],500,250,5};
[fs,freqBands,winSize,overlap,artifact_nStd_factor] = internal.stats.parseArgs(pnames,dflts,varargin{:});

nFreq = size(freqBands,1);
nChannel = size(lfpData,1);
nSamp = size(lfpData,2);

sliding_win_idx = slidingWin(nSamp,winSize,overlap)';
nWin = size(sliding_win_idx,2);

timestamps = mean(timestamps(sliding_win_idx));

mu = mean(lfpData,2);
sigma = std(lfpData,[],2);

lfpPower = nan(nChannel,nWin,nFreq);
n_artifact_times = zeros(nChannel,nWin);

for channel_k = 1:nChannel
    channel_csc = lfpData(channel_k,:);
    if ~isempty(notchFilters)
        for notch_k = 1:length(notchFilters)
            channel_csc = filtfilt(notchFilters{notch_k},channel_csc);
        end
    end
    win_csc = channel_csc(sliding_win_idx);
    n_artifact_times(channel_k,:) = sum(abs(win_csc - mu(channel_k)) > artifact_nStd_factor*sigma(channel_k),1);
    for f_k = 1:nFreq
        lfpPower(channel_k,:,f_k) = bandpower(win_csc,fs,freqBands(f_k,:));
    end
end

end
