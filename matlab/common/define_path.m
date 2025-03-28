%%%%%ここが各PCのパス
setenv("NIFS_path","/Volumes/experiment/results")%smb接続
% setenv("NIFS_path","/Users/rsomeya/sshfs/mnt/data")%koala経由
setenv('rsOnedrive','/Users/rsomeya/Library/CloudStorage/OneDrive-TheUniversityofTokyo/lab')
setenv('TErsGdrive','/Users/rsomeya/Library/CloudStorage/GoogleDrive-rsomeya.uot@gmail.com/マイドライブ')
setenv('MDSPLUS_DIR','/usr/local/mdsplus');
setenv('Fourier','/Volumes/md0');
pathname.fourier=getenv('Fourier');%resultsまでのpath（ドップラー、SXR）
pathname.NIFS=getenv('NIFS_path');%resultsまでのpath（ドップラー、SXR）
setenv("Local_NIFS","/Users/rsomeya/Documents/NIFS_copy")%ローカルにコピーしたNIFS
setenv("Local_TE","/Users/rsomeya/Desktop/TE")%ローカルにコピーしたTE
% pathname.ST40_Doppler=[getenv('TErsGdrive') '/ST40_Doppler'];%GDriveにコピーしたST40Dopplerデータ
pathname.ST40_Doppler='/Volumes/experiment/results/ST40/2024';
pathname.IDSP=[pathname.NIFS,'/Doppler/Andor/IDSP'];%smb接続
pathname.IDS288ch=[pathname.NIFS,'/Doppler/Andor/320CH'];%smb接続
pathname.ST40_CX=[pathname.NIFS,'/ST40/2023/Doppler'];%smb接続
pathname.ESP=[pathname.NIFS,'/ElectroStaticProbe'];%smb接続
% pathname.IDSP=getenv('Local_NIFS');%ローカルにコピーしたNIFS
pathname.TE=getenv('Local_TE');%ローカルにコピーしたTE
addpath(fullfile(getenv('MDSPLUS_DIR'), 'matlab'));
pathname.fig=[getenv('rsOnedrive') '/figure'];%figure保存先
pathname.mat=[getenv('rsOnedrive') '/mat'];%mat保存先
pathname.rawdata=[pathname.mat,'/pcb_raw'];%dtacqのrawdata.matの保管場所
pathname.processeddata=[pathname.mat,'/pcb_processed'];%磁場データmatの保管場所
pathname.flowdata=[pathname.mat,'/ionflow'];%流速データmatの保管場所
pathname.vdistdata=[pathname.mat,'/ionvdist'];%速度分布データmatの保管場所
pathname.tempdata=[pathname.mat,'/iontemp'];%温度分布データmatの保管場所
% pathname.rawdata38=getenv('rawdata038_path');%dtacq a038のrawdataの保管場所
% pathname.woTFdata=getenv('woTFdata_path');%rawdata（TFoffset引いた）の保管場所
% pathname.ts3u=getenv('ts3u_path');%old-koalaのts-3uまでのパス（mrdなど）
% pathname.fourier=getenv('fourier_path');%fourierのmd0（データックのショットが入ってる）までのpath
% pathname.save=getenv('output');%outputデータ保存先