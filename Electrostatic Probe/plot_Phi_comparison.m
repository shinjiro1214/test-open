function [] = plot_Phi_comparison(ESP,ESPdata2D,pathname)
addpath(fullfile(pathname.github,'test-open','Soft X-ray','Four-View'));
PCB.type = 1;
PCB.doOverwrite = false;
PCB.trange = 400:800;
PCB.n = 40;
PCB.start = 50;
% PCB.start = 63;
PCB.dt = 1;
% PCB.dt = 10;
PCB.idx = 30;
PCB.date = 240111;
PCB.shot = [3597 2071];
PCB.tfshot = [3569 2043];

% PCB.date = 230830;
% PCB.tfshot = [2417,896];
% % PCB.idx = 37;PCB.shot = [2452 931];
% PCB.idx = 24;
% if PCB.idx >= 17
%     PCB.shot = PCB.tfshot+PCB.idx-2;
% else
%     PCB.shot = PCB.tfshot+PCB.idx-3;
% end
PCB.i_EF = 200;
PCB.TF = 4;
% [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
[grid2D,data2D] = process_PCBdata_200ch(PCB,pathname);
% t_plot_idx = PCB.start:PCB.dt:PCB.start+PCB.dt*15;
t_plot_idx = PCB.start:PCB.dt:PCB.start+PCB.dt*31;
% t_plot_idx = PCB.start:PCB.dt:PCB.start+PCB.dt*3;
t_plot = PCB.trange(t_plot_idx);

a = 1.6;n=4;
if PCB.date == 240111
    P1 = ESPdata2D.phi_grid.*a;
    P2 = P1;
    P2(:,:,1:50-n) = P1(:,:,1+n:50);
    P2(:,:,50-n+1:50) = repmat(P1(:,:,50),1,1,n);
    ESPdata2D.phi_grid = P2;
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
[E_data,~] = get_Epara(grid2D,data2D,ESP,ESPdata2D,t_plot);


r_axis = ESPdata2D.phi_mesh_r(:,1);
rLim = [0.15,0.18];
r_indices = find(r_axis >= rLim(1) & r_axis <= rLim(2));
phiPerp_subset = E_data.phi_perp(r_indices, :, :);
phi_subset = ESPdata2D.phi_grid(:, r_indices, :);
dPhi_perp = squeeze(max(phiPerp_subset,[],[1 2]) - min(phiPerp_subset,[],[1 2]));
dPhi = max(phi_subset,[],[2 3])-min(phi_subset,[],[2 3]);

% dPhi_perp = squeeze(max(E_data.phi_perp,[],[1 2]) - min(E_data.phi_perp,[],[1 2]));
% dPhi = max(ESPdata2D.phi_grid,[],[2 3])-min(ESPdata2D.phi_grid,[],[2 3]);
figure;plot(t_plot,dPhi_perp,'LineWidth',2);
hold on;plot(ESP.trange,dPhi,'LineWidth',2);
legend({'Calculation','Experiment'})
% xlim([460 480]);
xlim([458 473]);
ylabel("Potential difference [V]");xlabel("time [us]");ax=gca;ax.FontSize=18;

% dphi = max(ESPdata2D.phi_grid,[],[2 3])-min(ESPdata2D.phi_grid,[],[2 3]);
ddphi_perp = diff(dPhi_perp)./(t_plot(2)-t_plot(1));
ddphi = diff(dPhi)./(ESP.trange(2)-ESP.trange(1));
figure;hold on;
plot(t_plot(1:end-1),smoothdata(ddphi_perp),'LineWidth',2);%xlim([460 475]);
plot(ESP.trange(1:end-1),smoothdata(ddphi,"movmean",6),'LineWidth',2);%xlim([460 475]);
xlim([458 473]);
ylabel("$\frac{d}{dt}\Delta\Phi$ [V/us]",'Interpreter','latex');xlabel("time [us]");ax=gca;ax.FontSize=18;


plotRange = [-180 180];
timing_plot = 469;
t_plot_idx_cal = find(t_plot==timing_plot);
t_plot_idx_exp = knnsearch(ESP.trange',timing_plot);
t_plot_idx_mag = knnsearch(PCB.trange.',timing_plot);
phi_exp = squeeze(ESPdata2D.phi_grid(t_plot_idx_exp,:,:));
phi_exp(ESPdata2D.phi_mesh_r(:,1)>0.23,:)= 0;
phi_exp = phi_exp - mean(phi_exp,"all");phi_exp(ESPdata2D.phi_mesh_r(:,1)>0.23,:)= 0;
% t_plot = PCB.trange(t_plot_idx);
figure;
subplot(1,2,1);
contourf(ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r,E_data.phi_perp(:,:,t_plot_idx_cal),linspace(plotRange(1),plotRange(2),100),'edgecolor','none');
colormap(redblue(3000));
xlim([-0.1,0.1]);ylim([0.13,0.31]);
pbaspect([1 1 1])
clim(plotRange)
hold on
contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,t_plot_idx_mag)),20,'black')
ax=gca;ax.FontSize=18;
subplot(1,2,2);
contourf(ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r,phi_exp,linspace(plotRange(1),plotRange(2),100),'edgecolor','none');
% contourf(ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r,squeeze(ESPdata2D.phi_grid(t_plot_idx_exp,:,:)),linspace(plotRange(1),plotRange(2),100),'edgecolor','none');
colormap(redblue(3000));
xlim([-0.1,0.1]);ylim([0.13,0.31]);
pbaspect([1 1 1])
clim(plotRange)
hold on
contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,t_plot_idx_mag)),20,'black')
ax=gca;ax.FontSize=18;

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