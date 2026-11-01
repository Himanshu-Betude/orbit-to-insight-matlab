function margin = accessMargin(c,raan,phase,site,t,kind)
%ACCESSMARGIN Positive when elevation and, if requested, cone limits hold.
r = mission.states(c,raan,phase,t);
unit = [cosd(site.lat_deg)*cosd(site.lon_deg); ...
    cosd(site.lat_deg)*sind(site.lon_deg);sind(site.lat_deg)];
g = c.radius_km*unit;
los = r-g;
range = sqrt(sum(los.^2,1));
elevation = asind(max(-1,min(1,sum(los.*unit,1)./range)));
if strcmp(kind,'downlink')
    margin = elevation-c.groundMask_deg;
elseif strcmp(kind,'imaging')
    offNadir = acosd(max(-1,min(1,sum((g-r).*(-r),1)./ ...
        (range.*sqrt(sum(r.^2,1))))));
    margin = min(elevation,c.fullFov_deg/2-offNadir);
else
    error('mission:BadKind','Use imaging or downlink.');
end
end
