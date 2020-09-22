function [lfp_interp, frame_data_rs, video_t_rs, lfp_fs] = get_aligned_lfp_frame_data(videoData,frame_ts_info,lfpData)

winSize = lfpData.winSize;
max_artifact_fract = 0.01;
freq_k = 2;
roundingFactor = 1e2;

frame_and_file_table_data = array2table([videoData.file_frame_number;videoData.fileIdx]');
frame_and_file_table_ts = array2table([frame_ts_info.file_frame_number;frame_ts_info.fileIdx]');
[~,idx_data,idx_ts] = intersect(frame_and_file_table_data,frame_and_file_table_ts,'stable');

video_timestamps_nlg = frame_ts_info.timestamps_nlg(idx_ts);
colons = repmat({':'},1,ndims(videoData.videoData)-1);
video_data = videoData.videoData(idx_data,colons{:});

sessionIdx = video_timestamps_nlg > 0;

video_data = video_data(sessionIdx,colons{:});
video_data = fillmissing(video_data,'linear',1,'EndValues','none');
video_timestamps_nlg = 1e-3*video_timestamps_nlg(sessionIdx);

vid_fs = 1/median(diff(video_timestamps_nlg));
vid_fs = round(roundingFactor*vid_fs)/roundingFactor;

nBat = length(lfpData);
lfp_power = cell(1,nBat);
for bat_k = 1:nBat
    lfpPower_artifact_removed = get_artifact_removed_full_session_LFP(lfpData(bat_k),winSize,max_artifact_fract,freq_k);
    lfp_power{bat_k} = lfpPower_artifact_removed{1};
end

lfp_fs = 1/median(diff(lfpData(1).lfp_power_timestamps));
lfp_fs = round(roundingFactor*lfp_fs)/roundingFactor;

[N,D] = rat(lfp_fs/vid_fs);

tRange = [max(cellfun(@min,{lfpData.lfp_power_timestamps})) min(cellfun(@max,{lfpData.lfp_power_timestamps}))];
[video_t,t_range_idx] = inRange(video_timestamps_nlg,tRange);
video_t_rs = resample(video_t,N,D,0);

frame_data_rs = zeros(length(video_t_rs),size(video_data,2),size(video_data,3));

for bat_k = 1:size(video_data,3)
    frame_data_rs(:,:,bat_k) = resample(video_data(t_range_idx,:,bat_k),N,D);
end

lfp_interp = cell(1,nBat);
for bat_k = 1:nBat
    nChannel = size(lfp_power{bat_k},1);
    lfp_interp{bat_k} = nan(nChannel,length(video_t_rs));
    for ch_k = 1:nChannel
        lfp_interp{bat_k}(ch_k,:) = interp1(lfpData(bat_k).lfp_power_timestamps,lfp_power{bat_k}(ch_k,:),video_t_rs,'linear');
    end
end

end
