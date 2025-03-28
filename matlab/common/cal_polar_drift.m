function [Polardata2D] = cal_polar_drift(POLAR,PCB,FIG,pathname,savename,range)

savename_polar = [pathname.mat,'/polar/',num2str(PCB.date),'_a039_',num2str(PCB.shot),'.mat'];
if exist(savename_polar,"file")
    load(savename_polar,'Polardata2D')
else
    if exist(savename.ExB,"file")
        load(savename.ExB,'ExBdata2D','newPCBdata2D')
    else
        warning([savename.ExB, 'does not exist.'])
        return
    end
    m_i = 1.67E-27*POLAR.A;%イオン質量[kg]
    q_i = 1.6E-19;%イオン電荷[C]
    z = ExBdata2D.zq(1,:);
    r = ExBdata2D.rq(:,1);
    idx_z_max = knnsearch(z',range.z_max);
    idx_z_min = knnsearch(z',range.z_min);
    idx_r_max = knnsearch(r,range.r_max);
    idx_r_min = knnsearch(r,range.r_min);
    z = z(idx_z_min:idx_z_max)';
    r = r(idx_r_min:idx_r_max);
    [Polardata2D.zq,Polardata2D.rq] = meshgrid(z,r);
    Polardata2D.trange = ExBdata2D.time(2:end-1);
    Polardata2D.Fpolar_z = zeros(size(Polardata2D.zq,1),size(Polardata2D.zq,2),size(Polardata2D.trange,1));
    Polardata2D.Fpolar_r = zeros(size(Polardata2D.zq,1),size(Polardata2D.zq,2),size(Polardata2D.trange,1));
    Polardata2D.Fpolar = zeros(size(Polardata2D.zq,1),size(Polardata2D.zq,2),size(Polardata2D.trange,1));
    Polardata2D.Vpolar_z = zeros(size(Polardata2D.zq,1),size(Polardata2D.zq,2),size(Polardata2D.trange,1));
    Polardata2D.Vpolar_r = zeros(size(Polardata2D.zq,1),size(Polardata2D.zq,2),size(Polardata2D.trange,1));
    Polardata2D.Vpolar = zeros(size(Polardata2D.zq,1),size(Polardata2D.zq,2),size(Polardata2D.trange,1));
    dt = 1E-6;
    for i_t = 1:size(Polardata2D.trange,1)
        idx_pcb_t = knnsearch(newPCBdata2D.trange',Polardata2D.trange(i_t));
        Bz = newPCBdata2D.Bz(:,:,idx_pcb_t);
        Br = newPCBdata2D.Br(:,:,idx_pcb_t);
        Bt_ext = newPCBdata2D.Bt_ext(:,:,idx_pcb_t);
        Bt = newPCBdata2D.Bt(:,:,idx_pcb_t);
        Bz = Bz(idx_r_min:idx_r_max,idx_z_min:idx_z_max);
        Br = Br(idx_r_min:idx_r_max,idx_z_min:idx_z_max);
        Bt_ext = Bt_ext(idx_r_min:idx_r_max,idx_z_min:idx_z_max);
        Bt = Bt(idx_r_min:idx_r_max,idx_z_min:idx_z_max);
        absB = sqrt(Bz.^2+Br.^2+Bt_ext.^2);
        % absB = sqrt(Bz.^2+Br.^2+Bt.^2);
        Polardata2D.Fpolar_z(:,:,i_t) = -m_i*(ExBdata2D.VExB_z(:,:,i_t+2)-ExBdata2D.VExB_z(:,:,i_t))./(2*dt);%力のz成分[N]
        Polardata2D.Fpolar_r(:,:,i_t) = -m_i*(ExBdata2D.VExB_r(:,:,i_t+2)-ExBdata2D.VExB_r(:,:,i_t))./(2*dt);%力のz成分[N]
        Polardata2D.Fpolar(:,:,i_t) = sqrt(Polardata2D.Fpolar_z(:,:,i_t).^2 + Polardata2D.Fpolar_r(:,:,i_t).^2);
        Polardata2D.Vpolar_z(:,:,i_t) = Polardata2D.Fpolar_r(:,:,i_t).*Bt_ext./(q_i*absB.^2)*1E-3;%∇Bドリフトのz成分[km/s]
        Polardata2D.Vpolar_r(:,:,i_t) = -Polardata2D.Fpolar_z(:,:,i_t).*Bt_ext./(q_i*absB.^2)*1E-3;%∇Bドリフトのr成分[km/s]
        % polardata2D.Vpolar_z(:,:,i_t) = polardata2D.Fpolar_r(:,:,i_t).*Bt./(q_i*absB.^2)*1E-3;%∇Bドリフトのz成分[km/s]
        % polardata2D.Vpolar_r(:,:,i_t) = -polardata2D.Fpolar_z(:,:,i_t).*Bt./(q_i*absB.^2)*1E-3;%∇Bドリフトのr成分[km/s]
        Polardata2D.Vpolar(:,:,i_t) = sqrt(Polardata2D.Vpolar_z(:,:,i_t).^2 + Polardata2D.Vpolar_r(:,:,i_t).^2);
    end
    Polardata2D.zq(end,:,:) = [];
    Polardata2D.zq(:,end,:) = [];
    Polardata2D.rq(end,:,:) = [];
    Polardata2D.rq(:,end,:) = [];
    Polardata2D.Fpolar_z(end,:,:) = [];
    Polardata2D.Fpolar_z(:,end,:) = [];
    Polardata2D.Fpolar_r(end,:,:) = [];
    Polardata2D.Fpolar_r(:,end,:) = [];
    Polardata2D.Fpolar(end,:,:) = [];
    Polardata2D.Fpolar(:,end,:) = [];
    Polardata2D.Vpolar_z(end,:,:) = [];
    Polardata2D.Vpolar_z(:,end,:) = [];
    Polardata2D.Vpolar_r(end,:,:) = [];
    Polardata2D.Vpolar_r(:,end,:) = [];
    Polardata2D.Vpolar(end,:,:) = [];
    Polardata2D.Vpolar(:,end,:) = [];

    save(savename_polar,'Polardata2D')
end