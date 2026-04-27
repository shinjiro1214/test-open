function [ExBdata2D,newPCBdata2D] = cal_ExB(pathname,PCBgrid2D,PCBdata2D,ESPdata2D,ESP,PCB,FIG)

savename = [pathname.ESPmat,'/',num2str(ESP.date),'_shot',num2str(ESP.shotlist(1)),'-',num2str(ESP.shotlist(end)),'-a039_',num2str(PCB.shot(1)),'_',num2str(FIG.start),'_',num2str(FIG.dt),'_',num2str(FIG.tate*FIG.yoko),'.mat'];
if exist(savename,"file") && ESP.Reset == false
    load(savename,'ExBdata2D','newPCBdata2D')
else
    %磁気プローブデータを静電プローブデータのグリッドに合わせる
    newPCBdata2D=struct(...
        'psi',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'Br',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'Bz',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'Bt',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'Bt_ext',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'Bt_th',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'Bt_plasma',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'Jt',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'Et',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'absB2',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'dBdt_magnitude',zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),size(PCBdata2D.trange,2)),...
        'zq',ESPdata2D.zq,...
        'rq',ESPdata2D.rq,...
        'trange',PCBdata2D.trange);
    for i=1:size(PCBdata2D.trange,2)
        newPCBdata2D.psi(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.psi(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        newPCBdata2D.Br(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.Br(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        newPCBdata2D.Bz(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.Bz(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        if ESP.probe == 1
            newPCBdata2D.Bt(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.Bt_th(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        elseif ESP.probe == 2
            newPCBdata2D.Bt(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.Bt(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        end
        % newPCBdata2D.Bt_ext(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.Bt_ext(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        % newPCBdata2D.Bt_plasma(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.Bt_plasma(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        newPCBdata2D.Jt(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.Jt(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        newPCBdata2D.Et(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.Et(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        % newPCBdata2D.curvature_B_r(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.curvature_B_r(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        % newPCBdata2D.curvature_B_t(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.curvature_B_t(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        % newPCBdata2D.curvature_B_z(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.curvature_B_z(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        % newPCBdata2D.dBdt_magnitude(:,:,i) = griddata(PCBgrid2D.zq(1,:), PCBgrid2D.rq(:,1), PCBdata2D.dBdt_magnitude(:,:,i), ESPdata2D.zq, ESPdata2D.rq);
        
        
        newPCBdata2D.absB2(:,:,i) = newPCBdata2D.Br(:,:,i).^2 + newPCBdata2D.Bz(:,:,i).^2 + newPCBdata2D.Bt(:,:,i).^2;
        newPCBdata2D.absB(:,:,i) = sqrt(newPCBdata2D.Br(:,:,i).^2 + newPCBdata2D.Bz(:,:,i).^2 + newPCBdata2D.Bt(:,:,i).^2);

    end
    %ExB計算
    ExBdata2D.time = zeros(FIG.tate*FIG.yoko,1);
    ExBdata2D.VExB_z = zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),FIG.tate*FIG.yoko);
    ExBdata2D.VExB_r = zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),FIG.tate*FIG.yoko);
    ExBdata2D.VExB_t = zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),FIG.tate*FIG.yoko);
    ExBdata2D.absVExB = zeros(size(ESPdata2D.rq,1),size(ESPdata2D.rq,2),FIG.tate*FIG.yoko);
    ExBdata2D.rq = ESPdata2D.rq;
    ExBdata2D.zq = ESPdata2D.zq;
    
    for i = 1:FIG.tate*FIG.yoko
        offset_ESP_t = knnsearch(ESPdata2D.trange',FIG.start);
        idx_ESP_t = offset_ESP_t+(i-1)*FIG.dt*10;
        offset_PCB_t = knnsearch(PCBdata2D.trange',FIG.start);
        idx_PCB_t = offset_PCB_t+(i-1)*FIG.dt;
        ExBdata2D.time(i) = ESPdata2D.trange(idx_ESP_t);
        ExBdata2D.VExB_z(:,:,i) = (squeeze(ESPdata2D.Er(idx_ESP_t,:,:)).*newPCBdata2D.Bt(:,:,idx_PCB_t) - newPCBdata2D.Br(:,:,idx_PCB_t).*newPCBdata2D.Et(:,:,idx_PCB_t))./newPCBdata2D.absB2(:,:,idx_PCB_t)*1e-3;  % Vz[km/s]
        ExBdata2D.VExB_r(:,:,i) = -(squeeze(ESPdata2D.Ez(idx_ESP_t,:,:)).*newPCBdata2D.Bt(:,:,idx_PCB_t) - newPCBdata2D.Bz(:,:,idx_PCB_t).*newPCBdata2D.Et(:,:,idx_PCB_t))./newPCBdata2D.absB2(:,:,idx_PCB_t)*1e-3; % Vr[km/s]
        ExBdata2D.VExB_t(:,:,i) = (squeeze(ESPdata2D.Ez(idx_ESP_t,:,:)).*newPCBdata2D.Br(:,:,idx_PCB_t) - newPCBdata2D.Bz(:,:,idx_PCB_t).*squeeze(ESPdata2D.Er(idx_ESP_t,:,:)))./newPCBdata2D.absB2(:,:,idx_PCB_t)*1e-3;  % Vt[km/s]
        ExBdata2D.absVExB(:,:,i) = sqrt(ExBdata2D.VExB_z(:,:,i).^2 + ExBdata2D.VExB_r(:,:,i).^2);% |V|[km/s]
        
        ExBdata2D.absE(:,:,i) = sqrt(newPCBdata2D.Et(:,:,idx_PCB_t).^2+squeeze(ESPdata2D.Ez(idx_ESP_t,:,:)).^2+squeeze(ESPdata2D.Er(idx_ESP_t,:,:)).^2);


        UEr = (newPCBdata2D.Et(:,:,idx_PCB_t).*newPCBdata2D.Bz(:,:,idx_PCB_t)-squeeze(ESPdata2D.Ez(idx_ESP_t,:,:)).*newPCBdata2D.Bt(:,:,idx_PCB_t))./newPCBdata2D.absB2(:,:,idx_PCB_t);
        UEt = (squeeze(ESPdata2D.Ez(idx_ESP_t,:,:)).*newPCBdata2D.Br(:,:,idx_PCB_t)-squeeze(ESPdata2D.Er(idx_ESP_t,:,:)).*newPCBdata2D.Bz(:,:,idx_PCB_t))./newPCBdata2D.absB2(:,:,idx_PCB_t);
        UEz = (squeeze(ESPdata2D.Er(idx_ESP_t,:,:)).*newPCBdata2D.Bt(:,:,idx_PCB_t)-newPCBdata2D.Et(:,:,idx_PCB_t).*newPCBdata2D.Br(:,:,idx_PCB_t))./newPCBdata2D.absB2(:,:,idx_PCB_t);

        [lBl_z,lBl_r] = gradient(sqrt(newPCBdata2D.absB2(:,:,idx_PCB_t)), ESPdata2D.zq(1,:), ESPdata2D.rq(:,1));
        lBl_t = zeros(size(lBl_z));
        ExBdata2D.betatron(:,:,i) = UEr.*lBl_r+UEt.*lBl_t+UEz.*lBl_z + newPCBdata2D.dBdt_magnitude(:,:,idx_PCB_t);

        % ExBdata2D.fermi(:,:,i) = newPCBdata2D.curvature_B_r(:,:,idx_PCB_t).*UEr + newPCBdata2D.curvature_B_t(:,:,idx_PCB_t).*UEt + newPCBdata2D.curvature_B_z(:,:,idx_PCB_t).*UEz;

        ExBdata2D.Epara(:,:,i) = squeeze(ESPdata2D.Er(idx_ESP_t,:,:)).*newPCBdata2D.Br(:,:,idx_PCB_t)./newPCBdata2D.absB(:,:,idx_PCB_t) + newPCBdata2D.Et(:,:,idx_PCB_t).*newPCBdata2D.Bt(:,:,idx_PCB_t)./newPCBdata2D.absB(:,:,idx_PCB_t) + squeeze(ESPdata2D.Ez(idx_ESP_t,:,:)).*newPCBdata2D.Bz(:,:,idx_PCB_t)./newPCBdata2D.absB(:,:,idx_PCB_t);
    end
    save(savename,'ExBdata2D','newPCBdata2D')
end

end