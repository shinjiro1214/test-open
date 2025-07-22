% function plot_SXR_test()
addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View'
close all 
% NL = false;
NL = true;

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

    
plot_flag = false;
% % ファントムテスト用の画像を準備（4視点分）
zmin = range(3);
zmax = range(4);
rmin = range(5);
rmax = range(6);
[EE_original,Iwgn_phantom1] = Assumption_3(N_projection,gm2d1,zmin,zmax,rmin,rmax,true);

% reconstruct original images from noisy signal using MFI
EE1 = clc_distribution(M,K,gm2d1,U1,s1,v1,Iwgn_phantom1,plot_flag,NL);
EE1(EE1<0) = 1e-5;
E1 = reshape(flipud(EE1),[],1);

% reconstruct original images from noisy signal using TP
EE_L = clc_distribution(M,K,gm2d1,U1,s1,v1,Iwgn_phantom1,plot_flag,false);
EE_L(EE_L<0) = 1e-5;
E_L = reshape(flipud(EE_L),[],1);

Iwgn1 = (gm2d1*E1).';

Iwgn1 = awgn(Iwgn1,10*log10(5),'measured');
% Iwgn=awgn(I,10*log10(10),'measured'); % 5 related to 20%; 10 related to 10%;
Iwgn1(Iwgn1<0) = 1e-5;

% figure;
% plot(Iwgn_phantom1);hold on;plot(Iwgn1);

EE_new1 = clc_distribution(M,K,gm2d1,U1,s1,v1,Iwgn1,plot_flag,NL);
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

load('/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111030.mat','data2D','grid2D');
cRange = [0 0.5];
% cRange = [0 5];
figure('Position',[1 358 1470 420]);
subplot(1,3,1)
[SXR_mesh_z,SXR_mesh_r] = meshgrid(z_space_SXR,r_space_SXR);
[~,h1] = contourf(SXR_mesh_z,SXR_mesh_r,EE0,linspace(cRange(1),cRange(2),20));
h1.LineStyle = 'none';hold on;
contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,70)),20,'black')
c=colorbar;c.Label.String='Intensity [a.u.]';%c.FontSize=18;
xlim([-0.05,0.05]);ylim([0.2,0.32]);clim(cRange);
title('オリジナル');
% axis equal

subplot(1,3,2)
[SXR_mesh_z,SXR_mesh_r] = meshgrid(z_space_SXR,r_space_SXR);
[~,h1] = contourf(SXR_mesh_z,SXR_mesh_r,EE1,linspace(cRange(1),cRange(2),20));
h1.LineStyle = 'none';hold on;
contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,70)),20,'black')
c=colorbar;c.Label.String='Intensity [a.u.]';%c.FontSize=18;
xlim([-0.05 0.05]);ylim([0.2 0.32]);clim(cRange);
title('再構成1回目');
% axis equal

EE_new1 = EE_new1(r_range,z_range);

subplot(1,3,3);
[SXR_mesh_z,SXR_mesh_r] = meshgrid(z_space_SXR,r_space_SXR);
[~,h1] = contourf(SXR_mesh_z,SXR_mesh_r,EE_new1,linspace(cRange(1),cRange(2),20));
h1.LineStyle = 'none';hold on;
contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,70)),20,'black')
c=colorbar;c.Label.String='Intensity [a.u.]';%c.FontSize=18;
xlim([-0.05 0.05]);ylim([0.2 0.32]);clim(cRange);
title('再構成2回目');
% axis equal

figure('Position',[1 358 1470 420]);
subplot(1,3,1)
[SXR_mesh_z,SXR_mesh_r] = meshgrid(z_space_SXR,r_space_SXR);
[~,h1] = contourf(SXR_mesh_z,SXR_mesh_r,EE0,linspace(cRange(1),cRange(2),20));
h1.LineStyle = 'none';hold on;
contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,70)),20,'white','LineWidth',1)
c=colorbar;c.Label.String='Intensity [a.u.]';%c.FontSize=18;
% xlim([-0.05 0.05]);ylim([0.2 0.32]);
xlim([-0.15,0.15]);ylim([0.1,0.32]);
clim(cRange);
title('オリジナル');
% axis equal

subplot(1,3,2)
[SXR_mesh_z,SXR_mesh_r] = meshgrid(z_space_SXR,r_space_SXR);
[~,h1] = contourf(SXR_mesh_z,SXR_mesh_r,EE1,linspace(cRange(1),cRange(2),20));
h1.LineStyle = 'none';hold on;
contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,70)),20,'white','LineWidth',1)
c=colorbar;c.Label.String='Intensity [a.u.]';%c.FontSize=18;
% xlim([-0.05 0.05]);ylim([0.2 0.32]);
xlim([-0.15,0.15]);ylim([0.1,0.32]);
clim(cRange);
title('非線形再構成');
% axis equal

subplot(1,3,3);
[SXR_mesh_z,SXR_mesh_r] = meshgrid(z_space_SXR,r_space_SXR);
[~,h1] = contourf(SXR_mesh_z,SXR_mesh_r,EE_L,linspace(cRange(1),cRange(2),20));
h1.LineStyle = 'none';hold on;
contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,70)),20,'white','LineWidth',1)
c=colorbar;c.Label.String='Intensity [a.u.]';%c.FontSize=18;
% xlim([-0.05 0.05]);ylim([0.2 0.32]);
xlim([-0.15,0.15]);ylim([0.1,0.32]);
clim(cRange);
title('線形再構成');
% axis equal

% error1 = sum((EE_new1-EE1).^2/max(EE1,[],'all'),'all')/numel(EE1);
error1 = sum((EE_new1-EE1).^2,'all')/numel(EE1);
% error1 = sum((EE_new1-EE1).^2./EE1,'all')/numel(EE1);
EE_original = EE_original(r_range,z_range);
% error_original = sum((EE_original-EE1).^2/max(EE_original,[],'all'),'all')/numel(EE_original);
error_original = sum((EE_original-EE1).^2,'all')/numel(EE_original);

disp(error1);
disp(error_original);


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