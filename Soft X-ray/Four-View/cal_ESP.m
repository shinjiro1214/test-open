%%% cal & plot ExB drift velocity %%%
function ESPdata2D = cal_ESP(pathname,ESP)
n_ch = 21;%静電プローブCH数
res_ratio = 50;%静電プローブ分圧比

%ファイル名をshot番号リストに対応して命名
savename = [pathname.ESPmat,'/',num2str(ESP.date),'_shot'];
for i_shot = 1:numel(ESP.shotlist)
    if i_shot == 1
        savename =[savename,num2str(ESP.shotlist(i_shot))];
    else
        if ESP.shotlist(i_shot) == ESP.shotlist(i_shot-1)+1%連番の場合間の番号をファイル名に含まない
            if i_shot < numel(ESP.shotlist)
                if ESP.shotlist(i_shot+1) > ESP.shotlist(i_shot)+1
                    savename =[savename,'-',num2str(ESP.shotlist(i_shot))];
                end
            else
                savename =[savename,'-',num2str(ESP.shotlist(i_shot))];
            end
        else%連番でない場合ファイル名に含む
            savename =[savename,'_',num2str(ESP.shotlist(i_shot))];
        end
    end
end
savename = [savename,'_mesh',num2str(ESP.mesh),'.mat'];
if exist(savename,"file")
    load(savename,'ESPdata2D')
else
    z = linspace(-0.15,0.15,ESP.mesh);%プロットメッシュZ座標[m]
    z_probe = linspace(0.15,-0.15,21);%静電プローブ計測点Z座標[m](CH1がZ=0.15m、CH21が-0.15mであることに注意!)
    %死んだCH
    if ESP.date == 240828
        ESPdata2D.ng_ch = [14 15 16 17 18 19 20 21]; % 240828
    elseif ESP.date == 240827
        ESPdata2D.ng_ch = [4 11 12 14 15 16 17 18 19 20 21]; % 240827
    elseif ESP.date == 230830
        ESPdata2D.ng_ch = [4 6 16 21]; % 230830
    end
    z_probe(ESPdata2D.ng_ch) = [];%z_probeから死んだCHを除く
    ESPdata2D.zprobe = z_probe;
    r = linspace(min(ESP.rlist),max(ESP.rlist),ESP.mesh)*1E-3;%プロットメッシュR座標[m]
    r_probe = unique(ESP.rlist)*1E-3;%静電プローブ計測点R座標[m]
    ESPdata2D.rprobe = r_probe;

    phi = zeros(numel(ESP.trange),n_ch,numel(r_probe));
    cnt_r = zeros(numel(r_probe),1);
    %同じR座標のデータ間の平均をとる
    for i = 1:numel(ESP.shotlist)
        idx_r = find(r_probe==ESP.rlist(i)*1E-3);
        cnt_r(idx_r) = cnt_r(idx_r) + 1;
        filename = sprintf("%s%03d%s",[pathname.ESPrawdata '/' num2str(ESP.date) '/ES_' num2str(ESP.date)], ESP.shotlist(i), '.csv');
        ESPdata = readmatrix(filename,'Range',sprintf('B%d:V%d',ESP.trange(1)*10+2,ESP.trange(end)*10+2));
        phi(:,:,idx_r) = (phi(:,:,idx_r)*(cnt_r(idx_r)-1) + ESPdata)/cnt_r(idx_r);
    end
    phi(:,ESPdata2D.ng_ch,:) = [];%死んだCHを除去
    phi = phi.*res_ratio;%分圧比を掛ける

    [ESPdata2D.zq,ESPdata2D.rq] = meshgrid(z,r);
    ESP.trange(1)
    ESPdata2D.trange = ESP.trange;
    ESPdata2D.trange(1)
    ESPdata2D.phi = zeros(numel(ESP.trange),ESP.mesh,ESP.mesh);
    ESPdata2D.Ez = zeros(numel(ESP.trange),ESP.mesh,ESP.mesh);
    ESPdata2D.Er = zeros(numel(ESP.trange),ESP.mesh,ESP.mesh);
    for i = 1:numel(ESP.trange)
        ESPdata2D.phi(i,:,:) = griddata(z_probe,r_probe,squeeze(phi(i,:,:))',ESPdata2D.zq,ESPdata2D.rq);
        ESPdata2D.phi(i,:,:) = movmean(ESPdata2D.phi(i,:,:),round(ESP.mesh/7),1);%移動平均
        ESPdata2D.phi(i,:,:) = movmean(ESPdata2D.phi(i,:,:),round(ESP.mesh/7),2);%移動平均
        ESPdata2D.Ez(i,:,2:end) = -diff(squeeze(ESPdata2D.phi(i,:,:)),1,2)/(z(2)-z(1));
        ESPdata2D.Er(i,2:end,:) = -diff(squeeze(ESPdata2D.phi(i,:,:)),1,1)/(r(2)-r(1));
    end
    save(savename,'ESPdata2D')
end