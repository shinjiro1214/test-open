
% pathFirstHalf = '/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/Documents/result_matrix/LF_NLR/240111/shot';
pathFirstHalf = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111/shot';
pathLastHalf = '/3.mat';

% 1:'1um Al', 2:'2.5um Al', 3:'2um Mylar', 4:'1um Mylar'

n_shot = 21;
nShot_1 = n_shot;
nShot_2 = n_shot;
nShot_3 = n_shot;
nShot_4 = n_shot;

mPath_1 = strcat(pathFirstHalf,num2str(nShot_1),pathLastHalf);
mPath_2 = strcat(pathFirstHalf,num2str(nShot_2),pathLastHalf);
mPath_3 = strcat(pathFirstHalf,num2str(nShot_3),pathLastHalf);
mPath_4 = strcat(pathFirstHalf,num2str(nShot_4),pathLastHalf);


% load(mPath_25_1,'EE1','EE2','EE3','EE4');
% EE_25_1=EE1;EE_25_2=EE2;EE_25_3=EE3;EE_25_4=EE4;
load(mPath_1,'EE1');EE_25_1=EE1;
load(mPath_2,'EE2');EE_25_2=EE2;
load(mPath_3,'EE3');EE_25_3=EE3;
load(mPath_4,'EE4');EE_25_4=EE4;
EE_25 = cat(3,EE_25_1,EE_25_2,EE_25_3,EE_25_4);

% EEE = cat(4,EE_25,EE_30,EE_40,EE_35);


% idx_mag = 21;
idx_mag = n_shot;
pathname.pre_processed_directory = getenv('pre_processed_directory_path');%計算結果の保存先（どこでもいい）
PCBfile = strcat(pathname.pre_processed_directory,'/',num2str(240111),sprintf('%03d',idx_mag),'_200ch.mat');
load(PCBfile,'data2D','grid2D');PCBdata25.data2D=data2D;PCBdata25.grid2D=grid2D;

% PCBdata = [PCBdata25,PCBdata30,PCBdata35,PCBdata40];

SXR.date = 240111;
SXR.shot = 0;
SXR.show_localmax = false;
SXR.doSave = false;
SXR.doFilter = false;
SXR.doNLR = true;

zhole1=40;zhole2=-40;                                  
% zmin1=-100;zmax1=180;zmin2=-180;zmax2=100;
zmin1=-200;zmax1=200;zmin2=-200;zmax2=200;
rmin=70;rmax=375;
range = [zmin1,zmax1,zmin2,zmax2,rmin,rmax];
t = 468;
range = range./1000;
zmin1 = range(1);
zmax1 = range(2);
zmin2 = range(3);
zmax2 = range(4);
rmin = range(5);
rmax = range(6);
r_space_SXR = linspace(rmin,rmax,50);
z_space_SXR1 = linspace(zmin1,zmax1,50);
z_space_SXR2 = linspace(zmin2,zmax2,50);

rmin_psi = min(grid2D.rq,[],'all');
rmax_psi = max(grid2D.rq,[],'all');
zmin_psi = min(grid2D.zq,[],'all');
zmax_psi = max(grid2D.zq,[],'all');

r_range = find(rmin_psi<=r_space_SXR & r_space_SXR<=rmax_psi);
r_space_SXR_plot = r_space_SXR(r_range);
z_range1 = find(zmin_psi<=z_space_SXR1 & z_space_SXR1<=zmax_psi);
z_range2 = find(zmin_psi<=z_space_SXR2 & z_space_SXR2<=zmax_psi);

z_space_SXR1_plot = z_space_SXR1(z_range1);
z_space_SXR2_plot = z_space_SXR2(z_range2);

[SXR_mesh_z1,SXR_mesh_r] = meshgrid(z_space_SXR1_plot,r_space_SXR_plot);
[SXR_mesh_z2,~] = meshgrid(z_space_SXR2_plot,r_space_SXR_plot);

psi_mesh_z = grid2D.zq;
psi_mesh_r = grid2D.rq;

SXRdata25.EE = EE_25;
SXRdata25.range = range;
SXRdata25.t = t;
% subplotをループで回して3×3くらいの図面をプロット
%EE1,EE2,EE3?
% X点近傍に限定

% f = figure;f.Units = 'normalized';f.Position = [0.1,0.2,0.8,0.8];
% plot_save_sxr(PCBdata25,SXR,SXRdata25);
% f = figure;f.Units = 'normalized';f.Position = [0.1,0.2,0.8,0.8];
% plot_save_sxr(PCBdata30,SXR,SXRdata30);
% f = figure;f.Units = 'normalized';f.Position = [0.1,0.2,0.8,0.8];
% plot_save_sxr(PCBdata35,SXR,SXRdata35);
% f = figure;f.Units = 'normalized';f.Position = [0.1,0.2,0.8,0.8];
% plot_save_sxr(PCBdata40,SXR,SXRdata40);

nameList = {'E < 50 eV', 'E < 80 eV', 'E > 100 eV'};
% cLimList = {[0 1],[0 0.6],[0 0.2]};
% cLimList = {[0 1],[0 0.6],[0 0.3]};
% cLimList = {[0 1.5],[0 0.8],[0 0.2]};

f = figure;
% f.Position = [0,0,1150,750];
f.Position = [1138 1526 605 276];
tl=tiledlayout(1,2,'TileSpacing','tight','Padding','tight');

PCBdata_tmp = PCBdata25;
data2D = PCBdata_tmp.data2D;
t_idx = find(data2D.trange==t);
psi = data2D.psi(:,:,t_idx);
Bz = data2D.Bz(:,:,t_idx);
Br = data2D.Br(:,:,t_idx);
Bp = sqrt(Bz.^2+Br.^2);

psi_min = min(min(psi));
psi_max = max(max(psi));
contour_layer = linspace(psi_min,psi_max,20);

% load(matrixPathArray(i),'EE1','EE2','EE4');
% % load(matrixPathArray(i),'EE2');
% % load(matrixPathArray(i),'EE3');
% 
% EE = cat(3,EE1,EE2,EE4);
EE = EE_25;

% 負の要素を0で置換
negativeEE = find(EE<0);
EE(negativeEE) = zeros(size(negativeEE));

switch n_shot
    case 19
        CV_z = [-0.03, -0.01, 0.015];
        CV_r = [0.005, 0.01, -0.02];
    case 20
        CV_z = [-0.03, -0.01, -0.008];
        CV_r = [0.01, 0.005, -0.012];
        % cLimList = {[0 1.5],[0 0.8],[0 0.3]};
        cLimList = {[0 3],[0 1],[0 0.25]};
    case 21
        CV_z = [-0.03, 0, 0];
        CV_r = [0, 0.002, -0.018];
        % cLimList = {[0 1.5],[0 0.8],[0 0.2]};
        % cLimList = {[0 0.8],[0 0.5],[0 0.3]};
        cLimList = {[0 1.5],[0 0.5],[0 0.25]};
    case 22
        CV_z = [-0.02, -0.01, -0.005];
        CV_r = [0.01, 0.014, -0.018];
    case 24
        CV_z = [-0.03, 0, 0.01];
        CV_r = [0.005, 0, -0.01];
    case 25
        CV_z = [-0.02, -0.01, -0.012];
        CV_r = [0.01, 0.014, -0.002];
        % cLimList = {[0 0.8],[0 0.5],[0 0.3]};
        cLimList = {[0 0.5],[0 0.6],[0 0.25]};
    case 28
        CV_z = [-0.03, -0.01, -0.015];
        CV_r = [0.02, 0.015, -0.02];
        cLimList = {[0 0.8],[0 0.5],[0 0.3]};
        %  cLimList = {[0 0.5],[0 0.4],[0 0.35]};
    case 29
        CV_z = [-0.03, -0.01, -0.015];
        CV_r = [0.01, 0.0, -0.02];
        cLimList = {[0 1],[0 0.6],[0 0.3]};
    otherwise
        CV_z = [0,0,0];
        CV_r = [0,0,0];
end

for i = 1:2
    j=i;
    if(j==2), j=3; end
    if j ~= 3
        EE_q = griddata(z_space_SXR2,r_space_SXR,EE(:,:,j),psi_mesh_z,psi_mesh_r);
    else
        EE_q = griddata(z_space_SXR1,r_space_SXR,EE(:,:,4),psi_mesh_z,psi_mesh_r);
    end
    % p = positionList(j);
    nexttile;

    cRange = cell2mat(cLimList(j));
    [~,h] = contourf(psi_mesh_z+CV_z(j),psi_mesh_r+CV_r(j),EE_q,linspace(cRange(1),cRange(2),20));clim(cRange);

    colormap('turbo');
    h.LineStyle = 'none';
    % c=colorbar;c.Label.String='Intensity [a.u.]';c.FontSize=18;
    hold on

    [~,hp]=contourf(interp_matrix(psi_mesh_z,3),interp_matrix(psi_mesh_r,3),interp_matrix(psi,3),contour_layer,'white','Fill','off');
    hp.LineWidth = 1.5;

    
    xlabel('z [m]')
    if j == 1
        yticks([0.21 0.31]);
        ylabel('r [m]')
    else
        yticks([]);
        colorbar('eastoutside');
    end

    axis equal

    hold off;
    % xlim([-0.02,0.02]);ylim([0.23,0.29]);
    % xlim([-0.05,0.05]);ylim([0.21,0.31]);xticks([-0.04,0,0.04]);
    xlim([-0.04,0.04]);ylim([0.21,0.31]);xticks([-0.04,0,0.04]);
    % xlim([-0.03,0.03]);ylim([0.21,0.31]);%xticks([-0.03,0,0.03]);

    ax = gca;
    ax.FontSize = 18;
end


% sgtitle(strcat(num2str(t),'us'));
drawnow;