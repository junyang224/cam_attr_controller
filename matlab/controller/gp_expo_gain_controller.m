function [optimal_expo, optimal_gain, optimal_img] = gp_expo_grain_controller(o_img, plot_optimal)
%GP_EXPO_GRAIN_CONTROLLER Summary of this function goes here
%   Detailed explanation goes here

%% HDR CRF curve fitting from a set of images
global E;   % irradiance
global B;   % sample time array for crf curve fitting
global time_itv;
global is_indoor;        

if (is_indoor) 
    test_env = 'indoor';
    time_array = [1, 18, 28, 38];   % [ms]
    time_itv = 0.0005; 
    B = log(E* (0.0001+ (time_array.* time_itv)));

else
    test_env = 'outdoor';
    time_array = [1, 15, 70, 90];   % [ms]
    time_itv = 0.00005; 
    B = log(E* (0.00005 + (time_array.* time_itv)));
end

datapath = strcat('../data/', test_env, '_sample/');

crf = csvread(strcat(datapath, 'crf.csv'));

%%

gain_roi = 1:13; % 
expo_roi = 1:39; % 

% indoor: 1000~20000 us (500us)
% outdoor: 100~2000 us (50us)
% gain: 0~12

[expos, gains] = meshgrid(expo_roi, gain_roi);

gain_arr = gains(:);
expo_arr = expos(:);

% initial_points = [sub2ind([13 59], 4, 10) sub2ind([13 59], 4, 30), ...
%                   sub2ind([13 59], 10, 10) sub2ind([13 59], 10, 30), ...
%                   sub2ind([13 39], 7, 20)];
initial_points = [sub2ind([13 39], 1, 1) ];

next_in = initial_points;
              
psi = 0;

for i = 1:length(initial_points)
    [target_gain, target_expo_index] = ind2sub([13 39], initial_points(i));
    img_metric = extract_img_metric(true, o_img, target_expo_index, target_gain, crf);
    metrics(i) = img_metric;
end

for i = 1:5
%     idx = [next_in,  round(fidx*0.95)] % 38,50,26,8
%     idx = [next_in,  next_in(1)+5] % 38,50,26,8 
    if length(next_in) > length(metrics)
        idx_metrics = length(metrics);
        target_expo_index = expo_arr(next_in(end));
        target_gain = gain_arr(next_in(end));
        img_metric = extract_img_metric(true, o_img, target_expo_index, target_gain, crf);
        metrics(idx_metrics+1) = img_metric;
    end
    idx_train = [next_in];
    t_train = [expo_arr(idx_train), gain_arr(idx_train)]';
    y_train = metrics;
    disp([num2str(i) ' ' num2str(expo_arr(idx_train(end))) '  ' num2str(gain_arr(idx_train(end))) '  ' num2str(y_train(end)) '; ']);
    

    tic;
    cfg = gp_cov_init ();
    K = gp_train (t_train, y_train, cfg);

    %% predict
%     idx = next_in(1):1:round(fidx*0.95);
    idx_pred = 1:1:numel(gain_arr);
    t_pred = [expo_arr(idx_pred), gain_arr(idx_pred)]';
%     y_true = metric_arr(idx);

    [y_pred, var_pred] = gp_predict (t_pred, t_train, K, y_train', cfg);
    [vals, optimal_id] = max(y_pred);
%     toc;
    
%     selection by GPMI
    alpha = 50; % 70 
    max_var = max(diag(var_pred));
    index_next = length(next_in) + 1;
    [next_in(index_next), psi, acq_func] = gpmi_optim(y_pred, var_pred, alpha, psi);

%     % selection by var max
%     acq_func = diag(var_pred);
%     max_var = max(diag(var_pred));
%     [va, in] = max(acq_func);
%     in(i) = in;
%     next_in(i+1) = in(i);
%     t_pred(next_in(i+1));
    
%     % stop criteria
%     if abs(t_pred(next_in(i+1))-t_pred(next_in(i))) < 15 || max_var < 500
%         [max_val, optimal_id] = max(y_pred);
%         fprintf('break, Optimal exposure time is %d \n', t_pred(optimal_id));
%         break;
%     end


% data = csvread(strcat(datapath, '/our_data.csv'));
% 
% real = data(gain_arr(idx_train(end)), expo_arr(idx_train(end)))/2.5;
% real_y = data(gain_arr(idx_train(:)), expo_arr(idx_train(:)))/2.5;
% 
% disp([num2str(i) '  ' num2str(expo_arr(idx_train(end))) '  ' num2str(gain_arr(idx_train(end))) '  ' num2str(real) ';  ']);
%     

end

%%
t_selected = t_pred(:, optimal_id)
y_selected = y_pred(optimal_id)

optimal_expo = t_selected(1);
optimal_gain = t_selected(2);


[~, optimal_img] =  extract_img_metric(true, o_img, optimal_expo, optimal_gain, crf);

if plot_optimal
    figure(222);
    clf;
    s2 = surf(reshape(y_pred, size(expos)), 'FaceAlpha',0.7); xlabel('Exposure time'); ylabel('Gain'); zlabel('NEWG'); hold on;
    s2.EdgeColor = 'none';
%     colormap(bone)

    p1 = plot3(t_selected(1), t_selected(2), y_selected  , 'ro', 'LineWidth', 5);
%     figure(333);
    p2 = plot3(t_train(1,:), t_train(2,:), y_train , 'kx', 'LineWidth', 5);
    
% data = csvread(strcat(datapath, '/our_data.csv'));
% 
% hold on
% data = data/2.5;
% caxis('manual');
% surf(data, 'LineStyle', 'none')


legend boxoff
    for ii = 1:length(t_train(1,:) )
        t = text(t_train(1,ii)-1.5, t_train(2,ii), 40, num2str(ii));
        t.Color = [0 0 0];
        t.FontSize = 20;
    end
    le = legend([p1 p2], 'Optimal point', 'Training points', 'Location', 'northeast', 'TextColor', 'b')
    colorbar;
    le.FontSize = 20;
    legend boxoff
    view(2);
%     axis([0 40 0 15 0 40])
%    colormap(bone)








end

end

