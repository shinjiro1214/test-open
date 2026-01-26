clearvars -except date IDXlist times
addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/pcb_experiment'; %getMDSdata.mとcoeff200ch.xlsxのあるフォルダへのパス

%%%%%%%%%%%%%%%%%%%%%%%%
%280ch用新規pcbプローブのみでの磁気面（Bz）
%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%ここが各PCのパス
%【※コードを使用する前に】環境変数を設定しておくか、matlab内のコマンドからsetenv('パス名','アドレス')で指定してから動かす
pathname.ts3u=getenv('ts3u_path');%old-koalaのts-3uまでのパス（mrdなど）
pathname.fourier=getenv('fourier_path');%fourierのmd0（データックのショットが入ってる）までのpath
pathname.NIFS=getenv('NIFS_path');%resultsまでのpath（ドップラー、SXR）
pathname.save=getenv('savedata_path');%outputデータ保存先
pathname.rawdata38=getenv('rawdata038_path');%dtacq a038のrawdataの保管場所
pathname.woTFdata=getenv('woTFdata_path');%rawdata（TFoffset引いた）の保管場所
pathname.rawdata=getenv('rawdata_path');%dtacqのrawdataの保管場所
pathname.pre_processed_directory = getenv('pre_processed_directory_path');%計算結果の保存先（どこでもいい）

%%%%実験オペレーションの取得
prompt = {'Date:','Shot number:','times:'};
definput = {'','',''};
if exist('date','var')
    definput{1} = num2str(date);
end
if exist('IDXlist','var')
    definput{2} = num2str(IDXlist);
end
if exist('times','var')
    definput{3} = num2str(times);
end
dlgtitle = 'Input';
dims = [1 35];
% if exist('date','var') && exist('IDX','var') && exist('times','var')
%     definput = {num2str(date),num2str(IDX),num2str(times)};
% else
%     definput = {'','',''};
% end
% definput = {'','',''};
% definput = {num2str(date),num2str(IDXlist),num2str(doCheck)};
answer = inputdlg(prompt,dlgtitle,dims,definput);
date = str2double(cell2mat(answer(1)));
IDXlist = str2num(cell2mat(answer(2))); 
times = str2num(cell2mat(answer(3))); 

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);
node='date';
% date=230714;
n_data = numel(IDXlist);
T=searchlog(T,node,date);
shot_a039 =T.a039(IDXlist);
shot_a040 = T.a040(IDXlist);
shotlist = [shot_a039, shot_a040];
tfshot_a039 =T.a039_TF(IDXlist);
tfshot_a040 =T.a040_TF(IDXlist);
tfshotlist = [tfshot_a039, tfshot_a040];
EFlist=T.EF_A_(IDXlist);
TFlist=T.TF_kV_(IDXlist);
dtacqlist=39;

PCB.trange=400:800;%【input】計算時間範囲
PCB.n=40; %【input】rz方向のメッシュ数
PCB.start = 63; %plot開始時間-400
PCB.dt = 1;

figure;
hold on
xlabel('time [us]');ylabel('Merging ratio [%]');
legendList = cell(1,n_data);
ax=gca;ax.FontSize=18;
for i=1:n_data
    % dtacq_num=dtacqlist;
    PCB.idx = IDXlist(i);
    PCB.shot=shotlist(i,:);
    PCB.tfshot=tfshotlist(i,:);
    if PCB.shot == PCB.tfshot
        PCB.tfshot = [0,0];
    end
    PCB.i_EF=EFlist(i);
    PCB.TF=TFlist(i);
    PCB.date = date;
    PCB.doOverwrite=false;
    [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
    % ***********************************************

    if isstruct(grid2D)==0 %もしdtacqデータがない場合次のloopへ(データがない場合NaNを返しているため)
        return
    end
    
    merging_ratio = get_merging_ratio(data2D,grid2D,times);
    legendList(i) = cellstr(strcat('shot',num2str(IDXlist(i))));

    % figure;
    plot(times,merging_ratio,'LineWidth',2);
    % xlabel('time [us]');ylabel('Merging ratio [%]');
    % title('Merging ratio');
    % ax=gca;ax.FontSize=18;

end
legend(legendList,'Location','northwest');
ylim([0 100]);%xlim([460 480]);

% if shot == tfshot
%     tfshot = [0,0];
% end
% i_EF=EF;
% 
% [grid2D,data2D] = process_PCBdata_280ch(date, shot, tfshot, pathname, n,i_EF,trange);
% 
% % ***********************************************
% 
% if isstruct(grid2D)==0 %もしdtacqデータがない場合次のloopへ(データがない場合NaNを返しているため)
%     return
% end
% 
% merging_ratio = get_merging_ratio(data2D,grid2D,times);
% 
% figure;
% plot(times,merging_ratio,'k-','LineWidth',2);
% xlabel('time [us]');ylabel('Merging ratio [%]');
% % title('Merging ratio');
% ax=gca;ax.FontSize=18;


function merging_ratio = get_merging_ratio(data2D,grid2D,times)

merging_ratio = zeros(numel(times),1);
i = 1;
[magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D); %時間ごとの磁気軸、X点を検索
for time = times
    % psi_timeseries = data2D.psi;
    % psi = psi_timeseries(:,:,data2D.trange==time);
    % merging_ratio(i) = clc_merging_ratio(psi,grid2D);
    merging_ratio(i) = xPointList.psi(data2D.trange==time)/min(magAxisList.psi(:,data2D.trange==time));
    i = i+1;
end
idx_nan=find(isnan(merging_ratio));
for j = 1:numel(idx_nan)
    i = idx_nan(j);
    if times(i)<470
        merging_ratio(i) = 0;
    elseif times(i)>480
        merging_ratio(i) = 1;
    end
end
merging_ratio(merging_ratio<0)=0;
merging_ratio=merging_ratio*100;
% figure('Position',[100 100 600 200]);
% if plot_flag
%     figure;
%     plot(times,merging_ratio,'k-','LineWidth',2);
%     xlabel('time [us]');ylabel('Merging ratio [%]');
%     title('Merging ratio');
%     ax=gca;ax.FontSize=18;
% end

% merging_speed = diff(merging_ratio);
% figure;
% plot(times(2:end),merging_speed,'k-','LineWidth',2);
% xlabel('time [us]');ylabel('Merging speed [a.u.]');
% title('Merging speed');
% ax=gca;ax.FontSize=18;

end

% function merging_ratio = clc_merging_ratio(psi,grid2D)

% [pos_oz,pos_or,pos_xz,~,psi_o,psi_x] = search_xo(psi,grid2D);

% % if sum(pos_oz<pos_xz)==1 && sum(isnan(pos_oz))==0 % pos_xzがpos_ozの最大値と最小値の間にあることを判別＆O点が2つあることを判別
% % 必要な条件：O点が少なくとも一つある＋X点が（あれば）その二つの間
% if max(sum(pos_oz<pos_xz),sum(pos_oz>pos_xz))==1 % pos_xzがpos_ozの最大値と最小値の間にあることを判別（NaNが入ってもいいように）
%     common_flux = psi_x;
%     private_flux = mean(psi_o,'omitnan');
% elseif sum(isnan(pos_oz))==0 && sum(pos_oz>0)==1 && isnan(pos_xz)% O点二つ（値が違う）あるけどX点なし
%     pos_xz = mean(pos_oz);
%     pos_xr = mean(pos_or);
%     r_space = grid2D.rq(:,1);
%     z_space = grid2D.zq(1,:);
%     z_idx = knnsearch(z_space',pos_xz);
%     r_idx = knnsearch(r_space,pos_xr);
%     common_flux = psi(r_idx,z_idx);
%     private_flux = min(psi_o);
% else
%     common_flux = NaN;
%     private_flux = NaN;
% end

% merging_ratio = common_flux/private_flux;

% end

% function [pos_oz,pos_or,pos_xz,pos_xr,psi_o,psi_x] = search_xo(psi,grid2D)

% r_space = grid2D.rq(:,1);
% z_space = grid2D.zq(1,:);
% mesh_r = numel(r_space);

% % psi_or=zeros(2,length(time));
% pos_or=zeros(2,1);
% pos_oz=pos_or;
% psi_o = zeros(2,1);
% % psi_xr=zeros(1,length(time));
% % psi_xz=psi_xr;
% % [max_psi,max_psi_r]=max(psi_store,[],1); %各時間、各列(z)ごとのpsiの最大値
% [max_psi,max_psi_r]=max(psi,[],1); %各列(z)ごとのpsiの最大値
% max_psi=squeeze(max_psi);

% % for i = time
% %     ind=i-time(1)+1;
% %     max_psi_ind=find(islocalmax(smooth(max_psi(:,i)),'MaxNumExtrema', 2));
%     max_psi_ind=find(islocalmax(smooth(max_psi),'MaxNumExtrema', 2));
% %     r_ind=max_psi_r(:,:,i);
%     r_ind=max_psi_r;
% %     if numel(max_psi(min(max_psi_ind),i))==0
%     if numel(max_psi(min(max_psi_ind)))==0
% %         psi_or(1,ind)=NaN;
% %         psi_oz(1,ind)=NaN;
%         pos_or(1)=NaN;
%         pos_oz(1)=NaN;
%         psi_o(1) = NaN;
%     else
%         o1r=r_ind(min(max_psi_ind));
% %         psi_or(1,ind)=r_space(o1r);
% %         psi_oz(1,ind)=z_space(min(max_psi_ind));
%         pos_or(1)=r_space(o1r);
%         pos_oz(1)=z_space(min(max_psi_ind));
% %         psi_o(1) = psi_store(min(max_psi_ind),o1r);
%         psi_o(1) = psi(o1r,min(max_psi_ind));
%     end
% %     if numel(max_psi(max(max_psi_ind),i))==0
%     if numel(max_psi(max(max_psi_ind)))==0
% %         psi_or(2,ind)=NaN;
% %         psi_oz(2,ind)=NaN;
%         pos_or(2)=NaN;
%         pos_oz(2)=NaN;
%         psi_o(2) = NaN;
%     else
%         o2r=r_ind(max(max_psi_ind));
% %         psi_or(2,ind)=r_space(o2r);
% %         psi_oz(2,ind)=z_space(max(max_psi_ind));
%         pos_or(2)=r_space(o2r);
%         pos_oz(2)=z_space(max(max_psi_ind));
% %         psi_o(2) = psi_store(min(max_psi_ind),o2r);
%         psi_o(2) = psi(o2r,max(max_psi_ind));
%     end
% %     if numel(find(islocalmin(smooth(max_psi(:,i)),'MaxNumExtrema', 1)))==0
%     if numel(find(islocalmin(smooth(max_psi),'MaxNumExtrema', 1)))==0
% %         psi_xr(1,ind)=NaN;
% %         psi_xz(1,ind)=NaN;
%         pos_xr=NaN;
%         pos_xz=NaN;
%         psi_x = NaN;
%     else
% %         min_psi_ind=islocalmin(smooth(max_psi(:,i)),'MaxNumExtrema', 1);
%         min_psi_ind=islocalmin(smooth(max_psi),'MaxNumExtrema', 1);
%         xr=r_ind(min_psi_ind);
%         if xr==1 || xr==mesh_r %r両端の場合は検知しない
% %             psi_xr(1,ind)=NaN;
% %             psi_xz(1,ind)=NaN;
%             pos_xr=NaN;
%             pos_xz=NaN;
%             psi_x = NaN;
%         else
% %             psi_xr(1,ind)=r_space(xr);
% %             psi_xz(1,ind)=z_space(min_psi_ind);
%             pos_xr=r_space(xr);
%             pos_xz=z_space(min_psi_ind);
% %             psi_x = psi_store(min_psi_ind,xr);
%             psi_x = psi(xr,min_psi_ind);
%         end
%     end
% %     if max_psi(1,i)==max(max_psi(1:end/2,i)) %z両端の場合はpsi中心が画面外として検知しない
%     mid_idx = round(numel(max_psi)/2);
%     if max_psi(1)==max(max_psi(1:mid_idx)) %z両端の場合はpsi中心が画面外として検知しない
% %         psi_or(1,ind)=NaN; %r_space(r_ind(1));
% %         psi_oz(1,ind)=NaN; %z_space(1);
%         pos_or(1)=NaN; %r_space(r_ind(1));
%         pos_oz(1)=NaN; %z_space(1);
%         psi_o(1) = NaN;
%     end
% %     if max_psi(end,i)==max(max_psi(end/2:end,i))
%     if max_psi(end)==max(max_psi(mid_idx:end))
% %         psi_or(2,ind)=NaN; %r_space(r_ind(1));
% %         psi_oz(2,ind)=NaN; %z_space(end);
%         pos_or(2)=NaN; %r_space(r_ind(1));
%         pos_oz(2)=NaN; %z_space(end);
%         psi_o(2) = NaN;
%     end
% end
