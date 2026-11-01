function tests=test_mission
tests=functiontests(localfunctions);
end

function setupOnce(testCase)
root=fileparts(fileparts(mfilename('fullpath')));
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(root));
end

function testCircularStateConservation(testCase)
c=mission.defaultConfig(); a=c.radius_km+c.altitude_km;
T=2*pi*sqrt(a^3/c.mu_km3_s2);
[~,r,v]=mission.states(c,40,20,linspace(0,3*T,601));
verifyEqual(testCase,sqrt(sum(r.^2,1)),a*ones(1,601),'AbsTol',1e-9);
energy=sum(v.^2,1)/2-c.mu_km3_s2./sqrt(sum(r.^2,1));
verifyEqual(testCase,energy,-c.mu_km3_s2/(2*a)*ones(1,601),'AbsTol',1e-10);
h=cross(r,v,1); verifyLessThan(testCase,max(vecnorm(h-h(:,1))),1e-8);
end

function testAgainstNumericalIntegration(testCase)
c=mission.defaultConfig(); a=c.radius_km+c.altitude_km;
T=2*pi*sqrt(a^3/c.mu_km3_s2); tt=linspace(0,2*T,250);
[~,r,v]=mission.states(c,30,15,tt);
rhs=@(~,y)[y(4:6);-c.mu_km3_s2*y(1:3)/norm(y(1:3))^3];
[~,y]=ode45(rhs,tt,[r(:,1);v(:,1)],odeset('RelTol',1e-11,'AbsTol',1e-12));
verifyLessThan(testCase,max(vecnorm(y(:,1:3)'-r)),1e-4); % <10 cm over two orbits
end

function testEarthRotation(testCase)
c=mission.defaultConfig(); c.inclination_deg=0;
t=c.siderealDay_s/4;
[fixed,inertial]=mission.states(c,0,0,t);
verifyEqual(testCase,fixed,[inertial(2);-inertial(1);inertial(3)],'AbsTol',1e-8);
end

function testOverheadAndOcculted(testCase)
c=mission.defaultConfig(); c.inclination_deg=0;
site=struct('lat_deg',0,'lon_deg',0);
verifyGreaterThan(testCase,mission.accessMargin(c,0,0,site,0,'imaging'),0);
verifyLessThan(testCase,mission.accessMargin(c,0,180,site,0,'imaging'),0);
verifyLessThan(testCase,mission.accessMargin(c,0,180,site,0,'downlink'),0);
end

function testHorizonLimit(testCase)
c=mission.defaultConfig(); c.inclination_deg=0; c.groundMask_deg=0;
angle=acosd(c.radius_km/(c.radius_km+c.altitude_km));
site=struct('lat_deg',0,'lon_deg',angle);
verifyEqual(testCase,mission.accessMargin(c,0,0,site,0,'downlink'),0,'AbsTol',1e-10);
end

function testPolarTargetNotReachable(testCase)
c=mission.defaultConfig(); site=struct('lat_deg',85,'lon_deg',0);
margin=mission.accessMargin(c,0,0,site,0:20:c.duration_s,'imaging');
verifyLessThan(testCase,max(margin),0);
end

function testKnownWindowBoundaries(testCase)
w=mission.windows(0:10:100,@(t)min(t-25,76-t));
verifyEqual(testCase,w,[25 76],'AbsTol',0.001);
verifyEqual(testCase,mission.windows(0:10:100,@(t)ones(size(t))),[0 100]);
verifySize(testCase,mission.windows(0:10:100,@(t)-ones(size(t))),[0 2]);
end

function testWindowUnionAndMetrics(testCase)
w=[70 80;10 20;15 30;30 40];
verifyEqual(testCase,mission.mergeWindows(w),[10 40;70 80]);
m=mission.accessMetrics(w,100);
verifyEqual(testCase,m.coverage_s,40);
verifyEqual(testCase,m.maxInternalGap_s,30);
verifyEqual(testCase,m.maxObservedGap_s,30);
verifyEqual(testCase,m.meanStartSpacing_s,60);
empty=mission.accessMetrics(zeros(0,2),100);
verifyEqual(testCase,empty.maxObservedGap_s,100);
verifyTrue(testCase,isnan(empty.maxInternalGap_s));
end

function testWholePacketAndBoundary(testCase)
[s,f]=mission.sendPacket(100,5,[100 120;200 240],2);
verifyEqual(testCase,[s f],[100 120]);
[s,f]=mission.sendPacket(100.01,5,[100 120;200 240],2);
verifyEqual(testCase,[s f],[200 220]);
[~,f]=mission.sendPacket(0,20,[0 10;20 30],8);
verifyTrue(testCase,isinf(f)); % two short contacts cannot be stitched
end

function testContactWaitCanDominateProcessing(testCase)
[~,a]=mission.sendPacket(15,2,[100 200],4);
[~,b]=mission.sendPacket(45,2,[100 200],4);
verifyEqual(testCase,a,b);
end

function testEndToEndEvents(testCase)
c=mission.defaultConfig(); r=mission.analyse(c,c.layouts(2));
verifyGreaterThan(testCase,height(r.events),0);
for k=1:height(r.events)
    s=r.events.Satellite(k); contacts=r.contacts{s};
    finish=r.events.SummaryUsable_s(k)-c.groundProcess_s;
    start=r.events.SummaryStart_s(k);
    if isfinite(finish)
        verifyGreaterThanOrEqual(testCase,start,r.events.Capture_s(k)+c.onboard_s);
        verifyTrue(testCase,any(start>=contacts(:,1)-1e-6 & finish<=contacts(:,2)+1e-6));
    end
end
end

function testSamplingRefinement(testCase)
c=mission.defaultConfig(); a=mission.analyse(c,c.layouts(2));
c.sample_s=2; b=mission.analyse(c,c.layouts(2));
for q=1:numel(c.targets)
    verifyEqual(testCase,a.metrics{q}.windows,b.metrics{q}.windows);
    verifyEqual(testCase,a.union{q},b.union{q},'AbsTol',0.002);
end
end

function testMonteCarloRepeatability(testCase)
c=mission.defaultConfig(); c.trials=8;
r=mission.analyse(c,c.layouts(2));
first=mission.sensitivity(r,c); second=mission.sensitivity(r,c);
verifyEqual(testCase,first,second);
verifyTrue(testCase,all(first.WithinDeadlineFraction>=0 & first.WithinDeadlineFraction<=1));
end
