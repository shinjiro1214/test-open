addpath '/Users/rsomeya/Documents/lab/matlab/common';

load("Grid.mat")
load("shot22_Plasma.mat")
idx_up_z = 24;
idx_up_r = 31;
idx_xp_z = 22;
idx_xp_r = 31;
idx_down_z = 22;
idx_down_r = 22;
idx_t_start = 52;
idx_t_end = 101;

time = PCBdata2D.trange(1,idx_t_start:idx_t_end);

Et_up = squeeze(PCBdata2D.Et(idx_up_r,idx_up_z,idx_t_start:idx_t_end));
Et_up = movmean(Et_up,5,1);
psi_up = squeeze(PCBdata2D.psi(idx_up_r,idx_up_z,idx_t_start:idx_t_end));
psi_up = movmean(psi_up,5,1);

Et_xp = squeeze(PCBdata2D.Et(idx_xp_r,idx_xp_z,idx_t_start:idx_t_end));
Et_xp = movmean(Et_xp,5,1);
psi_xp = squeeze(PCBdata2D.psi(idx_xp_r,idx_xp_z,idx_t_start:idx_t_end));
psi_xp = movmean(psi_xp,5,1);

Et_down = squeeze(PCBdata2D.Et(idx_down_r,idx_down_z,idx_t_start:idx_t_end));
Et_down = movmean(Et_down,5,1);
psi_down = squeeze(PCBdata2D.psi(idx_down_r,idx_down_z,idx_t_start:idx_t_end));
psi_down = movmean(psi_down,5,1);

figure
h = plot(time,Et_up,'b',"LineWidth",3);
legName = sprintf("Upstream Region (Z = %.3f m, R = %.3f m)",PCBgrid2D.zq(1,idx_up_z),PCBgrid2D.rq(idx_up_r,1));
hs = char.empty;
[hs,legStr] = make_legend(hs,h,"",legName);
% hold on
% h = plot(time,Et_xp,'g',"LineWidth",3);
% legName = sprintf("X-point (Z = %.3f m, R = %.3f m)",PCBgrid2D.zq(1,idx_xp_z),PCBgrid2D.rq(idx_xp_r,1));
% [hs,legStr] = make_legend(hs,h,legStr,legName);
hold on
h = plot(time,Et_down,'r',"LineWidth",3);
legName = sprintf("Downstream Region (Z = %.3f m, R = %.3f m)",PCBgrid2D.zq(1,idx_down_z),PCBgrid2D.rq(idx_down_r,1));
[hs,legStr] = make_legend(hs,h,legStr,legName);
xlabel("Time [us]")
ylabel("Toroidal Reconnection Electric Field [V/m]")
xlim([455 480])
fontsize(15,"points")
legend(hs,legStr,'Location','northwest')

figure
h = plot(time,psi_up,'b',"LineWidth",3);
legName = sprintf("Upstream Region (Z = %.3f m, R = %.3f m)",PCBgrid2D.zq(1,idx_up_z),PCBgrid2D.rq(idx_up_r,1));
hs = char.empty;
[hs,legStr] = make_legend(hs,h,"",legName);
% hold on
% h = plot(time,psi_xp,'g',"LineWidth",3);
% legName = sprintf("X-point (Z = %.3f m, R = %.3f m)",PCBgrid2D.zq(1,idx_xp_z),PCBgrid2D.rq(idx_xp_r,1));
% [hs,legStr] = make_legend(hs,h,legStr,legName);
hold on
h = plot(time,psi_down,'r',"LineWidth",3);
legName = sprintf("Downstream Region (Z = %.3f m, R = %.3f m)",PCBgrid2D.zq(1,idx_down_z),PCBgrid2D.rq(idx_down_r,1));
[hs,legStr] = make_legend(hs,h,legStr,legName);
% for i=1:size(psi,1)
%     plot(time,psi(i,:))
%     hold on
% end
% title(sprintf("Z = %.3f m, R = %.3f m",PCBgrid2D.zq(1,idx_down_z),PCBgrid2D.rq(idx_down_r,1)))
xlabel("Time [us]")
ylabel("Psi [Wb]")
xlim([455 480])
fontsize(15,"points")
legend(hs,legStr,'Location','northwest')
