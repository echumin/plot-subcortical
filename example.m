

% Example usage of the plot_subcort function

% Here the Tian et.al., 2020 scale 2 subcortical parcellation is used as
% the example
path2parc = fullfile(pwd,'Tian_Subcortex_S2_3T_1mm.nii.gz');

% For our vector of subcortical values we use a random set of numbers
subc_vals = rand([32 1]);

% For the base color we will use blue
base_clr = [0.4660 0.6740 0.1880];

% run the plot function
plot_subcort(path2parc,subc_vals,base_clr)