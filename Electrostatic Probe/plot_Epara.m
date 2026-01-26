function [] = plot_Epara(ESP,ESPdata2D,pathname)
addpath(fullfile(pathname.github,'test-open','Soft X-ray','Four-View'));
PCB.type = 1;
PCB.doOverwrite = false;
PCB.trange = 400:800;
PCB.n = 40;
% PCB.start = 56;
PCB.start = 67;
% PCB.start = 66;

% PCB.start = 65;
% PCB.start = 79;
PCB.dt = 2;
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

% PCB = get_PCB_data(240111,30,465,2);
% PCB = get_PCB_data(240111,28,465,2);
% PCB = get_PCB_data(240111,27,465,2);

% [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
[grid2D,data2D] = process_PCBdata_200ch(PCB,pathname);
% t_plot_idx = PCB.start:PCB.dt:PCB.start+PCB.dt*15;
% t_plot_idx = PCB.start:PCB.dt:PCB.start+PCB.dt*31;
% t_plot_idx = PCB.start:PCB.dt:PCB.start+PCB.dt*3;
% t_plot_idx = PCB.start:PCB.dt:PCB.start+PCB.dt*2;
t_plot_idx = PCB.start;
t_plot = PCB.trange(t_plot_idx);
% legendList = arrayfun(@(x) sprintf('%dus', x), t_plot, 'UniformOutput', false);
legendList = {'465us','468us','470us'};

n=4;
if PCB.date == 240111
    ER1 = ESPdata2D.Er_grid;
    ER2 = ER1;
    ER2(:,:,1:50-n) = ER1(:,:,1+n:50);
    ER2(:,:,50-n+1:50) = repmat(ER1(:,:,50),1,1,n);
    ESPdata2D.Er_grid = ER2;
    EZ1 = ESPdata2D.Ez_grid;
    EZ2 = EZ1;
    EZ2(:,:,1:50-n) = EZ1(:,:,1+n:50);
    EZ2(:,:,50-n+1:50) = repmat(EZ1(:,:,50),1,1,n);
    ESPdata2D.Ez_grid = EZ2;
end
[E_data,B_data] = get_Epara(grid2D,data2D,ESP,ESPdata2D,t_plot);
Epara = E_data.Epara;
% Epara = E_data.Et.*B_data.Bt;
% Epara = E_data.Ez.*B_data.Bz;
% Epara = E_data.Er.*B_data.Br;
% Epara = (E_data.Et.*B_data.Bt+E_data.Ez.*B_data.Bz)./(sqrt(B_data.Bt.^2+B_data.Bz.^2));
% Epara = E_data.Epara_t;
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
% ylabel('$E_{\parallel , t}$ [V/m]','Interpreter','latex'); % 単位は適宜変更してください
ylabel('$E_{\parallel}$ [V/m]','Interpreter','latex'); % 単位は適宜変更してください
% ylabel('$J_t$ [A/$\mathrm{m}^3$]','Interpreter','latex');
% title(['r方向の電場分布 (t = ', num2str(t_idx), ', z \approx ', num2str(z_actual), ' m)']);
grid on;
legend(legendList);
% 2. ゼロライン (加熱/冷却の境界)
yline(0, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.5, 'HandleVisibility', 'off');
ax=gca;ax.FontSize=18;currentLimits=ax.YLim;maxVal=max(abs(currentLimits));ax.YLim =[-maxVal, maxVal];


% figure;
% E_r_tmp = squeeze(Epara(:,z_indices,3));
% E_r_mean = mean(E_r_tmp,2);
% E_r_std = std(E_r_tmp,0,2);
% errorbar(r_axis,E_r_mean,E_r_std,'LineWidth',2,'Marker','o','MarkerSize',6,'CapSize',10);
% xlim([0.1 0.25]);
% xlabel('r [m]'); % 単位は適宜変更してください
% % ylabel('$E_{\parallel , t}$ [V/m]','Interpreter','latex'); % 単位は適宜変更してください
% ylabel('$E_{\parallel}$ [V/m]','Interpreter','latex'); % 単位は適宜変更してください
% grid on;ax=gca;ax.FontSize=18;currentLimits=ax.YLim;maxVal=max(abs(currentLimits));ax.YLim =[-maxVal, maxVal];

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

function PCB = get_PCB_data(date,shotIDX,start,dt)
    PCB.type = 1;
    PCB.doOverwrite = false;
    PCB.trange = 400:800;
    PCB.n = 40;
    PCB.start = start-399;
    PCB.dt = dt;

    % date = 230828;shotIDX=41;
    % date = 230830;shotIDX=37;
    % date = 240111;shotIDX=29;
    % date = 240828;shotIDX=5;
    % date = 250314;shotIDX=55;
    DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
    T=getTS6log(DOCID);
    node='date';
    % date=230714;
    T=searchlog(T,node,date);
    IDXlist = find(T.shot==shotIDX);
    % IDXlist= 1; %[5:50 52:55 58:59];%[4:6 8:11 13 15:19 21:23 24:30 33:37 39:40 42:51 53:59 61:63 65:69 71:74];
    % n_data=numel(IDXlist);%計測データ数
    shotlist_a039 =T.a039(IDXlist);
    shotlist_a040 = T.a040(IDXlist);
    shotlist = [shotlist_a039, shotlist_a040];
    tfshotlist_a039 =T.a039_TF(IDXlist);
    tfshotlist_a040 =T.a040_TF(IDXlist);
    tfshotlist = [tfshotlist_a039, tfshotlist_a040];
    EFlist=T.EF_A_(IDXlist);
    TFlist=T.TF_kV_(IDXlist);
    % dtacqlist=39.*ones(n_data,1);
    PCB.idx = shotIDX;
    PCB.shot=shotlist;
    PCB.tfshot=tfshotlist;
    if PCB.shot == PCB.tfshot
        PCB.tfshot = [0,0];
    end
    PCB.i_EF=EFlist;
    PCB.TF=TFlist;
    PCB.date = date;
end