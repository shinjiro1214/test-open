
% pathFirstHalf = '/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/Documents/result_matrix/LF_NLR/240111/shot';
pathFirstHalf = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111/shot';
pathLastHalf = '/3.mat';

% 1:'1um Al', 2:'2.5um Al', 3:'2um Mylar', 4:'1um Mylar'

nShot_25_1 = 19;
nShot_25_2 = 19;
nShot_25_3 = 19;
nShot_25_4 = 19;
nShot_30_1 = 24;
nShot_30_2 = 24;
nShot_30_3 = 24;
nShot_30_4 = 24;
nShot_35_1 = 25;
nShot_35_2 = 25;
nShot_35_3 = 25;
nShot_35_4 = 25;
% nShot_35_4 = 7;
% nShot_40_1 = 28;
% nShot_40_2 = 28;
% nShot_40_3 = 28; %or29
% % nShot_40_4 = 7;
% nShot_40_4 = 28;

nShot_40_1 = 29;
nShot_40_2 = 29;
nShot_40_3 = 29;
nShot_40_4 = 29;

mPath_25_1 = strcat(pathFirstHalf,num2str(nShot_25_1),pathLastHalf);
mPath_25_2 = strcat(pathFirstHalf,num2str(nShot_25_2),'/3.mat');
mPath_25_3 = strcat(pathFirstHalf,num2str(nShot_25_3),'/3.mat');
mPath_25_4 = strcat(pathFirstHalf,num2str(nShot_25_4),pathLastHalf);
mPath_30_1 = strcat(pathFirstHalf,num2str(nShot_30_1),pathLastHalf);
mPath_30_2 = strcat(pathFirstHalf,num2str(nShot_30_2),pathLastHalf);
mPath_30_3 = strcat(pathFirstHalf,num2str(nShot_30_3),pathLastHalf);
mPath_30_4 = strcat(pathFirstHalf,num2str(nShot_30_4),pathLastHalf);
% mpath_30_4_2 = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111/shot13/3.mat';
mPath_35_1 = strcat(pathFirstHalf,num2str(nShot_35_1),pathLastHalf);
mPath_35_2 = mPath_35_1;
mPath_35_3 = strcat(pathFirstHalf,num2str(nShot_35_3),pathLastHalf);
mPath_35_4 = strcat(pathFirstHalf,num2str(nShot_35_4),pathLastHalf);
mPath_40_1 = strcat(pathFirstHalf,num2str(nShot_40_1),pathLastHalf);
mPath_40_2 = strcat(pathFirstHalf,num2str(nShot_40_2),pathLastHalf);
mPath_40_3 = strcat(pathFirstHalf,num2str(nShot_40_3),pathLastHalf);
mPath_40_4 = strcat(pathFirstHalf,num2str(nShot_40_4),pathLastHalf);

% load(mPath_25_1,'EE1','EE2','EE3','EE4');
% EE_25_1=EE1;EE_25_2=EE2;EE_25_3=EE3;EE_25_4=EE4;
load(mPath_25_1,'EE1');EE_25_1=EE1;
load(mPath_25_2,'EE2');EE_25_2=EE2;
load(mPath_25_3,'EE3');EE_25_3=EE3;
load(mPath_25_4,'EE4');EE_25_4=EE4;
EE_25 = cat(3,EE_25_1,EE_25_2,EE_25_3,EE_25_4);

% load(mPath_30_1,'EE1','EE2');
% EE_30_1=EE1;EE_30_2=EE2;
load(mPath_30_1,'EE1');EE_30_1=EE1;
load(mPath_30_2,'EE2');EE_30_2=EE2;
load(mPath_30_3,'EE3');EE_30_3=EE3;
load(mPath_30_4,'EE4');EE_30_4=EE4;
% load(mpath_30_4_2,'EE4');EE_30_4_2 = EE4;
% EE_30_4 = EE_30_4_2;
% EE_30_4 = (EE_30_4+EE_30_4_2)/2;
% N = EE_30_4.*EE_30_4_2;
% N(N<0) = 0;
% EE_30_4 = sqrt(N);
EE_30 = cat(3,EE_30_1,EE_30_2,EE_30_3,EE_30_4);

load(mPath_35_1,'EE1','EE2');
EE_35_1=EE1;EE_35_2=EE2;
load(mPath_35_3,'EE3');EE_35_3=EE3;
load(mPath_35_4,'EE4');EE_35_4=EE4;
EE_35 = cat(3,EE_35_1,EE_35_2,EE_35_3,EE_35_4);

load(mPath_40_1,'EE1');EE_40_1=EE1;
load(mPath_40_2,'EE2');EE_40_2=EE2;
load(mPath_40_3,'EE3');EE_40_3=EE3;
load(mPath_40_4,'EE4');EE_40_4=EE4;
EE_40 = cat(3,EE_40_1,EE_40_2,EE_40_3,EE_40_4);

EEE = cat(4,EE_25,EE_30,EE_40,EE_35);


idx25 = 19;
idx30 = 24;
idx35 = 25;
idx40 = 28;
pathname.pre_processed_directory = getenv('pre_processed_directory_path');%計算結果の保存先（どこでもいい）
PCBfile25 = strcat(pathname.pre_processed_directory,'/',num2str(240111),sprintf('%03d',idx25),'_200ch.mat');
load(PCBfile25,'data2D','grid2D');PCBdata25.data2D=data2D;PCBdata25.grid2D=grid2D;
PCBfile30 = strcat(pathname.pre_processed_directory,'/',num2str(240111),sprintf('%03d',idx30),'_200ch.mat');
load(PCBfile30,'data2D','grid2D');PCBdata30.data2D=data2D;PCBdata30.grid2D=grid2D;
PCBfile35 = strcat(pathname.pre_processed_directory,'/',num2str(240111),sprintf('%03d',idx35),'_200ch.mat');
load(PCBfile35,'data2D','grid2D');PCBdata35.data2D=data2D;PCBdata35.grid2D=grid2D;
PCBfile40 = strcat(pathname.pre_processed_directory,'/',num2str(240111),sprintf('%03d',idx40),'_200ch.mat');
load(PCBfile40,'data2D','grid2D');PCBdata40.data2D=data2D;PCBdata40.grid2D=grid2D;

PCBdata = [PCBdata25,PCBdata30,PCBdata35,PCBdata40];

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
SXRdata30.EE = EE_30;
SXRdata35.EE = EE_35;
SXRdata40.EE = EE_40;

SXRdata25.range = range;
SXRdata30.range = range;
SXRdata35.range = range;
SXRdata40.range = range;
SXRdata25.t = 468;
SXRdata30.t = t;
SXRdata35.t = t;
SXRdata40.t = t;

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
cLimList = {[0 1],[0 0.6],[0 0.3]};
cLimList2 = {[0 0.8],[0 0.8],[0 0.3]};

f = figure;
% f.Position = [0,0,1150,750];
f.Position = [818        ,1021         ,881         ,935];
tiledlayout(3,3,'TileSpacing','tight','Padding','tight');
for i = 1:3
    t = 468;
    PCBdata_tmp = PCBdata(i);
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
    EE = EEE(:,:,:,i);
    
    % 負の要素を0で置換
    negativeEE = find(EE<0);
    EE(negativeEE) = zeros(size(negativeEE));
    for j = 1:3
    %% 
        if j ~= 3
            EE_q = griddata(z_space_SXR2,r_space_SXR,EE(:,:,j),psi_mesh_z,psi_mesh_r);
        else
            EE_q = griddata(z_space_SXR1,r_space_SXR,EE(:,:,4),psi_mesh_z,psi_mesh_r);
        end
        % p = positionList(j);
        nexttile(j+3*(i-1));
        if i==3
            cRange = cell2mat(cLimList2(j));
        else
            cRange = cell2mat(cLimList(j));
        end
        % [~,h] = contourf(psi_mesh_z,psi_mesh_r,EE_q,20);
        % [~,h] = contourf(psi_mesh_z,psi_mesh_r,EE_q./Bp.^0.3,linspace(cRange(1),cRange(2),20));clim(cRange);
        % [~,h] = contourf(psi_mesh_z,psi_mesh_r,EE_q./Bp.^0.3,20);colorbar;
        if j == 1
            [~,h] = contourf(psi_mesh_z-0.02,psi_mesh_r,EE_q,linspace(cRange(1),cRange(2),20));clim(cRange);
        %     [~,h] = contourf(psi_mesh_z,psi_mesh_r,EE_q,20);
        % elseif i ~=3
            % [~,h] = contourf(psi_mesh_z,psi_mesh_r,EE_q,linspace(cRange(1),cRange(2),20));clim(cRange);
        else
            [~,h] = contourf(psi_mesh_z,psi_mesh_r,EE_q,linspace(cRange(1),cRange(2),20));clim(cRange);
        end

        colormap('turbo');
        h.LineStyle = 'none';
        % c=colorbar;c.Label.String='Intensity [a.u.]';c.FontSize=18;
        hold on
    
        [~,hp]=contourf(interp_matrix(psi_mesh_z,3),interp_matrix(psi_mesh_r,3),interp_matrix(psi,3),contour_layer,'white','Fill','off');
        hp.LineWidth = 1.5;

        if i == 3
            xticks([-0.04,0,0.04]);
            xlabel('z [m]')
        else
            xticks([]);
        end
        if j == 1
            yticks([0.21 0.31]);
            ylabel('r [m]')
        else
            yticks([]);
        end

        axis equal
    
        hold off;
        % xlim([-0.02,0.02]);ylim([0.23,0.29]);
        xlim([-0.05,0.05]);ylim([0.21,0.31]);
        if i == 1
            title(string(nameList(j)));
        end

        ax = gca;
        ax.FontSize = 16;
    end
end


% sgtitle(strcat(num2str(t),'us'));
drawnow;