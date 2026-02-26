% function [grid2D,data2D] = process_PCBdata_280ch(date, shot, tfshot, pathname, n,i_EF,trange)
function [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname)
date = PCB.date;
shot = PCB.shot;
tfshot = PCB.tfshot;
n = PCB.n;
i_EF = PCB.i_EF;
trange = PCB.trange;
idx = PCB.idx;
mu0 = 4 * pi * 1e-7; % 真空の透磁率

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
    
    C = PCB.C;
    
    % 一時ファイルの削除（クリーンアップ）
    % %較正係数のバージョンを日付で判別
    % sheets = sheetnames('coeff200ch.xlsx');
    % sheets = str2double(sheets);
    % sheet_date=max(sheets(sheets<=date));
    % C = readmatrix('coeff200ch.xlsx','Sheet',num2str(sheet_date));
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
        max_wait = 100; % 最大待機時間(秒)
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
        
        if PCB.date >= 241110 %&& PCB.date <= 250125
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
    % [Bz_EF,~] = B_EF(z1_EF,z2_EF,r_EF,i_EF,n_EF,grid2D.rq,grid2D.zq,false);

    
    
    
    data2D_probe=struct(...
        'psi',zeros(size(grid2D_probe.rq,1),size(grid2D_probe.rq,2),size(trange,2)),...
        'Bz',zeros(size(grid2D_probe.rq,1),size(grid2D_probe.rq,2),size(trange,2)),...
        'Bt',zeros(size(grid2D_probe.rq,1),size(grid2D_probe.rq,2),size(trange,2)),...
        'Bt_th',zeros(size(grid2D_probe.rq,1),size(grid2D_probe.rq,2),size(trange,2)),...
        'Br',zeros(size(grid2D_probe.rq,1),size(grid2D_probe.rq,2),size(trange,2)),...
        'Bl',zeros(size(grid2D_probe.rq,1),size(grid2D_probe.rq,2),size(trange,2)),...
        'Jt',zeros(size(grid2D_probe.rq,1),size(grid2D_probe.rq,2),size(trange,2)),...
        'Et',zeros(size(grid2D_probe.rq,1),size(grid2D_probe.rq,2),size(trange,2)),...
        'dBzdt', zeros(size(grid2D_probe.rq,1), size(grid2D_probe.rq,2), size(trange,2)), ...
        'dBtdt', zeros(size(grid2D_probe.rq,1), size(grid2D_probe.rq,2), size(trange,2)), ...
        'dBrdt', zeros(size(grid2D_probe.rq,1), size(grid2D_probe.rq,2), size(trange,2)), ...
        'dBdt_magnitude', zeros(size(grid2D_probe.rq,1), size(grid2D_probe.rq,2), size(trange,2)), ...
        'dpsi_dt', zeros(size(grid2D_probe.rq,1), size(grid2D_probe.rq,2), size(trange,2)), ...
        'magnetic_pressure', zeros(size(grid2D_probe.rq,1), size(grid2D_probe.rq,2), size(trange,2)), ...
        'B_parallel', zeros(size(grid2D_probe.rq,1), size(grid2D_probe.rq,2), size(trange,2)), ...
        'dB_parallel_dt', zeros(size(grid2D_probe.rq,1), size(grid2D_probe.rq,2), size(trange,2)), ...
        'curvature', zeros(size(grid2D_probe.rq,1), size(grid2D_probe.rq,2), size(trange,2)), ...
        'gradB', zeros(size(grid2D_probe.rq,1), size(grid2D_probe.rq,2), size(trange,2)), ...   % 追加 (大きさ)
        'trange',trange);
    
    data2D = struct(...
        'psi',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Bz',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Bt',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Bt_th',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Br',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Bl',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Jt',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'Et',zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(trange,2)),...
        'dBzdt', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'dBtdt', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'dBrdt', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'dBdt_magnitude', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'dpsi_dt', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'magnetic_pressure', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'B_parallel', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'dB_parallel_dt', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
        'curvature', zeros(size(grid2D.rq,1), size(grid2D.rq,2), size(trange,2)), ...
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
    [Bz_EF,~] = B_EF(z1_EF,z2_EF,r_EF,i_EF,n_EF,rpos_bz(valid_idx_bz), zpos_bz(valid_idx_bz),false);
    clear EF r_EF n_EF i_EF z_EF

    % ==========================================================
    % 時間ループ
    % ==========================================================
    for i = 1:size(trange, 2)
        t = trange(i); % 行番号（時間インデックス）

        % --- Bz の高速補完 ---
        F_bz.Values = double(bz(t, valid_idx_bz))' - Bz_EF(:); 

        vq_bz = F_bz(grid2D_probe.rq, grid2D_probe.zq); 

        smooth_sigma = 1.5; 
        B_z = imgaussfilt(vq_bz, smooth_sigma);


        % --- Bt の高速補完 ---
        F_bt.Values = double(bt(t, valid_idx_bt))'; 
        vq_bt = F_bt(grid2D_probe.rq, grid2D_probe.zq);
        
        % 【追加】 スムージング処理 (Btも同様に)
        B_t = imgaussfilt(vq_bt, smooth_sigma); 
    
        % PSI計算
        data2D_probe.psi(:,:,i) = cumtrapz(grid2D_probe.rq(:,1),2*pi*B_z.*grid2D_probe.rq(:,1),1);
        % data2D.psi(:,:,i) = flip(get_psi(flip(B_z,1),flip(grid2D.rq(:,1)),1),1);
        % このままだと1/2πrが計算されてないので
        [data2D_probe.Br(:,:,i),data2D_probe.Bz(:,:,i)]=gradient(data2D_probe.psi(:,:,i),grid2D_probe.zq(1,:),grid2D_probe.rq(:,1)) ;
        data2D_probe.Br(:,:,i)=-data2D_probe.Br(:,:,i)./(2.*pi.*grid2D_probe.rq);
        data2D_probe.Bz(:,:,i)=data2D_probe.Bz(:,:,i)./(2.*pi.*grid2D_probe.rq);
        data2D_probe.Bt(:,:,i)=B_t;
        data2D_probe.Bl(:,:,i)=sqrt(data2D_probe.Bz(:,:,i).^2+data2D_probe.Br(:,:,i).^2+data2D_probe.Bt(:,:,i).^2);
        % data2D.Brt(:,:,i)=sqrt(data2D.Bt(:,:,i).^2+data2D.Br(:,:,i).^2);

        
        data2D_probe.magnetic_pressure(:,:,i) = (data2D_probe.Bl(:,:,i)).^2 / (2 * mu0);

        
        [gradB_z_temp, gradB_r_temp] = gradient(data2D_probe.Bl(:,:,i), grid2D_probe.zq(1,:), grid2D_probe.rq(:,1));
        data2D_probe.gradB(:,:,i)   = sqrt(gradB_r_temp.^2 + gradB_z_temp.^2); % 大きさ

        data2D_probe.Jt(:,:,i)= curl(grid2D_probe.zq(1,:),grid2D_probe.rq(:,1),data2D_probe.Bz(:,:,i),data2D_probe.Br(:,:,i))./(4*pi*1e-7);
        [curlt,~]               = curl(grid2D_probe.zq(1,:),grid2D_probe.rq(:,1),data2D_probe.Bz(:,:,i),data2D_probe.Br(:,:,i));
        data2D_probe.Jt(:,:,i)        = curlt/(4*pi*1e-7);
        

        if rgwflag
            timing = x/aquisition_rate==t;
            data2D_probe.Bt_th(:,:,i) = m0*I_TF(timing)*1e3*12./(2*pi()*grid2D_probe.rq);
        end
        
        % 磁力線方向の単位ベクトル
        e_parallel_r = data2D_probe.Br(:,:,i) ./ data2D_probe.Bl(:,:,i);
        e_parallel_z = data2D_probe.Bz(:,:,i) ./ data2D_probe.Bl(:,:,i);
        e_parallel_t = data2D_probe.Bt(:,:,i) ./ data2D_probe.Bl(:,:,i);
        data2D_probe.B_parallel(:,:,i) = data2D_probe.Br(:,:,i).*e_parallel_r + ...
                           data2D_probe.Bz(:,:,i).*e_parallel_z + ...
                           data2D_probe.Bt(:,:,i).*e_parallel_t;
        
        if i>1
            data2D_probe.Et(:,:,i) = -1*(data2D_probe.psi(:,:,i)-data2D_probe.psi(:,:,i-1))./(2*pi()*grid2D_probe.rq);
            
            dt = (trange(i) - trange(i-1))*1e-6; % 時間ステップ
            data2D_probe.Et(:,:,i) = data2D_probe.Et(:,:,i)/dt;

            data2D_probe.dBzdt(:,:,i) = (data2D_probe.Bz(:,:,i) - data2D_probe.Bz(:,:,i-1)) / dt;
            data2D_probe.dBtdt(:,:,i) = (data2D_probe.Bt(:,:,i) - data2D_probe.Bt(:,:,i-1)) / dt;
            data2D_probe.dBrdt(:,:,i) = (data2D_probe.Br(:,:,i) - data2D_probe.Br(:,:,i-1)) / dt;
            data2D_probe.dpsi_dt(:,:,i) = (data2D_probe.psi(:,:,i) - data2D_probe.psi(:,:,i-1)) / dt;

            data2D_probe.dBdt_magnitude(:,:,i) = sqrt(...
                data2D_probe.dBzdt(:,:,i).^2 + ...
                data2D_probe.dBtdt(:,:,i).^2 + ...
                data2D_probe.dBrdt(:,:,i).^2);
            data2D_probe.dB_parallel_dt(:,:,i) = (data2D_probe.B_parallel(:,:,i) - data2D_probe.B_parallel(:,:,i-1)) / dt;
        end

        [Br_z, Br_r] = gradient(data2D_probe.Br(:,:,i), grid2D_probe.zq(1,:), grid2D_probe.rq(:,1));
        [Bz_z, Bz_r] = gradient(data2D_probe.Bz(:,:,i), grid2D_probe.zq(1,:), grid2D_probe.rq(:,1));
        [Bt_z, Bt_r] = gradient(data2D_probe.Bt(:,:,i), grid2D_probe.zq(1,:), grid2D_probe.rq(:,1));
        e_Br_r = Br_r ./ data2D_probe.Bl(:,:,i);
        e_Br_z = Br_z ./ data2D_probe.Bl(:,:,i);
        e_Bz_z = Bz_z ./ data2D_probe.Bl(:,:,i);
        e_Bz_r = Bz_r ./ data2D_probe.Bl(:,:,i);
        e_Bt_z = Bt_z ./ data2D_probe.Bl(:,:,i);
        e_Bt_r = Bt_r ./ data2D_probe.Bl(:,:,i);
        
        curvature_B_r = e_Br_r .* e_parallel_r + e_Bt_r .* e_parallel_t + e_Bz_r .* e_parallel_z; % 
        curvature_B_t = zeros(size(curvature_B_r));
        curvature_B_z = e_Br_z .* e_parallel_r + e_Bt_z .* e_parallel_t + e_Bz_z .* e_parallel_z;

        data2D_probe.curvature(:,:,i) = sqrt(curvature_B_r.^2+curvature_B_t.^2+curvature_B_z.^2);

    
    end

    disp('Interpolating all coarse data to fine grid2D...');
    
    fields = fieldnames(data2D_probe);
    for f = 1:length(fields)
        fname = fields{f};
        if strcmp(fname, 'trange')
            data2D.(fname) = data2D_probe.(fname);
            continue;
        end
        % 各変数の全時間ステップを細かいグリッドに一括補間
        for i = 1:size(trange, 2)
            data2D.(fname)(:,:,i) = interp2(grid2D_probe.zq, grid2D_probe.rq, data2D_probe.(fname)(:,:,i), grid2D.zq, grid2D.rq, 'spline');
        end
    end

    
    % save(filename, 'data2D', 'grid2D', 'shot');
    disp("calculation finished")
else
    load(filename,'data2D','grid2D');
end

% if doCalculation
%     % clearvars -except data2D grid2D shot pathname filename;
%     % filename = strcat(pathname.pre_processed_directory,'/a039_',num2str(shot(1)),'.mat');
%     % save(filename)
%     
% end

end