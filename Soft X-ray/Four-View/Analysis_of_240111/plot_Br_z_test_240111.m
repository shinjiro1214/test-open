close all
dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;
% t = 441:480;
t = 468;
% t = 460;
Br_z = zeros(numel(shotList),40);
% trange = t-399;
j = 1;
figure;hold on;
for i = shotList
    load([dirPath,num2str(i,'%03i'),'.mat'],'data2D','grid2D');
    % Br_t_tmp = -1*get_Br_time(grid2D,data2D,trange);
    % Br_t(j,:) = Br_t_tmp - Br_t_tmp(1);
    t_idx = find(data2D.trange==t);
    z = grid2D.zq(1,:);
    Br_z(j,:) = -1*get_Br_z(grid2D,data2D,t_idx);
    plot(z,Br_z(j,:));
    j = j+1;
end
[~,idxTF40] = ismember([7:9,28:30],shotList);
[~,idxTF35] = ismember([10:12,25:27],shotList);
[~,idxTF30] = ismember([13:15,22:24],shotList);
[~,idxTF25] = ismember(16:21,shotList);

BrM40 = mean(Br_z(idxTF40,:),'omitmissing');
BrD40 = std(Br_z(idxTF40,:),'omitmissing');
BrM35 = mean(Br_z(idxTF35,:),'omitmissing');
BrD35 = std(Br_z(idxTF35,:),'omitmissing');
BrM30 = mean(Br_z(idxTF30,:),'omitmissing');
BrD30 = std(Br_z(idxTF30,:),'omitmissing');
BrM25 = mean(Br_z(idxTF25,:),'omitmissing');
BrD25 = std(Br_z(idxTF25,:),'omitmissing');
figure;
errorbar(z,BrM25,BrD25);hold on;
errorbar(z,BrM30,BrD30);
errorbar(z,BrM35,BrD35);
errorbar(z,BrM40,BrD40);
legend({'TF=2.5kV','TF=3kV','TF=3.5kV','TF=4kV'});

xlabel('z [m]');
ax=gca;ax.FontSize=18;
ylabel('Reconnection electric field [V/t]');


function Br_z = get_Br_z(grid2D,data2D,t_idx)
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    idxR = knnsearch(grid2D.rq(:,1),xPointList.r(t_idx));
    Br_z = mean(data2D.Br(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,t_idx));
    % t = 461:480;
    % m = 1;
    % for i = trange
    %     idxR = knnsearch(grid2D.rq(:,1),xPointList.r(i));
    %     idxZ = knnsearch(grid2D.zq(1,:).',xPointList.z(i));
    %     Br_z(m) = mean(data2D.Br(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),max(1,idxZ-1):min(numel(grid2D.zq(1,:)),idxZ+1),i),'all');
    %     m = m+1;
    % end
end