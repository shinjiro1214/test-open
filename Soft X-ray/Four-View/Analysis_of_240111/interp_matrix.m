function Aq = interp_matrix(A,x)
% usage:
% A: matrix to be interpolated
% x: magnificantion (must be a positive scalar)

originalSize1 = size(A,1);
originalSize2 = size(A,2);
newSize1 = originalSize1*x;
newSize2 = originalSize2*x;

[X,Y] = meshgrid(1:originalSize1,1:originalSize2);
[Xq,Yq] = meshgrid(linspace(1,originalSize1,newSize1),linspace(1,originalSize2,newSize2));

Aq = interp2(X,Y,A,Xq,Yq,'cubic');

end