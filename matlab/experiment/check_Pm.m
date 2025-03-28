clear all
load("Grid.mat")
load("shot22_Plasma.mat")
Jt = PCBdata2D.Jt(:,:,71);
Br = PCBdata2D.Br(:,:,71);

Jt = movmean(Jt,3,1);
Jt = movmean(Jt,3,2);
Br = movmean(Br,3,1);
Br = movmean(Br,3,2);

JtBr = Jt.*Br;
Pm = JtBr./10;

figure
contourf(PCBgrid2D.zq(1,:),PCBgrid2D.rq(:,1),Pm,[-5e2:50:5e2],'LineStyle','none')
colorbar
% clim([0 0.06])

% contourf(PCBgrid2D.zq(1,:),PCBgrid2D.rq(:,1),ratio,[0.9:1e-2:1.1],'LineStyle','none')
% colorbar
% % clim([0.9 1.1])

xlim([-0.04 0.07])
ylim([0.10 0.27])