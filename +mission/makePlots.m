function makePlots(study,uncertainty,outputDir)
%MAKEPLOTS Export measured model outputs, not hand-entered headline figures.
c=study{1}.config;
f=figure('Visible','off','Color','w','Position',[100 100 1400 920]);
closeOnExit=onCleanup(@()close(f)); %#ok<NASGU>
tl=tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
colors=[0.05 0.36 0.62;0.04 0.58 0.49;0.85 0.42 0.12;0.49 0.31 0.70];
ax=nexttile(tl); hold(ax,'on');
[x,y,z]=sphere(42);
surf(ax,c.radius_km*x,c.radius_km*y,c.radius_km*z, ...
    'FaceColor',[0.83 0.89 0.94],'EdgeColor','none','FaceAlpha',0.55);
r=study{2};
for s=1:numel(r.layout.raan_deg)
    [~,eci]=mission.states(c,r.layout.raan_deg(s),r.layout.phase_deg(s), ...
        linspace(0,r.period_s,250));
    plot3(ax,eci(1,:),eci(2,:),eci(3,:),'Color',colors(s,:),'LineWidth',1.2);
    scatter3(ax,eci(1,1),eci(2,1),eci(3,1),45,colors(s,:),'filled');
end
axis(ax,'equal'); view(ax,35,25); grid(ax,'on');
xlabel(ax,'x [km]'); ylabel(ax,'y [km]'); zlabel(ax,'z [km]');
title(ax,'Four spacecraft across two orbital planes');
ax=nexttile(tl); hold(ax,'on');
labels=cell(1,4); row=0;
for k=1:2
    for q=1:2
        row=row+1; w=study{k}.union{q};
        for j=1:size(w,1)
            plot(ax,w(j,:)/3600,[row row],'LineWidth',9,'Color',colors(q,:));
        end
        labels{row}=[study{k}.layout.name,' / ',c.targets(q).name];
    end
end
ylim(ax,[0.4 4.6]); xlim(ax,[0 c.duration_s/3600]);
yticks(ax,1:4); yticklabels(ax,labels); grid(ax,'on');
xlabel(ax,'Elapsed time [hours]'); title(ax,'Actual target access, merged across satellites');
ax=nexttile(tl); hold(ax,'on');
e=r.events;
for p=1:2
    if p==1, d=(e.RawUsable_s-e.Capture_s)/60; else, d=(e.SummaryUsable_s-e.Capture_s)/60; end
    ok=isfinite(d);
    scatter(ax,e.Capture_s(ok)/3600,d(ok),30,colors(p,:),'filled');
end
yline(ax,c.deadlineAfterCapture_s/60,'--','20 min target','HandleVisibility','off');
legend(ax,{'Raw data','Onboard summary'},'Location','best');
grid(ax,'on'); xlabel(ax,'Capture time [hours]'); ylabel(ax,'Delivered latency [min]');
title(ax,'Same observation, two delivery policies');
ax=nexttile(tl);
scatter(ax,uncertainty.Onboard_s,uncertainty.WithinDeadlineFraction*100, ...
    24,uncertainty.NetRate_Mbps,'filled');
cb=colorbar(ax); cb.Label.String='Net downlink rate [Mbit/s]';
xlabel(ax,'Onboard processing [s]'); ylabel(ax,'Events within 20 min [%]');
grid(ax,'on'); title(ax,'200 trials with synthetic uncertainty');
title(tl,'Orbit to Insight | Access and delivery study','FontWeight','bold','FontSize',19);
subtitle(tl,'600 km circular orbits | 55 deg inclination | 24 hours | one ground station');
exportgraphics(f,fullfile(outputDir,'overview.png'),'Resolution',160);
% Separate ground tracks: NaNs break curves at the date line.
f2=figure('Visible','off','Color','w','Position',[100 100 1200 550]);
close2=onCleanup(@()close(f2)); %#ok<NASGU>
ax=axes(f2); hold(ax,'on');
for s=1:numel(r.layout.raan_deg)
    pos=mission.states(c,r.layout.raan_deg(s),r.layout.phase_deg(s),0:30:2*r.period_s);
    lon=atan2d(pos(2,:),pos(1,:)); lat=asind(pos(3,:)./sqrt(sum(pos.^2,1)));
    jump=[false,abs(diff(lon))>180]; lon(jump)=NaN; lat(jump)=NaN;
    plot(ax,lon,lat,'Color',colors(s,:),'LineWidth',1.1);
end
for q=1:numel(c.targets)
    plot(ax,c.targets(q).lon_deg,c.targets(q).lat_deg,'kp','MarkerSize',11,'MarkerFaceColor','y');
    text(ax,c.targets(q).lon_deg+3,c.targets(q).lat_deg,c.targets(q).name);
end
xlim(ax,[-180 180]); ylim(ax,[-90 90]); xticks(ax,-180:30:180); yticks(ax,-90:30:90);
xlabel(ax,'Longitude [deg]'); ylabel(ax,'Geocentric latitude [deg]'); grid(ax,'on');
title(ax,'Two-plane ground tracks over two orbits | rotating spherical Earth');
exportgraphics(f2,fullfile(outputDir,'ground_tracks.png'),'Resolution',160);
end
