clear

% 温度に従って初期速度を生成
% 速度で衝突時間が決まる（早いほど衝突しづらく、長く加速される）
% 衝突時に確率1/eを引いたら加速が継続

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

v0 = sqrt(2*kBT/me);
v_e = ones(1e4,200).*v0; %m/s 初期値を熱速度に仮定

figure;hold on;set(gca,'YScale','log');set(gca,'XScale','log');
for i = 1:size(v_e,1)
    t = ones(1,size(v_e,2)).*1e-10;
    for j = 2:size(v_e,2)
        t_ei = 4*pi()*e0^2*mr^2*v_e(i,j-1)^3/(ne*Z^2*e^4*log(Lambda)); %衝突時間(s) (https://fusion.k.u-tokyo.ac.jp/~takase/plasma_3.pdf)
        v_e(i,j) = v_e(i,j-1) + e*Et/me*t_ei;
        t(j) = t(j-1)+t_ei;
        if rand*exp(1) > 1
            v_e(i,min(j+1,200)) = 1e6;
            t(j+1:end) = t(j);
            break;
        end
    end
    plot(t,0.5.*me.*v_e(i,:).^2./e);
end

v_e_max = max(v_e,[],2);
% figure;histogram(v_e_max);%plot(v_e_max);

E_e = 0.5.*me.*v_e_max.^2./e;
E_e(E_e>=200) = 200;
figure;histogram(E_e,'BinWidth',5);
set(gca,'YScale','log')
