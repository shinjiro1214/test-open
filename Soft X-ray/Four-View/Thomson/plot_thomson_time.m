addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View'

thomsonShotList = [14,15,16,17,19,21];
% magShotList = [20,26,27,37,38,46];
magShotList = 38;
thomsonTimeList = [465,466,467,468,469,470];

ne_t = nan(numel(thomsonTimeList),1);
Te_t = nan(numel(thomsonTimeList),1);
i=1;
for time = thomsonTimeList
    thomsonIdx = thomsonShotList(thomsonTimeList==time);
    thomsonPath = ['/Users/shinjirotakeda/Downloads/ThomsonData/241228',num2str(thomsonIdx,'%03i'),'-241228008_CIntvl_CDur_allfiber_TeNePe.csv'];
    T = readmatrix(thomsonPath);
    r = reshape(T(:,2),7,[]);
    z = reshape(T(:,3),7,[]);
    Te_mat = reshape(T(:,4),7,[]);
    ne_mat = reshape(T(:,6),7,[]);

    SD_Te_mat = reshape(T(:,5),7,[]);
    Te_mat(Te_mat<SD_Te_mat) = NaN;
    SD_ne_mat = reshape(T(:,7),7,[]);
    ne_mat(ne_mat<SD_ne_mat) = NaN;

    % figure;contourf(z,r,Te_mat,linspace(0,10,10),'LineStyle','none');

    % 内挿（NaNが多いのでやらない方が良さげ）
    T(T(:,4)<T(:,5),2:4) = 0;
    % F = scatteredInterpolant(T(:,3),T(:,2),T(:,4));
    [rq,zq] = meshgrid(linspace(0.125,0.302,40),linspace(-0.078,0.078,40));
    % Te_q = F(zq,rq);
    Te_q = interp2(r,z,Te_mat,rq,zq);
    ne_q = interp2(r,z,ne_mat,rq,zq);
    % figure;contourf(zq,rq,Te_q,linspace(0,10,10));
    % figure;contourf(zq,rq,ne_q,linspace(0,5e20,10));


    % 磁場からX点座標を取得
    folderPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/241228';
    fileExtention = '.mat';
    % magIdx = magShotList(thomsonTimeList==time);
    magIdx = magShotList;
    path = [folderPath,num2str(magIdx,'%03i'),fileExtention];
    load(path,'data2D','grid2D');
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    % hold on;plot(xPointList.z(time-400),xPointList.r(time-400),'kx');
    % 最も近い点（上下左右で4点？）を検索
    z=zq;r=rq;Te_mat=Te_q;ne_mat=ne_q;
    timeIndex=time-400;
    z_idx = find(z(:,1)<=xPointList.z(timeIndex),1,'last');
    r_idx = find(r(1,:)<=xPointList.r(timeIndex),1,'last');
    % その点の平均値を取得
    if r_idx == numel(r(1,:))
        % Te_x = mean([Te_mat([z_idx,z_idx+1],r_idx)],'omitnan');
        % ne_x = mean([ne_mat([z_idx,z_idx+1],r_idx)],'omitnan');
        Te_x = mean([Te_mat(z_idx-1:z_idx+1,r_idx)],'omitnan');
        ne_x = mean([ne_mat(z_idx-1:z_idx+1,r_idx)],'omitnan');
    else
        Te_x = mean([Te_mat([z_idx,z_idx+1],[r_idx,r_idx+1])],'all','omitnan');
        ne_x = mean([ne_mat([z_idx,z_idx+1],[r_idx,r_idx+1])],'all','omitnan');
    end
    % disp(Te_x);
    ne_t(i)=ne_x;
    Te_t(i)=Te_x;
    i=i+1;
end

figure;plot(thomsonTimeList,ne_t);title('Density');
figure;plot(thomsonTimeList,Te_t);title('Temperature');