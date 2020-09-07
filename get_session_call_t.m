function [call_t, callIdx, nonCallIdx] = get_session_call_t(baseDir,expDate,timestamps)

cut_call_fname = fullfile(baseDir,'call_data',[datestr(expDate,'yyyymmdd') '_cut_call_data.mat']);
if ~exist(cut_call_fname,'file')
    [call_t, callIdx, nonCallIdx] = deal(NaN);
    return
end

s = load(cut_call_fname);
cut_call_data = s.cut_call_data;

callPos = vertcat(cut_call_data.corrected_callpos)*1e-3;
callPos = callPos(:,1);
nCall = length(callPos);

call_t = zeros(1,nCall);

nT = length(timestamps);

for call_k = 1:length(callPos)
    current_call_t = find(timestamps - callPos(call_k) > 0,1,'first')-1;
    if ~isempty(current_call_t)
        call_t(call_k) = current_call_t;
    end
end

call_t = setdiff(call_t,0);
callIdx = unique(call_t);
nonCallIdx = setdiff(1:nT,callIdx);

end