function c = defaultConfig()
%DEFAULTCONFIG Original, synthetic mission scenarios. Distances are in km.
c.radius_km = 6371;
c.mu_km3_s2 = 398600.4418;
c.siderealDay_s = 86164.0905;
c.altitude_km = 600;
c.inclination_deg = 55;
c.earthAngleAtStart_deg = 0;
c.duration_s = 24*3600;
c.sample_s = 10;
c.fullFov_deg = 80;
c.groundMask_deg = 10;
c.targets = struct('name',{'Belfast','Singapore'}, ...
    'lat_deg',{54.60,1.35},'lon_deg',{-5.93,103.82});
c.ground = struct('name','Belfast ground station', ...
    'lat_deg',54.60,'lon_deg',-5.93);
c.layouts = struct('name',{'One plane','Two planes'}, ...
    'raan_deg',{[0 0 0 0],[0 0 90 90]}, ...
    'phase_deg',{[0 90 180 270],[0 180 90 270]});
c.raw_MB = 180;
c.summary_MB = 2;
c.netRate_Mbps = 6;
c.onboard_s = 45;
c.groundProcess_s = 15;
c.deadlineAfterCapture_s = 20*60;
c.seed = 307;
c.trials = 200;
c.rateRange_Mbps = [3 9];
c.processingRange_s = [15 600];
end
