% 電流シートの距離は一定、Bp（エラー磁場）を0.1%~10%近辺で変化

clear
% close all

R = ones(1,3)*0.02;

Bt = 0.1;
Bp = Bt./[20,10,5];

Et = 250; %V/m
me = 9.11e-31; %kg
e = 1.6*10^(-19); %C
e0 = 8.85e-12; %F/m
mi = 6.64e-26; %kg
mr = me*mi/(me+mi);
Te = 20; %eV
ne = 1*1e19; %m^-3
kBT = Te*e; %eV→J（kBはJ/K）
lambdaD = sqrt(e0*kBT/(ne*e^2)); %m
Lambda = 4*pi()*lambdaD^3*ne/3; %無次元数
Z = 2.5; %暫定的な価数

mu = 0;
sigma = sqrt(kBT/me);
v_0 = normrnd(mu,sigma,1,1e4);
% figure;histogram(v_0);

v_0 = abs(v_0);
t_ei = 4*pi()*e0^2*me*mr*v_0.^3./(ne*Z^2*e^4*log(Lambda));

Ep = Et.*Bp.*Bt./(Bp.^2+Bt^2);
t_ra = sqrt(2*me*R./(e.*Ep));


v_e = zeros(3,1e4);
E_e_hist = zeros(3,40);
for i = 1:3
    t_runaway = t_ra(i);
    t_acc = t_ei;
    t_acc(t_acc>t_runaway) = t_runaway;
    v_e(i,:) = v_0 + e*Et/me.*t_acc;
    E_e = 0.5.*me.*v_e(i,:).^2./e;
    E_e(E_e>=200) = 200;
    [E_hist,~] = histcounts(E_e,'BinWidth',5);
    E_e_hist(i,1:numel(E_hist)) = E_hist;
end

% figure;imagesc(sort(v_e,2,'descend'));
E_e_hist(E_e_hist<=1) = 1;
E_e_hist_log = log10(E_e_hist);
% figure;surf(E_e_hist_log);

figure;
[V_hist1,VEdge1] = histcounts(v_e(1,:),'NumBins',100);
[V_hist2,VEdge2] = histcounts(v_e(2,:),'NumBins',100);
[V_hist3,VEdge3] = histcounts(v_e(3,:),'NumBins',100);
[V_hist0,VEdge0] = histcounts(v_0,'NumBins',100);
% loglog(VEdge1(2:end),V_hist1,VEdge2(2:end),V_hist2,VEdge3(2:end),V_hist3,'LineWidth',2);
semilogy(VEdge1(2:end),V_hist1,VEdge2(2:end),V_hist2,VEdge3(2:end),V_hist3,VEdge0(2:end),V_hist0,'LineWidth',2);
xlabel('Electron velocity [km/m]');
ylabel('Number of particles');

E_e = 0.5.*me.*v_e.^2./e;
[E_hist1,Edge1] = histcounts(E_e(1,:),'BinWidth',5);
[E_hist2,Edge2] = histcounts(E_e(2,:),'BinWidth',5);
[E_hist3,Edge3] = histcounts(E_e(3,:),'BinWidth',5);

% Edge_thermal = Edge1;

E_0 = 0.5.*me.*v_0.^2./e;
[E_hist0,Edge0] = histcounts(E_0,'BinWidth',5);


figure;
% semilogy(Edge1(2:end),E_hist1,Edge2(2:end),E_hist2,Edge3(2:end),E_hist3,Edge1,2.2120e+03.*exp(-Edge1./Te));
% loglog(Edge1(2:end),E_hist1,Edge2(2:end),E_hist2,Edge3(2:end),E_hist3,Edge1,2.2120e+03.*exp(-Edge1./Te));
loglog(Edge1(2:end),E_hist1,Edge2(2:end),E_hist2,Edge3(2:end),E_hist3,Edge0(2:end),E_hist0,'LineWidth',2);
ylim([5 1e4]);xlim([0 500]);
ax = gca;
ax.FontSize = 18;
legend({['Bt/Bp=',num2str(Bt/Bp(1))],['Bt/Bp=',num2str(Bt/Bp(2))],['Bt/Bp=',num2str(Bt/Bp(3))],'Thermal'});
xlabel('Electron energy [eV]');
ylabel('Number of particles');
