% BrとBtの比から電流シートを抜けるまでの時間を計算
% その時間だけ加速を受けると仮定して速度を計算

Bt = 0.2;
Br = 0.0001:0.0001:0.2; % different strength of Br

L = 0.05; % width of current sheet [m]

Et = 250; %V/m
me = 9.11e-31; %kg
e = 1.6*10^(-19); %C

Er = Et.*Br.*Bt./(Br.^2+Bt^2);

t_alpha = sqrt(2*me*L./(e.*Er));

figure;plot(Br,t_alpha)
