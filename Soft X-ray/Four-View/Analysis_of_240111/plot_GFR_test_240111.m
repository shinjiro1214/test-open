addpath('/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View');
dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;
t = 441:480;
Br_z = zeros(numel(shotList),50);
GFR_z = zeros(numel(shotList),50);
trange = t-399;
j = 1;
t = 468;
figure;hold on;
for i = shotList
    load([dirPath,num2str(i,'%03i'),'_200ch.mat'],'data2D','grid2D');
    t_idx = find(data2D.trange==t);
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    idxR = knnsearch(grid2D.rq(:,1),xPointList.r(t_idx));
    z_mag = grid2D.zq(1,:);
    Br_z(j,:) = mean(data2D.Br(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,t_idx));
    Bt_z = mean(data2D.Bt_th(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,t_idx));
    GFR_z(j,:) = Bt_z./abs(Br_z(j,:));
    plot(z_mag,GFR_z(j,:));
    j = j+1;
end
xlim([-0.05 0.05]);

[~,idxTF40] = ismember([7:9,28:30],shotList);
[~,idxTF35] = ismember([10:12,25:27],shotList);
[~,idxTF30] = ismember([13:15,22:24],shotList);
[~,idxTF25] = ismember(16:21,shotList);

GFRM40 = mean(GFR_z(idxTF40,:),'omitmissing');
GFRD40 = std(GFR_z(idxTF40,:),'omitmissing');
GFRM35 = mean(GFR_z(idxTF35,:),'omitmissing');
GFRD35 = std(GFR_z(idxTF35,:),'omitmissing');
GFRM30 = mean(GFR_z(idxTF30,:),'omitmissing');
GFRD30 = std(GFR_z(idxTF30,:),'omitmissing');
GFRM25 = mean(GFR_z(idxTF25,:),'omitmissing');
GFRD25 = std(GFR_z(idxTF25,:),'omitmissing');
figure;
errorbar(z_mag,GFRM25,GFRD25);hold on;
errorbar(z_mag,GFRM30,GFRD30);
errorbar(z_mag,GFRM35,GFRD35);
errorbar(z_mag,GFRM40,GFRD40);
legend({'TF=2.5kV','TF=3kV','TF=3.5kV','TF=4kV'});
xlim([-0.05 0.05]);
xlabel('z [m]');
ax=gca;ax.FontSize=18;
ylabel('Guide field ratio');