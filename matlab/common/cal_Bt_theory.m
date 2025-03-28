function [Bt_th] = cal_Bt_theory(PCB,grid2D)

trange_rgw = PCB.trange(1):0.1:PCB.trange(end);%ロゴスキー時間範囲
rgw2txt(PCB.date,PCB.IDX)
folder_directory_rogo = '/Volumes/md0/rogowski/';
date_str = num2str(PCB.date);

if PCB.IDX < 10
    data_dir = [folder_directory_rogo,date_str,'/',date_str,'00',num2str(PCB.IDX)];
elseif PCB.IDX < 100
    data_dir = [folder_directory_rogo,date_str,'/',date_str,'0',num2str(PCB.IDX)];
elseif PCB.IDX < 1000
    data_dir = [folder_directory_rogo,date_str,'/',date_str,num2str(PCB.IDX)];
else
    disp('More than 999 shots! You need some rest!!!')
    return
end

txt_name = strcat(data_dir,'.txt');
Bt_th = zeros(size(grid2D.rq,1),size(grid2D.rq,2),size(PCB.trange,2));
if PCB.date < 240430
    ch_TF = 1;%TFロゴスキーCH番号
    calib_TF = 116.6647;%TFロゴスキー校正係数[kA/V]
else
    ch_TF = 2;
    calib_TF = 116.6647;%TFロゴスキー校正係数[kA/V]
end
if exist(txt_name,'file')
    rgw = importdata(txt_name);
    I_tf = rgw.data(trange_rgw*10,ch_TF+2)*calib_TF*1E3;
    for i=1:size(PCB.trange,2)
        i_rgw = (i-1)*10 + 1;
        for j = 1:PCB.mesh
            Bt_th(j,:,i)=12*2E-7/grid2D.rq(j,1)*I_tf(i_rgw);%12Turn*mu_0*I_tf/2πR
        end
    end
else
    Bt_th = [];
end