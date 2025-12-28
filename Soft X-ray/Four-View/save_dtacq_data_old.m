function save_dtacq_data(dtacq_num,shot,tfshot,fileName)

% rawdataPath=getenv('rawdata_path'); %保存先

% %%%%実験オペレーションの取得
% DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
% T=getTS6log(DOCID);
% node='date';
% % pat=230707;
% pat=date;
% T=searchlog(T,node,pat);
% IDXlist=6;%[4:6 8:11 13 15:19 21:23 24:30 33:37 39:40 42:51 53:59 61:63 65:69 71:74];
% IDXlist = shot;
% n_data=numel(IDXlist);%計測データ数
% shotlist=T.a039(IDXlist);
% tfshotlist=T.a039_TF(IDXlist);
% EFlist=T.EF_A_(IDXlist);
% TFlist=T.TF_kV_(IDXlist);
% dtacqlist=39.*ones(n_data,1);

% dtacqlist=39;
% shotlist= 1819;%【input】dtacqの保存番号
% tfshotlist = 1817;

% dtacqlist=40;
% shotlist= 299;%【input】dtacqの保存番号
% tfshotlist = 297;

% date = 230706;%【input】計測日
% n=numel(shotlist);%計測データ数

%RC係数読み込み

% for i=1:n
%     dtacq_num=dtacqlist(i);
%     shot=shotlist(i);
%     tfshot=tfshotlist(i);
%     [rawdata]=getMDSdata(dtacq_num,shot,tfshot);%測定した生信号
%     save(strcat(rawdataPath,'/rawdata_dtacq',num2str(dtacq_num),'_shot',num2str(shot),'_tfshot',num2str(tfshot),'.mat'),'rawdata');
%     if tfshot>0
%         [rawdata]=getMDSdata(dtacq_num,shot,0);
%         % save(strcat(pathname.rawdata,'/rawdata_dtacq',num2str(dtacq_num),'_shot',num2str(shot),'_tfshot0.mat'),'rawdata0');
%         save(strcat(rawdataPath,'/rawdata_dtacq',num2str(dtacq_num),'_shot',num2str(shot),'_tfshot0.mat'),'rawdata');
%     end
% end

% dtacq_num=dtacqlist(i);
% shot=shotlist(i);
% tfshot=tfshotlist(i);

% % 231128　下のブロックをコメントアウト
% [rawdata]=getMDSdata(dtacq_num,shot,tfshot);%測定した生信号
% save(strcat(rawdataPath,'/rawdata_dtacq',num2str(dtacq_num),'_shot',num2str(shot),'_tfshot',num2str(tfshot),'.mat'),'rawdata');
% if tfshot==0
%     [rawdata]=getMDSdata(dtacq_num,shot,0);
%     % save(strcat(pathname.rawdata,'/rawdata_dtacq',num2str(dtacq_num),'_shot',num2str(shot),'_tfshot0.mat'),'rawdata0');
%     save(strcat(rawdataPath,'/rawdata_dtacq',num2str(dtacq_num),'_shot',num2str(shot),'_tfshot0.mat'),'rawdata');
% end

% 231128　下のブロックとローカル関数を追加、未テスト
[rawdata_wTF, rawdata_woTF] = get_mds_data(dtacq_num,shot,tfshot);
save(fileName,"rawdata_wTF","rawdata_woTF");
% save(strcat(rawdataPath,'/mag_probe/dtacq',num2str(dtacq_num),'/shot',num2str(shot),'_tfshot',num2str(tfshot),'_wTF.mat'),'rawdata_wTF');
% save(strcat(rawdataPath,'/mag_probe/dtacq',num2str(dtacq_num),'/shot',num2str(shot),'_tfshot',num2str(tfshot),'_woTF.mat'),'rawdata_woTF');

end

function [rawdata_wTF, rawdata_woTF] = get_mds_data(dtacq_num,shot,tfshot)

%%%指定したデジタイザの192ch分のデータを読み込む＋オフセット＋TF差し引きをする関数
%%%【input】dtacq:38/39/40,
%%%shot:dtacqのshot番号,tfshot:TFoffsetに対応するdtacqのshot番号、ない場合は0
clear rawdata_wTF rawdata_TF
if dtacq_num==38
    ch_num=128;
else
    ch_num=192;
end
post=1000;%t=0からの計測時間[us]
dtacq=strcat('a',num2str(dtacq_num,'%03i'));%a038などの形式の文字列へ変換
rawdata_wTF=zeros(post,ch_num); %TF成分を含んだデータ
rawdata_TF=rawdata_wTF; %TF成分

import MDSplus.*
%ツリーのdatafileがあるフォルダのパスをtreename_pathという形で環境変数に設定(a038_path, a039_path, a040_path)
%mdsipのポートに接続して各デジタイザののツリーを開く。
mdsconnect('192.168.1.140');
mdsopen(dtacq, shot); 

for i=1:ch_num
    %各チャンネルにおいて「.AI:CHXXX」というノードを指定するためのノード名を作る
    chname=".AI:CH"+num2str(transpose(i),'%03i');
    % num2strで数値データをstrデータに変換。この時'%03i'で左側を(0)で埋めた(3)桁の整数(i)という形を指定できる。
    rawdata_wTF(:,i)=mdsvalue(chname);
    %データがとれていないときエラーメッセージが多分237文字で帰ってくるので、1000以下の要素はデータなしとしてリターンする
    if numel(rawdata_wTF(:,i)) <1000
        return
    end
    rawdata_wTF(:,i)=rawdata_wTF(:,i)-rawdata_wTF(1,i);% オフセット調整
end
rawdata_woTF=rawdata_wTF; %TF成分を差し引いたデータ
if tfshot>0 
    mdsopen(dtacq, tfshot);
    for i=1:ch_num
    %各チャンネルにおいて「.AI:CHXXX」というノードを指定するためのノード名を作る
        chname=".AI:CH"+num2str(transpose(i),'%03i');
        rawdata_TF(:,i)=mdsvalue(chname);
        if numel(rawdata_TF(:,i)) <1000
            rawdata_TF=zeros(post,ch_num);
        end
        rawdata_TF(:,i)=rawdata_TF(:,i)-rawdata_TF(1,i);% オフセット調整
    end
    rawdata_woTF=rawdata_wTF-rawdata_TF;% TFノイズを差し引いたもの
end

end