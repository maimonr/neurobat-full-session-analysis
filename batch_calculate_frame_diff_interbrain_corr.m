function [pairwiseCorr, corr_frame_regressed] = batch_calculate_frame_diff_interbrain_corr(baseDir,frame_diff_data)

nExp = length(frame_diff_data.expDate);
[pairwiseCorr,corr_frame_regressed] = deal(cell(1,nExp));
smoothSpan = 100;

for exp_k = 1:nExp
    expDate = frame_diff_data.expDate(exp_k);
    if ~isnat(expDate)
        [lfp_interp, frame_delta_rs] = get_aligned_lfp_frame_data(baseDir,expDate,frame_diff_data);
        
        nBat = length(lfp_interp);
        batPairs = combnk(1:nBat,2);
        nPair = size(batPairs,1);
        
        [pairwiseCorr{exp_k},corr_frame_regressed{exp_k}] = deal(nan(1,nPair));
        [lm,lfpPower] = deal(cell(1,2));
        for pair_k = 1:nPair
            pairIdx = batPairs(pair_k,:);
            lfpPower{1} = smoothdata(nanmedian(lfp_interp{pairIdx(1)},1),'movmean',smoothSpan);
            lfpPower{2} = smoothdata(nanmedian(lfp_interp{pairIdx(2)},1),'movmean',smoothSpan);
            R = corrcoef(lfpPower{:},'Rows','pairwise');
            pairwiseCorr{exp_k}(pair_k) = R(2);
            
            frameDelta = smoothdata(frame_delta_rs{1},'movmean',smoothSpan);
            
            lm{1} = fitlm(frameDelta,lfpPower{1});
            lm{2} = fitlm(frameDelta,lfpPower{2});
            
            R = corrcoef(lm{1}.Residuals.Raw,lm{2}.Residuals.Raw,'Rows','pairwise');
            corr_frame_regressed{exp_k}(pair_k) = R(2);
        end
        
    end
    
end

end