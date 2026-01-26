% function [grid2D,data2D] = process_PCBdata_280ch(date, shot, tfshot, pathname, n,i_EF,trange)
function [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname)
    
addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/pcb_experiment'
date = PCB.date;
shot = PCB.shot;
tfshot = PCB.tfshot;
n = PCB.n;
i_EF = PCB.i_EF;
trange = PCB.trange;
idx = PCB.idx;

% idx = convert_shot_number(PCB);

% filename = strcat(pathname.pre_processed_directory,'/a039_',num2str(shot(1)),'.mat');
filename = strcat(pathname.pre_processed_directory,'/',num2str(PCB.date),sprintf('%03d',idx),'.mat');
if exist(filename,'file') == 0 || PCB.doOverwrite
    doCalculation = true;
    % disp('no processed data -- start calculation');
    disp('processing data');
else
    doCalculation = false;
    disp('loading processed data');
end


if doCalculation
    %較正係数のバージョンを日付で判別
    sheets = sheetnames('coeff200ch.xlsx');
    sheets = str2double(sheets);
    sheet_date=max(sheets(sheets<=date));
    C = readmatrix('coeff200ch.xlsx','Sheet',num2str(sheet_date));
    r_shift = 0.00;
    ok = logical(C(:,14));
    dtacq_num_list = C(:,1);
    dtaq_ch = C(:,2);
    polarity=C(:,13);
    coeff=C(:,12);
    zpos=C(:,9);
    rpos=C(:,10)+r_shift;
    ch=C(:,7);
    
    if ismember(39,dtacq_num_list)
        % filename1 = strcat(pathname.rawdata,'/rawdata_dtacq',num2str(39),'_shot',num2str(shot(1)),'_tfshot',num2str(tfshot(1)),'.mat');
        filename1 = strcat(pathname.rawdata,'/mag_probe/dtacq',num2str(39),'/shot',num2str(shot(1)),'_tfshot',num2str(tfshot(1)),'.mat');
        if exist(filename1,"file")==0
            disp('No rawdata file of a039 -- Start generating!')
            % rawdataPath = pathname.rawdata;
            % save_dtacq_data(39, shot(1), tfshot(1),rawdataPath)
            save_dtacq_data(39, shot(1), tfshot(1),filename1)
            % disp(['File:',filename1,' does not exit']);
            % return
        end
        load(filename1,"rawdata_wTF","rawdata_woTF");
        a039_raw = rawdata_woTF;
        a039_raw_wTF = rawdata_wTF;
        % a039_raw = importdata(filename1);
    end
    if ismember(40,dtacq_num_list)
        % filename2 = strcat(pathname.rawdata,'/rawdata_dtacq',num2str(40),'_shot',num2str(shot(2)),'_tfshot',num2str(tfshot(2)),'.mat');
        filename2 = strcat(pathname.rawdata,'/mag_probe/dtacq',num2str(40),'/shot',num2str(shot(2)),'_tfshot',num2str(tfshot(2)),'.mat');
        if exist(filename2,"file")==0
            disp('No rawdata file of a040 -- Start generating!')
            % rawdataPath = pathname.rawdata;
            % save_dtacq_data(40, shot(2), tfshot(2),rawdataPath)
            save_dtacq_data(40, shot(2), tfshot(2),filename2)
            % disp(['File:',filename2,' does not exit']);
            % return
        end
        % a040_raw = importdata(filename2);
        load(filename2,"rawdata_wTF","rawdata_woTF");
        a040_raw = rawdata_woTF;
        a040_raw_wTF = rawdata_wTF;
    end
    
    raw = zeros(1000,length(dtaq_ch));
    raw_TF = zeros(1000,length(dtaq_ch));
    for i = 1:length(dtaq_ch)
        if dtacq_num_list(i) == 39
            raw(:,i) = a039_raw(:,dtaq_ch(i));
            raw_TF(:,i) = a039_raw_wTF(:,dtaq_ch(i));
        elseif dtacq_num_list(i) == 40
            raw(:,i) = a040_raw(:,dtaq_ch(i));
            raw_TF(:,i) = a040_raw_wTF(:,dtaq_ch(i));
        end
    end
    
    b=raw.*coeff';%較正係数RC/NS
    b=b.*polarity';%極性揃え

    b_TF=raw_TF.*coeff';%較正係数RC/NS
    b_TF=b_TF.*polarity';%極性揃え
    
    %デジタイザchからプローブ通し番号順への変換
    bz=zeros(1000,100);
    bt=bz;
    ok_bz=false(100,1);
    ok_bt=ok_bz;
    zpos_bz=zeros(100,1);
    rpos_bz=zpos_bz;
    zpos_bt=zpos_bz;
    rpos_bt=zpos_bz;
    
    %digital filter
    windowSize = 8;
    % windowSize = 3;
    bb = (1/windowSize)*ones(1,windowSize);
    aa = 1;
    
    for i=1:length(ch)
        b(:,i) = filter(bb,aa,b(:,i));
        b(:,i) = b(:,i) - mean(b(1:40,i));
        % b(:,i) = b(:,i) - mean(b(580:600,i));
        % b(:,i) = b(:,i) - mean(b(780:800,i));
        b_TF(:,i) = filter(bb,aa,b_TF(:,i));
        b_TF(:,i) = b_TF(:,i) - mean(b_TF(1:40,i));
        % b_TF(:,i) = b_TF(:,i) - mean(b_TF(780:800,i));
        if rem(ch(i),2)==1
            bz(:,ceil(ch(i)/2))=b(:,i);
            ok_bz(ceil(ch(i)/2))=ok(i);
            zpos_bz(ceil(ch(i)/2))=zpos(i);
            rpos_bz(ceil(ch(i)/2))=rpos(i);
        elseif rem(ch(i),2)==0
            % bt(:,ch(i)/2)=b(:,i);
            bt(:,ch(i)/2)=b_TF(:,i);
            ok_bt(ceil(ch(i)/2))=ok(i);
            zpos_bt(ceil(ch(i)/2))=zpos(i);
            rpos_bt(ceil(ch(i)/2))=rpos(i);
        end
    end
    
    % zprobepcb    = [-0.17 -0.1275 -0.0850 -0.0315 -0.0105 0.0105 0.0315 0.0850 0.1275 0.17];
    zprobepcb    = [-0.2975,-0.255,-0.17 -0.1275 -0.0850 -0.0315 -0.0105 0.0105 0.0315 0.0850 0.1275 0.17,0.255,0.2975];
    rprobepcb    = [0.06,0.09,0.12,0.15,0.18,0.21,0.24,0.27,0.30,0.33]+r_shift;
    rprobepcb_t  = [0.07,0.10,0.13,0.16,0.19,0.22,0.25,0.28,0.31,0.34]+r_shift;
    [zq,rq]      = meshgrid(linspace(min(zpos_bz),max(zpos_bz),n),linspace(min(rpos_bz),max(rpos_bz),n));
    % [zq,rq]      = meshgrid(zprobepcb,rprobepcb);
    [zq_probepcb,rq_probepcb]=meshgrid(zprobepcb,rprobepcb);
    ok_bt_matrix = false(length(rprobepcb),length(zprobepcb));
    ok_bz_matrix = false(length(rprobepcb),length(zprobepcb));
    for i = 1:length(ok_bt)
        if rpos_bt(i) > (r_shift)
            index_r = (abs(rpos_bt(i)-rprobepcb_t)<0.001);index_z = (zpos_bt(i)==zprobepcb);
            ok_bt_matrix = ok_bt_matrix + rot90(index_r,-1)*index_z*ok_bt(i);
        end
        index_r = (abs(rpos_bz(i)-rprobepcb)<0.001);index_z = (zpos_bz(i)==zprobepcb);
        ok_bz_matrix = ok_bz_matrix + rot90(index_r,-1)*index_z*ok_bz(i);
    end
    
    grid2D=struct(...
        'zq',zq,...
        'rq',rq,...
        'zprobepcb',zprobepcb,...
        'rprobepcb',rprobepcb,...
        'rprobepcb_t',rprobepcb_t,...1
        'ok_bz_matrix',ok_bz_matrix,...
        'ok_bt_matrix',ok_bt_matrix);
    grid2D_probe = struct('zq',zq_probepcb,'rq',rq_probepcb,'rq_t',rprobepcb_t);
    
    clear zq rq zprobepcb rprobepcb zq_probepcb rq_probepcb rprobepcb_t ok_bz_matrix ok_bt_matrix
    
    % probecheck_script;
    
    %data2Dcalc.m
    r_EF   = 0.5 ;
    n_EF   = 234. ;
    
    if date<221119
        z1_EF   = 0.68;
        z2_EF   = -0.68;
    else
        z1_EF   = 0.78;
        z2_EF   = -0.78;
    end
    [Bz_EF,~] = B_EF(z1_EF,z2_EF,r_EF,i_EF,n_EF,grid2D.rq,grid2D.zq,false);
    clear EF r_EF n_EF i_EF z_EF
    
    data2D=struct(...
        'psi',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Bz',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Bt',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Br',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Jt',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Jz',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Jr',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Et',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Lambda',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'trange',trange);
    
    if isfield(pathname,'fourier')
        directory_rogo = strcat(pathname.fourier,'rogowski/');
        current_folder = strcat(directory_rogo,num2str(date),'/');
        rgwfile = strcat(current_folder,num2str(date),sprintf('%03d',PCB.idx),'.rgw');
        if isfile(rgwfile)
            [I_TF,x,aquisition_rate] = get_TF_current(PCB,pathname);
            m0 = 4*pi*10^(-7);
            rgwflag = true;
        else
            disp(strcat('No rgw file at shot ',num2str(PCB.idx)));
            rgwflag = false;
        end
    else
        disp('Path to fourier does not exist');
        rgwflag = false;
    end

    % ******************* no angle correction ********************
    for i=1:size(trange,2)
        t=trange(i);
    
        %Bzの二次元補間(線形fit)
        vq = bz_rbfinterp(rpos_bz, zpos_bz, grid2D, bz, ok_bz, t);
        B_z = -Bz_EF+vq;
        B_t = bz_rbfinterp(rpos_bt, zpos_bt, grid2D, bt, ok_bt, t);
    
        % PSI計算
        data2D.psi(:,:,i) = cumtrapz(grid2D.rq(:,1),2*pi*B_z.*grid2D.rq(:,1),1);
        % data2D.psi(:,:,i) = flip(get_psi(flip(B_z,1),flip(grid2D.rq(:,1)),1),1);
        % このままだと1/2πrが計算されてないので
        [data2D.Br(:,:,i),data2D.Bz(:,:,i)]=gradient(data2D.psi(:,:,i),grid2D.zq(1,:),grid2D.rq(:,1)) ;
        data2D.Br(:,:,i)=-data2D.Br(:,:,i)./(2.*pi.*grid2D.rq);
        data2D.Bz(:,:,i)=data2D.Bz(:,:,i)./(2.*pi.*grid2D.rq);
        data2D.Bt(:,:,i)=B_t;%*1.2
        data2D.Jt(:,:,i)= curl(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bz(:,:,i),data2D.Br(:,:,i))./(4*pi*1e-7);
        [~,drBt_dr] = gradient(1.2*data2D.Bt(:,:,i).*grid2D.rq,grid2D.zq(1,:),grid2D.rq(:,1));
        data2D.Jz(:,:,i) = drBt_dr./(4*pi*1e-7.*grid2D.rq);

        if rgwflag
            timing = x/aquisition_rate==t;
            data2D.Bt_th(:,:,i) = m0*I_TF(timing)*1e3*12./(2*pi()*grid2D.rq);
        end

        if i>1
            data2D.Et(:,:,i) = -1*(data2D.psi(:,:,i)-data2D.psi(:,:,i-1))./(2*pi()*grid2D.rq)*1e+6;
        end
    end
else
    load(filename,'data2D','grid2D');
end

if doCalculation
    clearvars -except data2D grid2D shot pathname filename;
    % filename = strcat(pathname.pre_processed_directory,'/a039_',num2str(shot(1)),'.mat');
    save(filename)
end

end