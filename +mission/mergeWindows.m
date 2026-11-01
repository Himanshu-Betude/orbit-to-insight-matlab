function w = mergeWindows(w)
%MERGEWINDOWS Union across spacecraft; overlapping access counts once.
if isempty(w), w=zeros(0,2); return; end
w = sortrows(w,1);
out = w(1,:);
for k = 2:size(w,1)
    if w(k,1)<=out(end,2)
        out(end,2)=max(out(end,2),w(k,2));
    else
        out(end+1,:)=w(k,:); %#ok<AGROW>
    end
end
w=out;
end
