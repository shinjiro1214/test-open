dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;
t = 451:480;
Br_t = zeros(numel(shotList),numel(t));
trange = t-399;
j = 1;
figure;hold on;
for i = shotList
    load([dirPath,num2str(i,'%03i'),'.mat'],'data2D','grid2D');
    Br_t_tmp = get_Br_time(grid2D,data2D,trange);
    Br_t(j,:) = Br_t_tmp - Br_t_tmp(1);
    % Br_t(j,:) = get_Br_time(grid2D,data2D,trange);
    plot(t,Br_t(j,:));
    j = j+1;
end
[~,idxTF40] = ismember([7:9,28:30],shotList);
[~,idxTF35] = ismember([10:12,25:27],shotList);
[~,idxTF30] = ismember([13:15,22:24],shotList);
[~,idxTF25] = ismember(16:21,shotList);

MRM40 = mean(Br_t(idxTF40,:),'omitmissing');
MRD40 = std(Br_t(idxTF40,:),'omitmissing');
MRM35 = mean(Br_t(idxTF35,:),'omitmissing');
MRD35 = std(Br_t(idxTF35,:),'omitmissing');
MRM30 = mean(Br_t(idxTF30,:),'omitmissing');
MRD30 = std(Br_t(idxTF30,:),'omitmissing');
MRM25 = mean(Br_t(idxTF25,:),'omitmissing');
MRD25 = std(Br_t(idxTF25,:),'omitmissing');
figure;
errorbar(t,MRM25,MRD25);hold on;
errorbar(t,MRM30,MRD30);
errorbar(t,MRM35,MRD35);
errorbar(t,MRM40,MRD40);
legend({'TF=2.5kV','TF=3kV','TF=3.5kV','TF=4kV'},'Location','northwest');
xlabel('Time [us]');
ax=gca;ax.FontSize=18;
ylabel('Merging ratio');


function mergingRatio = get_Br_time(grid2D,data2D,trange)
    % % trange = data2D.trange;
    % Br = data2D.Br;
    % rq = grid2D.rq;
    % zq = grid2D.zq;
    [magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D);
    % Br_t = zeros(1,20);
    mergingRatio = NaN(1,numel(trange));
    % t = 461:480;
    m = 1;
    for i = trange
        % time = trange(i);
        % [magaxis,xpoint] = get_axis_x(grid2D,data2D,time);
        magaxis.r = magAxisList.r(:,i);
        magaxis.z = magAxisList.z(:,i);
        % xpoint.r = xPointList.r(:,i);
        % xpoint.z = xPointList.z(:,i);
        % if numel(magaxis.r) == 2
        if magaxis.z(1)~=magaxis.z(2) && ~isnan(magaxis.r(1))
            mergingRatio(1,m) = xPointList.psi(i)/mean(magAxisList.psi(:,i));
        elseif ~isnan(magaxis.r(1))
            mergingRatio(1,m) = xPointList.psi(i)/mean(magAxisList.psi(:,i));
        else
            mergingRatio(1,m) = NaN;
        end
        m=m+1;
    end
end