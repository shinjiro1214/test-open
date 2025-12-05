function [] = plot_Epara_on_PCB(ESP,ESPdata2D,pathname)
addpath(fullfile(pathname.github,'test-open','Soft X-ray','Four-View'));
PCB.type = 1;
PCB.doOverwrite = false;
PCB.trange = 400:800;
PCB.n = 40;
% PCB.start = 56;
PCB.start = 63;
PCB.dt = 2;
% PCB.dt = 10;
PCB.idx = 30;
PCB.date = 240111;
PCB.shot = [3597 2071];
PCB.tfshot = [3569 2043];

PCB.date = 230830;
PCB.tfshot = [2417,896];
% PCB.idx = 37;PCB.shot = [2452 931];
PCB.idx = 24;
if PCB.idx >= 17
    PCB.shot = PCB.tfshot+PCB.idx-2;
else
    PCB.shot = PCB.tfshot+PCB.idx-3;
end
PCB.i_EF = 200;
PCB.TF = 4;
% [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
[grid2D,data2D] = process_PCBdata_200ch(PCB,pathname);
% t_plot_idx = PCB.start:PCB.dt:PCB.start+PCB.dt*15;
% t_plot_idx = PCB.start:PCB.dt:PCB.start+PCB.dt*31;
t_plot_idx = PCB.start:PCB.dt:PCB.start+PCB.dt*3;
t_plot = PCB.trange(t_plot_idx);

a = 1.6;n=4;
if PCB.date == 240111
    ER1 = ESPdata2D.Er_grid.*a;
    ER2 = ER1;
    ER2(:,:,1:50-n) = ER1(:,:,1+n:50);
    ER2(:,:,50-n+1:50) = repmat(ER1(:,:,50),1,1,n);
    ESPdata2D.Er_grid = ER2;
    EZ1 = ESPdata2D.Ez_grid.*a;
    EZ2 = EZ1;
    EZ2(:,:,1:50-n) = EZ1(:,:,1+n:50);
    EZ2(:,:,50-n+1:50) = repmat(EZ1(:,:,50),1,1,n);
    ESPdata2D.Ez_grid = EZ2;
    % ESPdata2D.Er_grid = ESPdata2D.Er_grid.*a;
    % ESPdata2D.Ez_grid = ESPdata2D.Ez_grid.*a;
end
[E_data,B_data] = get_Epara(grid2D,data2D,ESP,ESPdata2D,t_plot);


phi_plot = ESPdata2D.phi_grid(ismember(ESP.trange,t_plot),:,:);
Epara = E_data.Epara;plotRange = [-600 600];
% Epara = E_data.Epara_t;plotRange = [-600 600];
% Epara = E_data.Epara_perp;plotRange = [-600 600];
% Epara = E_data.Ez;plotRange = [-3000 3000];
% Epara = E_data.Et;plotRange = [-600 600];
% Epara = E_data.phi_perp;plotRange = [-240 240];
% Epara = B_data.Bz;plotRange = [-0.3 0.3];
% Epara = B_data.Bt;plotRange = [-0.3 0.3];
figure('Position', [0 0 1500 1500],'visible','on');
% for m = 1:16
%     % i=start+m.*dt; %end
%     i = t_plot_idx(m);
%     subplot(4,4,m);
%     phi_tmp = squeeze(phi_plot(m,:,:));
%     phi_tmp = phi_tmp - mean(phi_tmp,"all");
%     contourf(ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r,Epara(:,:,m),linspace(plotRange(1),plotRange(2),100),'edgecolor','none');
%     % contourf(ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r,phi_tmp-Epara(:,:,m),linspace(plotRange(1),plotRange(2),100),'edgecolor','none');
%     colormap(redblue(3000));
%     xlim([-0.1 0.1]);ylim([0.13 0.31]);
%     pbaspect([1 1 1])
%     clim(plotRange)
%     hold on
%     contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),20,'black')
%     t=PCB.trange(i);
%     title(string(t)+' us')
% end
for m = 1:4
    % i=start+m.*dt; %end
    i = t_plot_idx(m);
    subplot(2,2,m);
    phi_tmp = squeeze(phi_plot(m,:,:));
    phi_tmp = phi_tmp - mean(phi_tmp,"all");
    contourf(ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r,Epara(:,:,m),linspace(plotRange(1),plotRange(2),100),'edgecolor','none');
    % contourf(ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r,phi_tmp-Epara(:,:,m),linspace(plotRange(1),plotRange(2),100),'edgecolor','none');
    colormap(redblue(3000));
    % xlim([-0.1 0.1]);ylim([0.13 0.31]);
    pbaspect([1 1 1])
    clim(plotRange)
    hold on
    contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),20,'black')
    t=PCB.trange(i);
    title(string(t)+' us')
    ax = gca; ax.FontSize = 18;
    if mod(m,2)==1
        ylabel('r [m]');
    end
    if m >= 3
        xlabel('z [m]')
    end
    colorbar;
end

% dPhi_perp = squeeze( max(E_data.phi_perp,[],[1 2]) - min(E_data.phi_perp,[],[1 2]) );
% dPhi = max(ESPdata2D.phi_grid,[],[2 3])-min(ESPdata2D.phi_grid,[],[2 3]);
% figure;plot(t_plot,dPhi_perp,'LineWidth',2);
% hold on;plot(ESP.trange,dPhi,'LineWidth',2);
% legend({'Calculation','Experiment'})
% % xlim([460 480]);
% xlim([455 475]);
% ylabel("Potential difference [V]");xlabel("time [us]");ax=gca;ax.FontSize=18;

% t_plot_idx = [66 69 71];
% t_plot = PCB.trange(t_plot_idx);
% [E_data,~] = get_Epara(grid2D,data2D,ESP,ESPdata2D,t_plot);
% Epara = E_data.phi_perp;
% phi_plot = ESPdata2D.phi_grid(ismember(ESP.trange,t_plot),:,:);
% % figure('Position', [0 0 1500 1500],'visible','on');
% plotRange = [-300 300];
% figure;
% for m = 1:3
%     % i=start+m.*dt; %end
%     i = t_plot_idx(m);
%     % subplot(1,3,m);
%     subplot(2,3,m);
%     contourf(ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r,Epara(:,:,m),linspace(plotRange(1),plotRange(2),100),'edgecolor','none');
%     colormap(redblue(3000));
%     % xlim([-0.1 0.1])
%     % ylim([0.12 0.32])
%     xlim([-0.1,0.1]);ylim([0.13,0.31]);
%     pbaspect([1 1 1])
%     clim(plotRange)
%     hold on
%     contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),20,'black')
%     t=PCB.trange(i);
%     title(string(t)+' us')
%     if m==1
%         ylabel('r [m]');
%     end
%     ax=gca;ax.FontSize=18;

%     subplot(2,3,m+3);
%     phi_tmp = squeeze(phi_plot(m,:,:));
%     phi_tmp = phi_tmp - mean(phi_tmp,"all");
%     contourf(ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r,phi_tmp,linspace(plotRange(1),plotRange(2),100),'edgecolor','none');
%     colormap(redblue(3000));
%     % xlim([-0.1 0.1])
%     % ylim([0.12 0.32])
%     xlim([-0.1,0.1]);ylim([0.13,0.31]);
%     pbaspect([1 1 1])
%     clim(plotRange)
%     hold on
%     contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),20,'black')
%     % t=PCB.trange(i);
%     % title(string(t)+' us')
%     xlabel('z [m]');
%     if m==1
%         ylabel('r [m]');
%     end
%     % if m == 3
%         % colorbar
%     % end
%     ax=gca;ax.FontSize=18;
% end

t_plot_idx = 68;
% t_plot_idx = 72;
t_plot = PCB.trange(t_plot_idx);
[E_data,B_data] = get_Epara(grid2D,data2D,ESP,ESPdata2D,t_plot);
B = cat(3,B_data.Br,B_data.Bz,B_data.Bt);
sizeB = sqrt(dot(B,B,3));
Epara_r = dot(E_data.Er,B_data.Br,3)./sizeB;
Epara_z = dot(E_data.Ez,B_data.Bz,3)./sizeB;
Epara_t = dot(E_data.Et,B_data.Bt,3)./sizeB;
Epara = cat(3,Epara_r,Epara_z,Epara_t,E_data.Epara);
plotRange = [-700 700];
% titleList = {'E_r ・ B_r','E_z ・ B_z','E_t ・ B_t'};
titleList = {'E_r ・ B_r','E_z ・ B_z','E_t ・ B_t', 'E_{parallel}'};
figure;
% for m = 1:3
%     % i=start+m.*dt; %end
%     i = t_plot_idx;
%     subplot(1,3,m);
%     % subplot(2,3,m);
%     contourf(ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r,Epara(:,:,m),linspace(plotRange(1),plotRange(2),100),'edgecolor','none');
%     colormap(redblue(3000));
%     % xlim([-0.1 0.1])
%     % ylim([0.12 0.32])
%     xlim([-0.1,0.1]);ylim([0.13,0.31]);
%     pbaspect([1 1 1])
%     clim(plotRange)
%     hold on
%     contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),20,'black')
%     % t=PCB.trange(i);
%     title(titleList(m));
%     ax=gca;ax.FontSize=18;
%     if m==1
%         ylabel('r [m]');
%     end
%     xlabel('z [m]');
%     colorbar;
% end
for m = 1:4
    % i=start+m.*dt; %end
    i = t_plot_idx;
    subplot(2,2,m);
    % subplot(2,3,m);
    contourf(ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r,Epara(:,:,m),linspace(plotRange(1),plotRange(2),100),'edgecolor','none');
    colormap(redblue(3000));
    % xlim([-0.1 0.1])
    % ylim([0.12 0.32])
    xlim([-0.1,0.1]);ylim([0.13,0.31]);
    pbaspect([1 1 1])
    clim(plotRange)
    hold on
    contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),20,'black')
    % t=PCB.trange(i);
    title(titleList(m));
    ax=gca;ax.FontSize=18;
    if mod(m,2)==1
        ylabel('r [m]');
    end
    if m >= 3
        xlabel('z [m]')
    end
    colorbar;
end

% figure;
% subplot(1,2,1);
% contourf(ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r,sum(Epara,3),linspace(plotRange(1),plotRange(2),100),'edgecolor','none');
% colormap(redblue(3000));
% xlim([-0.1,0.1]);ylim([0.13,0.31]);
% pbaspect([1 1 1])
% clim(plotRange)
% hold on
% contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),20,'black')
% ax=gca;ax.FontSize=18;
% subplot(1,2,2);
% contourf(ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r,E_data.Epara,linspace(plotRange(1),plotRange(2),100),'edgecolor','none');
% colormap(redblue(3000));
% xlim([-0.1,0.1]);ylim([0.13,0.31]);
% pbaspect([1 1 1])
% clim(plotRange)
% hold on
% contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),20,'black')
% ax=gca;ax.FontSize=18;

end


function [E_data,B_data] = get_Epara(grid2D,data2D,ESP,ESPdata2D,t_plot)
    [Epara,Epara_t,E_r,E_z,E_t,B_r,B_z,B_t,phi_perp,Epara_perp] = deal(zeros([size(ESPdata2D.phi_mesh_r),numel(t_plot)]));
    rq_mag = grid2D.rq;zq_mag = grid2D.zq;
    rq_esp = ESPdata2D.phi_mesh_r;zq_esp = ESPdata2D.phi_mesh_z;
    drq = abs( rq_esp(1,1) - rq_esp(2,1) );
    dzq = abs( zq_esp(1,1) - zq_esp(1,2) );
    for i = 1:numel(t_plot)
        t = t_plot(i);
        idx_mag = find(data2D.trange==t);
        idx_esp = find(ESP.trange==t);
        Bt = data2D.Bt_th(:,:,idx_mag);
        % Bt = 0.6*data2D.Bt_th(:,:,idx_mag);
        Br = data2D.Br(:,:,idx_mag);
        Bz = data2D.Bz(:,:,idx_mag);
        Et = data2D.Et(:,:,idx_mag);
        Bt_q = interp2(zq_mag,rq_mag,Bt,zq_esp,rq_esp);
        Br_q = interp2(zq_mag,rq_mag,Br,zq_esp,rq_esp);
        Bz_q = interp2(zq_mag,rq_mag,Bz,zq_esp,rq_esp);
        Et_q = interp2(zq_mag,rq_mag,Et,zq_esp,rq_esp);
        Er = squeeze(ESPdata2D.Er_grid(idx_esp,:,:));
        Ez = squeeze(ESPdata2D.Ez_grid(idx_esp,:,:));
        B = cat(3,Br_q,Bz_q,Bt_q);
        E = cat(3,Er,Ez,Et_q);
        norm_B = B./sqrt(dot(B,B,3));
        norm_Bp = Br_q.^2 + Bz_q.^2;
        alpha = -Et_q.*Bt_q ./ ( norm_Bp + eps );
        Er_perp = alpha .* Br_q;
        Ez_perp = alpha .* Bz_q;
        for j = 2:size(rq_esp,1)
            phi_perp(j,1,i) = phi_perp(j-1,1,i) + Er_perp(j-1,1) * drq;
        end
        for j = 2:size(rq_esp,1)
            phi_perp(:,j,i) = phi_perp(:, j-1,i) + Ez_perp(:,j-1) * dzq;
        end
        phi_perp(:,:,i) = phi_perp(:,:,i) - mean(phi_perp(:,:,i),"all");
        phi_perp(:,:,i) = -1 * phi_perp(:,:,i);
        Eperp = cat(3,Er_perp, Ez_perp, Et_q);
        Epara_perp(:,:,i) = dot(norm_B,Eperp,3);
        Epara(:,:,i) = dot(norm_B,E,3);
        Epara_t(:,:,i) = Epara(:,:,i).*Bt_q./sqrt(dot(B,B,3));
        E_r(:,:,i)=Er;E_z(:,:,i)=Ez;E_t(:,:,i)=Et_q;
        B_r(:,:,i)=Br_q;B_z(:,:,i)=Bz_q;B_t(:,:,i)=Bt_q;
        phi_perp(rq_esp(:,1)>0.23,:,i) = 0;
    end
    E_data.Epara = Epara;E_data.Epara_perp = Epara_perp;E_data.Epara_t = Epara_t;
    E_data.Er = E_r;E_data.Ez = E_z;E_data.Et = E_t;E_data.E = E;
    B_data.Br = B_r;B_data.Bz = B_z;B_data.Bt = B_t;B_data.B = B;
    E_data.phi_perp = phi_perp;
end