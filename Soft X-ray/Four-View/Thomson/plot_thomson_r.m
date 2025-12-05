% 径方向に電子密度、温度をプロット
% 0付近のz座標で切り取って平均をとる

% thomsonShotList = [13,14,15,16,17,19,21];
% thomsonTimeList = [464,465,466,467,468,469,470];
% magShotList = 38;

% magShotList = [20,22,26,27,37,38,46];
% magShotList = [7,7:9,28:30];

thomsonShotList = [30,31,32,33,36,37,38,40,42];
thomsonTimeList = [462,462,464,464,466,466,468,468,468];
% magshotList = 17;

addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View'

% ne_t = nan(numel(thomsonTimeList),1);
% Te_t = nan(numel(thomsonTimeList),1);
f1 = figure('Position', [0 0 1500 1500],'visible','on');t1=tiledlayout(3,3,'TileSpacing','compact','Padding','compact');
f2 = figure('Position', [0 0 1500 1500],'visible','on');t2=tiledlayout(3,3,'TileSpacing','compact','Padding','compact');
% i=1;
for i = 1:numel(thomsonTimeList)
    % subplot(2,4,i);hold on;
    time = thomsonTimeList(i);
    thomsonIdx = thomsonShotList(i);
    % thomsonPath = ['/Users/shinjirotakeda/Downloads/ThomsonData/241228',num2str(thomsonIdx,'%03i'),'-241228008_CIntvl_CDur_allfiber_TeNePe.csv'];
    thomsonPath = ['/Users/shinjirotakeda/Downloads/ThomsonData/250325',num2str(thomsonIdx,'%03i'),'_TeNePe.csv'];
    T = readmatrix(thomsonPath);
    r = reshape(T(:,2),7,[]);
    z = reshape(T(:,3),7,[]);
    Te_mat = reshape(T(:,4),7,[]);
    ne_mat = reshape(T(:,6),7,[]);

    SD_Te_mat = reshape(T(:,5),7,[]);
    SD_ne_mat = reshape(T(:,7),7,[]);
    % Te_mat(Te_mat<SD_Te_mat) = NaN;
    % ne_mat(ne_mat<SD_ne_mat) = NaN;
    Te_mat(Te_mat./SD_Te_mat<0.15) = NaN;
    ne_mat(ne_mat./SD_ne_mat<0.15) = NaN;

    z_axis = z(:,1);r_axis = r(1,:);
    z_indices = abs(z_axis) <= 0.01;
    Te_tmp = squeeze(Te_mat(z_indices,:));
    Te_mean = mean(Te_tmp,1);
    Te_std = std(Te_tmp,0,1);
    figure(f1);nexttile;hold on;
    errorbar(r_axis,Te_mean,Te_std,'LineWidth',2,'Marker','o','MarkerSize',6,'CapSize',10);
    title(string(time)+' us')
    ax=gca;ax.FontSize=18;
    ne_tmp = squeeze(ne_mat(z_indices,:));
    ne_mean = mean(ne_tmp,1);
    ne_std = std(ne_tmp,0,1);
    figure(f2);nexttile;hold on;
    errorbar(r_axis,ne_mean,ne_std,'LineWidth',2,'Marker','o','MarkerSize',6,'CapSize',10);
    title(string(time)+' us')
    ax=gca;ax.FontSize=18;

    % contourf(z,r,Te_mat,linspace(0,10,10),'LineStyle','none');
    % contourf(z,r,ne_mat,linspace(0,5e20,10),'LineStyle','none');

    % folderPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/241228';
    % % folderPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
    % fileExtention = '.mat';
    % % magIdx = magShotList(thomsonTimeList==time);
    % magIdx = magShotList;
    % path = [folderPath,num2str(magIdx,'%03i'),fileExtention];
    % load(path,'data2D','grid2D');

    % % 内挿（NaNが多いのでやらない方が良さげ）
    % % [rq,zq] = meshgrid(linspace(0.125,0.302,40),linspace(-0.078,0.078,40));
    % ZQ = grid2D.zq;RQ = grid2D.rq;
    % zq = ZQ(RQ(:,1)<=0.302&RQ(:,2)>=0.125,ZQ(1,:)<=0.078&ZQ(1,:)>=-0.078);
    % rq = RQ(RQ(:,1)<=0.302&RQ(:,2)>=0.125,ZQ(1,:)<=0.078&ZQ(1,:)>=-0.078);
    % Te_q = interp2(r,z,Te_mat,rq.',zq.');
    % ne_q = interp2(r,z,ne_mat,rq.',zq.');
    % figure(f1);nexttile;hold on;
    % contourf(zq(1,:),rq(:,1),Te_q.',linspace(0,15,10),'LineStyle','none');
    % if i==numel(thomsonTimeList)
    %     c1=colorbar;
    %     c1.Layout.Tile='east';
    % end
    % figure(f2);nexttile;hold on;
    % contourf(zq(1,:),rq(:,1),ne_q.',linspace(0,3e20,10),'LineStyle','none');
    % if i==numel(thomsonTimeList)
    %     c2=colorbar;
    %     c2.Layout.Tile='east';
    % end

    % [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    % timeIndex = time-401;
    % figure(f1);
    % contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,timeIndex)),20,'black');
    % axis equal
    % % plot(xPointList.z(timeIndex),xPointList.r(timeIndex),'kx');
    % xlim([-0.078,0.078]);ylim([0.125,0.302]);
    % % xlim([-0.05,0.05]);ylim([0.22,0.3]);
    % % xlim([-0.04,0.04]);ylim([0.15,0.32]);
    % hold off
    % title(string(time)+' us')
    % ax=gca;ax.FontSize=18;
    % figure(f2);
    % contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,timeIndex)),20,'black');
    % axis equal
    % % plot(xPointList.z(timeIndex),xPointList.r(timeIndex),'kx');
    % xlim([-0.078,0.078]);ylim([0.125,0.302]);
    % % xlim([-0.05,0.05]);ylim([0.22,0.3]);
    % % xlim([-0.04,0.04]);ylim([0.15,0.32]);
    % hold off
    % title(string(time)+' us')
    % ax=gca;ax.FontSize=18;
end

figure(f1);title(t1,'Te [eV]');
figure(f2);title(t2,'ne [m^-3]');