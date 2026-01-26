% plot_Te_r_multi
% 径方向に電子密度、温度をプロット
% 0付近のz座標で切り取って平均をとる

thomsonShotList = [30,31,32,33,36,37,38,40,42];
thomsonTimeList = [462,462,464,464,466,466,468,468,468];
% magshotList = 17;
% thomsonShotList = [30,32,36,42];
% thomsonTimeList = [462,464,466,468];

% thomsonShotList = [36,38];
% thomsonTimeList = [466,468];

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
    Te_mat = reshape(T(:,4),7,[]);

    SD_Te_mat = reshape(T(:,5),7,[]);
    Te_mat(Te_mat./SD_Te_mat<0.15) = NaN;

    z_axis = z(:,1);r_axis = r(1,:);
    % z_indices = abs(z_axis) <= 0.03;
    z_indices = abs(z_axis) <= 0.01;
    Te_tmp = squeeze(Te_mat(z_indices,:));
    Te_mean = mean(Te_tmp,1);
    % Te_std = std(Te_tmp,0,1);
    Te_std = squeeze(SD_Te_mat(z_indices,:));
    % figure;
    % yyaxis left
    errorbar(r_axis,Te_mean,Te_std,'LineWidth',2,'Marker','o','MarkerSize',6,'CapSize',10);
end

ylabel('Electron temperature [eV]');
xlabel('r [m]');
% legend({'$\mathrm{464 \mu s}$','$\mathrm{466 \mu s}$','$\mathrm{468 \mu s}$','$\mathrm{470 \mu s}$'},'Interpreter','latex','Location','best')
mu_str = char(181); 
legendLabels = string(thomsonTimeList) + " " + mu_str + "s";legend(legendLabels);
% title(string(time)+' us')
ax=gca;ax.FontSize=18;
% xlim([0.1 0.25]);
