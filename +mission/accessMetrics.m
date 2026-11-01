function m = accessMetrics(w,horizon)
%ACCESSMETRICS Distinguish internal revisit gaps from clipped edge gaps.
w=mission.mergeWindows(w);
m.windows=size(w,1);
m.coverage_s=sum(w(:,2)-w(:,1));
m.maxInternalGap_s=NaN;
m.meanStartSpacing_s=NaN;
if isempty(w)
    m.maxObservedGap_s=horizon;
    return
end
gaps=w(2:end,1)-w(1:end-1,2);
if ~isempty(gaps), m.maxInternalGap_s=max(gaps); end
starts=w(w(:,1)>0,1); % a pass clipped at t=0 has an unknown actual start
if numel(starts)>1, m.meanStartSpacing_s=mean(diff(starts)); end
m.maxObservedGap_s=max([w(1,1);gaps;horizon-w(end,2)]);
end
