clear all
load("Grid.mat")
load("shot22_Plasma.mat")
Bt_Plasma = PCBdata2D.Bt(:,:,71);
load("shot23_Plasma.mat")
Bt_Plasma = Bt_Plasma + PCBdata2D.Bt(:,:,71);
load("shot41_Plasma.mat")
Bt_Plasma = (Bt_Plasma + PCBdata2D.Bt(:,:,71))./3;
load("shot3_TFonly.mat")
Bt_TFonly = PCBdata2D.Bt(:,:,71);

ratio = Bt_Plasma./Bt_TFonly;
diff = abs(ratio-1);

figure
contourf(PCBgrid2D.zq(1,:),PCBgrid2D.rq(:,1),diff,[0:1e-2:0.1],'LineStyle','none')
colorbar
clim([0 0.06])

% contourf(PCBgrid2D.zq(1,:),PCBgrid2D.rq(:,1),ratio,[0.9:1e-2:1.1],'LineStyle','none')
% colorbar
% % clim([0.9 1.1])

xlim([-0.04 0.07])
ylim([0.10 0.27])