% 加速時間を衝突周波数のみに依存させる
% 加速時間だけ加速させて1-1/eで終了、そうでなければ続行
% ポロイダル方向に進ませてその距離が閾値を超えても終了

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
% Te = 200; %eV
% Te = 1000; %eV
ne = 1*1e19; %m^-3
kBT = Te*e; %eV→J（kBはJ/K）
lambdaD = sqrt(e0*kBT/(ne*e^2)); %m
Lambda = 4*pi()*lambdaD^3*ne/3; %無次元数
Z = 1; %暫定的な価数
h = 6.63e-34; %プランク定数
% Ry = me*e^4/(2*h^2);
Ry = 13.6*e;
c = 3e8;

mu = 0;
% mu = 3e6;
sigma = sqrt(3*kBT/me);
v_0 = normrnd(mu,sigma,1,1e4);

v_0 = abs(v_0);
t_ei = 4*pi()*e0^2*me*mr*abs(v_0).^3./(ne*Z^2*e^4*log(Lambda));

% Ep = Et.*Bp.*Bt./(Bp.^2+Bt^2);
% % t_ra = sqrt(2*me*R./(e.*Ep));
% t_ra = zeros(3,numel(v_0));
% 
% for i = 1:3
%     B_p = Bp(i);
%     A = sqrt(Bt^2+B_p^2);
%     B = (sqrt(v_0.^2.*B_p.^2+2*R(i)*e*Et*Bt*B_p/me)-v_0.*B_p);
%     C = (e*Et*Bt*B_p/me);
%     t_ra(i,:) = A*B/C;
% end

% 全粒子についてforループを使って計算？（計算量が一番多い）
% 3×numel(v_0)の行列（進むステップ数
% 1/eを引き続ける回数
% ガイド磁場依存性は脱出判定のみに使用？
v_e = zeros(3,numel(v_0));
for i = 1:3
    % v_e(i,:) = v_0 + e*Et/me.*t_ei;
    v_e(i,:) = v_0;
    % 加速するかどうかのフラッグを計算
    accelerationFlag = ones(1,numel(v_0));
    % 位置を表す配列の作成
    r = zeros(1,numel(v_0));
    r_matrix = nan(10,numel(v_0));
    r_matrix(1,:) = 0;
    t_matrix = nan(10,numel(v_0));
    t_matrix(1,:) = 0;
    v_matrix = nan(10,numel(v_0));
    v_matrix(1,:) = v_e(i,:);
    B_p = Bp(i);
    A = sqrt(Bt^2+B_p^2);
    C = (e*Et*Bt*B_p/me);
    j=2;
    while max(accelerationFlag) == 1
        % 加速するかどうかのフラッグを更新
        accelerationFlag = accelerationFlag.*ceil(rand(1,numel(v_0))-exp(-1));
        % 新しいt_eiを計算
        t_ei_new = 4*pi()*e0^2*me*mr*abs(v_e(i,:)).^3./(ne*Z^2*e^4*log(Lambda));
        % t_raを計算し、t_eiと比較して加速時間を算出
        % B = (sqrt(v_0.^2.*B_p.^2+2.*(R(i)-r).*e.*Et.*Bt.*B_p./me)-v_0.*B_p);
        B = (sqrt(v_e(i,:).^2.*B_p.^2+2.*(R(i)-r).*e.*Et.*Bt.*B_p./me)-v_e(i,:).*B_p);
        t_runaway = A*B/C;
        t_acc = min(t_runaway,t_ei_new);
        % t_accだけ加速
        v_e_old = v_e(i,:);
        v_e(i,:) = v_e(i,:) + e*Et/me.*t_acc.*accelerationFlag;  
        v_matrix(j,:) = v_e(i,:);
        % 位置を更新
        r = r + (v_e_old.*t_acc+1/2*e*Et/me.*t_acc.^2).*accelerationFlag;
        r(r>R(i)) = R(i);
        r_matrix(j,:) = r;
        t_matrix(j,:) = t_matrix(j-1,:) + t_acc.*accelerationFlag;
        j=j+1;
        % t_runawayの方が短い（脱出する）場合はフラッグを0に
        accelerationFlag(t_runaway<t_ei) = 0;
    end
    % f_r = figure;
    % f_v = figure;
    % for k = 1:1e2:numel(v_0)
    %     figure(f_r);
    %     plot(t_matrix(:,k),r_matrix(:,k));
    %     hold on
    %     figure(f_v);
    %     plot(t_matrix(:,k),v_matrix(:,k));
    %     hold on
    % end
end

v_e(v_e>1e9) = 1e9;


% % 加速の計算
% v_e = zeros(3,1e4);
% E_e_hist = zeros(3,40);
% for i = 1:3
%     t_runaway = t_ra(i,:);
%     t_acc = min(t_runaway,t_ei);
%     % t_acc = t_ei;
%     % t_acc(t_acc>t_runaway & v_0>0) = t_runaway;
%     v_e(i,:) = v_0 + e*Et/me.*t_acc;
% end

nBins = 1000;
% figure;
[V_hist1,VEdge1] = histcounts(v_e(1,:),'NumBins',nBins);
[V_hist2,VEdge2] = histcounts(v_e(2,:),'NumBins',nBins);
[V_hist3,VEdge3] = histcounts(v_e(3,:),'NumBins',nBins);
[V_hist0,VEdge0] = histcounts(v_0,'NumBins',nBins);
% loglog(VEdge1(2:end),V_hist1,VEdge2(2:end),V_hist2,VEdge3(2:end),V_hist3,'LineWidth',2);
% semilogy(VEdge1(2:end),V_hist1,VEdge2(2:end),V_hist2,VEdge3(2:end),V_hist3,VEdge0(2:end),V_hist0,'LineWidth',2);
% xlabel('Electron velocity [km/m]');
% ylabel('Number of particles');

% f_brem = 10.^(linspace(10,17,100));
f_brem = 1e14:1e14:1e17;
% ve = 1e6:1e6:1e8;

ve0 = VEdge0(2:end);
ve1 = VEdge1(2:end);
ve2 = VEdge2(2:end);
ve3 = VEdge3(2:end);
dP0 = V_hist0;
dP1 = V_hist1;
dP2 = V_hist2;
dP3 = V_hist3;

dW0 = log(me*ve0.'.^2./(h*2*pi()*f_brem))./ve0.';
dW1 = log(me*ve1.'.^2./(h*2*pi()*f_brem))./ve1.';
dW2 = log(me*ve2.'.^2./(h*2*pi()*f_brem))./ve2.';
dW3 = log(me*ve3.'.^2./(h*2*pi()*f_brem))./ve3.';

% プロット用のヒストグラム
[dP1_plot,ve1_plot] = histcounts(v_e(1,:),'BinWidth',1e5);
[dP2_plot,ve2_plot] = histcounts(v_e(2,:),'BinWidth',1e5);
[dP3_plot,ve3_plot] = histcounts(v_e(3,:),'BinWidth',1e5);
[dP0_plot,ve0_plot] = histcounts(v_0,'BinWidth',1e5);

figure;
semilogy(ve0_plot(2:end),dP0_plot,ve1_plot(2:end),dP1_plot,ve2_plot(2:end),dP2_plot,ve3_plot(2:end),dP3_plot,'LineWidth',2);
% legend({'thermal','simulation1','simulation2','simulation3'},'Location','northeast');
legend({'thermal',['Bt/Bp=',num2str(Bt/Bp(1))],['Bt/Bp=',num2str(Bt/Bp(2))],['Bt/Bp=',num2str(Bt/Bp(3))]},'Location','northeast');
xlabel('Electron velocity [m/s]');
ylabel('Number of particles');
ax = gca;
ax.FontSize = 18;
title('Electron velocity distribution');

E_e = 0.5.*me.*v_e.^2./e;
[E_hist1,Edge1] = histcounts(E_e(1,:),'BinWidth',5);
[E_hist2,Edge2] = histcounts(E_e(2,:),'BinWidth',5);
[E_hist3,Edge3] = histcounts(E_e(3,:),'BinWidth',5);

E_0 = 0.5.*me.*v_0.^2./e;
[E_hist0,Edge0] = histcounts(E_0,'BinWidth',5);

figure;
% loglog(Edge1(2:end),E_hist1,Edge2(2:end),E_hist2,Edge3(2:end),E_hist3,Edge0(2:end),E_hist0,'LineWidth',2);
loglog(Edge0(2:end),E_hist0,Edge1(2:end),E_hist1,Edge2(2:end),E_hist2,Edge3(2:end),E_hist3,'LineWidth',2);
% ylim([5 1e4]);xlim([0 500]);
ax = gca;
ax.FontSize = 18;
% legend({['Bt/Bp=',num2str(Bt/Bp(1))],['Bt/Bp=',num2str(Bt/Bp(2))],['Bt/Bp=',num2str(Bt/Bp(3))],'Thermal'});
% legend({'thermal','simulation1','simulation2','simulation3'},'Location','northeast');
legend({'thermal',['Bt/Bp=',num2str(Bt/Bp(1))],['Bt/Bp=',num2str(Bt/Bp(2))],['Bt/Bp=',num2str(Bt/Bp(3))]},'Location','northeast');
xlabel('Electron energy [eV]');
ylabel('Number of particles');
title('Electron energy distrbution');

A0 = ve0.^2.*dP0;
A1 = ve1.^2.*dP1;
A2 = ve2.^2.*dP2;
A3 = ve3.^2.*dP3;
num_e0 = sum(A0);
num_e1 = sum(A1);
num_e2 = sum(A2);
num_e3 = sum(A3);

emissivity0 = sum(dW0.*A0.')/num_e0;
emissivity1 = sum(dW1.*A1.')/num_e1;
emissivity2 = sum(dW2.*A2.')/num_e2;
emissivity3 = sum(dW3.*A3.')/num_e3;

energy = h*f_brem/e;

figure;
loglog(energy,emissivity0,energy,emissivity1,energy,emissivity2,energy,emissivity3,'LineWidth',2);
% legend({'thermal','simulation1','simulation2','simulation3'},'Location','northeast');
legend({'thermal',['Bt/Bp=',num2str(Bt/Bp(1))],['Bt/Bp=',num2str(Bt/Bp(2))],['Bt/Bp=',num2str(Bt/Bp(3))]},'Location','southwest');
xlabel('Photon energy [eV]');ylabel('Intensity [a.u.]');title('Bremsstrahlung spectrum');
ax = gca;
ax.FontSize = 18;

T = readmatrix('/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/研究資料/フィルタ/Filters_231107.xlsx');
E = T(:,1);
T_Al10 = T(:,2);
T_Al25 = T(:,3);
T_My10 = T(:,4);
T_My20 = T(:,5);

E_new = 2:200;
T_Al10_new = interp1(E,T_Al10,E_new);
T_Al25_new = interp1(E,T_Al25,E_new);
T_My10_new = interp1(E,T_My10,E_new);
T_My20_new = interp1(E,T_My20,E_new);
% figure;plot(E_new,T_Al10_new,'LineWidth',2);hold on;plot(E_new,T_Al25_new,'LineWidth',2);plot(E_new,T_My10_new,'LineWidth',2);plot(E_new,T_My20_new,'LineWidth',2);
% title('filter transmittance');xlabel('Photon energy [eV]');ylabel('Transmittance');
% ax = gca;
% ax.FontSize = 18;

emissivity0_new = interp1(energy,emissivity0,E_new);
emissivity1_new = interp1(energy,emissivity1,E_new);
emissivity2_new = interp1(energy,emissivity2,E_new);
emissivity3_new = interp1(energy,emissivity3,E_new);
emissivityMatrix = [emissivity0_new;emissivity1_new;emissivity2_new;emissivity3_new];
emissivityMatrix(emissivityMatrix<0) = 0;

intensity_Al10 = emissivityMatrix*T_Al10_new.';
intensity_Al25 = emissivityMatrix*T_Al25_new.';
intensity_My10 = emissivityMatrix*T_My10_new.';
intensity_My20 = emissivityMatrix*T_My20_new.';

GFR = Bt./Bp;
% GFR = [100, GFR];
figure;
subplot(2,2,1);semilogx(GFR,intensity_Al10(2:end),'LineWidth',2);xlabel('Bt/Bp');subtitle('Al10');
subplot(2,2,2);semilogx(GFR,intensity_Al25(2:end),'LineWidth',2);xlabel('Bt/Bp');subtitle('Al25');
subplot(2,2,3);semilogx(GFR,intensity_My10(2:end),'LineWidth',2);xlabel('Bt/Bp');subtitle('My10');
subplot(2,2,4);semilogx(GFR,intensity_My20(2:end),'LineWidth',2);xlabel('Bt/Bp');subtitle('My20');