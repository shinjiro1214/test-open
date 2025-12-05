% function plot_SXR_test()
addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View'
close all 
% NL = false;
% NL = true;

% Definition of reconstruction condition
N_projection_new = 30; %square root of the projection number
N_grid_new = 70; %square root of the grid number

% load parameters for the reconstruction
% filepath = 'parameters.mat';
filepath = '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View/parameters.mat';

% if the parameter file does not exist, calculate the parameters
if isfile(filepath)
    load(filepath, 'gm2d1', 'gm2d2', 'gm2d3', 'gm2d4', 'U1', 'U2', 'U3', 'U4', ...
        's1', 's2', 's3', 's4', 'v1', 'v2', 'v3', 'v4', 'M', 'K', 'range','N_projection', 'N_grid');
    % if N_projection_new ~= N_projection || N_grid_new ~= N_grid
    %     disp('Different parameters - Start calculation!');
    %     clc_parameters_new(N_projection_new,N_grid_new,filepath);
    %     % clc_parameters(N_projection_new,N_grid_new,filepath);
    %     load(filepath, 'gm2d1', 'gm2d2', 'gm2d3', 'gm2d4', 'U1', 'U2', 'U3', 'U4', ...
    %         's1', 's2', 's3', 's4', 'v1', 'v2', 'v3', 'v4', 'M', 'K', 'range','N_projection', 'N_grid');
    % end
else
    disp('No parameter - Start calculation!');
    clc_parameters_new(N_projection_new,N_grid_new,filepath);
    % clc_parameters(N_projection_new,N_grid_new,filepath);
    load(filepath, 'gm2d1', 'gm2d2', 'gm2d3', 'gm2d4', 'U1', 'U2', 'U3', 'U4', ...
        's1', 's2', 's3', 's4', 'v1', 'v2', 'v3', 'v4', 'M', 'K', 'range','N_projection', 'N_grid');   
end

param.M = M;
param.K = K;
param.U = U1;
param.s = s1;
param.v = v1;
param.gm2d = gm2d1;
    
plot_flag = false;
% % ファントムテスト用の画像を準備（4視点分）
zmin = range(3);
zmax = range(4);
rmin = range(5);
rmax = range(6);
[EE_original,Iwgn_phantom1] = Assumption_3(N_projection,gm2d1,zmin,zmax,rmin,rmax,true,param);
EE_original(EE_original<0) = 1e-5;

% reconstruct original images from noisy signal using MFI
EE1 = clc_distribution(M,K,gm2d1,U1,s1,v1,Iwgn_phantom1,plot_flag,true);
EE1(EE1<0) = 1e-5;
E1 = reshape(flipud(EE1),[],1);

% reconstruct original images from noisy signal using TP
EE_L = clc_distribution(M,K,gm2d1,U1,s1,v1,Iwgn_phantom1,plot_flag,false);
EE_L(EE_L<0) = 1e-5;
E_L = reshape(flipud(EE_L),[],1);

Iwgn1 = (gm2d1*E1).';

Iwgn1 = awgn(Iwgn1,10*log10(2),'measured');
% Iwgn=awgn(I,10*log10(10),'measured');
Iwgn1(Iwgn1<0) = 1e-5;

% figure;
% plot(Iwgn_phantom1);hold on;plot(Iwgn1);

EE_new1 = clc_distribution(M,K,gm2d1,U1,s1,v1,Iwgn1,plot_flag,true);
EE_new1(EE_new1<0) = 1e-5;

% plot the reconstructed images
range = range./1000;
zmin = range(1);
zmax = range(2);
rmin = range(5);
rmax = range(6);
r_space_SXR = linspace(rmin,rmax,size(EE1,1));
z_space_SXR = linspace(zmin,zmax,size(EE1,2));

r_range = find(0.060<=r_space_SXR & r_space_SXR<=0.330);
r_space_SXR = r_space_SXR(r_range);
z_range = find(-0.17<=z_space_SXR & z_space_SXR<=0.17);

z_space_SXR = z_space_SXR(z_range);

EE_original = flipud(EE_original);
% figure;hold on;
% plot(EE_original(25,:)./max(EE_original(25,:)));plot(EE1(25,:)./max(EE1(25,:)));
% [GFRM,GFRD] = generate_gfr();errorbar(GFRM,GFRD);
% % plot(EE_new1(25,:)./max(EE_new1(25,:)));
EE0 = EE_original(r_range,z_range);
EE1 = EE1(r_range,z_range);
EE_L = EE_L(r_range,z_range);
EE_new1 = EE_new1(r_range,z_range);

load('/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111030.mat','data2D','grid2D');
cRange = [0 0.5];
% cRange = [0 0.8];
% cRange = [0 5];
% figure('Position',[1 358 1470 420]);
% subplot(1,3,1)
% [SXR_mesh_z,SXR_mesh_r] = meshgrid(z_space_SXR,r_space_SXR);
% [~,h1] = contourf(SXR_mesh_z,SXR_mesh_r,EE0,linspace(cRange(1),cRange(2),20));
% h1.LineStyle = 'none';hold on;
% contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,70)),20,'black')
% c=colorbar;c.Label.String='Intensity [a.u.]';%c.FontSize=18;
% xlim([-0.05,0.05]);ylim([0.2,0.32]);clim(cRange);
% title('オリジナル');
% % axis equal

% subplot(1,3,2)
% [SXR_mesh_z,SXR_mesh_r] = meshgrid(z_space_SXR,r_space_SXR);
% [~,h1] = contourf(SXR_mesh_z,SXR_mesh_r,EE1,linspace(cRange(1),cRange(2),20));
% h1.LineStyle = 'none';hold on;
% contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,70)),20,'black')
% c=colorbar;c.Label.String='Intensity [a.u.]';%c.FontSize=18;
% xlim([-0.05 0.05]);ylim([0.2 0.32]);clim(cRange);
% title('再構成1回目');
% % axis equal

% subplot(1,3,3);
% [SXR_mesh_z,SXR_mesh_r] = meshgrid(z_space_SXR,r_space_SXR);
% [~,h1] = contourf(SXR_mesh_z,SXR_mesh_r,EE_new1,linspace(cRange(1),cRange(2),20));
% h1.LineStyle = 'none';hold on;
% contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,70)),20,'black')
% c=colorbar;c.Label.String='Intensity [a.u.]';%c.FontSize=18;
% xlim([-0.05 0.05]);ylim([0.2 0.32]);clim(cRange);
% title('再構成2回目');
% % axis equal

% 1. Figureと1x3のタイルレイアウトを作成
figure('Position',[1 358 1470 420]);
t = tiledlayout(1, 3); % 1行3列のレイアウト

% (推奨) プロット間の間隔と、図全体の余白を詰める
t.TileSpacing = 'compact';
t.Padding = 'compact';

% 2. メッシュグリッドの計算 (3回繰り返す必要はないため、先に実行)
[SXR_mesh_z, SXR_mesh_r] = meshgrid(z_space_SXR, r_space_SXR);

% --- (a) 1番目のプロット ---
ax1 = nexttile; % subplot(1,3,1) の代わり
[~,h1] = contourf(ax1, SXR_mesh_z, SXR_mesh_r, EE0, linspace(cRange(1), cRange(2), 20));
h1.LineStyle = 'none';

hold(ax1, 'on'); % hold on の代わり
contour(ax1, grid2D.zq(1,:), grid2D.rq(:,1), squeeze(data2D.psi(:,:,70)), 20, 'white', 'LineWidth', 1);
hold(ax1, 'off');

xlabel('z [m]');
ylabel('r [m]');

c = colorbar(ax1);
c.Label.String = 'Intensity [a.u.]';
c.FontSize = 18;

xlim(ax1, [-0.15, 0.15]);
ylim(ax1, [0.1, 0.32]);
clim(ax1, cRange);

title(ax1, '(a) オリジナルファントム画像');
ax1.FontSize = 18;
axis equal

% --- (b) 2番目のプロット ---
ax2 = nexttile; % subplot(1,3,2) の代わり
[~,h1] = contourf(ax2, SXR_mesh_z, SXR_mesh_r, EE_L, linspace(cRange(1), cRange(2), 20));
h1.LineStyle = 'none';

hold(ax2, 'on');
contour(ax2, grid2D.zq(1,:), grid2D.rq(:,1), squeeze(data2D.psi(:,:,70)), 20, 'white', 'LineWidth', 1);
hold(ax2, 'off');

xlabel('z [m]');

c = colorbar(ax2);
c.Label.String = 'Intensity [a.u.]';
c.FontSize = 18;

xlim(ax2, [-0.15, 0.15]);
ylim(ax2, [0.1, 0.32]);
clim(ax2, cRange);

title(ax2, '(b) Tikhonov-Phillisps正則化');
ax2.FontSize = 18;
axis equal

% --- (c) 3番目のプロット ---
ax3 = nexttile; % subplot(1,3,3) の代わり
[~,h1] = contourf(ax3, SXR_mesh_z, SXR_mesh_r, EE1, linspace(cRange(1), cRange(2), 20));
h1.LineStyle = 'none';

hold(ax3, 'on');
contour(ax3, grid2D.zq(1,:), grid2D.rq(:,1), squeeze(data2D.psi(:,:,70)), 20, 'white', 'LineWidth', 1);
hold(ax3, 'off');

xlabel('z [m]');

c = colorbar(ax3);
c.Label.String = 'Intensity [a.u.]';
c.FontSize = 18;

xlim(ax3, [-0.15, 0.15]);
ylim(ax3, [0.1, 0.32]);
clim(ax3, cRange);

title(ax3, '(c) 最小Fisher情報量法');
ax3.FontSize = 18;
axis equal

% figure('Position',[1 358 1470 420]);
% subplot(1,3,1)
% [SXR_mesh_z,SXR_mesh_r] = meshgrid(z_space_SXR,r_space_SXR);
% [~,h1] = contourf(SXR_mesh_z,SXR_mesh_r,EE0,linspace(cRange(1),cRange(2),20));
% h1.LineStyle = 'none';hold on;
% contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,70)),20,'white','LineWidth',1)
% c=colorbar;c.Label.String='Intensity [a.u.]';c.FontSize=18;
% % xlim([-0.05 0.05]);ylim([0.2 0.32]);
% xlim([-0.15,0.15]);ylim([0.1,0.32]);
% clim(cRange);
% title('(a) オリジナルファントム画像');
% ax=gca;ax.FontSize=18;
% % axis equal

% subplot(1,3,2)
% [SXR_mesh_z,SXR_mesh_r] = meshgrid(z_space_SXR,r_space_SXR);
% [~,h1] = contourf(SXR_mesh_z,SXR_mesh_r,EE_L,linspace(cRange(1),cRange(2),20));
% h1.LineStyle = 'none';hold on;
% contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,70)),20,'white','LineWidth',1)
% c=colorbar;c.Label.String='Intensity [a.u.]';c.FontSize=18;
% % xlim([-0.05 0.05]);ylim([0.2 0.32]);
% xlim([-0.15,0.15]);ylim([0.1,0.32]);
% clim(cRange);
% title('(b) Phillisps-Tikhonov正則化');
% ax=gca;ax.FontSize=18;
% % axis equal

% subplot(1,3,3);
% [SXR_mesh_z,SXR_mesh_r] = meshgrid(z_space_SXR,r_space_SXR);
% [~,h1] = contourf(SXR_mesh_z,SXR_mesh_r,EE1,linspace(cRange(1),cRange(2),20));
% h1.LineStyle = 'none';hold on;
% contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,70)),20,'white','LineWidth',1)
% c=colorbar;c.Label.String='Intensity [a.u.]';c.FontSize=18;
% % xlim([-0.05 0.05]);ylim([0.2 0.32]);
% xlim([-0.15,0.15]);ylim([0.1,0.32]);
% clim(cRange);
% title('(c) 最小Fisher情報量法)');
% ax=gca;ax.FontSize=18;
% % axis equal

% --- 1. z=0 のインデックスを特定（前回のコードから再利用） ---
z_target = 0.0; 
[~, z_idx] = min(abs(z_space_SXR - z_target));
z_used = z_space_SXR(z_idx); % 実際に使用するzの値

% --- 2. データの抽出 ---
E_r_dist_0 = EE0(:, z_idx); 
E_r_dist_L = EE_L(:, z_idx); 
E_r_dist_1 = EE1(:, z_idx); 

% --- 3. 新しいFigureとレイアウトを作成 ---
figure('Position',[100 100 800 600]);
t_single = tiledlayout(1, 1); % 1x1 の単一タイルレイアウト

ax_main = nexttile; % メインの軸を取得

% --- 4. プロットの重ね合わせ (hold on) ---
hold(ax_main, 'on');

% オリジナル (EE0)
plot(ax_main, r_space_SXR, E_r_dist_0, 'b-', 'LineWidth', 2, 'DisplayName', 'オリジナルファントム画像'); 

% Tikhonov-Phillisps (EE_L)
plot(ax_main, r_space_SXR, E_r_dist_L, 'r--', 'LineWidth', 2, 'DisplayName', 'Tikhonov-Phillisps正則化'); 

% 最小Fisher情報量法 (EE1)
plot(ax_main, r_space_SXR, E_r_dist_1, 'g--', 'LineWidth', 2, 'DisplayName', '最小Fisher情報量法'); 

hold(ax_main, 'off');

% --- 5. 軸と凡例の設定 ---
% X軸ラベル
xlabel(ax_main, 'r 座標 [m]'); 

% Y軸ラベル (LaTeX表現を使用し、フォント統一のため $...$ で囲む)
ylabel(ax_main, '発光強度 [a.u.]', 'Interpreter', 'latex'); 

% Y軸の範囲を [0, 2] に固定
ylim(ax_main, [0, 2]);

% タイトル
title(ax_main, 'r方向分布 (z \approx 0 m)');

% 凡例の表示
legend(ax_main, 'Location', 'best');

grid(ax_main, 'on');
ax_main.FontSize = 18;

% error1 = sum((EE_new1-EE1).^2/max(EE1,[],'all'),'all')/numel(EE1);
error1 = sum((EE_new1-EE1).^2,'all')/numel(EE1);
% error1 = sum((EE_new1-EE1).^2./EE1,'all')/numel(EE1);
EE_original = EE_original(r_range,z_range);
% error_original = sum((EE_original-EE1).^2/max(EE_original,[],'all'),'all')/numel(EE_original);
error_original = sum((EE_original-EE1).^2,'all')/numel(EE_original);
% error_original = sum((EE_original-EE1).^2./EE_original,'all')/numel(EE_original);
mse_original = sum((EE_original-EE1).^2,'all')/numel(EE_original);
psnr_original = 10*log10(max(EE_original,[],'all')^2/mse_original);

psnr1 = 10*log10(max(EE1,[],'all')^2/error1);

% disp(error1);disp(max(EE1,[],'all'));
% disp(error_original);disp(max(EE_original,[],'all'));
% disp(psnr_original);
% disp(psnr1);

error_1 = sum((EE1-EE_original).^2,'all')/numel(EE_original);
error_new = sum((EE_new1-EE_original).^2,'all')/numel(EE_original);
error_L = sum((EE_L-EE_original).^2,'all')/numel(EE_original);
disp(error_1);disp(error_new);disp(error_L);
PSNR_1 = 10*log10(max(EE_original,[],'all')^2/error_1);
PSNR_new = 10*log10(max(EE_original,[],'all')^2/error_new);
PSNR_L = 10*log10(max(EE_original,[],'all')^2/error_L);
disp(PSNR_1);disp(PSNR_new);disp(PSNR_L);


function [GFRM,GFRD] = generate_gfr()
    dirPathMag = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
    shotList = 7:30;
    % t = 441:480;
    t = 468;
    [Et_z,Br_z,GFR_z] = deal(zeros(numel(shotList),50));
    % trange = t-399;
    j = 1;
    for i = shotList
        load([dirPathMag,num2str(i,'%03i'),'_200ch.mat'],'data2D','grid2D');
        t_idx = find(data2D.trange==t);
        [~,xPointList] = get_axis_x_multi(grid2D,data2D);
        idxR = knnsearch(grid2D.rq(:,1),xPointList.r(t_idx));
        Et_z(j,:)  = -1*mean(data2D.Et(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,t_idx));
        Br_z(j,:)  = mean(data2D.Br(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,t_idx));
        Bt_z = mean(data2D.Bt_th(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,t_idx));
        GFR_z(j,:) = Bt_z./abs(Br_z(j,:));
        j = j+1;
    end

    [~,idxTF40] = ismember([7:9,28:30],shotList);

    EtM40 = mean(Et_z(idxTF40,:),'omitmissing');
    EtD40 = std(Et_z(idxTF40,:),'omitmissing');
    % BrM40 = mean(Br_z(idxTF40,:),'omitmissing');
    % BrD40 = std(Br_z(idxTF40,:),'omitmissing');
    GFRM40 = mean(GFR_z(idxTF40,:),'omitmissing');
    GFRD40 = std(GFR_z(idxTF40,:),'omitmissing');
    % GF. RM = GFRM(15:36);GFRD = GFRD(15:36);
    % A=GFRM40.*EtM40;A(A<=0)=0;
    % EE = A.'*A;
    GFRM=EtM40.*GFRM40;
    GFRD=sqrt((EtD40.*GFRM40).^2+(EtM40.*GFRD40).^2);
    GFRM(GFRM<0)=0;
end

function [EE,Iwgn] = Assumption_3(N_projection,gm2d,zmin,zmax,rmin,rmax,plot_flag,param)

[~, N_g] = size(gm2d);
% N_projection = sqrt(N_p);
N_grid = sqrt(N_g);
m=N_grid;
n=N_grid;
% z_0=0.3;
z_0=0;
r_0=0.3;
% r_0=0.5;
z=linspace(-1,1,m);
r=linspace(-1,1,n);

% z_grid = linspace(200,-200,m);
% z_grid = linspace(zmin,zmax,m);
% r_grid = linspace(rmax,rmin,n);

[r_space,z_space] = meshgrid(r,z); %rが横、zが縦の座標系（左上最小）

% % 1点の発光
% r0_space = sqrt((z_space-z_0).^2+(r_space-r_0).^2);
% EE = exp(-10*r0_space.^2);

% 2点の発光
r0_space = sqrt(4*(z_space-z_0).^2+4*(r_space-r_0).^2);
% r1_space = sqrt(4*(z_space+z_0).^2+4*(r_space+r_0).^2);
% r0_space = sqrt((z_space-z_0).^2+(r_space-r_0).^2);
r1_space = sqrt((z_space+z_0).^2+(r_space+r_0).^2);
% r1_space = sqrt((z_space+z_0).^2+(r_space+0.5*r_0).^2);
% % r1_space = abs((z_space-z_0)+(r_space-r_0));
% % EE = exp(-0.5*r0_space.^2).*exp(-5*r1_space)+1.5*exp(-r0_space.^2);

% 数値的にファントムを生成
% EE = exp(-25*r0_space.^2) + exp(-25*r1_space.^2);
% EE = exp(-100*r0_space.^2) + exp(-25*r1_space.^2);
EE = 0.5*exp(-15*r0_space.^2) + exp(-25*r1_space.^2);
% EE = zeros(size(r0_space));
% EE(r0_space<0.2) = 1;
% EE(r0_space<0.1 | r1_space<0.2) = 1;

% % 斜め発光
% r0_space = sqrt((z_space-z_0).^2+(r_space-r_0).^2);
% r1_space = abs(1.5*(z_space-z_0)+(r_space-r_0))/sqrt(1.25);
% EE = exp(-1*r0_space.^2).*exp(-10*r1_space)+0.5*exp(-25*r0_space.^2);

% EE = generate_phantom_gfr();
EE = EE./max(EE,[],'all');
% EE = EE + exp(-10*r1_space.^2);

% % 広めに定義したグリッドデータを元にファントムを生成し、そのうちから再構成領域のみを抉り取りたい
% [r_space1,z_space1] = meshgrid(r_grid,z_grid); %rが横、zが縦の座標系（右上最小?）

% % EE = zeros(m,n);
% % for i=1:m
% %     for j=1:n
% %         r0 = sqrt((z(i)-z_0)^2+(r(j)-r_0)^2);
% %         r1 = abs(0.5*(z(i)-z_0)+(r(j)-r_0))/sqrt(1.25);
% %         EE(i,j) = 1*exp(-0.5*r0^2)*exp(-5*r1)+1.5*exp(-r0^2);
% %     end
% % end
% % size(E)
EE = EE./max(max(EE))*2;
EE = fliplr(rot90(EE)); %rが縦、zが横、右下最小

% EE = ones(N_grid);

% % 2視点システム時のデータからファントム生成
% loadpath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_LR/210924/shot45/4_high.txt';
% EE = readmatrix(loadpath);

% % 4視点システム時のデータからファントム生成
% load('/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111/shot29/3.mat','EE2');
% EE = EE2;
% % load('/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111/shot24/3.mat','EE4');
% % EE = EE4;
% EE = flipud(EE);
% EE = imresize(EE,sqrt(size(gm2d,2))/size(EE,1),'nearest');

%2D matrix is transformed to 1D transversal vector
E = reshape(EE,1,[]);
% whos gm2d
% whos E
I=gm2d*(E)';
% I = zeros(716,1);
SNR = 10;
% SNR = 5;
% Iwgn=awgn(I,10*log10(10),'measured'); % 5 related to 20%; 10 related to 10%;
% Iwgn=awgn(I,10*log10(5),'measured'); % 5 related to 20%; 10 related to 10%;
Iwgn=awgn(I,10*log10(SNR),'measured');
Iwgn(Iwgn<0)=0;


% 1D column vector is transformed to 2D matrix
n_p = N_projection;
II = zeros(n_p);
IIwgn = zeros(n_p);
k=FindCircle(n_p/2);
II(k) = I;
IIwgn(k) = Iwgn;
Iwgn = Iwgn.';

% I_check = II(75,:);
% j = 1:numel(I_check);
% figure;plot(j,I_check);

% reconstruct original images from noisy signal
EE1 = clc_distribution(param.M,param.K,param.gm2d,param.U,param.s,param.v,Iwgn,false,true);
EE1(EE1<0) = 1e-5;
EE1 = flipud(EE1);
% E1 = reshape(flipud(EE1),[],1);


if plot_flag
    % 1. Figureと2x2のタイルレイアウトを作成
    figure('Position',[248    97   917   730]);
    t = tiledlayout(2, 2);

    % (推奨) プロット間の間隔と、図全体の余白を詰める
    t.TileSpacing = 'compact';
    t.Padding = 'compact';

    % --- (a) 左上のプロット ---
    ax1 = nexttile; % subplot(2,2,1) の代わり
    imagesc(ax1, EE);
    c = colorbar(ax1);
    c.Label.String = 'Emission intensity [a.u.]';
    c.FontSize = 18;
    title(ax1, '(a) Original phantom image');
    axis(ax1, 'image');
    ax1.FontSize = 18;

    % --- (b) 右上のプロット ---
    ax2 = nexttile; % subplot(2,2,2) の代わり
    imagesc(ax2, II);
    c = colorbar(ax2, 'Ticks', [0, 20, 40]);
    c.Label.String = 'Signal intensity [a.u.]';
    c.FontSize = 18;
    title(ax2, '(b) Projected emission w/o noise');
    axis(ax2, 'image');
    ax2.FontSize = 18;

    % --- (c) 左下のプロット ---
    ax3 = nexttile; % subplot(2,2,3) の代わり
    imagesc(ax3, IIwgn);
    c = colorbar(ax3, 'Ticks', [0, 20, 40]);
    c.FontSize = 18;
    c.Label.String = 'Signal intensity [a.u.]';
    title(ax3, '(c) Projected emission w/ noise');
    axis(ax3, 'image');
    ax3.FontSize = 18;

    % --- (d) 右下のプロット ---
    ax4 = nexttile; % subplot(2,2,4) の代わり
    imagesc(ax4, EE1);
    c = colorbar(ax4);
    c.Label.String = 'Emission intensity [a.u.]';
    c.FontSize = 18;
    title(ax4, '(d) Reconstructed image');
    axis(ax4, 'image');
    ax4.FontSize = 18;
end


end

function k = FindCircle(L)
R = zeros(2*L);
for i = 1:2*L
    for j = 1:2*L
        R(i,j) = sqrt((L-i+0.5)^2+(j-L-0.5)^2);
    end
end
% figure;imagesc(R)
k = find(R<L);
end


function EE = generate_phantom_gfr()
    dirPathMag = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
    shotList = 7:30;
    % t = 441:480;
    t = 468;
    [Et_z,Br_z,GFR_z] = deal(zeros(numel(shotList),50));
    % trange = t-399;
    j = 1;
    for i = shotList
        load([dirPathMag,num2str(i,'%03i'),'_200ch.mat'],'data2D','grid2D');
        t_idx = find(data2D.trange==t);
        [~,xPointList] = get_axis_x_multi(grid2D,data2D);
        idxR = knnsearch(grid2D.rq(:,1),xPointList.r(t_idx));
        Et_z_tmp = -1*mean(data2D.Et(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,t_idx));
        Br_z_tmp = mean(data2D.Br(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,t_idx));
        Bt_z_tmp = mean(data2D.Bt_th(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,t_idx));
        if numel(Et_z_tmp) ~= size(Et_z,2)
            zq_tmp = grid2D.zq(1,:);
            zq_q = linspace(min(zq_tmp),max(zq_tmp),size(Et_z,2));
            Et_z(j,:) = interp1(zq_tmp,Et_z_tmp,zq_q);
            Br_z(j,:) = interp1(zq_tmp,Br_z_tmp,zq_q);
            Bt_z = interp1(zq_tmp,Bt_z_tmp,zq_q);
        else
           Et_z(j,:) = Et_z_tmp;
           Br_z(j,:) = Br_z_tmp;
           Bt_z = Bt_z_tmp;
        end   
        % Et_z(j,:)  = -1*mean(data2D.Et(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,t_idx));
        % Br_z(j,:)  = mean(data2D.Br(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,t_idx));
        % Bt_z = mean(data2D.Bt_th(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,t_idx));
        GFR_z(j,:) = Bt_z./abs(Br_z(j,:));
        j = j+1;
    end

    [~,idxTF40] = ismember([7:9,28:30],shotList);

    EtM40 = mean(Et_z(idxTF40,:),'omitmissing');
    % EtD40 = std(Et_z(idxTF40,:),'omitmissing');
    % BrM40 = mean(Br_z(idxTF40,:),'omitmissing');
    % BrD40 = std(Br_z(idxTF40,:),'omitmissing');
    GFRM40 = mean(GFR_z(idxTF40,:),'omitmissing');
    % GFRD40 = std(GFR_z(idxTF40,:),'omitmissing');
    A=GFRM40.*EtM40;A(A<=0)=0;
    EE = A.'*A;
end