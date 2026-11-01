function study = run_study(outputDir)
%RUN_STUDY Compare orbital access and data latency. No add-on toolboxes.
root=fileparts(mfilename('fullpath'));
if nargin==0, outputDir=fullfile(root,'results'); end
if ~exist(outputDir,'dir'), mkdir(outputDir); end
c=mission.defaultConfig();
study=cell(numel(c.layouts),1); rows=cell(0,9);
for k=1:numel(c.layouts)
    r=mission.analyse(c,c.layouts(k)); study{k}=r;
    writetable(r.events,fullfile(outputDir,sprintf('events_layout_%d.csv',k)));
    for q=1:numel(c.targets)
        m=r.metrics{q}; e=r.events(r.events.Target==q,:);
        delays=e.SummaryUsable_s-e.Capture_s;
        fraction=NaN; med=NaN;
        if ~isempty(e), fraction=mean(delays<=c.deadlineAfterCapture_s); end
        if any(isfinite(delays)), med=median(delays(isfinite(delays)))/60; end
        rows(end+1,:)={c.layouts(k).name,c.targets(q).name,m.windows, ...
            m.coverage_s/60,m.maxInternalGap_s/60,m.maxObservedGap_s/60, ...
            height(e),fraction,med}; %#ok<AGROW>
        writematrix(r.union{q},fullfile(outputDir,sprintf('access_layout_%d_target_%d.csv',k,q)));
    end
end
summary=cell2table(rows,'VariableNames',{'Layout','Target','MergedWindows', ...
    'Coverage_min','MaxInternalGap_min','MaxObservedGap_min', ...
    'ObservationEvents','WithinDeadlineFraction','MedianDeliveredLatency_min'});
writetable(summary,fullfile(outputDir,'comparison.csv'));
uncertainty=mission.sensitivity(study{2},c);
writetable(uncertainty,fullfile(outputDir,'sensitivity.csv'));
% Re-run only access geometry at a finer step, comparing both layouts.
fine=c; fine.sample_s=2; conv=zeros(0,6);
for k=1:numel(c.layouts)
    rFine=mission.analyse(fine,c.layouts(k));
    for q=1:numel(c.targets)
        coarse=study{k}.metrics{q}; refined=rFine.metrics{q};
        conv(end+1,:)=[k,q,coarse.windows,refined.windows, ...
            refined.coverage_s-coarse.coverage_s, ...
            refined.maxObservedGap_s-coarse.maxObservedGap_s]; %#ok<AGROW>
    end
end
convergence=array2table(conv,'VariableNames',{'Layout','Target','Windows10s', ...
    'Windows2s','CoverageDifference_s','MaxGapDifference_s'});
writetable(convergence,fullfile(outputDir,'convergence.csv'));
mission.makePlots(study,uncertainty,outputDir);
save(fullfile(outputDir,'study.mat'),'study','summary','uncertainty','convergence','c');
meta=struct('MATLAB',version,'generatedUTC',char(datetime('now','TimeZone','UTC')), ...
    'seed',c.seed,'model','Circular two-body, spherical rotating Earth', ...
    'sample_s',c.sample_s,'refinedSample_s',fine.sample_s,'duration_s',c.duration_s);
fid=fopen(fullfile(outputDir,'run_metadata.json'),'w');
closer=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(meta,'PrettyPrint',true));
disp(summary); disp(convergence);
fprintf('Period: %.3f min. Results saved in %s\n',study{1}.period_s/60,outputDir);
end
