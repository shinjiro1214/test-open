load('/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111022.mat','data2D','grid2D');
[~,xPointList] = get_axis_x_multi(grid2D,data2D);

eta_t1 = zeros(1,20);
t1 = 461:480;
m = 1;
for i = 61:80
    idxR = knnsearch(grid2D.rq(:,1),xPointList.r(i));
    idxZ = knnsearch(grid2D.zq(1,:).',xPointList.z(i));
    eta = data2D.Et(:,:,i)./data2D.Jt(:,:,i);
    eta_t1(m) = mean(eta(max(1,idxR-3):min(idxR+3,numel(grid2D.rq(:,1))),max(1,idxZ-3):min(numel(grid2D.zq(1,:)),idxZ+3)),'all');
    m = m+1;
end

load('/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111023.mat','data2D','grid2D');
[~,xPointList] = get_axis_x_multi(grid2D,data2D);

eta_t2 = zeros(1,20);
t2 = 461:480;
m = 1;
for i = 61:80
    idxR = knnsearch(grid2D.rq(:,1),xPointList.r(i));
    idxZ = knnsearch(grid2D.zq(1,:).',xPointList.z(i));
    eta = data2D.Et(:,:,i)./data2D.Jt(:,:,i);
    eta_t2(m) = mean(eta(max(1,idxR-3):min(idxR+3,numel(grid2D.rq(:,1))),max(1,idxZ-3):min(numel(grid2D.zq(1,:)),idxZ+3)),'all');
    m = m+1;
end

load('/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111024.mat','data2D','grid2D');
[~,xPointList] = get_axis_x_multi(grid2D,data2D);

eta_t3 = zeros(1,20);
t3 = 461:480;
m = 1;
for i = 61:80
    idxR = knnsearch(grid2D.rq(:,1),xPointList.r(i));
    idxZ = knnsearch(grid2D.zq(1,:).',xPointList.z(i));
    eta = data2D.Et(:,:,i)./data2D.Jt(:,:,i);
    eta_t3(m) = mean(eta(max(1,idxR-3):min(idxR+3,numel(grid2D.rq(:,1))),max(1,idxZ-3):min(numel(grid2D.zq(1,:)),idxZ+3)),'all');
    m = m+1;
end

figure;plot(t1,eta_t1);hold on;plot(t2,eta_t2);plot(t3,eta_t3);

eta_t = [eta_t1;eta_t2;eta_t3];
eta_M = mean(eta_t,'omitmissing');
eta_D = std(eta_t,'omitmissing');
figure;errorbar(t1,eta_M,eta_D,'LineWidth',3);
xlabel('time [us]');ylabel('Electric field [V/m]');
ax = gca; ax.FontSize = 18;
xlim([460 470]);
% yticks([-400 -200 0]);
xticks([460 465 470]);
