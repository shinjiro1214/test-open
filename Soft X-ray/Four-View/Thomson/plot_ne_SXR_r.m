% plot_ne_SXR_r
% 径方向に電子密度、温度をプロット
% 0付近のz座標で切り取って平均をとる

thomsonShotList = [30,31,32,33,36,37,38,40,42];
thomsonTimeList = [462,462,464,464,466,466,468,468,468];
% magshotList = 17;

addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View'

% i=5;
i=9;
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
figure;
% yyaxis left
errorbar(r_axis,ne_mean,ne_std,'LineWidth',2,'Marker','o','MarkerSize',6,'CapSize',10);
ylabel('Electron density [m^{-3}]');
% title(string(time)+' us')
ax=gca;ax.FontSize=18;

pathFirstHalf = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111/shot';
pathLastHalf = '/3.mat';
% nshot_1 = 29;
nshot_1 = 7;
path_1 = strcat(pathFirstHalf,num2str(nshot_1),pathLastHalf);
load(path_1,'EE2');
EE = EE2;

zmin1=-200;zmax1=200;zmin2=-200;zmax2=200;
rmin=70;rmax=375;
range = [zmin1,zmax1,zmin2,zmax2,rmin,rmax];

range = range./1000;
zmin2 = range(3);
zmax2 = range(4);
rmin = range(5);
rmax = range(6);
r_space_SXR = linspace(rmin,rmax,50);
z_space_SXR2 = linspace(zmin2,zmax2,50);

z_indices_SXR = abs(z_space_SXR2)<=0.01;
SXR_r_tmp = EE(:,z_indices_SXR) .* 4;
SXR_r_mean = mean(SXR_r_tmp,2);
SXR_r_std = std(SXR_r_tmp,0,2);

% yyaxis right
% errorbar(r_space_SXR,SXR_r_mean,SXR_r_std,'LineWidth',2,'Marker','o','MarkerSize',6,'CapSize',10);
% ylabel('SXR intensity [a.u.]');ylim([0 1]);
% xlabel('r [m]');
% xlim([0.15 0.3])