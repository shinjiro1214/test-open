close all
dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;
% t = 441:480;
t = 468;
Et_z = zeros(numel(shotList),40);
% trange = t-399;
j = 1;
figure;hold on;
for i = shotList
    load([dirPath,num2str(i,'%03i'),'.mat'],'data2D','grid2D');
    % Et_t_tmp = -1*get_Et_time(grid2D,data2D,trange);
    % Et_t(j,:) = Et_t_tmp - Et_t_tmp(1);
    t_idx = find(data2D.trange==t);
    z = grid2D.zq(1,:);
    Et_z(j,:) = -1*get_Et_z(grid2D,data2D,t_idx);
    plot(z,Et_z(j,:));
    j = j+1;
end
[~,idxTF40] = ismember([7:9,28:30],shotList);
[~,idxTF35] = ismember([10:12,25:27],shotList);
[~,idxTF30] = ismember([13:15,22:24],shotList);
[~,idxTF25] = ismember(16:21,shotList);

EtM40 = mean(Et_z(idxTF40,:),'omitmissing');
EtD40 = std(Et_z(idxTF40,:),'omitmissing');
EtM35 = mean(Et_z(idxTF35,:),'omitmissing');
EtD35 = std(Et_z(idxTF35,:),'omitmissing');
EtM30 = mean(Et_z(idxTF30,:),'omitmissing');
EtD30 = std(Et_z(idxTF30,:),'omitmissing');
EtM25 = mean(Et_z(idxTF25,:),'omitmissing');
EtD25 = std(Et_z(idxTF25,:),'omitmissing');
figure;
errorbar(z,EtM25,EtD25);hold on;
errorbar(z,EtM30,EtD30);
errorbar(z,EtM35,EtD35);
errorbar(z,EtM40,EtD40);
legend({'TF=2.5kV','TF=3kV','TF=3.5kV','TF=4kV'});

xlabel('z [m]');
ax=gca;ax.FontSize=18;
ylabel('Reconnection electric field [V/t]');


function Et_z = get_Et_z(grid2D,data2D,t_idx)
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    idxR = knnsearch(grid2D.rq(:,1),xPointList.r(t_idx));
    Et_z = mean(data2D.Et(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,t_idx));
    % t = 461:480;
    % m = 1;
    % for i = trange
    %     idxR = knnsearch(grid2D.rq(:,1),xPointList.r(i));
    %     idxZ = knnsearch(grid2D.zq(1,:).',xPointList.z(i));
    %     Et_z(m) = mean(data2D.Et(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),max(1,idxZ-1):min(numel(grid2D.zq(1,:)),idxZ+1),i),'all');
    %     m = m+1;
    % end
end