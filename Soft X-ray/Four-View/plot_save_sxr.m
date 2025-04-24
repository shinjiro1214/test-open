function plot_save_sxr(PCBdata,SXR,SXRdata,PCB)

grid2D = PCBdata.grid2D;
data2D = PCBdata.data2D;
date = SXR.date;
shot = SXR.shot;
% show_xpoint = SXR.show_xpoint;
show_localmax = SXR.show_localmax;
% start = SXR.start;
% interval = SXR.interval;
doSave = SXR.doSave;
doFilter = SXR.doFilter;
ReconMethod = SXR.ReconMethod;
% SXRfilename = SXR.SXRfilename;

EE = SXRdata.EE;
t = SXRdata.t;
range = SXRdata.range;

range = range./1000;
zmin1 = range(1);
zmax1 = range(2);
zmin2 = range(3);
zmax2 = range(4);
rmin = range(5);
rmax = range(6);
r_space_SXR = linspace(rmin,rmax,size(EE,1));
z_space_SXR1 = linspace(zmin1,zmax1,size(EE,2));
z_space_SXR2 = linspace(zmin2,zmax2,size(EE,2));

rmin_psi = min(grid2D.rq,[],'all');
rmax_psi = max(grid2D.rq,[],'all');
zmin_psi = min(grid2D.zq,[],'all');
zmax_psi = max(grid2D.zq,[],'all');

% r_range = find(0.060<=r_space_SXR & r_space_SXR<=0.330);
% r_space_SXR_plot = r_space_SXR(r_range);
% z_range1 = find(-0.12<=z_space_SXR1 & z_space_SXR1<=0.12);
% z_range2 = find(-0.12<=z_space_SXR2 & z_space_SXR2<=0.12);
r_range = find(rmin_psi<=r_space_SXR & r_space_SXR<=rmax_psi);
r_space_SXR_plot = r_space_SXR(r_range);
z_range1 = find(zmin_psi<=z_space_SXR1 & z_space_SXR1<=zmax_psi);
z_range2 = find(zmin_psi<=z_space_SXR2 & z_space_SXR2<=zmax_psi);

z_space_SXR1_plot = z_space_SXR1(z_range1);
z_space_SXR2_plot = z_space_SXR2(z_range2);

% EE1 = EE(r_range,z_range,1);
% EE2 = EE(r_range,z_range,2);
% EE3 = EE(r_range,z_range,3);
% EE4 = EE(r_range,z_range,4);

psi_mesh_z = grid2D.zq;
psi_mesh_r = grid2D.rq;
t_idx = find(data2D.trange==t);
psi = data2D.psi(:,:,t_idx);
Bz = data2D.Bz(:,:,t_idx);
Br = data2D.Br(:,:,t_idx);
Bp = sqrt(Bz.^2+Br.^2);

psi_min = min(min(psi));
psi_max = max(max(psi));
contour_layer = linspace(psi_min,psi_max,20);

[SXR_mesh_z1,SXR_mesh_r] = meshgrid(z_space_SXR1_plot,r_space_SXR_plot);
[SXR_mesh_z2,~] = meshgrid(z_space_SXR2_plot,r_space_SXR_plot);

% f = figure;
% f.Units = 'normalized';
% f.Position = [0.1,0.2,0.8,0.8];

set(gcf, 'Visible', 'off');  % Suppress plot display

EE_q = zeros(50,50,4);
for i = 1:4
    if i <=2
        EE_q(:,:,i) = griddata(z_space_SXR2,r_space_SXR,EE(:,:,i),psi_mesh_z,psi_mesh_r);
    else
        EE_q(:,:,i) = griddata(z_space_SXR1,r_space_SXR,EE(:,:,i),psi_mesh_z,psi_mesh_r);
    end
end


[magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D,PCB); %時間ごとの磁気軸、X点を検索

positionList = [2,4,1,3];
nameList = {'1um Al', '2.5um Al', '2um Mylar', '1um Mylar'};
% cLimList = {[0 0.15],[0 0.15],[0 0.05],[0 0.2]};
% cLimList = {[0 0.15],[0 0.15],[0 0.05],[0 0.1]};
% cLimList = {[0 0.15],[0 0.075],[0 0.05],[0 0.075]};
% cLimList = {[0 0.5],[0 0.5],[0 0.1],[0 0.5]};
% cLimList = {[0 0.1],[0 0.1],[0 0.02],[0 0.1]};
% cLimList = {[0 1],[0 1.8],[0 1],[0 1]};
% cLimList = {[0 1],[0 1.8],[0 0.8],[0 0.5]};
% cLimList = {[0 1],[0 1.8],[0 0.8],[0 0.2]};
% cLimList = {[0 0.4],[0 1],[0 0.4],[0 0.2]};
% cLimList = {[0 0.4],[0 6],[0 0.4],[0 0.2]};

% cLimList = {[0 1],[0 2],[0 0.3],[0 0.15]};

if PCB.date == 241110
    cLimList = {[0 10],[0 5],[0 10], [0 5]}; %241110
elseif PCB.date == 240111
    cLimList = {[0 2],[0 2],[0 2], [0 2]}; % 240111
elseif PCB.date == 241230
    cLimList = {[0 0.5],[0 0.5],[0 0.5],[0 5]}; %241230
elseif PCB.date == 250125
    cLimList = {[0 3], [0 3], [0 3],[0 5]};
else
    cLimList = {[0 10],[0 5],[0 5],[0 5]};
end




% cLimList = {[0 1],[0 0.5],[0 0.3],[0 0.15]};
% cLimList = {[0 1.5],[0 0.5],[0 1],[0 1.5]};
% cLimList = {[0 0.3],[0 0.3],[0 0.3],[0 0.15]};
% cLimList = {[0 2],[0 2],[0 2],[0 2]};
% cLimList = {[0 1],[0 1],[0 1],[0 0.6]};

% 負の要素を0で置換
negativeEE = find(EE<0);
EE(negativeEE) = zeros(size(negativeEE));
negativeEEq = find(EE_q<0);
EE_q(negativeEEq) = zeros(size(negativeEEq));

for i = 1:4
    p = positionList(i);
    subplot(2,2,p);
    cRange = cell2mat(cLimList(i));

    if i <= 2
        z_range = z_range2;
        SXR_mesh_z = SXR_mesh_z2;
    else
        z_range = z_range1;
        SXR_mesh_z = SXR_mesh_z1;
    end
    EE_plot = EE(r_range,z_range,i);
    % [~,h] = contourf(SXR_mesh_z,SXR_mesh_r,EE_plot,linspace(cRange(1),cRange(2),20));clim(cRange);
    % [~,h] = contourf(SXR_mesh_z,SXR_mesh_r,EE_plot,20);

    [~,h] = contourf(psi_mesh_z,psi_mesh_r,EE_q(:,:,i),linspace(cRange(1),cRange(2),20));clim(cRange);
    % [~,h] = contourf(psi_mesh_z,psi_mesh_r,EE_q(:,:,i),20);

    colormap('turbo');
    h.LineStyle = 'none';
    c=colorbar;c.Label.String='Intensity [a.u.]';c.FontSize=18;
    hold on
    if show_localmax
        localmax_idx = imregionalmax(EE_plot);
        EE_localmax = EE_plot.*localmax_idx;
        [~, localmax_idx] = maxk(EE_localmax(:),2);
        localmax_pos_r = SXR_mesh_r(localmax_idx);
        localmax_pos_z = SXR_mesh_z(localmax_idx);
        plot(localmax_pos_z,localmax_pos_r,'r*');
    end
    [~,hp]=contourf(psi_mesh_z,psi_mesh_r,psi,contour_layer,'white','Fill','off');axis([-0.17 0.17 0.06 0.33]);%axis([-0.12 0.12 0.06 0.33]);
    % [~,hp]=contourf(psi_mesh_z,psi_mesh_r,psi,contour_layer,'-k','Fill','off');
    hp.LineWidth = 1.5;
    % plot(magAxisList.z(:,t_idx),magAxisList.r(:,t_idx),'wo','LineWidth',3);
    plot(xPointList.z(t_idx),xPointList.r(t_idx),'wx','LineWidth',3);
    hold off;
    % xlim([-0.05,0.05]);ylim([0.18,0.32]);
    % xlim([-0.02,0.02]);ylim([0.23,0.29]);
    % % xlim([-0.03,0.03]);ylim([0.21,0.3]);
    if PCB.date == 241110 ||PCB.date == 250205 || PCB.date ==250206
        ylim([0.1 0.32]);
    end
    title(string(nameList(i)));
end

sgtitle(strcat('shot',num2str(shot),',',num2str(t),'us'));
drawnow;

% subplot(2,2,1);
% [SXR_mesh_z,SXR_mesh_r] = meshgrid(z_space_SXR,r_space_SXR);
% [~,h1] = contourf(SXR_mesh_z,SXR_mesh_r,EE1,20);
% h1.LineStyle = 'none';
% c=colorbar;c.Label.String='Intensity [a.u.]';c.FontSize=18;
% hold on
% if show_localmax
%     localmax_idx = imregionalmax(EE1);
%     EE_localmax = EE1.*localmax_idx;
%     [~, localmax_idx] = maxk(EE_localmax(:),2);
%     localmax_pos_r = SXR_mesh_r(localmax_idx);
%     localmax_pos_z = SXR_mesh_z(localmax_idx);
%     plot(localmax_pos_z,localmax_pos_r,'r*');
% end
% if show_flux_surface
%     [~,hp1]=contourf(psi_mesh_z,psi_mesh_r,psi,contour_layer,'-k','Fill','off');
%     hp1.LineWidth = 1.5;
%     if show_xpoint
%         [~,~,pos_xz,pos_xr,~,~] = search_xo(psi,z_space,r_space);
%         dz = 0.02;
%         dr = 0.03;
%         pos_xz_lower = pos_xz - dz;
%         pos_xr_lower = pos_xr - dr;
%         r = rectangle('Position',[pos_xz_lower pos_xr_lower dz*2 dr*2]);
%         r.EdgeColor = 'red';
%         r.LineWidth = 1.5;
%     end
% end
% title('1');
% hold off;
% 
% subplot(2,2,2);
% [~,h2] = contourf(SXR_mesh_z,SXR_mesh_r,EE2,20);
% h2.LineStyle = 'none';
% c=colorbar;c.Label.String='Intensity [a.u.]';c.FontSize=18;
% hold on
% if show_localmax
%     localmax_idx = imregionalmax(EE2);
%     EE_localmax = EE2.*localmax_idx;
%     [~, localmax_idx] = maxk(EE_localmax(:),2);
%     localmax_pos_r = SXR_mesh_r(localmax_idx);
%     localmax_pos_z = SXR_mesh_z(localmax_idx);
%     plot(localmax_pos_z,localmax_pos_r,'r*');
% end
% if show_flux_surface
%     [~,hp2]=contourf(psi_mesh_z,psi_mesh_r,psi,contour_layer,'-k','Fill','off');
%     hp2.LineWidth = 1.5;
%     if show_xpoint
%         [~,~,pos_xz,pos_xr,~,~] = search_xo(psi,z_space,r_space);
%         dz = 0.02;
%         dr = 0.03;
%         pos_xz_lower = pos_xz - dz;
%         pos_xr_lower = pos_xr - dr;
%         r = rectangle('Position',[pos_xz_lower pos_xr_lower dz*2 dr*2]);
%         r.EdgeColor = 'red';
%         r.LineWidth = 1.5;
%     end
% end
% title('2');
% hold off;
% 
% subplot(2,2,3);
% [~,h3] = contourf(SXR_mesh_z,SXR_mesh_r,EE3,20);
% h3.LineStyle = 'none';
% c=colorbar;c.Label.String='Intensity [a.u.]';c.FontSize=18;
% hold on
% if show_localmax
%     localmax_idx = imregionalmax(EE3);
%     EE_localmax = EE3.*localmax_idx;
%     [~, localmax_idx] = maxk(EE_localmax(:),2);
%     localmax_pos_r = SXR_mesh_r(localmax_idx);
%     localmax_pos_z = SXR_mesh_z(localmax_idx);
%     plot(localmax_pos_z,localmax_pos_r,'r*');
% end
% if show_flux_surface
%     [~,hp3]=contourf(psi_mesh_z,psi_mesh_r,psi,contour_layer,'-k','Fill','off');
%     hp3.LineWidth = 1.5;
%     if show_xpoint
%         [~,~,pos_xz,pos_xr,~,~] = search_xo(psi,z_space,r_space);
%         dz = 0.02;
%         dr = 0.03;
%         pos_xz_lower = pos_xz - dz;
%         pos_xr_lower = pos_xr - dr;
%         r = rectangle('Position',[pos_xz_lower pos_xr_lower dz*2 dr*2]);
%         r.EdgeColor = 'red';
%         r.LineWidth = 1.5;
%     end
% end
% title('3');
% hold off;
% 
% subplot(2,2,4);
% [~,h4] = contourf(SXR_mesh_z,SXR_mesh_r,EE4,20);
% h4.LineStyle = 'none';
% c=colorbar;c.Label.String='Intensity [a.u.]';c.FontSize=18;
% hold on
% if show_localmax
%     localmax_idx = imregionalmax(EE4);
%     EE_localmax = EE4.*localmax_idx;
%     [~, localmax_idx] = maxk(EE_localmax(:),2);
%     localmax_pos_r = SXR_mesh_r(localmax_idx);
%     localmax_pos_z = SXR_mesh_z(localmax_idx);
%     plot(localmax_pos_z,localmax_pos_r,'r*');
% end
% if show_flux_surface
%     [~,hp4]=contourf(psi_mesh_z,psi_mesh_r,psi,contour_layer,'-k','Fill','off');
%     hp4.LineWidth = 1.5;
%     if show_xpoint
%         [~,~,pos_xz,pos_xr,~,~] = search_xo(psi,z_space,r_space);
%         dz = 0.02;
%         dr = 0.03;
%         pos_xz_lower = pos_xz - dz;
%         pos_xr_lower = pos_xr - dr;
%         r = rectangle('Position',[pos_xz_lower pos_xr_lower dz*2 dr*2]);
%         r.EdgeColor = 'red';
%         r.LineWidth = 1.5;
%     end
% end
% title('4');
% hold off;

if doSave
    pathname_png = getenv('SXR_RECONSTRUCTED_DIR');
    pathname_fig = getenv('SXR_RECONSTRUCTED_FIG_DIR');
    if doFilter 
        if ReconMethod == 0
            directory = '/NLF_TP/';
        elseif ReconMethod == 1
            directory = '/NLF_MFI/';
        elseif ReconMethod == 2
            directory = '/NLF_MEM';
        elseif ReconMethod == 3
            directory = '/NLF_cGAN/';
        elseif ReconMethod == 4
            directory = '/NLF_GPT/';
        end
    elseif ~doFilter
        if ReconMethod == 0
            directory = '/LF_TP/';
        elseif ReconMethod == 1
            directory = '/LF_MFI/';
        elseif ReconMethod == 2
            directory = '/LF_MEM';
        elseif ReconMethod == 3
            directory = '/LF_cGAN/';
        elseif ReconMethod == 4
            directory = '/LF_GPT/';
        end
    end

    foldername_png = strcat(pathname_png,directory,'/',num2str(date),'/shot',num2str(shot));
    foldername_fig = strcat(pathname_fig,directory,'/',num2str(date),'/shot',num2str(shot));
    if exist(foldername_png,'dir') == 0
        mkdir(foldername_png);
    end
    if exist(foldername_fig,'dir') == 0
        mkdir(foldername_fig);
    end
    filename_png = strcat('/shot',num2str(shot),'_',num2str(t),'us.png');
    filename_fig = strcat('/shot',num2str(shot),'_',num2str(t),'us.fig');
    saveas(gcf,strcat(foldername_png,filename_png));
    saveas(gcf,strcat(foldername_fig,filename_fig));
end

% [data2D_q,zq,rq] = interp_data(grid2D,data2D,SXRdata);
% figure;
% for i = 1:4
%     subplot(2,2,positionList(i));
%     [~,h] = contourf(zq,rq,data2D_q.EE(:,:,i),20);
%     colormap('turbo');
%     h.LineStyle = 'none';
%     % c=colorbar;c.Label.String='Intensity [a.u.]';c.FontSize=18;
%     clim(cell2mat(cLimList(i)));
%     hold on
%     [~,hp]=contourf(zq,rq,data2D_q.psi,contour_layer,'white','Fill','off');
%     hp.LineWidth = 1.5;
%     hold off
% end