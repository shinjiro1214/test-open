thomsonShotList = [13,14,15,16,17,19,21];
% magShotList = [20,22,26,27,37,38,46];
% magShotList = [7,7:9,28:30];
magShotList = 38;
thomsonTimeList = [464,465,466,467,468,469,470];

e0 = 8.85e-12;
e = 1.6e-19;
me = 9.11e-31;

% ne_t = nan(numel(thomsonTimeList),1);
% Te_t = nan(numel(thomsonTimeList),1);
figure('Position', [0 0 1500 1500],'visible','on');
% i=1;
for i = 1:7
    subplot(2,4,i);hold on;
    time = thomsonTimeList(i);
    thomsonIdx = thomsonShotList(i);
    thomsonPath = ['/Users/shinjirotakeda/Downloads/ThomsonData/241228',num2str(thomsonIdx,'%03i'),'-241228008_CIntvl_CDur_allfiber_TeNePe.csv'];
    T = readmatrix(thomsonPath);
    r = reshape(T(:,2),7,[]);
    z = reshape(T(:,3),7,[]);
    Te_mat = reshape(T(:,4),7,[]);
    ne_mat = reshape(T(:,6),7,[]);

    SD_Te_mat = reshape(T(:,5),7,[]);
    Te_mat(Te_mat<SD_Te_mat) = NaN;
    SD_ne_mat = reshape(T(:,7),7,[]);
    ne_mat(ne_mat<SD_ne_mat) = NaN;

    lambdaD = sqrt(e0.*e.*Te_mat./(e^2.*ne_mat));
    Lambda = 4*pi*ne_mat.*lambdaD.^3;
    v_Te = sqrt(3*e*Te_mat./me);
    E_D = e^3*ne_mat.*log(Lambda)./(4*pi*e0^2*me*v_Te.^2);

    % contourf(z,r,Te_mat,linspace(0,10,10),'LineStyle','none');
    % contourf(z,r,ne_mat,linspace(0,5e20,10),'LineStyle','none');
    contourf(z,r,E_D,linspace(0,5000,50),'LineStyle','none');

    folderPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/241228';
    % folderPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
    fileExtention = '.mat';
    % magIdx = magShotList(thomsonTimeList==time);
    magIdx = magShotList;
    path = [folderPath,num2str(magIdx,'%03i'),fileExtention];
    load(path,'data2D','grid2D');
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,time-400)),20,'black');
    plot(xPointList.z(time-400),xPointList.r(time-400),'kx');
    hold off
    title(string(time)+' us')
    xlim([-0.07,0.07]);ylim([0.2,0.32]);
end