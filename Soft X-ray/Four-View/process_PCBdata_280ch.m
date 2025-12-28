% function [grid2D,data2D] = process_PCBdata_280ch(date, shot, tfshot, pathname, n,i_EF,trange)
function [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname)
date = PCB.date;
shot = PCB.shot;
tfshot = PCB.tfshot;
n = PCB.n;
i_EF = PCB.i_EF;
trange = PCB.trange;
idx = PCB.idx;

% idx = convert_shot_number(PCB);

% filename = strcat(pathname.pre_processed_directory,'/a039_',num2str(shot(1)),'.mat');
filename = strcat(pathname.pre_processed_directory_path,'/',num2str(PCB.date),sprintf('%03d',idx),'.mat');
if exist(filename, 'file') == 0 || any(PCB.restart == 1)
    doCalculation = true;
    disp('no processed data -- start calculation');
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
    
    % ダウンロードが必要かチェックし、必要ならコマンドを発行（待機しない）
    files_to_wait = {}; % 待ちリスト
    
    % --- a039 の確認とバックグラウンド実行 ---
    if ismember(39, dtacq_num_list)
        filename1 = strcat(pathname.rawdata,'/mag_probe/dtacq39/shot',num2str(shot(1)),'_tfshot',num2str(tfshot(1)),'.mat');
        if exist(filename1,"file")==0
            disp('Requesting rawdata for a039 (Background)...')
            % 第5引数に true を追加して「並列モード」にする
            save_dtacq_data(39, shot(1), tfshot(1), filename1, true); 
            files_to_wait{end+1} = filename1;
        else
            % すでにロード可能ならロードしておく（あるいは後でまとめてロード）
        end
    end

    % --- a040 の確認とバックグラウンド実行 ---
    if ismember(40, dtacq_num_list)
        filename2 = strcat(pathname.rawdata,'/mag_probe/dtacq40/shot',num2str(shot(2)),'_tfshot',num2str(tfshot(2)),'.mat');
        if exist(filename2,"file")==0
            disp('Requesting rawdata for a040 (Background)...')
            save_dtacq_data(40, shot(2), tfshot(2), filename2, true);
            files_to_wait{end+1} = filename2;
        end
    end
    
    % --- 全ファイルの生成待ち ---
    if ~isempty(files_to_wait)
        disp('Waiting for Python downloads to finish...');
        max_wait = 20; % 最大待機時間(秒)
        tic;
        while true
            all_exist = true;
            for k = 1:length(files_to_wait)
                if exist(files_to_wait{k}, 'file') == 0
                    all_exist = false;
                    break;
                end
            end
            if all_exist, break; end
            if toc > max_wait, error('Python download timeout.'); end
            pause(0.1); % 0.1秒待機して再確認
        end
        disp('All data downloaded.');
    end
    
    if ismember(39, dtacq_num_list)
        % もし filename1 が未定義なら再定義（通常は上のif文を通るので大丈夫ですが安全のため）
        if isempty(filename1)
            filename1 = strcat(pathname.rawdata,'/mag_probe/dtacq39/shot',num2str(shot(1)),'_tfshot',num2str(tfshot(1)),'.mat');
        end
        load(filename1, "rawdata_woTF");
        a039_raw = rawdata_woTF;
    end
    
    if ismember(40, dtacq_num_list)
        if isempty(filename2)
            filename2 = strcat(pathname.rawdata,'/mag_probe/dtacq40/shot',num2str(shot(2)),'_tfshot',num2str(tfshot(2)),'.mat');
        end
        load(filename2, "rawdata_woTF");
        a040_raw = rawdata_woTF;
    end

    raw = zeros(1000,length(dtaq_ch));
    for i = 1:length(dtaq_ch)
        if dtacq_num_list(i) == 39
            raw(:,i) = a039_raw(:,dtaq_ch(i));
        elseif dtacq_num_list(i) == 40
            raw(:,i) = a040_raw(:,dtaq_ch(i));
        end
    end
    
    b=raw.*coeff';%較正係数RC/NS
    b=b.*polarity';%極性揃え
    
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
    bb = (1/windowSize)*ones(1,windowSize);
    aa = 1;
    
    for i=1:length(ch)
        b(:,i) = filter(bb,aa,b(:,i));
        
        if PCB.date >= 241110 && PCB.date <= 250118
            b(:,i) = b(:,i) - mean(b(580:600,i));
        end

        if rem(ch(i),2)==1
            bz(:,ceil(ch(i)/2))=b(:,i);
            ok_bz(ceil(ch(i)/2))=ok(i);
            zpos_bz(ceil(ch(i)/2))=zpos(i);
            rpos_bz(ceil(ch(i)/2))=rpos(i);
        elseif rem(ch(i),2)==0
            bt(:,ch(i)/2)=b(:,i);
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
        'Bt_th',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Br',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Bl',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Jt',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Et',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Lambda',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'dBzdt', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'dBtdt', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'dBrdt', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'dBdt_magnitude', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'B_parallel', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'dB_parallel_dt', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'curvature_B_r', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'curvature_B_t', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'curvature_B_z', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'curvature', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'jxB', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'Lamor', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'gradB_r', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ... % 追加
        'gradB_z', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ... % 追加
        'gradB', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...   % 追加 (大きさ)
        'trange',trange);

    % rgwflag = false;
    if isfield(pathname,'fourier')
        directory_rogo = strcat(pathname.fourier,'/rogowski/');
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
    % --- Bz用の準備 ---
    valid_idx_bz = find(ok_bz); 
    % 【修正1】 bz(時間, チャンネル) の順でアクセスし、転置(')して列ベクトルにする
    t_init = trange(1); % 最初の時間を初期化に使う
    F_bz = scatteredInterpolant(...
        rpos_bz(valid_idx_bz), ...
        zpos_bz(valid_idx_bz), ...
        double(bz(t_init, valid_idx_bz))', ... % ここを修正: (行, 列)の順
        'natural', 'nearest'); 

    % --- Bt用の準備 ---
    valid_idx_bt = find(ok_bt);
    % 【修正1】 Btも同様に修正
    F_bt = scatteredInterpolant(...
        rpos_bt(valid_idx_bt), ...
        zpos_bt(valid_idx_bt), ...
        double(bt(t_init, valid_idx_bt))', ... % ここを修正
        'natural', 'nearest'); 


    % ==========================================================
    % 時間ループ
    % ==========================================================
    for i = 1:size(trange, 2)
        t = trange(i); % 行番号（時間インデックス）

        % --- Bz の高速補完 ---
        F_bz.Values = double(bz(t, valid_idx_bz))'; 
        vq_bz = F_bz(grid2D.rq, grid2D.zq);
        
        % 【追加】 スムージング処理
        % sigma の値を大きくするとより滑らかになります。
        % まずは 1.0 ～ 2.0 程度で試してみてください。
        smooth_sigma = 1.5; 
        vq_bz = imgaussfilt(vq_bz, smooth_sigma);
        
        B_z = -Bz_EF + vq_bz;


        % --- Bt の高速補完 ---
        F_bt.Values = double(bt(t, valid_idx_bt))'; 
        vq_bt = F_bt(grid2D.rq, grid2D.zq);
        
        % 【追加】 スムージング処理 (Btも同様に)
        vq_bt = imgaussfilt(vq_bt, smooth_sigma); 

        B_t = vq_bt;
    
        % PSI計算
        data2D.psi(:,:,i) = cumtrapz(grid2D.rq(:,1),2*pi*B_z.*grid2D.rq(:,1),1);
        % data2D.psi(:,:,i) = flip(get_psi(flip(B_z,1),flip(grid2D.rq(:,1)),1),1);
        % このままだと1/2πrが計算されてないので
        [data2D.Br(:,:,i),data2D.Bz(:,:,i)]=gradient(data2D.psi(:,:,i),grid2D.zq(1,:),grid2D.rq(:,1)) ;
        data2D.Br(:,:,i)=-data2D.Br(:,:,i)./(2.*pi.*grid2D.rq);
        data2D.Bz(:,:,i)=data2D.Bz(:,:,i)./(2.*pi.*grid2D.rq);
        data2D.Bt(:,:,i)=B_t;
        data2D.Bl(:,:,i)=sqrt(data2D.Bz(:,:,i).^2+data2D.Br(:,:,i).^2+data2D.Bt(:,:,i).^2);

        
        [gradB_z_temp, gradB_r_temp] = gradient(data2D.Bl(:,:,i), grid2D.zq(1,:), grid2D.rq(:,1));
        data2D.gradB_r(:,:,i) = gradB_r_temp;
        data2D.gradB_z(:,:,i) = gradB_z_temp;
        data2D.gradB(:,:,i)   = sqrt(gradB_r_temp.^2 + gradB_z_temp.^2); % 大きさ


        data2D.Jt(:,:,i)= curl(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bz(:,:,i),data2D.Br(:,:,i))./(4*pi*1e-7);
        [curlt,~]               = curl(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bz(:,:,i),data2D.Br(:,:,i));
        data2D.Jt(:,:,i)        = curlt/(4*pi*1e-7);
        [~,dRBt_dR]             = gradient(grid2D.rq.*data2D.Bt(:,:,i),grid2D.zq(1,:),grid2D.rq(:,1));
        [dBt_dZ,~]              = gradient(data2D.Bt(:,:,i),grid2D.zq(1,:),grid2D.rq(:,1));
        data2D.Jz(:,:,i)        = 1./grid2D.rq.*dRBt_dR./(4*pi*1e-7);
        data2D.Jr(:,:,i)        = -dBt_dZ./(4*pi*1e-7);

        if rgwflag
            timing = x/aquisition_rate==t;
            data2D.Bt_th(:,:,i) = m0*I_TF(timing)*1e3*12./(2*pi()*grid2D.rq);
        end
        
        % 磁力線方向の単位ベクトル
        e_parallel_r = data2D.Br(:,:,i) ./ data2D.Bl(:,:,i);
        e_parallel_z = data2D.Bz(:,:,i) ./ data2D.Bl(:,:,i);
        e_parallel_t = data2D.Bt(:,:,i) ./ data2D.Bl(:,:,i);
        data2D.B_parallel(:,:,i) = data2D.Br(:,:,i).*e_parallel_r + ...
                           data2D.Bz(:,:,i).*e_parallel_z + ...
                           data2D.Bt(:,:,i).*e_parallel_t;

        
        if i>1
            data2D.Et(:,:,i) = -1*(data2D.psi(:,:,i)-data2D.psi(:,:,i-1))./(2*pi()*grid2D.rq);
            
            dt = (trange(i) - trange(i-1))*1e-6; % 時間ステップ
            data2D.Et(:,:,i) = data2D.Et(:,:,i)/dt;

            data2D.dBzdt(:,:,i) = (data2D.Bz(:,:,i) - data2D.Bz(:,:,i-1)) / dt;
            data2D.dBtdt(:,:,i) = (data2D.Bt(:,:,i) - data2D.Bt(:,:,i-1)) / dt;
            data2D.dBrdt(:,:,i) = (data2D.Br(:,:,i) - data2D.Br(:,:,i-1)) / dt;

            data2D.dBdt_magnitude(:,:,i) = sqrt(...
                data2D.dBzdt(:,:,i).^2 + ...
                data2D.dBtdt(:,:,i).^2 + ...
                data2D.dBrdt(:,:,i).^2);
            data2D.dB_parallel_dt(:,:,i) = (data2D.B_parallel(:,:,i) - data2D.B_parallel(:,:,i-1)) / dt;
        end

        [Br_z, Br_r] = gradient(data2D.Br(:,:,i), grid2D.zq(1,:), grid2D.rq(:,1));
        [Bz_z, Bz_r] = gradient(data2D.Bz(:,:,i), grid2D.zq(1,:), grid2D.rq(:,1));
        [Bt_z, Bt_r] = gradient(data2D.Bt(:,:,i), grid2D.zq(1,:), grid2D.rq(:,1));
        e_Br_r = Br_r ./ data2D.Bl(:,:,i);
        e_Br_z = Br_z ./ data2D.Bl(:,:,i);
        e_Bz_z = Bz_z ./ data2D.Bl(:,:,i);
        e_Bz_r = Bz_r ./ data2D.Bl(:,:,i);
        e_Bt_z = Bt_z ./ data2D.Bl(:,:,i);
        e_Bt_r = Bt_r ./ data2D.Bl(:,:,i);
        
        curvature_B_r = e_Br_r .* e_parallel_r + e_Bt_r .* e_parallel_t + e_Bz_r .* e_parallel_z; % 
        curvature_B_t = zeros(size(curvature_B_r));
        curvature_B_z = e_Br_z .* e_parallel_r + e_Bt_z .* e_parallel_t + e_Bz_z .* e_parallel_z;
        
        data2D.curvature_B_r(:,:,i) = curvature_B_r;
        data2D.curvature_B_t(:,:,i) = curvature_B_t;
        data2D.curvature_B_z(:,:,i) = curvature_B_z;
        data2D.curvature(:,:,i) = sqrt(curvature_B_r.^2+curvature_B_t.^2+curvature_B_z.^2);
        
        me = 9.11e-31; %電子質量
        v_pe = 1e6; %垂直速度仮定 この時3eV。1e5m/sの時は0.03eV。1e7の時は300eV。
        q = 1.6e-19; %電子素量
        data2D.Lamor(:,:,i) = me*v_pe/q./data2D.Bl(:,:,i);

        data2D.JxBr(:,:,i) = data2D.Jt(:,:,i).*data2D.Bz(:,:,i)-data2D.Jz(:,:,i).*data2D.Bt(:,:,i);
        
        % data2D.absJxB(:,:,i) = sqrt(data2D.JxBr(:,:,i).^2+data2D.JxBt(:,:,i).^2+data2D.JxBz(:,:,i).^2);
        
        %まだ試行錯誤中
        % [B_r, B_z] = gradient(data2D.Bl(:,:,i), grid2D.zq(1,:), grid2D.rq(:,1));

        % data2D.Vcurvature(:,:,i) = cross([data2D.Br(:,:,i) data2D.Bt(:,:,i) data2D.Bz(:,:,i)],[data2D.curvature_B_r(:,:,i) data2D.curvature_B_t(:,:,i) data2D.curvature_B_z(:,:,i)]);
        % data2D.VdeltaB(:,:,i) = cross([data2D.Br(:,:,i) data2D.Bt(:,:,i) data2D.Bz(:,:,i)], [B_r 0 B_z]);
    
    end
    disp("calculation finished")
else
    load(filename,'data2D','grid2D');
end

if doCalculation
    % clearvars -except data2D grid2D shot pathname filename;
    % filename = strcat(pathname.pre_processed_directory,'/a039_',num2str(shot(1)),'.mat');
    % save(filename)
    save(filename, 'data2D', 'grid2D', 'shot');
end

end