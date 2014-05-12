function fa_gen_check(base_exp,fa_exp,folder)
% Loads in images generated by fa_gen (designated by fa_exp) and base
% images to plot over. Plots the outlines of the blobs as white polygons
% over the chosen base images. Saves the results to a .gif image file.

fa_img = file_search(fa_exp,folder);
base_img = file_search(base_exp,folder);

if length(fa_img)~=length(base_img)
    disp('The image sets are different sizes')
else
    title1 = strrep(base_exp,'\d+_','');
    title1 = title1(1:end-4);
    title1 = ['fa_stack_' title1 '.gif'];
    for i = 1:length(fa_img)
        fi = double(imread(fa_img{i}));
        fbw = im2bw(fi,0);
        [B,L] = bwboundaries(fbw,'noholes');
        bi = double(imread(base_img{i}));
        figure; imagesc(bi); hold on; title(strrep(fa_img{i},'_',' '))
        for k = 1:length(B)
            boundary = B{k};
            plot(boundary(:,2),boundary(:,1),'w','LineWidth',1)
        end
        F = getframe(gcf);
        im = frame2im(F);
        [X,Map] = rgb2ind(im,256);
            if i == 1
               imwrite(X,Map,fullfile(pwd,folder,title1),'gif','LoopCount',Inf,'DelayTime',5);
            else
               imwrite(X,Map,fullfile(pwd,folder,title1),'gif','WriteMode','append','DelayTime',5);
            end
        close all;
    end
end