
% pathFirstHalf = '/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/Documents/result_matrix/LF_NLR/240111/shot';
pathFirstHalf = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111/shot';
pathLastHalf = '/3.mat';

% 1:'1um Al', 2:'2.5um Al', 3:'2um Mylar', 4:'1um Mylar'

nshot_1 = 25;
nshot_2 = 11;
nshot_3 = 25;
% nshot_3 = 9;

path_1 = strcat(pathFirstHalf,num2str(nshot_1),'/3.mat');
path_2 = strcat(pathFirstHalf,num2str(nshot_2),'/3.mat');
path_3 = strcat(pathFirstHalf,num2str(nshot_3),'/3.mat');

load(path_1,'EE1');
load(path_2,'EE2');
load(path_3,'EE4');

EE = cat(3,EE1,EE2,EE4);

idx_mag = 25;
path_mag = getenv('pre_processed_directory_path');%計算結果の保存先（どこでもいい）
PCBfile = strcat(path_mag,'/',num2str(240111),sprintf('%03d',idx_mag),'_200ch.mat');
load(PCBfile,'data2D','grid2D');PCBdata.data2D=data2D;PCBdata.grid2D=grid2D;

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

SXRdata.EE = EE;

SXRdata.range = range;
SXRdata.t = t;

% subplotをループで回して3×3くらいの図面をプロット
%EE1,EE2,EE3?
% X点近傍に限定

nameList = {'E < 50 eV', 'E < 80 eV', 'E > 100 eV'};
% cLimList = {[0 1],[0 0.6],[0 0.3]};
cLimList = {[0 0.8],[0 0.3],[0 0.3]};

f = figure;
% f.Position = [0,0,1150,750];
% f.Position = [818        ,1021         ,881         ,935];
tiledlayout(1,3,'TileSpacing','tight','Padding','tight');
% for i = 1:3
    % t = 468;
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
    % EE = EEE(:,:,:,i);
    % EE(:,:,2) = EE(:,:,2)./EE(:,:,1);
    % EE(:,:,4) = EE(:,:,4)./EE(:,:,1);
    
    % 負の要素を0で置換
    negativeEE = find(EE<0);
    EE(negativeEE) = zeros(size(negativeEE));
    for j = 1:3
    %% 
        % if j ~= 3
            EE_q = griddata(z_space_SXR2,r_space_SXR,EE(:,:,j),psi_mesh_z,psi_mesh_r);
        % else
        %     EE_q = griddata(z_space_SXR1,r_space_SXR,EE(:,:,4),psi_mesh_z,psi_mesh_r);
        % end
        % p = positionList(j);
        nexttile;
        % if i==3
        %     cRange = cell2mat(cLimList2(j));
        % else
            % cRange = cell2mat(cLimList(j));
        % end
        % cRange = [0 1];
        cRange = cell2mat(cLimList(j));
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

        % if i == 3
            % xticks([-0.04,0,0.04]);
            xlabel('z [m]')
        % else
            % xticks([]);
        % end
        if j == 1
            % yticks([0.21 0.31]);
            ylabel('r [m]')
        else
            yticks([]);
        end

        axis equal
    
        hold off;
        % xlim([-0.02,0.02]);ylim([0.23,0.29]);
        % xlim([-0.06,0.06]);ylim([0.1,0.31]);
        xlim([-0.1,0.1]);ylim([0.13,0.31]);
        % if i == 1
            % title(string(nameList(j)));
        % end

        ax = gca;
        ax.FontSize = 18;
    end
% end


% sgtitle(strcat(num2str(t),'us'));
drawnow;