t = 472;

pathname = '/Users/rsomeya/Documents/lab/9_B4/実験/200120-200121/matlab_psi/';
h = openfig([pathname,'CB2_',num2str(t),'.fig'],'invisible');
ax = gca; % 現在の軸を取得します
contourObj = findobj(ax, 'Type', 'Contour');
newLevels = linspace(min(contourObj.ZData, [], 'all'), max(contourObj.ZData, [], 'all'), 100); % 20レベルの等間隔
figure
contourf(contourObj.XData, contourObj.YData, contourObj.ZData, [-6E-3:0.5E-3:7E-3]);
colormap("jet")
hold on
plot(0.021,0.2,'wx','LineWidth',3,'MarkerSize',10)
daspect([1 1 1])
colorbar
clim([-6E-3 7E-3])
title([num2str(t),'us'])
view([90 -90])%RZ反転
% xlim([-0.02 0.06])
% ylim([0.18 0.22])
