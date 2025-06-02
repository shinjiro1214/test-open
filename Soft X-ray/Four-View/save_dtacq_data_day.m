clearvars -except date
addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/pcb_experiment'; %getMDSdata.mとcoeff200ch.xlsxのあるフォルダへのパス
addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View_Simulation';


%%%%%ここが各PCのパスx
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

%%%%実験オペレーションの取得
prompt = {'Date:'};
definput = {''};
if exist('date','var')
    definput{1} = num2str(date);
end

dlgtitle = 'Input';
dims = [1 35];
% if exist('date','var') && exist('IDXlist','var') && exist('doCheck','var')
%     definput = {num2str(date),num2str(IDXlist),num2str(doCheck)};
% else
%     definput = {'','',''};
% end
% definput = {'','',''};
% definput = {num2str(date),num2str(IDXlist),num2str(doCheck)};
answer = inputdlg(prompt,dlgtitle,dims,definput);
date = str2double(cell2mat(answer(1)));

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);
node='date';
% date=230714;
T=searchlog(T,node,date);
% IDXlist= 1; %[5:50 52:55 58:59];%[4:6 8:11 13 15:19 21:23 24:30 33:37 39:40 42:51 53:59 61:63 65:69 71:74];
IDXlist = T.shot;
IDXlist = IDXlist.';
n_data=numel(IDXlist);%計測データ数
shotlist_a039 =T.a039(IDXlist);
shotlist_a040 = T.a040(IDXlist);
shotlist = [shotlist_a039, shotlist_a040];
tfshotlist_a039 =T.a039_TF(IDXlist);
tfshotlist_a040 =T.a040_TF(IDXlist);
tfshotlist = [tfshotlist_a039, tfshotlist_a040];
EFlist=T.EF_A_(IDXlist);
TFlist=T.TF_kV_(IDXlist);
dtacqlist=39.*ones(n_data,1);

PCB.trange=400:800;%【input】計算時間範囲
PCB.n=40; %【input】rz方向のメッシュ数
PCB.start = 55; %plot開始時間-400
PCB.dt = 1;

for i=1:n_data
    idx = IDXlist(i);
    shot=shotlist(i,:);
    tfshot=tfshotlist(i,:);
    if any(isnan(shot))
        continue
    end
    if shot == tfshot
        tfshot = [0,0];
    end
    i_EF=EFlist(i);
    TF=TFlist(i);
    filename1 = strcat(pathname.rawdata,'/mag_probe/dtacq',num2str(39),'/shot',num2str(shot(1)),'_tfshot',num2str(tfshot(1)),'.mat');
    if exist(filename1,"file")==0
        disp('No rawdata file of a039 -- Start generating!')
        save_dtacq_data(39, shot(1), tfshot(1),filename1)
    end
    filename2 = strcat(pathname.rawdata,'/mag_probe/dtacq',num2str(40),'/shot',num2str(shot(2)),'_tfshot',num2str(tfshot(2)),'.mat');
    if exist(filename2,"file")==0
        disp('No rawdata file of a040 -- Start generating!')
        save_dtacq_data(40, shot(2), tfshot(2),filename2)
    end
end