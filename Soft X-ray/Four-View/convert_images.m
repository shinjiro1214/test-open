function [] = convert_images(date_str)
% path = foldername;% 軟X線画像の保存されているフォルダのパス

% /Users/shohgookazaki/shohgo-okazaki@g.ecc.u-tokyo.ac.jp\ -\ Google\ Drive/My\ Drive/OnoLab/data/SXR_Images/260331
base_dir = '/Users/shohgookazaki/shohgo-okazaki@g.ecc.u-tokyo.ac.jp - Google Drive/My Drive/OnoLab/data/SXR_Images';
path = fullfile(base_dir, date_str);

if exist(path,'dir') == 0
    disp('Inadequate path')
    return
end
MyFolderInfo = dir(path);
path2 = strcat(path,'/converted');
if exist(path2,'dir') == 0
    mkdir(path2);
    NumData = numel(MyFolderInfo);
    MyFolderInfo = MyFolderInfo(3:NumData);
else
    NumData = numel(MyFolderInfo);
    MyFolderInfo = MyFolderInfo(4:NumData);
end
% MyFolderInfo = MyFolderInfo(4:NumData);
MyFolderDir = MyFolderInfo.folder;
MyFolderName = {MyFolderInfo.name};
FolderInfo = strcat(MyFolderDir,'/',MyFolderName);

for i = 1:numel(FolderInfo)
    if MyFolderInfo(i).isdir
        continue
    elseif ~contains(MyFolderName(i),'.tif')
        continue
    end
    figure(1);
    % figure;
    IM = imread(string(FolderInfo(i)));
    imagesc(IM,[40,70]);
    % imagesc(IM);
    saveas(gcf,strcat(path2,'/',string(MyFolderName(i))));
end
end