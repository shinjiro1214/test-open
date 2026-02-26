clear
close all

% 温度で速度分布を定義
% それに従って初期速度を生成
% 速度で衝突時間が決まる（早いほど衝突しづらく、長く加速される）

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
v_0 = normrnd(mu,sigma,1,1e6);
figure;histogram(v_0);

% v_0(v_0<=0) = 0;
v_0 = abs(v_0);
figure('visible','off');h1=histogram(v_0,'BinWidth',5e5);%set(gca,'YScale','log');
t_ei = 4*pi()*e0^2*me*mr*v_0.^3./(ne*Z^2*e^4*log(Lambda));
figure;plot(sort(t_ei));set(gca,'YScale','log');
v_e = v_0 + e*Et/me*t_ei;
figure('visible','off');h2=histogram(v_e,'BinWidth',5e5);%set(gca,'YScale','log');

V1 = h1.Values;E1 = h1.BinEdges;E1 = E1(2:end);
V2 = h2.Values;E2 = h2.BinEdges;E2 = E2(2:end);
figure;plot(E1,V1);hold on;plot(E2,V2);xlim([0 1e7]);set(gca,'YScale','log');

E_e0 = 0.5.*me.*v_0.^2./e;
E_e0(E_e0>=200) = 200;
figure('visible','off');h3=histogram(E_e0,'BinWidth',5);
E_e = 0.5.*me.*v_e.^2./e;
E_e(E_e>=200) = 200;
figure('visible','off');h4=histogram(E_e,'BinWidth',5);

V3 = h3.Values;V3(V3==0) = 1;E3 = h3.BinEdges;E3 = E3(2:end);
V4 = h4.Values;V4(V4==0) = 1;E4 = h4.BinEdges;E4 = E4(2:end);
figure;plot(E3,V3);hold on;plot(E4,V4);%set(gca,'YScale','log');

Al = find(E3<=80);
I1 = sum(V3(Al));
I2 = sum(V4(Al));
disp(I2/I1*100);