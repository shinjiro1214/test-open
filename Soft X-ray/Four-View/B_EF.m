function [Bz_EF,Br_EF] = B_EF(z1_EF,z2_EF,r_EF,i_EF,n_EF,probe_mesh_r,probe_mesh_z,Br_on)
% input:
%   z1_EF & z2_EF: z position of center of EF coils
%   r_EF: r position of EF coils
%   i_EF: EF coil current 
%   n_EF: EF coil turns
%   probe_mesh_r & probe_mesh_z: 2d mesh of (z,r) position of B probes
%   Br_on: true -> calculate Br_EF
%          false-> give zeros
% output:
%   2d array of Bz and Br due to EF coil,
%       and it corresponds to the input position mesh
% a-helmholtz-coil-like configuration is assumed
% algorithm comes from:
%   https://tiggerntatie.github.io/emagnet/offaxis/iloopoffaxis.htm
%   https://permalink.lanl.gov/object/tr?what=info:lanl-repo/lareport/LA-UR-17-27619



mu0   = 4*pi*10^(-7);

% 共通パラメータ計算
alpha = probe_mesh_r / r_EF;
beta1 = (probe_mesh_z + z1_EF) / r_EF;
beta2 = (probe_mesh_z + z2_EF) / r_EF;

Q1 = ((1 + alpha).^2 + beta1.^2);
Q2 = ((1 + alpha).^2 + beta2.^2);

% m = k^2 の計算
m1 = 4 * alpha ./ Q1;
m2 = 4 * alpha ./ Q2;

B0 = i_EF * n_EF * mu0 / (2 * r_EF);

% --- 【高速化】MATLAB組み込み関数で楕円積分を一括計算 ---
[K1, E1] = ellipke(m1); % elliptic_K -> K1, elliptic_E -> E1
[K2, E2] = ellipke(m2); 
% -----------------------------------------------------

% Bz の計算
% 式中の elliptic_E(m1) を E1 に、elliptic_K(m1) を K1 に置き換え
Bz1 = B0 ./ (pi * Q1.^0.5) .* (E1 .* (1 - alpha.^2 - beta1.^2) ./ (Q1 - 4 * alpha) + K1);
Bz2 = B0 ./ (pi * Q2.^0.5) .* (E2 .* (1 - alpha.^2 - beta2.^2) ./ (Q2 - 4 * alpha) + K2);
Bz_EF = Bz1 + Bz2;

if Br_on
    gamma1 = (probe_mesh_z + z1_EF) ./ probe_mesh_r;
    gamma2 = (probe_mesh_z + z2_EF) ./ probe_mesh_r;
    
    Br1 = B0 * gamma1 ./ (pi * Q1.^0.5) .* (E1 .* (1 + alpha.^2 + beta1.^2) ./ (Q1 - 4 * alpha) - K1);
    Br2 = B0 * gamma2 ./ (pi * Q2.^0.5) .* (E2 .* (1 + alpha.^2 + beta2.^2) ./ (Q2 - 4 * alpha) - K2);
    Br_EF = Br1 + Br2;
else
    Br_EF = zeros(size(Bz_EF));
end

end






% mu0   = 4*pi*10^(-7);
% alpha = probe_mesh_r/r_EF;
% beta1 = (probe_mesh_z+z1_EF)/r_EF;
% beta2 = (probe_mesh_z+z2_EF)/r_EF;
% Q1 = ((1+alpha).^2+beta1.^2);
% Q2 = ((1+alpha).^2+beta2.^2);
% k1 = (4*alpha./Q1).^0.5;
% k2 = (4*alpha./Q2).^0.5;
% m1 = k1.^2;
% m2 = k2.^2;
% B0 = i_EF*n_EF*mu0/(2*r_EF);

% Bz1 = B0./(pi*Q1.^0.5).*(elliptic_E(m1).*(1-alpha.^2-beta1.^2)./(Q1-4*alpha)+elliptic_K(m1));
% Bz2 = B0./(pi*Q2.^0.5).*(elliptic_E(m2).*(1-alpha.^2-beta2.^2)./(Q2-4*alpha)+elliptic_K(m2));
% Bz_EF = Bz1 + Bz2;

% if Br_on
% gamma1 = (probe_mesh_z+z1_EF)./probe_mesh_r;
% gamma2 = (probe_mesh_z+z2_EF)./probe_mesh_r;
% Br1 = B0*gamma1./(pi*Q1.^0.5).*(elliptic_E(m1).*(1+alpha.^2+beta1.^2)./(Q1-4*alpha)-elliptic_K(m1));
% Br2 = B0*gamma2./(pi*Q2.^0.5).*(elliptic_E(m2).*(1+alpha.^2+beta2.^2)./(Q2-4*alpha)-elliptic_K(m2));
% Br_EF = Br1 + Br2;
% else
%     Br_EF = zeros(size(Bz_EF));
% end

% function ellipE = elliptic_E(m)
% N = 200;
% theta = linspace(0,pi/2,N);
% d_theta = theta(2:end)-theta(1:end-1);
% d_theta = [0,d_theta];
% ellipE = zeros(size(m));
% [rows,columns] = size(m);
% for i = 1:rows
%     for j = 1:columns
%         integrand = (1-m(i,j)*(sin(theta)).^2).^0.5;
%         ellipE(i,j) = integrand*rot90(d_theta,3);
%     end
% end
% end

% function ellipK = elliptic_K(m)
% N = 200;
% theta = linspace(0,pi/2,N);
% d_theta = theta(2:end)-theta(1:end-1);
% d_theta = [0,d_theta];
% ellipK = zeros(size(m));
% [rows,columns] = size(m);
% for i = 1:rows
%     for j = 1:columns
%         integrand = (1-m(i,j)*(sin(theta)).^2).^(-0.5);
%         ellipK(i,j) = integrand*rot90(d_theta,3);
%     end
% end
% end

% %figure
% %streamslice(z_probe,r_probe,Bz_EF1,Br_EF1,2);
% end