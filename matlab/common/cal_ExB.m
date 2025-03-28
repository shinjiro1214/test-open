function [ExBdata2D,newPCBdata2D] = cal_ExB(pathname,PCBgrid2D,PCBdata2D,ESPdata2D,ESP,PCB,trange)

%ファイル名をshot番号リストに対応して命名
savename = [pathname.mat,'/ExB/',num2str(ESP.date),'_shot'];
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
savename = [savename,'-a039_',num2str(PCB.shot(1)),'_',num2str(trange(1)),'_',num2str(trange(2)-trange(1)),'_',num2str(trange(end)),'.mat'];

if exist(savename,"file")
    load(savename,'ExBdata2D','newPCBdata2D')
else
    %磁気プローブデータを静電プローブデータのグリッドに合わせる
    newPCBdata2D=struct(...
        'psi',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'Br',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'Bz',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'Bt',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'Bt_plasma',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'Bt_ext',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'Jt',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'Et',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'absB2',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'zq',ESPdata2D.zq,...
        'rq',ESPdata2D.rq,...
        'trange',PCBdata2D.trange);
    for i=1:size(PCBdata2D.trange,2)
        newPCBdata2D.psi(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.psi(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        newPCBdata2D.Br(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.Br(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        newPCBdata2D.Bz(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.Bz(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        newPCBdata2D.Bt(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.Bt(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        newPCBdata2D.Bt_plasma(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.Bt_plasma(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        newPCBdata2D.Bt_ext(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.Bt_ext(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        newPCBdata2D.Jt(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.Jt(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        newPCBdata2D.Et(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.Et(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        newPCBdata2D.absB2(:,:,i) = newPCBdata2D.Br(:,:,i).^2 + newPCBdata2D.Bz(:,:,i).^2 + newPCBdata2D.Bt_ext(:,:,i).^2;
    end
    %ExB計算
    ExBdata2D.trange = trange;
    ExBdata2D.EdotB = zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),numel(trange));
    ExBdata2D.cosEB = zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),numel(trange));
    ExBdata2D.absE2 = zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),numel(trange));
    ExBdata2D.VExB_z = zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),numel(trange));
    ExBdata2D.VExB_r = zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),numel(trange));
    ExBdata2D.absVExB = zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),numel(trange));
    ExBdata2D.rq = ESPdata2D.rq;
    ExBdata2D.zq = ESPdata2D.zq;
    for i = 1:numel(trange)
        idx_ESP_t = knnsearch(ESPdata2D.trange',trange(i));
        idx_PCB_t = knnsearch(PCBdata2D.trange',trange(i));
        ExBdata2D.absE2(:,:,i) = squeeze(ESPdata2D.Ez(idx_ESP_t,:,:)).^2 + squeeze(ESPdata2D.Er(idx_ESP_t,:,:)).^2 + newPCBdata2D.Et(:,:,idx_PCB_t).^2;
        ExBdata2D.EdotB(:,:,i) = squeeze(ESPdata2D.Er(idx_ESP_t,:,:)).*newPCBdata2D.Br(:,:,idx_PCB_t) +...
            squeeze(ESPdata2D.Ez(idx_ESP_t,:,:)).*newPCBdata2D.Bz(:,:,idx_PCB_t) + newPCBdata2D.Et(:,:,idx_PCB_t).*newPCBdata2D.Bt_ext(:,:,idx_PCB_t);% E・B[V/m・T]
        ExBdata2D.cosEB(:,:,i) = ExBdata2D.EdotB(:,:,i)./sqrt(ExBdata2D.absE2(:,:,i))./sqrt(newPCBdata2D.absB2(:,:,idx_PCB_t));% E・B/|E||B| []
        ExBdata2D.VExB_z(:,:,i) = (squeeze(ESPdata2D.Er(idx_ESP_t,:,:)).*newPCBdata2D.Bt_ext(:,:,idx_PCB_t) -...
            newPCBdata2D.Br(:,:,idx_PCB_t).*newPCBdata2D.Et(:,:,idx_PCB_t))./newPCBdata2D.absB2(:,:,idx_PCB_t)*1e-3;  % Vz[km/s]
        ExBdata2D.VExB_r(:,:,i) = -(squeeze(ESPdata2D.Ez(idx_ESP_t,:,:)).*newPCBdata2D.Bt_ext(:,:,idx_PCB_t) -...
            newPCBdata2D.Bz(:,:,idx_PCB_t).*newPCBdata2D.Et(:,:,idx_PCB_t))./newPCBdata2D.absB2(:,:,idx_PCB_t)*1e-3; % Vr[km/s]
        ExBdata2D.absVExB(:,:,i) = sqrt(ExBdata2D.VExB_z(:,:,i).^2 + ExBdata2D.VExB_r(:,:,i).^2);% |V|[km/s]
    end
    save(savename,'ExBdata2D','newPCBdata2D')
end

end