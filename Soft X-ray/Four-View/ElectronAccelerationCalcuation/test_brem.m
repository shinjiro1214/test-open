close all
clear

R = ones(1,3)*0.01;

Bt = 1;
% Bp = Bt./[1000,100,10];
Bp = Bt./[10,100,1000];
% Bp = Bt./[200 500 1000];
% Bp = Bt./[100 200 500];

Et = 250; %V/m
me = 9.11e-31; %kg
e = 1.6*10^(-19); %C
e0 = 8.85e-12; %F/m
mi = 6.64e-26; %kg
mr = me*mi/(me+mi);
Te = 10; %eV
% Te = 100; %eV
% Te = 1000; %eV
ne = 1*1e20; %m^-3
kBT = Te*e; %eV→J（kBはJ/K）
lambdaD = sqrt(e0*kBT/(ne*e^2)); %m
Lambda = 4*pi()*lambdaD^3*ne/3; %無次元数
Z = 1; %暫定的な価数
h = 6.63e-34; %プランク定数
ke = (4*pi()*e0)^(-1);
Ry = me*e^4*ke^2/(2*(0.5*h/pi())^2);
% Ry = 13.6*e;
c = 3e8;

mu = 0;
% mu = 3e6;
sigma = sqrt(kBT/me);
v_0 = normrnd(mu,sigma,1,1e5);

v_0 = sort(abs(v_0));
% t_ei = 4*pi()*e0^2*me*mr*abs(v_0).^3./(ne*Z^2*e^4*log(Lambda));

nBins = 10000;
% figure;

[V_hist0,VEdge0] = histcounts(v_0,'NumBins',nBins);

% f_brem = 1e11:1e11:1e15;
f_brem = 1e13:1e13:1e16;
% f_brem = 1e14:1e14:1e17;
% f_brem = 1e16:1e16:1e19;
w_brem = f_brem*2*pi();

ve0 = VEdge0(2:end);

v_threshold = sqrt(2*Z^2*Ry/me);
bmax = ve0.'./w_brem;
% ve_low = ve0.*(ve0<=v_threshold);
% ve_high = ve0.*(ve0>v_threshold);
% bmin1 = 2*Z*e^2*ke./(me*ve_low.^2);
% bmin1(isnan(bmin1)) = 0;
% bmin1(isinf(bmin1)) = 0;
% bmin2 = h./(me.*ve_high)/(4*pi());
% % bmin2 = h./(me.*ve_high);
% bmin2(isnan(bmin2)) = 0;
% bmin2(isinf(bmin2)) = 0;
% bmin = bmin1+bmin2;
% figure;semilogy(ve0,2*Z*e^2*ke./(me*ve0.^2),ve0,h./(me.*ve0)/(4*pi()));

bmin1 = 2*Z*e^2*ke./(me*ve0.^2);
bmin2 = h./(me.*ve0)/(4*pi());
bmin = max(bmin1,bmin2);

% bmin = h./(me.*ve0);
gff = log(bmax./bmin.');

figure;semilogy(ve0,bmin);

dP0 = V_hist0;
% dW0 = log(me*ve0.'.^2./(h*2*pi()*f_brem))./ve0.';
dW0 = gff./ve0.';
% dW0 = log(me*ve0.'.^3./(2*Z*e^2*2*pi()*f_brem))./ve0.';
% vmin = sqrt(2*h*f_brem/me);
% dW0(ve0.'<vmin) = 0;
dW0(dW0<0) = 0;


% プロット用のヒストグラム
[dP0_plot,ve0_plot] = histcounts(v_0,'BinWidth',1e5);
P0_th = exp(-0.5*me*ve0_plot.^2./(kBT));
P0_th = P0_th*(dP0_plot(1)/P0_th(1));

% figure;
% semilogy(ve0_plot(2:end),dP0_plot,ve0_plot,P0_th,'LineWidth',2);
% % legend({'thermal','simulation1','simulation2','simulation3'},'Location','northeast');
% % legend({'thermal',['Bt/Bp=',num2str(Bt/Bp(1))],['Bt/Bp=',num2str(Bt/Bp(2))],['Bt/Bp=',num2str(Bt/Bp(3))]},'Location','northeast');
% xlabel('Electron velocity [m/s]');
% ylabel('Number of particles');
% ax = gca;
% ax.FontSize = 18;
% title('Electron velocity distribution');

E_0 = 0.5.*me.*v_0.^2./e;
[E_hist0,Edge0] = histcounts(E_0,'BinWidth',5);

% figure;
% % loglog(Edge1(2:end),E_hist1,Edge2(2:end),E_hist2,Edge3(2:end),E_hist3,Edge0(2:end),E_hist0,'LineWidth',2);
% loglog(Edge0(2:end),E_hist0,'LineWidth',2);
% hold on;xline(Z^2*Ry/e);
% % hold on;xline(Z^2*me*e^3/(2*(h/(2*pi()))^2));
% % ylim([5 1e4]);xlim([0 500]);
% ax = gca;
% ax.FontSize = 18;
% % legend({['Bt/Bp=',num2str(Bt/Bp(1))],['Bt/Bp=',num2str(Bt/Bp(2))],['Bt/Bp=',num2str(Bt/Bp(3))],'Thermal'});
% % legend({'thermal','simulation1','simulation2','simulation3'},'Location','northeast');
% % legend({'thermal',['Bt/Bp=',num2str(Bt/Bp(1))],['Bt/Bp=',num2str(Bt/Bp(2))],['Bt/Bp=',num2str(Bt/Bp(3))]},'Location','northeast');
% xlabel('Electron energy [eV]');
% ylabel('Number of particles');
% title('Electron energy distrbution');

A0 = ve0.^2.*dP0;
num_e0 = sum(A0);

emissivity0 = sum(dW0.*A0.')/num_e0;
emissivity0 = emissivity0/sum(emissivity0);

emissivity_th = exp(-h*f_brem./(e*Te)).*sqrt(3*e*Te./(pi()*h*f_brem));
emissivity_th2 = (h*f_brem).^-0.4.*exp(-h*f_brem./(e*Te));

energy = h*f_brem/e;

emissivity_th = emissivity_th/sum(emissivity_th);
emissivity_th2 = emissivity_th2/sum(emissivity_th2);

figure;
loglog(energy,emissivity0,energy,emissivity_th,energy,emissivity_th2,'LineWidth',2);
xlabel('Photon energy [eV]');ylabel('Intensity [a.u.]');title('Bremsstrahlung spectrum');
ax = gca;
ax.FontSize = 18;

figure;loglog(energy,emissivity0./emissivity_th,energy,emissivity_th2./emissivity_th);

% figure;
% loglog(energy,emissivity0,'LineWidth',2);
% xlabel('Photon energy [eV]');ylabel('Intensity [a.u.]');title('Bremsstrahlung spectrum');
% ax = gca;
% ax.FontSize = 18;