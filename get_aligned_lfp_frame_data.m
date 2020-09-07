function [lfp_interp, frame_delta_rs, frame_delta_t_rs, lfp_fs] = get_aligned_lfp_frame_data(baseDir,expDate,frame_diff_data)

winSize = 500;
max_artifact_fract = 0.01;
selectCamera = 1;
freq_k = 2;
roundingFactor = 1e2;

[lfp_interp, frame_delta_rs, frame_delta_t_rs, lfp_fs] = deal(NaN);

frame_ts_fnames = dir(fullfile(baseDir,'video_data','video_ts_data',[datestr(expDate,'mmddyyyy') '*' 'frame_timestamps_info.mat']));
if isempty(frame_ts_fnames)
    return
end

nCamera = length(frame_ts_fnames);
frame_timestamps_nlg = cell(1,nCamera);
frame_ts_info = cell(1,nCamera);
for v_k = 1:nCamera
    s = load(fullfile(frame_ts_fnames(v_k).folder,frame_ts_fnames(v_k).name));
    frame_ts_info{v_k} = s.frame_ts_info;
    frame_timestamps_nlg{v_k} = frame_ts_info{v_k}.timestamps_nlg;
end

nFrame = cellfun(@(x) sum(x>0),frame_timestamps_nlg);
[~,camIdx] = min(nFrame);

exp_date_idx = frame_diff_data.expDate == expDate;
frame_delta = cell(1,nCamera);

for v_k = 1:nCamera
    if ~iscell(frame_diff_data.frameDelta{exp_date_idx})
        return
    end
    cameraIdx = arrayfun(@(x) contains(x.name,['Camera ' num2str(v_k)]),frame_diff_data.video_file_names{exp_date_idx});
    current_frame_delta = frame_diff_data.frameDelta{exp_date_idx}(cameraIdx);
    file_ks = unique(frame_ts_info{v_k}.fileIdx);
    for v_file_k = 1:length(file_ks)
        
        n_frame_delta = length(current_frame_delta{v_file_k});
        frame_ts_idx = find(frame_ts_info{v_k}.fileIdx == file_ks(v_file_k));
        n_frame_ts = length(frame_ts_idx);
        
        if n_frame_ts > n_frame_delta
            rmIdx = frame_ts_idx(frame_ts_idx - frame_ts_idx(1)+1 > n_frame_delta);
            frame_timestamps_nlg{v_k}(rmIdx) = NaN;
        elseif n_frame_ts < n_frame_delta
            current_frame_delta{v_file_k} = current_frame_delta{v_file_k}(1:n_frame_ts);    
        end
    end
    
    frame_timestamps_nlg{v_k}(isnan(frame_timestamps_nlg{v_k})) = [];
    
    current_frame_delta = [current_frame_delta{:}];
    
    sessionIdx = frame_timestamps_nlg{v_k} > 0;
    
    frame_delta{v_k} = current_frame_delta(sessionIdx);
    frame_timestamps_nlg{v_k} = 1e-3*frame_timestamps_nlg{v_k}(sessionIdx);
end

if ~isempty(selectCamera)
    frame_timestamps_nlg = frame_timestamps_nlg(selectCamera);
    frame_delta = frame_delta(selectCamera);
    camIdx = 1;
    nCamera = 1;
end

frame_delta_t = frame_timestamps_nlg{camIdx};
vid_fs = 1/median(diff(frame_delta_t));
vid_fs = round(roundingFactor*vid_fs)/roundingFactor;
frame_delta_interp = cell(1,nCamera);
for v_k = 1:nCamera
    frame_delta_interp{v_k} = interp1(frame_timestamps_nlg{v_k},frame_delta{v_k},frame_delta_t);
end

lfpData = struct('lfpPower',[],'lfp_power_timestamps',[],'batNum',[],'n_artifact_times',[]);
lfp_fnames = dir(fullfile(baseDir,'lfp_data',['*' datestr(expDate,'yyyymmdd') '_all_session_lfp_results.mat']));

if isempty(lfp_fnames)
    return
end

nBat = length(lfp_fnames);
lfp_power = cell(1,nBat);
for bat_k = 1:nBat
    lfpData(bat_k) = load(fullfile(lfp_fnames(bat_k).folder,lfp_fnames(bat_k).name), 'lfpPower','lfp_power_timestamps','batNum','n_artifact_times');
    lfpPower_artifact_removed = get_artifact_removed_full_session_LFP(lfpData(bat_k),winSize,max_artifact_fract,freq_k);
    lfp_power{bat_k} = lfpPower_artifact_removed{1};
end

lfp_fs = 1/median(diff(lfpData(1).lfp_power_timestamps));
lfp_fs = round(roundingFactor*lfp_fs)/roundingFactor;

[N,D] = rat(lfp_fs/vid_fs);

tRange = [max(cellfun(@min,{lfpData.lfp_power_timestamps})) min(cellfun(@max,{lfpData.lfp_power_timestamps}))];
[frame_delta_t,t_range_idx] = inRange(frame_delta_t,tRange);
frame_delta_t_rs = resample(frame_delta_t,N,D,0);

frame_delta_rs = cell(1,nCamera);
for v_k = 1:nCamera
    frame_delta_rs{v_k} = resample(frame_delta_interp{v_k}(t_range_idx),N,D);
    frame_delta_rs{v_k} = frame_delta_rs{v_k};
end

lfp_interp = cell(1,nBat);
for bat_k = 1:nBat
    nChannel = size(lfp_power{bat_k},1);
    lfp_interp{bat_k} = nan(nChannel,length(frame_delta_t_rs));
    for ch_k = 1:nChannel
        lfp_interp{bat_k}(ch_k,:) = interp1(lfpData(bat_k).lfp_power_timestamps,lfp_power{bat_k}(ch_k,:),frame_delta_t_rs,'linear');
    end
end

end
