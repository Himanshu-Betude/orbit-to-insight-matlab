function [start_s,finish_s] = sendPacket(ready_s,size_MB,contacts,rate_Mbps)
%SENDPACKET Earliest whole-packet transfer that fits within one contact.
validateattributes(ready_s,{'numeric'},{'scalar','finite','real','nonnegative'});
validateattributes(size_MB,{'numeric'},{'scalar','finite','real','positive'});
validateattributes(rate_Mbps,{'numeric'},{'scalar','finite','real','positive'});
assert(size(contacts,2)==2 && all(isfinite(contacts(:))) && ...
    all(contacts(:,2)>=contacts(:,1)), 'Invalid contact windows.');
contacts=sortrows(contacts,1);
start_s=Inf; finish_s=Inf;
duration_s=8*size_MB/rate_Mbps; % decimal MB and Mbit/s
for k=1:size(contacts,1)
    candidate=max(ready_s,contacts(k,1));
    if candidate+duration_s<=contacts(k,2)+1e-9
        start_s=candidate; finish_s=candidate+duration_s;
        return
    end
end
end
