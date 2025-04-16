GFR_t1 = get_GFR_time(28);GFR_t2 = get_GFR_time(29);GFR_t3 = get_GFR_time(30);
figure;plot(t1,GFR_t1);hold on;plot(t2,GFR_t2);plot(t3,GFR_t3);

GFR_t = [GFR_t1;GFR_t2;GFR_t3];
GFRM = mean(GFR_t,'omitmissing');
GFRD = std(GFR_t,'omitmissing');
figure;errorbar(t1,GFRM,GFRD,'LineWidth',3);
xlabel('time [us]');ylabel('GFR');
ax = gca; ax.FontSize = 18;
xlim([460 470]);
% yticks([-400 -200 0]);
xticks([460 465 470]);

function GFR_t = get_GFR_time(shot)
    folderPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
    fileExtention = '.mat';
    path = [folderPath,num2str(shot,'%03i'),fileExtention];
    load(path,'data2D','grid2D');
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);

    GFR_t = zeros(1,20);
    % t1 = 461:480;
    m = 1;
    for i = 61:80
        Bp = sqrt(data2D.Bz(:,:,i).^2+data2D.Br(:,:,i).^2);
        [zq,rq] = meshgrid(linspace(-0.1,0.1,200),linspace(0.2,0.32,200));
        Bp_q = griddata(grid2D.zq(1,:),grid2D.rq(:,1),Bp,zq,rq);
        Bt_th_q = griddata(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bt_th(:,:,i),zq,rq);
        GFR = Bt_th_q./Bp_q;
        idxRq = knnsearch(rq(:,1),xPointList.r(i));
        idxZq = knnsearch(zq(1,:).',xPointList.z(i));
        GFR_t(m) = min(GFR(max(1,idxRq-3):min(idxRq+3,numel(rq(:,1))),max(1,idxZq-3):min(numel(zq(1,:)),idxZq+3)),[],'all');
        m = m+1;
    end
end