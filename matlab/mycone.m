function h = mycone(r,h,phi,theta)


m = h/r;
[R,A] = meshgrid(linspace(0,r,11),linspace(0,2*pi,41));
X = R .* cos(A);
Y = R .* sin(A);
Z = m*R;
% Cone around the z-axis, point at the origin
%mesh(X,Y,Z)

X1 = X*cos(phi) - Z*sin(phi);
Y1 = Y;
Z1 = X*sin(phi) + Z*cos(phi);
% Previous cone, rotated by angle phi about the y-axis

X2 = X1*cos(theta) - Y1*sin(theta);
Y2 = X1*sin(theta) + Y1*cos(theta);
Z2 = Z1;
% Second cone rotated by angle theta about the z-axis
mesh(double(X2),double(Y2),double(Z2))

axis square
axis vis3d