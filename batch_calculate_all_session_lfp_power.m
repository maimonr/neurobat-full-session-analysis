function [success,errs] = batch_calculate_all_session_lfp_power(baseDir,outDir,varargin)

pnames = {'overwriteFlag','used_exp_dates'};
dflts  = {true,[]};
[overwriteFlag,used_exp_dates] = internal.stats.parseArgs(pnames,dflts,varargin{:});

t = tic;

expDirs = dir(fullfile(baseDir,'*20*'));
expDirs = expDirs([expDirs.isdir]);
lfpDirs = cell(1,length(expDirs));
for k = 1:length(expDirs)
    lfpDirs{k} = dir(fullfile(expDirs(k).folder,expDirs(k).name,'lfpformat','*LFP.mat'));
end
lfpDirs = vertcat(lfpDirs{:});

lfp_file_strs = arrayfun(@(x) strsplit(x.name,'_'),lfpDirs,'un',0);
batNums = cellfun(@(x) x{1},lfp_file_strs,'un',0);
expDates = cellfun(@(x) datetime(x{2},'InputFormat','yyyyMMdd'),lfp_file_strs);

if ~isempty(used_exp_dates)
   used_exp_idx = ismember(expDates,used_exp_dates);
   lfpDirs = lfpDirs(used_exp_idx);
   batNums = batNums(used_exp_idx);
   expDates = expDates(used_exp_idx);
end

nFile = length(lfpDirs);
success = false(1,nFile);
errs = cell(1,nFile);

fs = 2083;
notch_filter_60Hz=designfilt('bandstopiir','FilterOrder',2,'HalfPowerFrequency1',59.5,'HalfPowerFrequency2',60.5,'DesignMethod','butter','SampleRate',fs);
notch_filter_120Hz=designfilt('bandstopiir','FilterOrder',2,'HalfPowerFrequency1',119.5,'HalfPowerFrequency2',120.5,'DesignMethod','butter','SampleRate',fs);
notchFilters = {notch_filter_60Hz,notch_filter_120Hz};

winSize = 500;
overlap = 250;
artifact_nStd_factor = 5;
freqBands = [5 20; 70 150];

lastProgress = 0;
for file_k = 1:length(lfpDirs)
    lfp_data_fname = fullfile(lfpDirs(file_k).folder,lfpDirs(file_k).name);
    results_fname = fullfile(outDir,[batNums{file_k} '_' datestr(expDates(file_k),'yyyymmdd') '_all_session_lfp_results.mat']);
    if overwriteFlag || ~exist(results_fname,'file')
        try
            lfpData = load(lfp_data_fname,'lfpData','timestamps');
            idx = lfpData.timestamps > 0 ;
            timestamps = lfpData.timestamps(idx);
            lfpData = lfpData.lfpData(:,idx);
            [lfpPower, lfp_power_timestamps, n_artifact_times] = calculate_all_session_lfp_power(lfpData,timestamps,notchFilters,...
                'fs',fs,'freqBands',freqBands,'winSize',winSize,'overlap',overlap,...
                'artifact_nStd_factor',artifact_nStd_factor);
            batNum = batNums{file_k};
            expDate = expDates(file_k);
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
    
    progress = 100*(file_k/length(lfpDirs));
    elapsed_time = round(toc(t));
    
    if mod(progress,10) < mod(lastProgress,10)
        fprintf('%d %% of current bat''s directories  processed\n',round(progress));
        fprintf('%d total directories processed, %d s elapsed\n',file_k,elapsed_time);
    end
    lastProgress = progress;
end
end