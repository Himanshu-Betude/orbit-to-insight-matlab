function r = analyse(c,layout)
%ANALYSE Couple geometric observations to the same satellite's downlinks.
assert(c.altitude_km>0 && c.duration_s>0 && c.sample_s>0);
assert(c.fullFov_deg>0 && c.fullFov_deg<=180);
assert(c.inclination_deg>=0 && c.inclination_deg<=180);
assert(c.groundMask_deg>=0 && c.groundMask_deg<90);
assert(numel(layout.raan_deg)==numel(layout.phase_deg));
t=unique([0:c.sample_s:c.duration_s,c.duration_s]);
ns=numel(layout.raan_deg); nt=numel(c.targets);
r.layout=layout; r.config=c; r.time_s=t;
r.contacts=cell(ns,1); r.imaging=cell(ns,nt);
r.union=cell(nt,1); r.metrics=cell(nt,1);
events=zeros(0,7);
for s=1:ns
    O=layout.raan_deg(s); u=layout.phase_deg(s);
    r.contacts{s}=mission.windows(t,@(tt)mission.accessMargin(c,O,u,c.ground,tt,'downlink'));
    for q=1:nt
        w=mission.windows(t,@(tt)mission.accessMargin(c,O,u,c.targets(q),tt,'imaging'));
        r.imaging{s,q}=w;
        for j=1:size(w,1)
            capture=mean(w(j,:)); % one instantaneous observation per pass
            [rawStart,rawEnd]=mission.sendPacket(capture,c.raw_MB,r.contacts{s},c.netRate_Mbps);
            [sumStart,sumEnd]=mission.sendPacket(capture+c.onboard_s,c.summary_MB,r.contacts{s},c.netRate_Mbps);
            events(end+1,:)=[s,q,capture,rawStart,rawEnd+c.groundProcess_s, ...
                sumStart,sumEnd+c.groundProcess_s]; %#ok<AGROW>
        end
    end
end
r.events=array2table(events,'VariableNames', ...
    {'Satellite','Target','Capture_s','RawStart_s','RawUsable_s','SummaryStart_s','SummaryUsable_s'});
if ~isempty(r.events), r.events=sortrows(r.events,'Capture_s'); end
for q=1:nt
    w=vertcat(r.imaging{:,q});
    r.union{q}=mission.mergeWindows(w);
    r.metrics{q}=mission.accessMetrics(w,c.duration_s);
end
r.period_s=2*pi*sqrt((c.radius_km+c.altitude_km)^3/c.mu_km3_s2);
end
