dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;
t = 460:500;
psi_t = zeros(numel(shotList),numel(t));
trange = t-399;
j = 1;
figure;hold on;
for i = shotList
    load([dirPath,num2str(i,'%03i'),'.mat'],'data2D','grid2D');
    % psi_t_tmp = get_psi_time(grid2D,data2D,trange);
    % psi_t(j,:) = psi_t_tmp - psi_t_tmp(1);
    psi_t(j,:) = get_psi_time(grid2D,data2D,trange);
    plot(t,psi_t(j,:));
    j = j+1;
end
[~,idxTF40] = ismember([7:9,28:30],shotList);
[~,idxTF35] = ismember([10:12,25:27],shotList);
[~,idxTF30] = ismember([13:15,22:24],shotList);
[~,idxTF25] = ismember(16:21,shotList);

PsiM40 = mean(psi_t(idxTF40,:),'omitmissing');
PsiD40 = std(psi_t(idxTF40,:),'omitmissing');
PsiM35 = mean(psi_t(idxTF35,:),'omitmissing');
PsiD35 = std(psi_t(idxTF35,:),'omitmissing');
PsiM30 = mean(psi_t(idxTF30,:),'omitmissing');
PsiD30 = std(psi_t(idxTF30,:),'omitmissing');
PsiM25 = mean(psi_t(idxTF25,:),'omitmissing');
PsiD25 = std(psi_t(idxTF25,:),'omitmissing');
figure;
errorbar(t,PsiM25,PsiD25);hold on;
errorbar(t,PsiM30,PsiD30);
errorbar(t,PsiM35,PsiD35);
errorbar(t,PsiM40,PsiD40);
legend({'TF=2.5kV','TF=3kV','TF=3.5kV','TF=4kV'});
xlabel('Time [us]');
ax=gca;ax.FontSize=18;
ylabel('Pribate flux [wb]');


function psi_t = get_psi_time(grid2D,data2D,trange)
    % % trange = data2D.trange;
    % Br = data2D.Br;
    % rq = grid2D.rq;
    % zq = grid2D.zq;
    [magAxisList,~] = get_axis_x_multi(grid2D,data2D);
    % psi_t = zeros(1,20);
    psi_t = NaN(1,numel(trange));
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
            psi_t(1,m) = mean(magAxisList.psi(:,i));
        elseif ~isnan(magaxis.r(1))
            psi_t(1,m) = mean(magAxisList.psi(:,i));
        else
            psi_t(1,m) = NaN;
        end
        m=m+1;
    end
end