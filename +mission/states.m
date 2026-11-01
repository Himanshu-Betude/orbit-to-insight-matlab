function [rFixed,rInertial,vInertial] = states(c,raan_deg,phase_deg,t_s)
%STATES Circular two-body state; columns correspond to elapsed times.
a = c.radius_km+c.altitude_km;
n = sqrt(c.mu_km3_s2/a^3);
u = deg2rad(phase_deg)+n*t_s(:)';
O = deg2rad(raan_deg); i = deg2rad(c.inclination_deg);
Q = [cos(O),-sin(O)*cos(i),sin(O)*sin(i); ...
     sin(O),cos(O)*cos(i),-cos(O)*sin(i); 0,sin(i),cos(i)];
rInertial = Q*[a*cos(u);a*sin(u);zeros(size(u))];
vInertial = Q*[-a*n*sin(u);a*n*cos(u);zeros(size(u))];
theta = deg2rad(c.earthAngleAtStart_deg)+2*pi*t_s(:)'/c.siderealDay_s;
rFixed = [cos(theta).*rInertial(1,:)+sin(theta).*rInertial(2,:); ...
    -sin(theta).*rInertial(1,:)+cos(theta).*rInertial(2,:);rInertial(3,:)];
end
