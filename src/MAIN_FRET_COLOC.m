%% Set up
clear;
close all;
clc;
prefix = '';

%% Get Information
folder = input('Type the name of the folder that contains your images, \n make sure it is added to the path, \n and name your files so they look like \n"exp_01_w1channel1.TIF" and "exp_01_w2channel2.TIF": ','s');
SaveParams = GetInfo_FRET_Coloc(folder);
    
%% Crop & Register Images if Desired
rehash
if strcmpi(SaveParams.crop,'y') && strcmpi(SaveParams.reg,'n') && isempty(file_search('crop_\w+',folder))
    img_cropper('\w+.TIF',folder)
elseif strcmpi(SaveParams.reg,'y') && isempty(file_search('crop_\w+',folder)) % double check cropping
    img_reg_new(folder)
end

if strcmpi(SaveParams.crop,'y') || strcmpi(SaveParams.reg,'y')
    prefix = 'crop_';
end

%% Shade Correct Images new
rehash
if strcmpi(SaveParams.shadecorrect,'y') && isempty(file_search('sc_\w+',folder))
    if strcmpi(SaveParams.bt,'y')
        shade_correct([prefix SaveParams.shade_pre '\w+\d+\w+' SaveParams.FRETchannel '.TIF'],[prefix SaveParams.donor_pre '\w+\d+\w+' SaveParams.FRETchannel '.TIF'],folder);
        shade_correct([prefix SaveParams.shade_pre '\w+\d+\w+' SaveParams.FRETchannel '.TIF'],[prefix SaveParams.acceptor_pre '\w+\d+\w+' SaveParams.FRETchannel '.TIF'],folder);
        shade_correct([prefix SaveParams.shade_pre '\w+\d+\w+' SaveParams.Achannel '.TIF'],[prefix SaveParams.donor_pre '\w+\d+\w+' SaveParams.Achannel '.TIF'],folder);
        shade_correct([prefix SaveParams.shade_pre '\w+\d+\w+' SaveParams.Achannel '.TIF'],[prefix SaveParams.acceptor_pre '\w+\d+\w+' SaveParams.Achannel '.TIF'],folder);
        shade_correct([prefix SaveParams.shade_pre '\w+\d+\w+' SaveParams.Dchannel '.TIF'],[prefix SaveParams.donor_pre '\w+\d+\w+' SaveParams.Dchannel '.TIF'],folder);
        shade_correct([prefix SaveParams.shade_pre '\w+\d+\w+' SaveParams.Dchannel '.TIF'],[prefix SaveParams.acceptor_pre '\w+\d+\w+' SaveParams.Dchannel '.TIF'],folder);
    end
    for i = 1:SaveParams.num_exp
        shade_correct([prefix SaveParams.shade_pre '\w+\d+\w+' SaveParams.FRETchannel '.TIF'],[prefix SaveParams.exp_cell{i} '\w+\d+\w+' SaveParams.FRETchannel '.TIF'],folder);
        shade_correct([prefix SaveParams.shade_pre '\w+\d+\w+' SaveParams.Achannel '.TIF'],[prefix SaveParams.exp_cell{i} '\w+\d+\w+' SaveParams.Achannel '.TIF'],folder);
        shade_correct([prefix SaveParams.shade_pre '\w+\d+\w+' SaveParams.Dchannel '.TIF'],[prefix SaveParams.exp_cell{i} '\w+\d+\w+' SaveParams.Dchannel '.TIF'],folder);
        shade_correct([prefix SaveParams.shade_pre '\w+\d+\w+' SaveParams.Schannel '.TIF'],[prefix SaveParams.exp_cell{i} '\w+\d+\w+' SaveParams.Schannel '.TIF'],folder);
    end
    shade_correct([prefix SaveParams.shade_pre '\w+\d+\w+' SaveParams.FRETchannel '.TIF'],[prefix SaveParams.shade_pre '\w+\d+\w+' SaveParams.FRETchannel '.TIF'],folder);
    shade_correct([prefix SaveParams.shade_pre '\w+\d+\w+' SaveParams.Achannel '.TIF'],[prefix SaveParams.shade_pre '\w+\d+\w+' SaveParams.Achannel '.TIF'],folder);
    shade_correct([prefix SaveParams.shade_pre '\w+\d+\w+' SaveParams.Dchannel '.TIF'],[prefix SaveParams.shade_pre '\w+\d+\w+' SaveParams.Dchannel '.TIF'],folder);
    shade_correct([prefix SaveParams.shade_pre '\w+\d+\w+' SaveParams.Schannel '.TIF'],[prefix SaveParams.shade_pre '\w+\d+\w+' SaveParams.Schannel '.TIF'],folder);
end

if strcmpi(SaveParams.shadecorrect,'y');
    prefix = ['sc_' prefix];
end

%% Background Subtract
rehash
if isempty(file_search('bs_\w+',folder));
    params.bin = 1;
    params.nozero = 0;
    imgs = file_search([prefix '\w+.TIF'],folder);
    for i = 1:length(imgs)
        a = double(imread(imgs{i}));
        imout = bs_ff(a,params);
        imwrite2tif(imout,[],fullfile(folder,['bs_' imgs{i}]),'single');
    end
end
prefix = ['bs_' prefix];
param.sourcefolder = folder;
param.destfolder = folder;

%% Calculate Bleedthroughs
rehash

param.bit = 16;
param.width = 100;
param.avg = 50;
param.outname = [folder '_' prefix 'bleedthroughs'];
param.sourcefolder = folder;
param.destfolder = folder;

param.dthres = SaveParams.dthres;
param.athres = SaveParams.athres;

param.nobkgd = 1;
param.nozero = 0;
param.ocimg = 0;

if strcmpi(SaveParams.bt,'y') && isempty(file_search('bsa_\w+',folder))
    [SaveParams.abt,SaveParams.dbt] = fret_bledth([prefix SaveParams.donor_pre '\w+\d+\w+' SaveParams.Achannel '.TIF'],[prefix SaveParams.donor_pre '\w+\d+\w+' SaveParams.Dchannel '.TIF'],[prefix SaveParams.donor_pre '\w+\d+\w+' SaveParams.FRETchannel '.TIF'],...
        [prefix SaveParams.acceptor_pre '\w+\d+\w+' SaveParams.Achannel '.TIF'],[prefix SaveParams.acceptor_pre '\w+\d+\w+' SaveParams.Dchannel '.TIF'],[prefix SaveParams.acceptor_pre '\w+\d+\w+' SaveParams.FRETchannel '.TIF'],param);
    save(fullfile(pwd,folder,['SaveParams_' folder '.mat']),'-struct','SaveParams');
end

%% Correct the Images
rehash
file = param.outname;
param.imin = [SaveParams.venus_thres 0 -10000];
param = rmfield(param,'outname');
param.donor_norm = 0;
param.double_norm = 0;
param.leave_neg = 1;
param.ocimg = 1;
if strcmpi(SaveParams.correct,'y') && isempty(file_search('cna_\w+.TIF',folder));
    for i = 1:SaveParams.num_exp
        fret_correct([prefix SaveParams.exp_cell{i} '\w+\d+\w+' SaveParams.Achannel '.TIF'],[prefix SaveParams.exp_cell{i} '\w+\d+\w+' SaveParams.Dchannel '.TIF'],[prefix SaveParams.exp_cell{i} '\w+\d+\w+' SaveParams.FRETchannel '.TIF'],{SaveParams.abt},{SaveParams.dbt},param)
    end
end

%% Optimize FA params
rehash
if strcmpi(SaveParams.find_blobs,'y') && strcmpi(SaveParams.optimize,'y') && isempty(file_search('fa_\w+.TIF',folder))
    WidthRange = [0,100];
    ThreshRange = [0,10000];
    MergeRange = [0,100];
    ParameterValues = SaveParams.blob_params;
    ImageNameCell = file_search([prefix SaveParams.exp_cell{1} '\w+\d+\w+' SaveParams.blob_channel '.TIF'],folder);
    for i = 1:length(ImageNameCell);
        ImageName = ImageNameCell{i};
        Image = double(imread(ImageName));
        Values(i,:) = ParameterSelectorFunction(Image,WidthRange,ThreshRange,MergeRange,ParameterValues);
    end
    SaveParams.blob_params = mean(Values);
    save(fullfile(pwd,folder,['SaveParams_' folder '.mat']),'-struct','SaveParams');
end

%% Generate FA Masks
rehash
if strcmpi(SaveParams.find_blobs,'y') && isempty(file_search('fa_\w+',folder))
    for i = 1:SaveParams.num_exp
        fa_gen([prefix SaveParams.exp_cell{i} '\w+' SaveParams.blob_channel '.TIF'],SaveParams.blob_params,param.destfolder)
    end
end

%% Run Blob Analysis and Mask Images
rehash
if strcmpi(SaveParams.analyze_blobs,'y')
    for i = 1:SaveParams.num_exp
        keywords(i).sizemin = 0;
        keywords(i).sizemax = 10000;
        keywords(i).folder = param.destfolder;
        pre_outname1 = file_search([prefix SaveParams.exp_cell{i} '\w+' SaveParams.Achannel '.TIF'],folder);
        pre_outname2 = pre_outname1{1}(1:end-(10+length(SaveParams.Achannel)));
        keywords(i).outname = pre_outname2;
        if length(file_search('blb_anl\w+.txt',folder)) < i
            blob_analyze({['cna_' prefix SaveParams.exp_cell{i} '\w+' SaveParams.FRETchannel '.TIF'],['bsd_' prefix SaveParams.exp_cell{i} '\w+' SaveParams.Dchannel '.TIF'],['bsa_' prefix SaveParams.exp_cell{i} '\w+' SaveParams.Achannel '.TIF'],[prefix SaveParams.exp_cell{i} '\w+' SaveParams.Schannel '.TIF'],['fa_' prefix SaveParams.exp_cell{i} '\w+.TIF']},keywords(i))
        end
    end
end
rehash
if strcmpi(SaveParams.analyze_blobs,'y') && isempty(file_search('masked\w+.TIF',folder))
    app_mask_FRET_COLOC(SaveParams.Achannel,SaveParams.Dchannel,SaveParams.FRETchannel,SaveParams.Schannel,param.destfolder)
end

%% Select Boundaries and calculate boundary properties
rehash
if strcmpi(SaveParams.reg_select,'y')
    for i = 1:SaveParams.num_exp
        newcols = boundary_dist([prefix SaveParams.exp_cell{i} '\w+\d+\w+' SaveParams.blob_channel '.TIF'],['blb_anl_' keywords(i).outname '.txt'],folder,SaveParams.closed_open,SaveParams.manual,SaveParams.reg_calc,SaveParams.rat,SaveParams.pre_exist,SaveParams.num_channel);
        img_names = file_search([prefix SaveParams.exp_cell{i} '\w+\d+\w+' SaveParams.blob_channel '.TIF'],folder);
        num_img = length(img_names);
        for j = 1:num_img
            mask_img(['polymask\w+' img_names{j}],folder)
        end
        app_cols_blb(['blb_anl_' keywords(i).outname '.txt'],newcols,folder,SaveParams.num_channel)
    end
end