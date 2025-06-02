
dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;
t = 441:480;
Br_t = zeros(numel(shotList),numel(t));
trange = t-399;
j = 1;
figure;hold on;
for i = shotList
    load([dirPath,num2str(i,'%03i'),'.mat'],'data2D','grid2D');
    Br_t(j,:) = get_Br_time(grid2D,data2D,trange);
    plot(t,Br_t(j,:));
    j = j+1;
end
[~,idxTF40] = ismember([7:9,28:30],shotList);
[~,idxTF35] = ismember([10:12,25:27],shotList);
[~,idxTF30] = ismember([13:15,22:24],shotList);
[~,idxTF25] = ismember(16:21,shotList);

BrM40 = mean(Br_t(idxTF40,:),'omitmissing');
BrD40 = std(Br_t(idxTF40,:),'omitmissing');
BrM35 = mean(Br_t(idxTF35,:),'omitmissing');
BrD35 = std(Br_t(idxTF35,:),'omitmissing');
BrM30 = mean(Br_t(idxTF30,:),'omitmissing');
BrD30 = std(Br_t(idxTF30,:),'omitmissing');
BrM25 = mean(Br_t(idxTF25,:),'omitmissing');
BrD25 = std(Br_t(idxTF25,:),'omitmissing');
figure;
errorbar(t,BrM25,BrD25);hold on;
errorbar(t,BrM30,BrD30);
errorbar(t,BrM35,BrD35);
errorbar(t,BrM40,BrD40);
legend({'TF=2.5kV','TF=3kV','TF=3.5kV','TF=4kV'});

xlabel('Time [us]');
ax=gca;ax.FontSize=18;
ylabel('Reconection magnetic field [T]');


function B_reconnection = get_Br_time(grid2D,data2D,trange)
    % trange = data2D.trange;
    Br = data2D.Br;
    rq = grid2D.rq;
    zq = grid2D.zq;
    [magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D);
    % Br_t = zeros(1,20);
    B_reconnection = NaN(1,numel(trange));
    % t = 461:480;
    m = 1;
    for i = trange
        % time = trange(i);
        % [magaxis,xpoint] = get_axis_x(grid2D,data2D,time);
        magaxis.r = magAxisList.r(:,i);
        magaxis.z = magAxisList.z(:,i);
        xpoint.r = xPointList.r(:,i);
        xpoint.z = xPointList.z(:,i);
        % if numel(magaxis.r) == 2
        if magaxis.z(1)~=magaxis.z(2) && ~isnan(magaxis.r(1))
            range_r = rq(:,1)>=min(magaxis.r)&rq(:,1)<=max(magaxis.r);
            range_z = zq(1,:)>=min(magaxis.z)&zq(1,:)<=max(magaxis.z);
            % 値の取り方は考えた方がいい、Btは理論値でもよさそう
            Br_tmp = Br(:,:,i);
            if sum(range_r) == 1
                Br_mean = Br_tmp(range_r,range_z);
            else
                Br_mean = mean(Br_tmp(range_r,range_z));
            end
            Br1 = max(Br_mean);
            Br2 = abs(min(Br_mean));
            B_reconnection(1,m) = min([Br1,Br2]);
        elseif ~isnan(magaxis.r(1))
            range = rq>=min(magaxis.r(1),xpoint.r)&rq<=max(magaxis.r(1),xpoint.r)&zq>=min(magaxis.z(1),xpoint.z)&zq<=max(magaxis.z(1),xpoint.z);
            Br_tmp = Br(:,:,i);
            B_reconnection(1,m) = mean([max(Br_tmp(range),[],'all'),abs(min(Br_tmp(range),[],"all"))]);
        else
            B_reconnection(1,m) = NaN;
        end
        m=m+1;
    end
end