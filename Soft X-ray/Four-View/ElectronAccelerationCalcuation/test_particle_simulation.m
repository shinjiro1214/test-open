close all

% ガイド磁場スキャンのレシピ
% Te=10;ne=repelem(5e19,4);Et=[270 330 390 450];GFR=Et/5;
Te=10;ne=repelem(5e19,4);Et=[270 330 390 450];GFR=Et/10;legendList = {'Thermal','GFR = 4.5','GFR = 5.5','GFR = 6.5','GFR = 7.5'};
% Te=2:2:8;ne=repelem(5e19,4);Et=[270 330 390 450];GFR=Et/10;legendList = {'Thermal','GFR = 4.5','GFR = 5.5','GFR = 6.5','GFR = 7.5'};
% Te=50;ne=repelem(5e19,4);Et=[270 330 390 450];GFR=Et/5;

% Te=10;ne=repelem(5e19,4);Et=[200 300 400 500];GFR=Et/5;
% Te=10;ne=repelem(5e19,3);Et=[200 400 600];GFR=Et/4;

% % 時間発展のレシピ
% Te=10;ne=[2e20 2e20 5e19];Et=[120 240 360];GFR=repelem(50,3);
% legendList = {'Thermal','t=465us','t=468us','t=470us'};

% Te = 10; %[eV]
% Te = 100; %[eV
% Te =300; %[eV]

% ne = [3e20, 5e19]; %[m^-3]
% ne = [1e20, 5e19]; %[m^-3]
% ne = [3e19, 5e18]; %[m^-3]
% ne = repelem(5e19, 3);
% ne = repelem(5e18, 3);

% Et = [270, 330]; %[V/m]
% Et = [300, 400]; %[V/m]
% Et = [200, 400]; %[V/m]
% Et = repelem(400, 4); %[V/m]
% Et = [200 400 600]; %[V/m]

% GFR = [50,50];
% GFR = [50,100,150];

h = 6.63e-34; %プランク定数
e = 1.602176634e-19; %C
me = 9.1093837015e-31;

% f = 1e14:1e14:1e17; %計算する波長帯
% E = 1:1000;
E=1:250;
f = e * E ./ h;

num_particle = 1e5;

v_e = zeros(num_particle,numel(ne));
eps_rad = zeros(numel(ne),numel(f));
I_rad = zeros(4,numel(ne));

for i = 1:numel(ne)
    v_e(:,i) = get_electron_acceleration(num_particle,Te,ne(i),Et(i),GFR(i),false);
    % v_e(:,i) = get_electron_acceleration(num_particle,Te(i),ne(i),Et(i),GFR(i),false);
    eps_rad(i,:) = get_bremsstrahlung_spectrum(v_e(:,i),f,false);
    I_rad(:,i) = get_filtered_intensity(eps_rad(i,:), f);
end
v_e_th = get_electron_acceleration(num_particle,Te(1),ne(1),0,0,false);
eps_rad_th = get_bremsstrahlung_spectrum(v_e_th,f,false);
I_rad_th = get_filtered_intensity(eps_rad_th, f);

% 速度分布のプロット
figure;
v_e_th(v_e_th>2e7)=2e7;[N, edges] = histcounts(v_e_th,'BinWidth',1e5);
semilogy(edges(2:end), N,'k-','LineWidth',2);
hold on;
for i = 1:numel(ne)
    v = v_e(:,i);
    v(v>2e7) = 2e7;
    [N, edges] = histcounts(v,'BinWidth',1e5);
    semilogy(edges(2:end), N,'LineWidth',2);
    % if i == 1
    %     hold on;
    % end
end
xlabel('Electron velocity [m/s]');
ylabel('Number of particles');
legend(legendList,'Location','northeast');
ax = gca;
ax.FontSize = 18;
xlim([0 1.5e7]);
title('Electron velocity distribution');

% 電流計算
I_e = sum(v_e);I_e_th = sum(v_e_th);
% I_e = (I_e - I_e_th) * e * 1e20 / num_particle;
% I_e = I_e * e * 1e20 / (num_particle * 2.5 * 10^3);
I_e = I_e * e * 1e20 / (num_particle * 2.5 * 10^2);
% TF = 2.5:0.5:4;
GFR = 4.5:7.5;
figure;plot(GFR,I_e,'o-','LineWidth',3);
xlabel('Guide field ratio');ylabel('Toroidal current density [A/m^3]');
ax=gca;ax.FontSize=18;xlim([4 8]);

% エネルギー分布のプロット
k_e = zeros(size(v_e));
figure;
k_th = 0.5*me*v_e_th.^2./e;[N, edges] = histcounts(k_th,'BinWidth',1);
semilogy(edges(2:end), N,'k-','LineWidth',2);
hold on;
for i = 1:numel(ne)
    v = v_e(:,i);
    v(v>2e7) = 2e7;
    k = 0.5*me*v.^2./e;
    k_e(:,i) = k;
    [N, edges] = histcounts(k,'BinWidth',1);
    semilogy(edges(2:end), N,'LineWidth',2);
    % if i == 1
    %     hold on;
    % end
end
xlabel('Electron energy [eV]');
ylabel('Number of particles');
legend(legendList,'Location','northeast');
ax = gca;
ax.FontSize = 18;
xlim([0 500]);
title('Electron energy distribution');

% % エネルギーの増加を計算
% K_e=sum(k_e);K_th=sum(k_th);
% K = [K_th, K_e];
% TF = [0, 2.5:0.5:4];
% figure;plot(TF,K,'LineWidth',3);
% xlabel('TF voltage [kV]');ylabel('Electron kinetic energy');
% ax=gca;ax.FontSize=18;%xlim([2.3 4.2]);

% 制動放射スペクトルのプロット
figure;
% yyaxis left
loglog(E,eps_rad_th/sum(eps_rad_th),'k-','LineWidth',2);hold on;
for i = 1:numel(ne)
    eps_plot = eps_rad(i,:)/sum(eps_rad(i,:));
    loglog(E,eps_plot,'LineWidth',2);
    % if i == 1
    %     hold on;
    % end
end
% loglog(E,eps_rad_th/sum(eps_rad_th),'k-','LineWidth',2);
xlabel('Photon energy [eV]');
ylabel('Emissivity [a.u.]');
ax = gca;
ax.FontSize = 18;
title('Bremsstrahlung spectrum');

% yyaxis right
% set(gca, 'YScale', 'log');  % 明示的に右y軸を対数に
% set(gca, 'XScale', 'log');  % x軸も対数に（loglogに対応）
% T = readmatrix('/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/研究資料/フィルタ/Filters_231107.xlsx');
% T(:,3) = T(:,3) * 3;
% T(T<=1e-2) = 1e-2;
% for i = 2:4
%     plot(T(:,1),T(:,i),'LineWidth',2);
%     if i==2
%         hold on;
%     end
% end
% % xlabel('Photon energy [eV]');
% ylabel('Transmittance');

xlim([10 250]);
legend(legendList,'Location','northeast');
% legend({legendList{2:end},'Al 1um','Al 2.5um','Mylar 1um'},'Location','northeast');
ax = gca;
ax.FontSize = 18;

% 発光強度のプロット
figure;hold on;
I_plot = zeros(numel(ne),2);
for i = 1:numel(ne)
    I = I_rad(:,i);
    I = I./I(2);
    % I = I([1,3]);
    % plot(I,'LineWidth',2);
    I_plot(i,:) = I([1,3]);
end
% x_data = 4.5:7.5;
x_data = [465, 468, 470];
% I_plot = I_plot./I_plot(1,:);
plot(x_data,I_plot(:,1)/max(I_plot(:,1)),'o-','LineWidth',2);
plot(x_data,I_plot(:,2)/max(I_plot(:,2)),'o-','LineWidth',2);
% plot(I_plot,'o-','LineWidth',2);
ylabel('Intensity [a.u.]');%xlabel('Photon energy [eV]');
legend({'Low energy','High energy'},'Location','southeast')
% yticks([]);xticks([]);
% ylim([0 inf]);
ax = gca;ax.FontSize = 18;