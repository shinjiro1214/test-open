close all
dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;
% t = 441:480;
% t = 468;
t = 460;
Jt_z = zeros(numel(shotList),40);
% trange = t-399;
j = 1;
figure;hold on;
for i = shotList
    load([dirPath,num2str(i,'%03i'),'.mat'],'data2D','grid2D');
    % Jt_t_tmp = -1*get_Jt_time(grid2D,data2D,trange);
    % Jt_t(j,:) = Jt_t_tmp - Jt_t_tmp(1);
    t_idx = find(data2D.trange==t);
    z = grid2D.zq(1,:);
    Jt_z(j,:) = -1*get_Jt_z(grid2D,data2D,t_idx);
    plot(z,Jt_z(j,:));
    j = j+1;
end
[~,idxTF40] = ismember([7:9,28:30],shotList);
[~,idxTF35] = ismember([10:12,25:27],shotList);
[~,idxTF30] = ismember([13:15,22:24],shotList);
[~,idxTF25] = ismember(16:21,shotList);

JtM40 = mean(Jt_z(idxTF40,:),'omitmissing');
JtD40 = std(Jt_z(idxTF40,:),'omitmissing');
JtM35 = mean(Jt_z(idxTF35,:),'omitmissing');
JtD35 = std(Jt_z(idxTF35,:),'omitmissing');
JtM30 = mean(Jt_z(idxTF30,:),'omitmissing');
JtD30 = std(Jt_z(idxTF30,:),'omitmissing');
JtM25 = mean(Jt_z(idxTF25,:),'omitmissing');
JtD25 = std(Jt_z(idxTF25,:),'omitmissing');
figure;
errorbar(z,JtM25,JtD25);hold on;
errorbar(z,JtM30,JtD30);
errorbar(z,JtM35,JtD35);
errorbar(z,JtM40,JtD40);
legend({'TF=2.5kV','TF=3kV','TF=3.5kV','TF=4kV'});

xlabel('z [m]');
ax=gca;ax.FontSize=18;
ylabel('Toroidal current density [A/m^2]');


function Jt_z = get_Jt_z(grid2D,data2D,t_idx)
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    idxR = knnsearch(grid2D.rq(:,1),xPointList.r(t_idx));
    Jt_z = mean(data2D.Jt(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,t_idx));
    % t = 461:480;
    % m = 1;
    % for i = trange
    %     idxR = knnsearch(grid2D.rq(:,1),xPointList.r(i));
    %     idxZ = knnsearch(grid2D.zq(1,:).',xPointList.z(i));
    %     Jt_z(m) = mean(data2D.Jt(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),max(1,idxZ-1):min(numel(grid2D.zq(1,:)),idxZ+1),i),'all');
    %     m = m+1;
    % end
end