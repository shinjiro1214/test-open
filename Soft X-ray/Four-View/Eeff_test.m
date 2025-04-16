Epara_t1 = get_Epara_time(10);Epara_t2 = get_Epara_time(11);Epara_t3 = get_Epara_time(12);Epara_t4 = get_Epara_time(25);Epara_t5 = get_Epara_time(26);Epara_t6 = get_Epara_time(27);
% Epara_t1 = get_Epara_time(7);Epara_t2 = get_Epara_time(7);Epara_t3 = get_Epara_time(9);Epara_t4 = get_Epara_time(28);Epara_t5 = get_Epara_time(29);Epara_t6 = get_Epara_time(30);
% Epara_t1 = get_Epara_time(13);Epara_t2 = get_Epara_time(14);Epara_t3 = get_Epara_time(15);Epara_t4 = get_Epara_time(22);Epara_t5 = get_Epara_time(23);Epara_t6 = get_Epara_time(24);
% Epara_t1 = get_Epara_time(16);Epara_t2 = get_Epara_time(17);Epara_t3 = get_Epara_time(18);Epara_t4 = get_Epara_time(19);Epara_t5 = get_Epara_time(20);Epara_t6 = get_Epara_time(21);
% figure;plot(t1,movmean(Epara_t1,3));hold on;plot(t2,movmean(Epara_t2,3));plot(t3,movmean(Epara_t3,3));

t = 461:480;
Epara_t = [Epara_t1;Epara_t2;Epara_t3;Epara_t4;Epara_t5;Epara_t6];
% Epara_t = [movmean(Epara_t1,3);movmean(Epara_t2,3);movmean(Epara_t3,3)];
EparaM = mean(Epara_t,'omitmissing');
EparaD = std(Epara_t,'omitmissing');
figure;errorbar(t,EparaM,EparaD,'LineWidth',3);
xlabel('time [us]');ylabel('Effective Electric field [V/m]');
ax = gca; ax.FontSize = 18;
xlim([460 475]);
% yticks([-400 -200 0]);
xticks([460 465 470 475]);


function Epara = get_Epara_time(shot)
    folderPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
    fileExtention = '.mat';
    path = [folderPath,num2str(shot,'%03i'),fileExtention];
    load(path,'data2D','grid2D');
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);

    Epara = zeros(1,20);
    % t1 = 461:480;
    m = 1;
    for i = 61:80
        Bp = sqrt(data2D.Bz(:,:,i).^2+data2D.Br(:,:,i).^2);
        [zq,rq] = meshgrid(linspace(-0.1,0.1,200),linspace(0.2,0.32,200));
        Bp_q = griddata(grid2D.zq(1,:),grid2D.rq(:,1),Bp,zq,rq);
        Bt_th_q = griddata(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bt_th(:,:,i),zq,rq);
        idxRq = knnsearch(rq(:,1),xPointList.r(i));
        idxZq = knnsearch(zq(1,:).',xPointList.z(i));
        Et_q = griddata(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Et(:,:,i),zq,rq);
        Epara_q = Et_q.*Bt_th_q./sqrt(Bt_th_q.^2+Bp_q.^2);
        Epara(m) = mean(Epara_q(max(1,idxRq-3):min(idxRq+3,numel(rq(:,1))),max(1,idxZq-3):min(numel(zq(1,:)),idxZq+3)),'all');
        m = m+1;
    end
end