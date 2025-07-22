close all
clear
% ne：468（5番目）でr=0.273（15列目）
% Te：同じ時間、rは0.2870（16列目でもいい）
addpath('/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View');

% thomsonShotList = [13,14,15,16,17,19,21];
thomsonShot = 17;
% magShotList = [20,22,26,27,37,38,46];
% magShotList = [7,7:9,28:30];
magShotList = 38;
% thomsonTimeList = [464,465,466,467,468,469,470];
thomsonTime = 468;

thomsonPath = '/Users/shinjirotakeda/Downloads/ThomsonData/241228017-241228008_CIntvl_CDur_allfiber_TeNePe.csv';
T = readmatrix(thomsonPath);
r = reshape(T(:,2),7,[]);
z = reshape(T(:,3),7,[]);
Te_mat = reshape(T(:,4),7,[]);
ne_mat = reshape(T(:,6),7,[]);

SD_Te_mat = reshape(T(:,5),7,[]);
Te_mat(Te_mat<SD_Te_mat) = NaN;
SD_ne_mat = reshape(T(:,7),7,[]);
ne_mat(ne_mat<SD_ne_mat) = NaN;

Te_line = Te_mat(:,15);
Te_SD_line = SD_Te_mat(:,15);
ne_line = ne_mat(:,15);
ne_SD_line = SD_ne_mat(:,15);

z_ne = z(:,1).';
normNe = ne_line.'./max(ne_line);
normNe_std = ne_SD_line.'./max(ne_line);

e0 = 8.85e-12;
e = 1.6e-19;
me = 9.11e-31;
lambdaD = sqrt(e0.*e.*Te_line./(e^2.*ne_line));
Lambda = 4*pi*ne_line.*lambdaD.^3;
v_Te = sqrt(3*e*Te_line./me);
E_D = e^3*ne_line.*log(Lambda)./(4*pi*e0^2*me*v_Te.^2);
dEDdTe = e^2/(4*pi*e0^2).*(1.5.*ne_line-log(Lambda)./Te_line.^2);
dEDdne = e^2/(4*pi*e0^2).*(-0.5./Te_line+log(Lambda)./Te_line);
ED_std = dEDdTe.*Te_SD_line+dEDdne.*ne_SD_line;

ED_th = 5.6e-18*ne_line.*log(Lambda)./Te_line;


% figure;errorbar(z,Te_line,Te_SD_line);
% figure;errorbar(z,ne_line,ne_SD_line);

% Et, Br：X点近傍のr座標をどうにかして取得
dirPathMag = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;
% t = 441:480;
t = 468;
[Et_z,Br_z,Jt_z,GFR_z] = deal(zeros(numel(shotList),50));
% trange = t-399;
j = 1;
for i = shotList
    load([dirPathMag,num2str(i,'%03i'),'_200ch.mat'],'data2D','grid2D');
    t_idx = find(data2D.trange==t);
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    idxR = knnsearch(grid2D.rq(:,1),xPointList.r(t_idx));
    Et_z(j,:) = -1*mean(data2D.Et(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,t_idx));
    Br_z(j,:) = mean(data2D.Br(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,t_idx));
    Jt_z(j,:) = -1*mean(data2D.Jt(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,t_idx));
    Bt_z = mean(data2D.Bt_th(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,t_idx));
    GFR_z(j,:) = Bt_z./abs(Br_z(j,:));
    j = j+1;
end

[~,idxTF40] = ismember([7:9,28:30],shotList);

EtM40 = mean(Et_z(idxTF40,:),'omitmissing');
EtD40 = std(Et_z(idxTF40,:),'omitmissing');
BrM40 = mean(Br_z(idxTF40,:),'omitmissing');
BrD40 = std(Br_z(idxTF40,:),'omitmissing');
JtM40 = mean(Jt_z(idxTF40,:),'omitmissing');
JtD40 = std(Jt_z(idxTF40,:),'omitmissing');
GFRM40 = mean(GFR_z(idxTF40,:),'omitmissing');
GFRD40 = std(GFR_z(idxTF40,:),'omitmissing');

z_mag = grid2D.zq(1,:);
% z_mag = grid2D.zq(1,:)*5;
z_mag_range = min(z_ne)<=z_mag&z_mag<=max(z_ne);
z_mag = z_mag(z_mag_range);
normEt = EtM40(z_mag_range)./max(EtM40(z_mag_range));
normEt_std = EtD40(z_mag_range)./max(EtM40(z_mag_range));
normBr = BrM40(z_mag_range)./max(BrM40(z_mag_range));
normBr_std = BrD40(z_mag_range)./max(BrM40(z_mag_range));
normJt = JtM40(z_mag_range)./max(JtM40(z_mag_range));
normJt_std = JtD40(z_mag_range)./max(JtM40(z_mag_range));
normGFR = GFRM40(z_mag_range)./max(GFRM40(z_mag_range));
normGFR_std = GFRD40(z_mag_range)./max(GFRM40(z_mag_range));

figure;errorbar(z_mag,GFRM40(z_mag_range),GFRD40(z_mag_range));

% figure;errorbar(z,EtM40,EtD40);
% figure;errorbar(z,BrM40,BrD40);

% 発光強度：x点の座標を取得して横に切り取りたい
load('parameters.mat','range');
range = range./1000;
zmin1 = range(1);zmax1 = range(2);zmin2 = range(3);zmax2 = range(4);rmin = range(5);rmax = range(6);
dirPathSXR = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111';
EE_line = NaN(numel(shotList),50,4);
j=1;
for i = shotList
    load(fullfile(dirPathSXR,['shot',num2str(i)],'3.mat'),'EE1','EE2','EE3','EE4');
    EE = cat(3,EE1,EE2,EE3,EE4);
    EE(EE<0) = 0;
    r_space_SXR = linspace(rmin,rmax,size(EE1,1));
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    t_idx_SXR = find(data2D.trange==468);
    idxR = knnsearch(r_space_SXR.',xPointList.r(t_idx_SXR));
    for k = 1:4
        EE_line(j,:,k) = mean(EE(idxR-2:idxR+2,:,k));
    end
    j = j+1;
end

z_space_SXR1 = linspace(zmin1,zmax1,size(EE1,2));
z_space_SXR2 = linspace(zmin2,zmax2,size(EE1,2));

[EM,ED] = deal(zeros(4,50));
for i = 1:4
    EM(i,:) = mean(EE_line(idxTF40,:,i),'omitmissing');
    ED(i,:) = std(EE_line(idxTF40,:,i),'omitmissing');
    % if i<=2
    %     figure;errorbar(z_space_SXR2,EM(i,:),ED(i,:));
    % else
    %     figure;errorbar(z_space_SXR1,EM(i,:),ED(i,:));
    % end
end
z_SXR = z_space_SXR2;
z_SXR_range = min(z_ne)<=z_SXR&z_SXR<=max(z_ne);
z_SXR = z_SXR(z_SXR_range);
normSXR = EM(2,z_SXR_range)./max(EM(2,z_SXR_range));
% normSXR_std = ED(2,z_SXR_range)./max(EM(2,z_SXR_range));
normSXR_std = ED(2,z_SXR_range);

% E1M = mean(EE_line(idxTF40,:),'omitmissing');
% E1D = std(EE_line(idxTF40,:),'omitmissing');



figure;hold on;
errorbar(z_ne,normNe,normNe_std);
errorbar(z_mag,normEt,normEt_std);
errorbar(z_mag,normBr,normBr_std);
errorbar(z_mag,normJt,normJt_std);
errorbar(z_mag,normGFR,normGFR_std);
errorbar(z_SXR,normSXR,normSXR_std);
legend({'n_e','E_t','B_r','J_t','GFR','I_{SXR}'},'Location','southwest');
xlabel('z [m]');
ax=gca;ax.FontSize=18;

figure;hold on;
% plot(z_ne,E_D);
errorbar(z_ne,E_D,ED_std);
errorbar(grid2D.zq(1,:),EtM40,EtD40);
plot(z_ne,ED_th);
