function out = sensitivity(r,c)
%SENSITIVITY Synthetic uncertainty; not fitted to measured flight data.
previous=rng; cleanup=onCleanup(@()rng(previous)); %#ok<NASGU>
rng(c.seed,'twister');
n=height(r.events);
rates=c.rateRange_Mbps(1)+diff(c.rateRange_Mbps)*rand(c.trials,1);
processing=c.processingRange_s(1)+diff(c.processingRange_s)*rand(c.trials,1);
delivered=zeros(c.trials,1); onTime=zeros(c.trials,1); medianDelay=nan(c.trials,1);
for k=1:c.trials
    delays=inf(n,1);
    for e=1:n
        capture=r.events.Capture_s(e); s=r.events.Satellite(e);
        [~,finish]=mission.sendPacket(capture+processing(k),c.summary_MB,r.contacts{s},rates(k));
        delays(e)=finish+c.groundProcess_s-capture;
    end
    if n>0
        delivered(k)=mean(isfinite(delays));
        onTime(k)=mean(delays<=c.deadlineAfterCapture_s);
    else
        delivered(k)=NaN; onTime(k)=NaN;
    end
    if any(isfinite(delays)), medianDelay(k)=median(delays(isfinite(delays))); end
end
out=table((1:c.trials)',rates,processing,delivered,onTime,medianDelay, ...
    'VariableNames',{'Trial','NetRate_Mbps','Onboard_s','DeliveredFraction', ...
    'WithinDeadlineFraction','MedianDeliveredLatency_s'});
end
