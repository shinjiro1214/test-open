thomsonShotList = [13,14,15,16,17,19,21];
magShotList = [20,22,26,27,37,38,46];
thomsonTimeList = [464,465,466,467,468,469,470];

time = 470;
thomsonIdx = thomsonShotList(thomsonTimeList==time);
thomsonPath = ['/Users/shinjirotakeda/Downloads/ThomsonData/241228',num2str(thomsonIdx,'%03i'),'-241228008_CIntvl_CDur_allfiber_TeNePe.csv'];
T = readmatrix(thomsonPath);
r = reshape(T(:,2),7,[]);
z = reshape(T(:,3),7,[]);
Te_mat = reshape(T(:,4),7,[]);

SD_Te_mat = reshape(T(:,5),7,[]);
Te_mat(Te_mat<SD_Te_mat) = NaN;

figure;contourf(z,r,Te_mat,linspace(0,10,10),'LineStyle','none');

% % 内挿（NaNが多いのでやらない方が良さげ）
% T(T(:,4)<T(:,5),2:4) = 0;
% F = scatteredInterpolant(T(:,3),T(:,2),T(:,4));
% [rq,zq] = meshgrid(linspace(0.125,0.302,40),linspace(-0.078,0.078,40));
% Te_q = F(zq,rq);
% figure;contourf(zq,rq,Te_q,linspace(0,10,10));


% 磁場からX点座標を取得
folderPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/241228';
fileExtention = '.mat';
magIdx = magShotList(thomsonTimeList==time);
path = [folderPath,num2str(magIdx,'%03i'),fileExtention];
load(path,'data2D','grid2D');
[~,xPointList] = get_axis_x_multi(grid2D,data2D);
hold on;plot(xPointList.z(time-400),xPointList.r(time-400),'kx');
% 最も近い点（上下左右で4点？）を検索
z_idx = find(z(:,1)<=xPointList.z(time-400),1,'last');
r_idx = find(r(1,:)<=xPointList.r(time-400),1,'last');
% その点の平均値を取得
if r_idx == numel(r(1,:))
    Te_x = mean([Te_mat([z_idx,z_idx+1],r_idx)],'omitnan');
else
    Te_x = mean([Te_mat([z_idx,z_idx+1],[r_idx,r_idx+1])],'all','omitnan');
end
disp(Te_x);