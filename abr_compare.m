%Author(s): Andrew Sivaprakasam
%Description: This is a simple script that generates ABR click/4k/whatever
%waterfalls collected with NEL in a quick/easy manner. Currently no
%peak-picking functionality but can be used to quickly verify/plot data.
%Last Updated: 12/2021

clear all
close all

%TODO: Generalize this for a given data directory structure!

%Script written to compare ABR Data:
pre_data_folder = 'Data/Q405/pre/Baselines';
post_data_folder = 'Data/Q405/post/2weeksPostCA';

%Files with our respective data/probe placements

leg = ["Baseline","Carbo-2Wks"];
scaling = [-1,1];

%Waterfall
waterfall_db = 0:10:80;
%waterfall_db = [0:10:50,80];

%SPECIFY THE PIC NUMS YOU NEED!
pre_click = [4:12];
pre_4k = [13:21];

post_click = [4:12];
post_4k = [13:21];

% Looking at carbo 2wks vs carbo few months
% pre_click = [4:9,12];
% pre_4k = [13:18,21];

% post_click = [4:10];
% post_4k = [11:17];

%Filtering/Resampling
fs = 8e3; %to resample to
cutoff = [300,3e3];

[b,a] = butter(8,[cutoff(1),cutoff(2)]/(fs/2));

%% Get Data and plot 
cwd = pwd;

%load pre data
cd(pre_data_folder);

%REQUIRED: Both 4k and click, pre and post, must have matched number of levels
%TODO: Generalize so that the condition (click,4k) can be called as
%variables

%Pre
for i = 1:length(pre_click)
    %click
    num_click = sprintf('%04d',pre_click(i));
    run(['a',num_click,'_ABR_click']);
    fs_run = floor(ans.AD_Data.SampleRate);
    abr = ans.AD_Data.AD_Avg_V;
    if(iscell(abr))
       abr = abr{1};
       if(iscell(abr))
            abr = abr{1};
       end
    end
    pre_click_waves(:,i) = scaling(1)*(resample(abr,fs,fs_run)-mean(abr));
    clear abr

    %4k
    num_4k = sprintf('%04d',pre_4k(i));
    run(['a',num_4k,'_ABR_4000']);
    fs_run = floor(ans.AD_Data.SampleRate);
    abr = ans.AD_Data.AD_Avg_V;
    if(iscell(abr))
       abr = abr{1};
       if(iscell(abr))
            abr = abr{1};
       end
    end
    pre_4k_waves(:,i) = scaling(2)*(resample(abr,fs,fs_run)-mean(abr));
    clear abr
end

pre_4k_waves = filtfilt(b,a,pre_4k_waves);
pre_click_waves = filtfilt(b,a,pre_click_waves);

%Post
cd(cwd);
cd(post_data_folder);

for i = 1:length(post_click)
    num_click = sprintf('%04d',post_click(i));
    run(['a',num_click,'_ABR_click']);
    fs_run = floor(ans.AD_Data.SampleRate);
    abr = ans.AD_Data.AD_Avg_V;
    if(iscell(abr))
       abr = abr{1};
       if(iscell(abr))
            abr = abr{1};
       end
    end
    post_click_waves(:,i) = scaling(2)*(resample(abr,fs,fs_run)-mean(abr));
    clear abr
   
    num_4k = sprintf('%04d',post_4k(i));
    run(['a',num_4k,'_ABR_4000']);
    fs_run = floor(ans.AD_Data.SampleRate);
    abr = ans.AD_Data.AD_Avg_V;
    if(iscell(abr))
       abr = abr{1};
       if(iscell(abr))
            abr = abr{1};
       end
    end
    post_4k_waves(:,i) = scaling(2)*(resample(abr,fs,fs_run)-mean(abr));
    clear abr;
end

post_4k_waves = filtfilt(b,a,post_4k_waves);
post_click_waves = filtfilt(b,a,post_click_waves);

cd(cwd)

%% Plotting

%click
h1 = figure;
%4k
h2 = figure;
%click difference
h3 = figure;
%4k difference
h4 = figure;

for i = 1:length(waterfall_db)

    figure(h1);
    subplot(length(waterfall_db),1,i);
    hold on
    plot((1:length(pre_click_waves))/fs,pre_click_waves(:,i),'LineWidth',1.5)
    plot((1:length(post_click_waves))/fs,post_click_waves(:,i),'LineWidth',1.5);
    hold off
    title(strcat('Click Waterfall | ',num2str(waterfall_db(i)), ' dB'))
    ylim([-0.02,0.02])
    xlim([0, length(pre_click_waves)/fs]);

    figure(h2);
    subplot(length(waterfall_db),1,i);
    hold on
    plot((1:length(pre_4k_waves))/fs,pre_4k_waves(:,i),'LineWidth',1.5)
    plot((1:length(post_4k_waves))/fs,post_4k_waves(:,i),'LineWidth',1.5);
    hold off
    title(strcat('4k Waterfall | ',num2str(waterfall_db(i)), ' dB'))
    ylim([-0.02,0.02])
    xlim([0, length(pre_4k_waves)/fs]);

    %correct for any length differences
    difflength = min(length(post_click_waves),length(pre_click_waves));

    figure(h3);
    subplot(length(waterfall_db),1,i);
    hold on
    plot((1:difflength)/fs,pre_click_waves(1:difflength,i)-post_click_waves(1:difflength,i),'k','LineWidth',1.5)
    hold off
    title(strcat('Click Waterfall | Pre-Post |',num2str(waterfall_db(i)), ' dB'))
    ylim([-0.02,0.02])
    xlim([0, difflength/fs]);

    figure(h4);
    subplot(length(waterfall_db),1,i);
    hold on
    plot((1:difflength)/fs,pre_4k_waves(1:difflength,i)-post_4k_waves(1:difflength,i),'k','LineWidth',1.5)
    hold off
    title(strcat('4k Waterfall | Pre-Post |',num2str(waterfall_db(i)), ' dB'))
    ylim([-0.02,0.02])
    xlim([0, difflength/fs]);

end 


figure(h1);
legend(leg);
xlabel('Time (s)');
set(gcf,'Position',[20,20,800,1200]);

figure(h2);
legend(leg);
xlabel('Time (s)');
set(gcf,'Position',[830,1230,800,1200]);

figure(h3);
legend('Difference');
xlabel('Time (s)');
set(gcf,'Position',[830,1230,800,1200]);

figure(h4);
legend('Difference');
xlabel('Time (s)');
set(gcf,'Position',[830,1230,800,1200]);

%% Figure Exporting (uncomment if exporting)

print(h1,'click_comparison','-r300','-dpng');
print(h2,'4k_comparison','-r300','-dpng');
