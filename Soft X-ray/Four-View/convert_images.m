function [] = convert_images(foldername)
% path = '/Users/shinjirotakeda/OneDrive - The University of Tokyo/Documents/SXR_Images/';
% path = strcat(path,foldername);
path = foldername;% 軟X線画像の保存されているフォルダのパス
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
    % imagesc(IM,[40,70]);
    imagesc(IM,[40,180]);
    axis image
    % imagesc(IM);
    saveas(gcf,strcat(path2,'/',string(MyFolderName(i))));
end
end
