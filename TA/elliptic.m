Z = 0.22; % PFからの高さ
R = 0.22; % 大半径
mu_0 = 4*pi*1e-7;
I_EF = 2.02; % Ampere
I_PF = 14.59; % Ampere
color_limits = [0, 10e-6];

zvec = linspace(-Z, Z, 31); %めちゃ適当に30分割にした。理由はないです！
rvec = linspace(0, R, 31);
[Rgrid, Zgrid] = meshgrid(rvec, zvec);

%%%%%%%%%%%%%%%%ここからEFコイルの計算
r_EF = 0.26;
z_EF = [0.2,-0.2];
z_EF = reshape(z_EF, 1, 1, []); %上下に二つあるから整形

k_EF = sqrt(4*r_EF*Rgrid./((r_EF+Rgrid).^2 + (Zgrid - z_EF).^2));
[K_EF,E_EF] = ellipke(k_EF);
psi_EF = 2*mu_0*I_EF./k_EF.*sqrt(Rgrid.*r_EF).*((1-k_EF.^2/2).*K_EF-E_EF);
psi_EF_sum = sum(psi_EF, 3); %上下二つを合算
%%%%%%%%%%%%%%%ここからPFコイルの計算
r_PF = 0.15;
z_PF = 0.0;

k_PF = sqrt(4*r_PF*Rgrid./((r_PF+Rgrid).^2 + (Zgrid - z_PF).^2));
[K_PF,E_PF] = ellipke(k_PF);
psi_PF = 2*mu_0*I_PF./k_PF.*sqrt(Rgrid.*r_PF).*((1-k_PF.^2/2).*K_PF-E_PF);
%%%%%%%%%%%%%%%

figure;
contourf(Rgrid, Zgrid, psi_EF_sum,20); colorbar;
xlabel('R [m]');
ylabel('Z [m]');
title('Summed Poloidal Flux (psi\_EF only)');

figure;
contourf(Rgrid, Zgrid, psi_PF,20); colorbar;
xlabel('R [m]');
ylabel('Z [m]');
clim(color_limits);
title('Poloidal Flux (psi\_PF only)');

figure;
contourf(Rgrid, Zgrid, psi_PF + psi_EF_sum,20); colorbar;
xlabel('R [m]');
ylabel('Z [m]');
clim(color_limits);
title('Total Poloidal Flux (psi\_EF + psi\_PF)');

figure;
contourf(Rgrid, Zgrid, psi_PF - psi_EF_sum,20); colorbar;
xlabel('R [m]');
ylabel('Z [m]');
clim(color_limits);
title('Total Poloidal Flux (-psi\_EF + psi\_PF)');