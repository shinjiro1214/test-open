dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;
t = 450:500;
x_t = zeros(numel(shotList),numel(t));
trange = t-399;
j = 1;
figure;hold on;
for i = shotList
    load([dirPath,num2str(i,'%03i'),'.mat'],'data2D','grid2D');
    % x_t_tmp = get_x_time(grid2D,data2D,trange);
    % x_t(j,:) = x_t_tmp - x_t_tmp(1);
    x_t(j,:) = get_xpoint_time(grid2D,data2D,trange);
    plot(t,x_t(j,:));
    j = j+1;
end
[~,idxTF40] = ismember([7:9,28:30],shotList);
[~,idxTF35] = ismember([10:12,25:27],shotList);
[~,idxTF30] = ismember([13:15,22:24],shotList);
[~,idxTF25] = ismember(16:21,shotList);

PsiM40 = mean(x_t(idxTF40,:),'omitmissing');
PsiD40 = std(x_t(idxTF40,:),'omitmissing');
PsiM35 = mean(x_t(idxTF35,:),'omitmissing');
PsiD35 = std(x_t(idxTF35,:),'omitmissing');
PsiM30 = mean(x_t(idxTF30,:),'omitmissing');
PsiD30 = std(x_t(idxTF30,:),'omitmissing');
PsiM25 = mean(x_t(idxTF25,:),'omitmissing');
PsiD25 = std(x_t(idxTF25,:),'omitmissing');
figure;
errorbar(t,PsiM25,PsiD25);hold on;
errorbar(t,PsiM30,PsiD30);
errorbar(t,PsiM35,PsiD35);
errorbar(t,PsiM40,PsiD40);
legend({'TF=2.5kV','TF=3kV','TF=3.5kV','TF=4kV'});
xlabel('Time [us]');
ax=gca;ax.FontSize=18;
ylabel('X-point position [mm]');


function x_t = get_xpoint_time(grid2D,data2D,trange)
    % % trange = data2D.trange;
    % Br = data2D.Br;
    % rq = grid2D.rq;
    % zq = grid2D.zq;
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    % x_t = zeros(1,20);
    x_t = NaN(1,numel(trange));
    % t = 461:480;
    m = 1;
    for i = trange
        % time = trange(i);
        % [magaxis,xpoint] = get_axis_x(grid2D,data2D,time);
        % magaxis.r = magAxisList.r(:,i);
        % magaxis.z = magAxisList.z(:,i);
        x_t(m) = 1000 * xPointList.r(:,i);
        % xpoint.z = xPointList.z(:,i);
        % if numel(magaxis.r) == 2
        % if ~isnan(xpoint.r)
        %     x_t(1,m) = xPointList.psi(i);
        % else
        %     x_t(1,m) = NaN;
        % end
        m=m+1;
    end
end