function h = scatter_text(x,y,labels)
% function h = scatter_text(x,y,labels)


if nargin < 3
   error('Must supply three arguments');
   return
end


if size(x) ~= size(y)
   error('Size of x and y must be equal');
   return
end



for r = 1 : length(x)
   h(r) = text(x(r),y(r),labels(r)); 
end

