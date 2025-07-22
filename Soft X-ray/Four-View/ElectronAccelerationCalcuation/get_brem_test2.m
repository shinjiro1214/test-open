% 電流シートの距離は一定、Bp（エラー磁場）を0.1%~10%近辺で変化

clear

% R = ones(1,3)*0.02;
% 
% Bt = 1;
% % Bp = Bt./[1000,100,10];
% % Bp = Bt./[10,100,1000];
% % Bp = Bt./[200 500 1000];
% Bp = Bt./[100 200 500];

Et = 250; %V/m
me = 9.11e-31; %kg
e = 1.6*10^(-19); %C
e0 = 8.85e-12; %F/m
mi = 6.64e-26; %kg
mr = me*mi/(me+mi);
% Te = 20; %eV
Te = 20; %eV
ne = 1*1e19; %m^-3
kBT = Te*e; %eV→J（kBはJ/K）
lambdaD = sqrt(e0*kBT/(ne*e^2)); %m
Lambda = 4*pi()*lambdaD^3*ne/3; %無次元数
Z = 1; %暫定的な価数
h = 6.63e-34; %プランク定数
% Ry = me*e^4/(2*h^2);
Ry = 13.6*e;
c = 3e8;

% mu = 0;
mu = 0;
sigma = sqrt(kBT/me);
% v_0 = normrnd(mu,sigma,1,1e4);
% 
% v_0 = abs(v_0);

F = @(v) exp(-1/2*((v-mu)./sigma).^2)/(sigma*sqrt(2*pi()));
F2 = @(v) 1e17*v.^(-4);
v_vals = 1e5:1e5:1e7;
PDF = F(v_vals);
CDF = cumtrapz(v_vals,PDF);
CDF = CDF/max(CDF);

n = 1e4;
u = sort(rand(1,n));
samples = interp1(CDF,v_vals,u);

figure;
% histogram(samples,5, 'Normalization', 'pdf');
histogram(samples,'Normalization', 'pdf','BinWidth',1e5);
hold on;
fplot(F, [1e5 1e7], 'r-', 'LineWidth', 1.5);
set(gca, 'YScale', 'log');
xlabel('x');
ylabel('Probability Density');
title('Inverse Transform Sampling for F(x)');
legend('Sampled Data', 'Target PDF');

figure;
fplot(F, [1e5 1e7], 'r-', 'LineWidth', 1.5);
hold on;
fplot(F2, [1e5 1e7], 'b-', 'LineWidth', 1.5);
set(gca, 'YScale', 'log');