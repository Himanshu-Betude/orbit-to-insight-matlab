function animate_orbits()
%ANIMATE_ORBITS Base-MATLAB 3D animation of one orbital period.
c=mission.defaultConfig(); layout=c.layouts(2);
T=2*pi*sqrt((c.radius_km+c.altitude_km)^3/c.mu_km3_s2);
f=figure('Name','Orbit to Insight','Color','w'); ax=axes(f); hold(ax,'on');
[x,y,z]=sphere(50);
surf(ax,c.radius_km*x,c.radius_km*y,c.radius_km*z, ...
    'FaceColor',[0.65 0.79 0.9],'FaceAlpha',0.5,'EdgeColor','none');
colors=lines(4); markers=gobjects(4,1);
for s=1:4
    [~,p]=mission.states(c,layout.raan_deg(s),layout.phase_deg(s),linspace(0,T,250));
    plot3(ax,p(1,:),p(2,:),p(3,:),'Color',colors(s,:));
    markers(s)=plot3(ax,p(1,1),p(2,1),p(3,1),'o', ...
        'MarkerFaceColor',colors(s,:),'MarkerSize',8,'Color',colors(s,:));
end
axis(ax,'equal'); axis(ax,[-7500 7500 -7500 7500 -7500 7500]);
grid(ax,'on'); view(ax,35,25); rotate3d(f,'on');
xlabel(ax,'x [km]'); ylabel(ax,'y [km]'); zlabel(ax,'z [km]');
for t=linspace(0,T,500)
    if ~isgraphics(f), break; end
    for s=1:4
        [~,p]=mission.states(c,layout.raan_deg(s),layout.phase_deg(s),t);
        set(markers(s),'XData',p(1),'YData',p(2),'ZData',p(3));
    end
    title(ax,sprintf('Four satellites, two planes | elapsed %.1f min',t/60));
    drawnow; pause(0.025);
end
end
