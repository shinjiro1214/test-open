function save_dtacq_data(dtacq_num,shot,tfshot,fileName)



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
rawdata_woTF=rawdata_wTF; %TF成分を差し引いたデータ

import MDSplus.*
%ツリーのdatafileがあるフォルダのパスをtreename_pathという形で環境変数に設定(a038_path, a039_path, a040_path)
%mdsipのポートに接続して各デジタイザののツリーを開く。
mdsconnect('192.168.1.140');
mdsopen(dtacq, shot); 

for i=1:ch_num
    %各チャンネルにおいて「.AI:CHXXX」というノードを指定するためのノード名を作る
    chname=".AI:CH"+num2str(transpose(i),'%03i');
    % num2strで数値データをstrデータに変換。この時'%03i'で左側を(0)で埋めた(3)桁の整数(i)という形を指定できる。
    %データがとれていないときエラーメッセージが多分237文字で帰ってくるので、1000以下の要素はデータなしとしてリターンする
    if numel(mdsvalue(chname)) <1000
        return
    end
    rawdata_wTF(:,i)=mdsvalue(chname);
    % %データがとれていないときエラーメッセージが多分237文字で帰ってくるので、1000以下の要素はデータなしとしてリターンする
    % if numel(rawdata_wTF(:,i)) <1000
    %     return
    % end
    rawdata_wTF(:,i)=rawdata_wTF(:,i)-rawdata_wTF(1,i);% オフセット調整
end
% rawdata_woTF=rawdata_wTF; %TF成分を差し引いたデータ
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