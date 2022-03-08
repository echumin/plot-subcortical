function plot_subcort(path2parc,subc_vals,base_clr)
%%                      Subcortical MRI Plot                            %%
% Description:
% Plot an overlay of subcortical values for a given input parcellation onto 
% MNI152_1mm MRI template, as varying saturations on an input color.

%INPUTS:
%       path2parc - path to nifti parcellation with integer indices in
%               MNI152_1mm space.
%       subc_vals - A vector of values to plot, one for each region in the
%               input parcellation (in order matching the accending
%               parcellation indices).
%       base_clr - base color to be used to plot values as saturation of that
%               color (rgb_triplet).
%
% Evgeny Chumin, Indiana University, 2022
%%
%% RGB values for each subcortical node.
vals_rgb = zeros(length(subc_vals),3);
    vals_rgb(:,:) = interp1(linspace(min(subc_vals),max(subc_vals),6),...
        [ones(1,3)*0.1; ones(1,3)*0.4; ones(1,3)*0.7;...
        base_clr + 0.2; base_clr; base_clr],subc_vals);
vals_rgb(vals_rgb > 1) = 1;

%% create evenly distributed centered colormap
    vals_rgb_even = interp1(linspace(min(subc_vals),max(subc_vals),6),...
        [ones(1,3)*0.1; ones(1,3)*0.4; ones(1,3)*0.7;...
        base_clr + 0.2; base_clr; base_clr],linspace(min(subc_vals),max(subc_vals)));
% Make the figure
fclr = figure(...
    'units','inches',...
    'position',[1 1 3 1],...
    'paperpositionmode','auto');
fclr.Color='w'; 
 
imagesc(1:1:100)
yticks([])
xticks([1 100])
colormap(vals_rgb_even)
xticklabels([round(min(subc_vals),2) round(max(subc_vals),2)])

%% load subcortical parcellation
tsc_info = niftiinfo(path2parc);
tsc = niftiread(tsc_info);
tc_info = niftiinfo('MNI152_T1_1mm_brain.nii.gz');
tc = niftiread(tc_info);

% oriented coordinate order x,y,x in accending order: A-P x
% coordinates, L-R y coordinates, I-S z coordiantes.
tsc = permute(tsc, [2 1 3]);
tsc = flip(tsc,1);
tsc = flip(tsc,2);
tc = permute(tc, [2 1 3]);
tc = flip(tc,1);
tc = flip(tc,2);

% crop the field of view to subcortex
% finding the first and last slices with data along each dimention
[x,y,z]=size(tsc);
for i=1:x
    tmp(i)=sum(sum(tsc(i,:,:)));
end
x_bounds(1)=find(tmp>0,1,'first');
x_bounds(2)=find(tmp>0,1,'last');
clear tmp
for i=1:y
    tmp(i)=sum(sum(tsc(:,i,:)));
end
y_bounds(1)=find(tmp>0,1,'first');
y_bounds(2)=find(tmp>0,1,'last');
clear tmp
for i=1:z
    tmp(i)=sum(sum(tsc(:,:,i)));
end
z_bounds(1)=find(tmp>0,1,'first');
z_bounds(2)=find(tmp>0,1,'last');
%---------------------------------%
tsc_fov = tsc(x_bounds(1)-5:x_bounds(2)+5,y_bounds(1)-5:y_bounds(2)+5,z_bounds(1)-5:z_bounds(2)+5);
tc_fov = tc(x_bounds(1)-5:x_bounds(2)+5,y_bounds(1)-5:y_bounds(2)+5,z_bounds(1)-5:z_bounds(2)+5);

% These are slices I chose in advance (from the cropped images), in order I want them
% plotted. The nan is where the z slice will go.
x_slices = [16 31 nan 53 66];
z_slice = 32;

% pull out 2D slices and rotate them for the figure
for i=1:5
    if i<3
%left hemisphere
        s1{i,1} = flip(rot90(squeeze(tsc_fov(:,x_slices(i),:))),2);
    elseif i==3
% center axial
        s1{i,1} = tsc_fov(:,:,z_slice); 
    elseif i>3
% right hemisphere
        s1{i,1} = flipud(permute(squeeze(tsc_fov(:,x_slices(i),:)),[2 1]));
    end
end

% switch out node indices for corresponding RGB
s = cell(5,1);
for si=1:5
    [row,col]=size(s1{si,1});
    s{si,1}=zeros(row,col,3);   
    for r=1:row
        for c=1:col
            if s1{si,1}(r,c)>0
            s{si,1}(r,c,:)=vals_rgb(s1{si,1}(r,c),:);
            else
                s{si,1}(r,c,:)=[1 1 1];
            end
        end
    end
end

% Make the figure
fig_handle = figure(...
    'units','inches',...
    'position',[1 1 8 3],...
    'paperpositionmode','auto');

fig_handle.Color='w'; 
gmap = gray(256);
a=0.8; % alpha
tl=tiledlayout(1,5,'TileSpacing','none','Padding','none');
for i=1:5
    idx=unique(s1{i});
    if i<3
        nexttile
        ax(i)=gca;
        fig_handle(i)=imagesc(flip(rot90(squeeze(tc_fov(:,x_slices(i),:))),2));
        colormap(ax(i),gray(256))
        hold on
        set(gca,'DataAspectRatio',[1 1 1])
        fig_handle(i+5)=imagesc(s{i});
        msk = sum(s{i},3);
        msk(msk==3)=0;
        msk(msk~=0)=a;
        fig_handle(i+5).AlphaData=msk;
        for cnt=2:length(idx)
            contour(s1{i}==idx(cnt),1,'LineColor','w','LineWidth',1);
        end
    elseif i==3
        nexttile
        ax(i)=gca;
        fig_handle(i)=imagesc(tc_fov(:,:,z_slice));
        colormap(ax(i),gray(256))
        hold on
        set(gca,'DataAspectRatio',[1 1 1])
        fig_handle(i+5)=imagesc(s{i});
        msk = sum(s{i},3);
        msk(msk==3)=0;
        msk(msk~=0)=a;
        fig_handle(i+5).AlphaData=msk;
        for cnt=2:length(idx)
            contour(s1{i}==idx(cnt),1,'LineColor','w','LineWidth',1);
        end
    elseif i>3
        nexttile
        ax(i)=gca;
        fig_handle(i)=imagesc(flipud(permute(squeeze(tc_fov(:,x_slices(i),:)),[2 1])));
        colormap(ax(i),gray(256))
        hold on
        set(gca,'DataAspectRatio',[1 1 1])
        fig_handle(i+5)=imagesc(s{i});
        msk = sum(s{i},3);
        msk(msk==3)=0;
        msk(msk~=0)=a;
        fig_handle(i+5).AlphaData=msk;
        for cnt=2:length(idx)
            contour(s1{i}==idx(cnt),1,'LineColor','w','LineWidth',1);
        end
    end
    set(tl.Children,'XTick',[],'YTick',[]);
end    
        