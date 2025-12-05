% plot_ne_r_multi
% 径方向に電子密度、温度をプロット
% 0付近のz座標で切り取って平均をとる

% thomsonShotList = [30,31,32,33,36,37,38,40,42];
% thomsonTimeList = [462,462,464,464,466,466,468,468,468];
% magshotList = 17;
thomsonShotList = [30,32,36,42];
thomsonTimeList = [462,464,466,468];

addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View'

% i=5;
% i=9;
figure;hold on;
for i = 1:numel(thomsonTimeList)
    time = thomsonTimeList(i);
    thomsonIdx = thomsonShotList(i);
    thomsonPath = ['/Users/shinjirotakeda/Downloads/ThomsonData/250325',num2str(thomsonIdx,'%03i'),'_TeNePe.csv'];
    T = readmatrix(thomsonPath);
    r = reshape(T(:,2),7,[]);
    z = reshape(T(:,3),7,[]);
    ne_mat = reshape(T(:,6),7,[]);

    SD_ne_mat = reshape(T(:,7),7,[]);
    ne_mat(ne_mat./SD_ne_mat<0.15) = NaN;

    z_axis = z(:,1);r_axis = r(1,:);
    z_indices = abs(z_axis) <= 0.03;
    ne_tmp = squeeze(ne_mat(z_indices,:));
    ne_mean = mean(ne_tmp,1);
    ne_std = std(ne_tmp,0,1);
    % figure;
    % yyaxis left
    errorbar(r_axis,ne_mean,ne_std,'LineWidth',2,'Marker','o','MarkerSize',6,'CapSize',10);
end

ylabel('Electron density [m^{-3}]');
xlabel('r [m]');
legend({'$\mathrm{464 \mu s}$','$\mathrm{466 \mu s}$','$\mathrm{468 \mu s}$','$\mathrm{470 \mu s}$'},'Interpreter','latex')
% title(string(time)+' us')
ax=gca;ax.FontSize=18;