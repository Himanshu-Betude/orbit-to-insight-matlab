function w = windows(t,marginFunction)
%WINDOWS Detect sign changes, then refine each boundary to 0.001 seconds.
% A complete pass shorter than the sampling interval can still be missed.
t = t(:)';
validateattributes(t,{'numeric'},{'finite','real','nonempty'});
assert(all(diff(t)>0),'Time samples must increase strictly.');
active = marginFunction(t)>=0;
assert(numel(active)==numel(t),'Margin must have one value per time.');
changes = find(diff(active)~=0);
edges = zeros(1,numel(changes));
for k = 1:numel(changes)
    j = changes(k); lo = t(j); hi = t(j+1);
    while hi-lo>1e-3
        mid = (lo+hi)/2;
        if (marginFunction(mid)>=0)==active(j), lo=mid; else, hi=mid; end
    end
    edges(k) = (lo+hi)/2;
end
if active(1), edges = [t(1),edges]; end
if active(end), edges = [edges,t(end)]; end
w = reshape(edges,2,[])';
w = w(w(:,2)>w(:,1),:);
end
