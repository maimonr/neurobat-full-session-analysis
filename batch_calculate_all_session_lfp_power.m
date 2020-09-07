function [success,errs] = batch_calculate_all_session_lfp_power(baseDir,outDir)

overwriteFlag = true;
t = tic;

lfp_fnames = dir(fullfile(baseDir,'*LFP.mat'));
nFile = length(lfp_fnames);
success = false(1,nFile);
errs = cell(1,nFile);

lfp_file_strs = arrayfun(@(x) strsplit(x.name,'_'),lfp_fnames,'un',0);
batNums = cellfun(@(x) x{1},lfp_file_strs,'un',0);
expDates = cellfun(@(x) datetime(x{2},'InputFormat','yyyyMMdd'),lfp_file_strs,'un',0);

fs = 2083;
notch_filter_60Hz=designfilt('bandstopiir','FilterOrder',2,'HalfPowerFrequency1',59.5,'HalfPowerFrequency2',60.5,'DesignMethod','butter','SampleRate',fs);
notch_filter_120Hz=designfilt('bandstopiir','FilterOrder',2,'HalfPowerFrequency1',119.5,'HalfPowerFrequency2',120.5,'DesignMethod','butter','SampleRate',fs);
notchFilters = {notch_filter_60Hz,notch_filter_120Hz};

winSize = 500;
overlap = 250;
artifact_nStd_factor = 5;
freqBands = [5 20; 70 150];

lastProgress = 0;
for file_k = 1:length(lfp_fnames)
    lfp_data_fname = fullfile(lfp_fnames(file_k).folder,lfp_fnames(file_k).name);
    results_fname = fullfile(outDir,[batNums{file_k} '_' datestr(expDates{file_k},'yyyymmdd') '_all_session_lfp_results.mat']);
    if overwriteFlag || ~exist(results_fname,'file')
        try
            lfpData = load(lfp_data_fname,'lfpData','timestamps');
            idx = lfpData.timestamps > 0 ;
            timestamps = lfpData.timestamps(idx);
            lfpData = lfpData.lfpData(:,idx);
            [lfpPower, lfp_power_timestamps, n_artifact_times] = calculate_all_session_lfp_ps(lfpData,timestamps,notchFilters,...
                'fs',fs,'freqBands',freqBands,'winSize',winSize,'overlap',overlap,...
                'artifact_nStd_factor',artifact_nStd_factor);
            batNum = batNums{file_k};
            expDate = expDates{file_k};
            save(results_fname,'lfpPower','lfp_power_timestamps','n_artifact_times',...
                'freqBands','winSize','overlap','fs','artifact_nStd_factor',...
                'batNum','expDate');
        catch err
            errs{file_k} = err;
            success(file_k) = false;
        end
        success(file_k) = true;
    else
        success(file_k) = false;
    end
    
    progress = 100*(file_k/length(lfp_fnames));
    elapsed_time = round(toc(t));
    
    if mod(progress,10) < mod(lastProgress,10)
        fprintf('%d %% of current bat''s directories  processed\n',round(progress));
        fprintf('%d total directories processed, %d s elapsed\n',file_k,elapsed_time);
    end
    lastProgress = progress;
end
end