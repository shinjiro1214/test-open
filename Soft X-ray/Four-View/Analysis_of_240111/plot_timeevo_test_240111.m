clear
pathFirstHalf = [getenv('SXR_MATRIX_DIR'),'/LF_NLR/240111/shot'];

% 1:'1um Al', 2:'2.5um Al', 3:'2um Mylar', 4:'1um Mylar'

matrixPathMatrix = strings(4,3);
matrixPathMatrix(1,1) = [pathFirstHalf,'29/2.mat'];
matrixPathMatrix(1,2) = [pathFirstHalf,'29/3.mat'];
matrixPathMatrix(1,3) = [pathFirstHalf,'29/4.mat'];
matrixPathMatrix(2,1) = [pathFirstHalf,'29/2.mat'];
% matrixPathMatrix(2,2) = [pathFirstHalf,'29/3.mat'];
matrixPathMatrix(2,2) = [pathFirstHalf,'28/4.mat'];
matrixPathMatrix(2,3) = [pathFirstHalf,'29/4.mat'];
matrixPathMatrix(3,1) = [pathFirstHalf,'12/2.mat'];
matrixPathMatrix(3,2) = [pathFirstHalf,'25/3.mat'];
matrixPathMatrix(3,3) = [pathFirstHalf,'29/4.mat'];
matrixPathMatrix(4,1) = [pathFirstHalf,'18/2.mat'];
matrixPathMatrix(4,2) = [pathFirstHalf,'7/3.mat'];
matrixPathMatrix(4,3) = [pathFirstHalf,'29/4.mat'];

idx = 29;
pathname.pre_processed_directory = getenv('pre_processed_directory_path');%計算結果の保存先（どこでもいい）
PCBfile = strcat(pathname.pre_processed_directory,'/',num2str(240111),sprintf('%03d',idx),'_200ch.mat');
load(PCBfile,'data2D','grid2D');

date = 240111;
shot = 0;
show_localmax = false;
doSave = false;
doFilter = false;
doNLR = true;

zhole1=40;zhole2=-40;                                  
zmin1=-240;zmax1=320;zmin2=-320;zmax2=240;             
rmin=55;rmax=375;
range = [zmin1,zmax1,zmin2,zmax2,rmin,rmax];
% t = 469;


% grid2D = PCBdata.grid2D;
% data2D = PCBdata.data2D;
% date = SXR.date;
% shot = SXR.shot;
% % show_xpoint = SXR.show_xpoint;
% show_localmax = SXR.show_localmax;
% % start = SXR.start;
% % interval = SXR.interval;
% doSave = SXR.doSave;
% doFilter = SXR.doFilter;
% doNLR = SXR.doNLR;
% % SXRfilename = SXR.SXRfilename;

% EE = SXRdata.EE;
% t = SXRdata.t;
% range = SXRdata.range;

range = range./1000;
zmin1 = range(1);
zmax1 = range(2);
zmin2 = range(3);
zmax2 = range(4);
rmin = range(5);
rmax = range(6);
r_space_SXR = linspace(rmin,rmax,91);
z_space_SXR1 = linspace(zmin1,zmax1,91);
z_space_SXR2 = linspace(zmin2,zmax2,91);

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

[magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D); %時間ごとの磁気軸、X点を検索

% positionList = [2,4,1,3];
positionList = [1,2,4,3];
nameList = {'1um Al', '2.5um Al', '2um Mylar', '1um Mylar'};

% cLimList = {[0 1],[0 2],[0 0.3],[0 0.15]};
% cLimList = {[0 1],[0 0.5],[0 0.3],[0 0.15]}; %240111
cLimList = {[0 2],[0 2],[0 1.5],[0 0.4]};


% サブプロットのループ
% 3行4列くらいの時間発展プロットをしたい
% 外に時間のループ（インデックスはi）
% 内側にエネルギーのループ（インデックスはj）
% サブプロットの番号は4*(i-1)+j
% 時間は465+5*(i-1)
f = figure;
f.Position = [0,0,1020,750];
tiledlayout(3,4,'TileSpacing','tight','Padding','tight');
for i = 1:3
    t = 465+i*(i-1);
    t_idx = find(data2D.trange==t);
    psi = data2D.psi(:,:,t_idx);
    Bz = data2D.Bz(:,:,t_idx);
    Br = data2D.Br(:,:,t_idx);
    Bp = sqrt(Bz.^2+Br.^2);
    
    psi_min = min(min(psi));
    psi_max = max(max(psi));
    contour_layer = linspace(psi_min,psi_max,20);

    load(matrixPathMatrix(1,i),'EE1');
    load(matrixPathMatrix(2,i),'EE2');
    load(matrixPathMatrix(3,i),'EE3');
    load(matrixPathMatrix(4,i),'EE4');
    EE = cat(3,EE1,EE2,EE3,EE4);
    % 負の要素を0で置換
    negativeEE = find(EE<0);
    EE(negativeEE) = zeros(size(negativeEE));
    for j = 1:4
        if j <=2
            EE_q = griddata(z_space_SXR2,r_space_SXR,EE(:,:,j),psi_mesh_z,psi_mesh_r);
        else
            EE_q = griddata(z_space_SXR1,r_space_SXR,EE(:,:,j),psi_mesh_z,psi_mesh_r);
        end
        p = positionList(j);
        nexttile(p+4*(i-1));
        cRange = cell2mat(cLimList(j));
        % [~,h] = contourf(psi_mesh_z,psi_mesh_r,EE_q,20);
        % [~,h] = contourf(psi_mesh_z,psi_mesh_r,EE_q./Bp.^0.3,linspace(cRange(1),cRange(2),20));clim(cRange);
        % [~,h] = contourf(psi_mesh_z,psi_mesh_r,EE_q./Bp.^0.3,20);colorbar;
        if j <= 2 && i ~=2
            [~,h] = contourf(psi_mesh_z,psi_mesh_r,EE_q,20);
        elseif i ~=3
            [~,h] = contourf(psi_mesh_z,psi_mesh_r,EE_q./Bp.^0.3,linspace(cRange(1),cRange(2),20));clim(cRange);
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
            xticks([-0.07,0,0.07]);
            xlabel('z [m]')
        else
            xticks([]);
        end
        if j == 1
            yticks([0.2 0.26 0.32]);
            ylabel('r [m]')
        else
            yticks([]);
        end

        axis equal
    
        hold off;
        % xlim([-0.02,0.02]);ylim([0.23,0.29]);
        xlim([-0.07,0.07]);ylim([0.2,0.32]);
        if i == 1
            title(string(nameList(j)));
        end

        ax = gca;
        ax.FontSize = 16;
    end
end


% sgtitle(strcat(num2str(t),'us'));
drawnow;