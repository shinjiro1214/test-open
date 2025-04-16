%【※コードを使用する前に】環境変数を設定しておくか、matlab内のコマンドからsetenv('パス名','アドレス')で指定してから動かす
pathname.ts3u=getenv('ts3u_path');%old-koalaのts-3uまでのパス（mrdなど）
pathname.fourier=getenv('fourier_path');%fourierのmd0（データックのショットが入ってる）までのpath
pathname.NIFS=getenv('NIFS_path');%resultsまでのpath（ドップラー、SXR）
pathname.save=getenv('savedata_path');%outputデータ保存先
pathname.rawdata38=getenv('rawdata038_path');%dtacq a038のrawdataの保管場所
pathname.woTFdata=getenv('woTFdata_path');%rawdata（TFoffset引いた）の保管場所
pathname.rawdata=getenv('rawdata_path');%dtacqのrawdataの保管場所
pathname.pre_processed_directory = getenv('pre_processed_directory_path');%計算結果の保存先（どこでもいい）
pathname.MAGDATA = getenv('MAGDATA_DIR');

TF40list = [7,9,28:30];
TF35list = [10:12,25:27];
TF30list = [13:15,22:24];
TF25list = 16:21;

[Eeff40,merging_ratio_40] = get_Eeff(TF40list,pathname);
[Eeff35,merging_ratio_35] = get_Eeff(TF35list,pathname);
[Eeff30,merging_ratio_30] = get_Eeff(TF30list,pathname);
[Eeff25,merging_ratio_25] = get_Eeff(TF25list,pathname);
times = 455:470;
figure;hold on;
errorbar(times,Eeff25.plot,Eeff25.error);
errorbar(times,Eeff30.plot,Eeff30.error);
errorbar(times,Eeff35.plot,Eeff35.error);
errorbar(times,Eeff40.plot,Eeff40.error);
xlabel("time [us]");ylabel("Effective electric field [V/m]");
legend({"TF 2.5kV","TF 3.0kV","TF 3.5kV","TF 4.0kV"},'location','southwest');

figure;hold on;
errorbar(times,merging_ratio_25.plot,merging_ratio_25.error);
errorbar(times,merging_ratio_30.plot,merging_ratio_30.error);
errorbar(times,merging_ratio_35.plot,merging_ratio_35.error);
errorbar(times,merging_ratio_40.plot,merging_ratio_40.error);
xlabel("time [us]");ylabel("Merging ratio");
legend({"TF 2.5kV","TF 3.0kV","TF 3.5kV","TF 4.0kV"},'location','southwest');

% errorbar(merging_ratio_25.plot,Eeff25.plot,Eeff25.error,Eeff25.error,merging_ratio_25.error,merging_ratio_25.error);
% errorbar(merging_ratio_30.plot,Eeff30.plot,Eeff30.error,Eeff30.error,merging_ratio_30.error,merging_ratio_30.error);
% errorbar(merging_ratio_35.plot,Eeff35.plot,Eeff35.error,Eeff35.error,merging_ratio_35.error,merging_ratio_35.error);
% errorbar(merging_ratio_40.plot,Eeff40.plot,Eeff40.error,Eeff40.error,merging_ratio_40.error,merging_ratio_40.error);

ax=gca;ax.FontSize=18;


function [Eeff,merging_ratio] = get_Eeff(shotIDXlist,pathname)
    addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/pcb_experiment';
    PCB.date = 240111;
    DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
    T=getTS6log(DOCID);
    node='date';
    T=searchlog(T,node,PCB.date);

    % IDXlist40 = find(T.shot==TF40list);
    % n_data40=numel(IDXlist40);%計測データ数
    % shotlist40_a039 =T.a039(IDXlist40);
    % shotlist40_a040 = T.a040(IDXlist40);
    % shotlist40 = [shotlist40_a039, shotlist40_a040];
    % tfshotlist40_a039 =T.a039_TF(IDXlist40);
    % tfshotlist40_a040 =T.a040_TF(IDXlist40);
    % tfshotlist40 = [tfshotlist40_a039, tfshotlist40_a040];
    % EFlist40=T.EF_A_(IDXlist40);
    % TFlist40=T.TF_kV_(IDXlist40);
    % dtacqlist40=39.*ones(n_data40,1);

    PCB.trange=400:800;%【input】計算時間範囲
    PCB.n=40; %【input】rz方向のメッシュ数
    PCB.start = 55; %plot開始時間-400
    PCB.dt = 1;
    PCB.doOverwrite = false;

    [~,IDXlist] = ismember(shotIDXlist,T.shot);
    n_data=numel(IDXlist);%計測データ数
    shotlist_a039 =T.a039(IDXlist);
    shotlist_a040 = T.a040(IDXlist);
    shotlist = [shotlist_a039, shotlist_a040];
    tfshotlist_a039 =T.a039_TF(IDXlist);
    tfshotlist_a040 =T.a040_TF(IDXlist);
    tfshotlist = [tfshotlist_a039, tfshotlist_a040];
    EFlist=T.EF_A_(IDXlist);
    TFlist=T.TF_kV_(IDXlist);
    % dtacqlist=39.*ones(n_data,1);

    n_time = 16;
    Eeff_data = zeros(n_data,n_time);
    merging_ratio_data = zeros(n_data,n_time);
    for i=1:n_data
        PCB.idx = shotIDXlist(i);
        PCB.shot=shotlist(i,:);
        PCB.tfshot=tfshotlist(i,:);
        if PCB.shot == PCB.tfshot
            PCB.tfshot = [0,0];
        end
        PCB.i_EF=EFlist(i);
        PCB.TF=TFlist(i);

        % Eeffを計算する処理
        [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
        [magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D);
        for m = 1:n_time
            j = PCB.start+(m-1)*PCB.dt;
            Bp = sqrt(data2D.Bz(:,:,j).^2+data2D.Br(:,:,j).^2);
            [zq,rq] = meshgrid(linspace(-0.1,0.1,200),linspace(0.2,0.32,200));
            Bp_q = griddata(grid2D.zq(1,:),grid2D.rq(:,1),Bp,zq,rq);
            Bt_th_q = griddata(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bt_th(:,:,j),zq,rq);
            Et_q = griddata(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Et(:,:,j),zq,rq);
            GFR_q = abs(Bt_th_q./Bp_q);
            idxRq = knnsearch(rq(:,1),xPointList.r(j));
            idxZq = knnsearch(zq(1,:).',xPointList.z(j));
            E_eff_tmp = Et_q.*GFR_q;
            Eeff_data(i,m) = min(E_eff_tmp(max(1,idxRq-10):min(200,idxRq+10),max(1,idxZq-10):min(200,idxZq+10)),[],"all");
            merging_ratio_data(i,m) = xPointList.psi(j)/min(magAxisList.psi(j));
        end
    end
    Eeff.plot = mean(Eeff_data,'omitmissing');
    Eeff.error = std(Eeff_data,'omitmissing')/sqrt(n_data);
    merging_ratio.plot = mean(merging_ratio_data,'omitmissing');
    merging_ratio.error = std(merging_ratio_data,'omitmissing')/sqrt(n_data);
end