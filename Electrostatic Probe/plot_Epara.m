function [] = plot_Epara(ESP,ESPdata2D,pathname)
addpath(fullfile(pathname.github,'test-open','Soft X-ray','Four-View'));
PCB.type = 1;
PCB.doOverwrite = false;
PCB.trange = 400:800;
PCB.n = 40;
% PCB.start = 56;
% PCB.start = 64;
PCB.start = 66;
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
% t_plot_idx = PCB.start:PCB.dt:PCB.start+PCB.dt*3;
t_plot_idx = PCB.start:PCB.dt:PCB.start+PCB.dt*2;
t_plot = PCB.trange(t_plot_idx);
legendList = arrayfun(@(x) sprintf('%dus', x), t_plot, 'UniformOutput', false);

% a = 1.6;n=4;
a = 2;n=4;
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
% Epara = E_data.Epara;
Epara = E_data.Epara_t;
Jt = B_data.Jt;

% z_target=0;
z_axis = ESPdata2D.phi_mesh_z(1,:);
r_axis = ESPdata2D.phi_mesh_r(:,1);
figure;hold on;
% [~, z_idx] = min(abs(z_axis - z_target));
% z_indices = abs(z_axis)<=0.01;
z_indices = abs(z_axis-0.01)<=0.01;
for i = 1:numel(t_plot_idx)
    % % E_r_tmp = squeeze(Epara(:,z_idx,i));
    % % plot(r_axis,E_r_tmp,'LineWidth',2);
    E_r_tmp = squeeze(Epara(:,z_indices,i));
    E_r_mean = mean(E_r_tmp,2);
    E_r_std = std(E_r_tmp,0,2);
    errorbar(r_axis,E_r_mean,E_r_std,'LineWidth',2,'Marker','o','MarkerSize',6,'CapSize',10);

    % J_r_tmp = squeeze(Jt(:,z_indices,i));
    % J_r_mean = mean(J_r_tmp,2);
    % J_r_std = std(J_r_tmp,0,2);
    % errorbar(r_axis,J_r_mean,J_r_std,'LineWidth',2,'Marker','o','MarkerSize',6,'CapSize',10);

end
xlim([0.1 0.25]);
xlabel('r [m]'); % 単位は適宜変更してください
ylabel('$E_{\parallel , t}$ [V/m]','Interpreter','latex'); % 単位は適宜変更してください
% ylabel('$J_t$ [A/$\mathrm{m}^3$]','Interpreter','latex');
% title(['r方向の電場分布 (t = ', num2str(t_idx), ', z \approx ', num2str(z_actual), ' m)']);
grid on;
legend(legendList);
ax=gca;ax.FontSize=18;currentLimits=ax.YLim;maxVal=max(abs(currentLimits));ax.YLim =[-maxVal, maxVal];


figure;
E_r_tmp = squeeze(Epara(:,z_indices,3));
E_r_mean = mean(E_r_tmp,2);
E_r_std = std(E_r_tmp,0,2);
errorbar(r_axis,E_r_mean,E_r_std,'LineWidth',2,'Marker','o','MarkerSize',6,'CapSize',10);
xlim([0.1 0.25]);
xlabel('r [m]'); % 単位は適宜変更してください
ylabel('$E_{\parallel , t}$ [V/m]','Interpreter','latex'); % 単位は適宜変更してください
grid on;ax=gca;ax.FontSize=18;currentLimits=ax.YLim;maxVal=max(abs(currentLimits));ax.YLim =[-maxVal, maxVal];

end

function [E_data,B_data] = get_Epara(grid2D,data2D,ESP,ESPdata2D,t_plot)
    [Epara,Epara_t,E_r,E_z,E_t,B_r,B_z,B_t,J_t,phi_perp,Epara_perp] = deal(zeros([size(ESPdata2D.phi_mesh_r),numel(t_plot)]));
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
        Jt = data2D.Jt(:,:,idx_mag);
        Bt_q = interp2(zq_mag,rq_mag,Bt,zq_esp,rq_esp);
        Br_q = interp2(zq_mag,rq_mag,Br,zq_esp,rq_esp);
        Bz_q = interp2(zq_mag,rq_mag,Bz,zq_esp,rq_esp);
        Et_q = interp2(zq_mag,rq_mag,Et,zq_esp,rq_esp);
        Jt_q = interp2(zq_mag,rq_mag,Jt,zq_esp,rq_esp);
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
        J_t(:,:,i)=Jt_q;
        phi_perp(rq_esp(:,1)>0.23,:,i) = 0;
    end
    E_data.Epara = Epara;E_data.Epara_perp = Epara_perp;E_data.Epara_t = Epara_t;
    E_data.Er = E_r;E_data.Ez = E_z;E_data.Et = E_t;E_data.E = E;
    B_data.Br = B_r;B_data.Bz = B_z;B_data.Bt = B_t;B_data.B = B;B_data.Jt = J_t;
    E_data.phi_perp = phi_perp;
end