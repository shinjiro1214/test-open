r = 0.4; % radius
d = 0.4; % distance between coils
mu0 = 4*pi*10^-7;
I = 1; % Ampere

z1 = d/2;
z2 = z1-d;
B1 = mu0*I/2*(r^2)/(r^2+z1^2)^(3/2);
B2 = mu0*I/2*(r^2)/(r^2+z2^2)^(3/2);
B = B1+B2;
disp(['B = ',num2str(B),' T']);
disp(B1);
disp(B2);