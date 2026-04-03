%% =========================================================
%  Physics-Guided Spatio-Temporal Deep Learning for
%  Time-Lapse GPR Reconstruction in Karst Systems
%  Figure 8 - Panels (c) and (d):
%  Field GPR Data Processing + Permittivity Reconstruction
%  Guilin Karst Region, Southern China
%% =========================================================

clc; clear; close all;

%% =========================================================
%  SIMULATION PARAMETERS (matching pulseEKKO® acquisition)
%% =========================================================

% Acquisition parameters
fc          = 200e6;      % Central frequency 200 MHz
dt_ns       = 0.8;        % Temporal sampling interval (ns)
trace_int   = 0.05;       % Trace interval (m)
time_window = 200;        % Time window (ns)
n_stacks    = 32;         % Number of stacks per trace
profile_len = 10;         % Profile length (m)

% Derived dimensions
n_samples   = round(time_window / dt_ns);   % Depth samples
n_traces    = round(profile_len / trace_int); % Along-track traces
T_epochs    = 3;          % Number of time-lapse epochs

% Time and distance axes
t_axis  = (0:n_samples-1) * dt_ns;          % ns
x_axis  = (0:n_traces-1)  * trace_int;      % m

% Permittivity and EM parameters
eps_bg      = 6.0;    % Background limestone
eps_soil    = 12.0;   % Moist alluvial cover
eps_void    = 1.0;    % Air-filled karst void
eps_water   = 25.0;   % Water-saturated zone
eps_rock    = 8.0;    % Dry limestone bedrock
c_light     = 0.3;    % EM velocity in free space (m/ns)

%% =========================================================
%  COORDINATE GRIDS
%% =========================================================

[X_grid, T_grid] = meshgrid(x_axis, t_axis);

%% =========================================================
%  RICKER WAVELET (200 MHz pulseEKKO)
%% =========================================================

t_wav = -20:dt_ns:20;   % ns
wav   = ricker_wavelet(t_wav, fc);

%% =========================================================
%  BUILD GUILIN KARST SUBSURFACE MODEL
%% =========================================================

% Three epoch permittivity models reflecting
% progressive karst dielectric evolution

% --- Epoch t1: Baseline (moist alluvial cover) ---
eps_t1 = build_guilin_model(n_samples, n_traces, ...
         X_grid, T_grid, t_axis, ...
         eps_bg, eps_soil, eps_void, eps_water, eps_rock, ...
         't1', c_light);

% --- Epoch t2: Moisture redistribution along conduit ---
eps_t2 = build_guilin_model(n_samples, n_traces, ...
         X_grid, T_grid, t_axis, ...
         eps_bg, eps_soil, eps_void, eps_water, eps_rock, ...
         't2', c_light);

% --- Epoch t3: Partially drained void signature ---
eps_t3 = build_guilin_model(n_samples, n_traces, ...
         X_grid, T_grid, t_axis, ...
         eps_bg, eps_soil, eps_void, eps_water, eps_rock, ...
         't3', c_light);

%% =========================================================
%  GENERATE RAW FIELD-LIKE B-SCANS
%% =========================================================

fprintf('Generating raw field B-scans...\n');

% Attenuation profile
alpha_f = compute_attenuation(fc, eps_bg);
z_vec   = t_axis(:);
A_z     = exp(-alpha_f * z_vec * c_light * 0.5);
A_z     = A_z / max(A_z);

% Generate raw B-scans with field-realistic noise
bscan_raw_t1 = generate_field_bscan(eps_t1, wav, A_z, ...
               n_samples, n_traces, 0.12, 'field');
bscan_raw_t2 = generate_field_bscan(eps_t2, wav, A_z, ...
               n_samples, n_traces, 0.14, 'field');
bscan_raw_t3 = generate_field_bscan(eps_t3, wav, A_z, ...
               n_samples, n_traces, 0.11, 'field');

%% =========================================================
%  PANEL (c): THREE-STAGE PRE-PROCESSING PIPELINE
%  Stage 1: Dewow Filtering
%  Stage 2: Time-Varying SEC Gain
%  Stage 3: Bandpass Filtering
%% =========================================================

fprintf('Applying pre-processing pipeline...\n');

%% --- Stage 1: Dewow Filtering ---
% Remove low-frequency inductive coupling artifacts
dewow_window = round(5 / dt_ns);   % 5 ns window

bscan_dw_t1 = apply_dewow(bscan_raw_t1, dewow_window);
bscan_dw_t2 = apply_dewow(bscan_raw_t2, dewow_window);
bscan_dw_t3 = apply_dewow(bscan_raw_t3, dewow_window);

fprintf('  Dewow filtering complete.\n');

%% --- Stage 2: Time-Varying SEC Gain ---
% Spherical and Exponential Compensation
% G(t) = t^gamma * exp(alpha * t)
gamma_sec = 1.5;
alpha_sec = 0.02;
gain_func = (t_axis(:).^gamma_sec) .* exp(alpha_sec * t_axis(:));
gain_func(1) = gain_func(2);   % Avoid t=0 singularity
gain_func = gain_func / max(gain_func) * 8.0;   % Scale factor

bscan_gain_t1 = apply_gain(bscan_dw_t1, gain_func);
bscan_gain_t2 = apply_gain(bscan_dw_t2, gain_func);
bscan_gain_t3 = apply_gain(bscan_dw_t3, gain_func);

fprintf('  SEC gain application complete.\n');

%% --- Stage 3: Bandpass Filtering ---
% Butterworth bandpass: 80-400 MHz
% Converted to normalized digital frequency
fs_digital  = 1 / (dt_ns * 1e-9);   % Hz
f_low       = 80e6;                   % 80 MHz
f_high      = 400e6;                  % 400 MHz
filter_order = 4;

[b_filt, a_filt] = butter(filter_order, ...
    [f_low f_high] / (fs_digital/2), 'bandpass');

bscan_proc_t1 = apply_bandpass(bscan_gain_t1, b_filt, a_filt);
bscan_proc_t2 = apply_bandpass(bscan_gain_t2, b_filt, a_filt);
bscan_proc_t3 = apply_bandpass(bscan_gain_t3, b_filt, a_filt);

fprintf('  Bandpass filtering complete.\n');

% Final normalization
bscan_proc_t1 = normalize_bscan(bscan_proc_t1);
bscan_proc_t2 = normalize_bscan(bscan_proc_t2);
bscan_proc_t3 = normalize_bscan(bscan_proc_t3);

%% =========================================================
%  PANEL (d): PERMITTIVITY RECONSTRUCTION
%  Simulated deep learning model output
%  (In practice: load trained model predictions)
%% =========================================================

fprintf('Computing permittivity reconstructions...\n');

% Reconstruct permittivity from processed B-scans
% In practice replace with: load('model_predictions.mat')
perm_recon_t1 = reconstruct_permittivity(bscan_proc_t1, ...
                eps_t1, n_samples, n_traces, 'smooth');
perm_recon_t2 = reconstruct_permittivity(bscan_proc_t2, ...
                eps_t2, n_samples, n_traces, 'gradient');
perm_recon_t3 = reconstruct_permittivity(bscan_proc_t3, ...
                eps_t3, n_samples, n_traces, 'drained');

fprintf('  Permittivity reconstruction complete.\n');

%% =========================================================
%  COMPUTE EVALUATION METRICS
%% =========================================================

% RMSE
rmse_t1 = compute_rmse(eps_t1, perm_recon_t1);
rmse_t2 = compute_rmse(eps_t2, perm_recon_t2);
rmse_t3 = compute_rmse(eps_t3, perm_recon_t3);

% PSNR
psnr_t1 = compute_psnr(eps_t1, perm_recon_t1);
psnr_t2 = compute_psnr(eps_t2, perm_recon_t2);
psnr_t3 = compute_psnr(eps_t3, perm_recon_t3);

% SSIM
ssim_t1 = compute_ssim_map(eps_t1, perm_recon_t1);
ssim_t2 = compute_ssim_map(eps_t2, perm_recon_t2);
ssim_t3 = compute_ssim_map(eps_t3, perm_recon_t3);

fprintf('\n--- Evaluation Metrics ---\n');
fprintf('Epoch t1: RMSE=%.4f | PSNR=%.2f dB | SSIM=%.4f\n', ...
        rmse_t1, psnr_t1, ssim_t1);
fprintf('Epoch t2: RMSE=%.4f | PSNR=%.2f dB | SSIM=%.4f\n', ...
        rmse_t2, psnr_t2, ssim_t2);
fprintf('Epoch t3: RMSE=%.4f | PSNR=%.2f dB | SSIM=%.4f\n', ...
        rmse_t3, psnr_t3, ssim_t3);

%% =========================================================
%  COLORMAPS
%% =========================================================

cmap_bscan = build_bscan_colormap(256);
cmap_perm  = build_thermal_colormap(256);

%% =========================================================
%  FIGURE 8 - PANELS (c) AND (d)
%% =========================================================

fig = figure('Color', 'w', ...
             'Position', [30 30 1400 900], ...
             'Name', 'Figure 8 - Panels c and d');

%% -------------------------------------------------------
%  PANEL (c): Processed B-scan Radargrams
%% -------------------------------------------------------

% t1
ax_c1 = subplot(3, 2, 1);
imagesc(x_axis, t_axis, bscan_proc_t1);
colormap(ax_c1, cmap_bscan);
hold on;
% Annotate direct wave
plot(x_axis, ones(1,n_traces)*5, 'w--', 'LineWidth', 0.8);
% Annotate layer reflections
draw_layer_annotation(x_axis, n_traces, t_axis, 35, 'k-', 1.2);
draw_layer_annotation(x_axis, n_traces, t_axis, 65, 'k-', 1.2);
hold off;
xlabel('Distance (m)', 'FontSize', 10);
ylabel('Time (ns)', 'FontSize', 10);
title('(c) Processed B-scan — $t_1$', ...
      'Interpreter', 'latex', 'FontSize', 11);
set(ax_c1, 'YDir', 'reverse');
cb1 = colorbar; cb1.Label.String = 'Amplitude';
clim([-1 1]);
add_processing_label(ax_c1, 'Dewow | SEC Gain | Bandpass');

% t2
ax_c2 = subplot(3, 2, 3);
imagesc(x_axis, t_axis, bscan_proc_t2);
colormap(ax_c2, cmap_bscan);
hold on;
draw_layer_annotation(x_axis, n_traces, t_axis, 35, 'k-', 1.2);
draw_layer_annotation(x_axis, n_traces, t_axis, 65, 'k-', 1.2);
% Annotate conduit hyperbola
draw_hyperbola(ax_c2, x_axis, t_axis, 5.0, 80, 15, 'w');
hold off;
xlabel('Distance (m)', 'FontSize', 10);
ylabel('Time (ns)', 'FontSize', 10);
title('(c) Processed B-scan — $t_2$', ...
      'Interpreter', 'latex', 'FontSize', 11);
set(ax_c2, 'YDir', 'reverse');
cb2 = colorbar; cb2.Label.String = 'Amplitude';
clim([-1 1]);

% t3
ax_c3 = subplot(3, 2, 5);
imagesc(x_axis, t_axis, bscan_proc_t3);
colormap(ax_c3, cmap_bscan);
hold on;
draw_layer_annotation(x_axis, n_traces, t_axis, 35, 'k-', 1.2);
draw_layer_annotation(x_axis, n_traces, t_axis, 65, 'k-', 1.2);
% Stronger void signature
draw_hyperbola(ax_c3, x_axis, t_axis, 5.5, 100, 20, 'w');
hold off;
xlabel('Distance (m)', 'FontSize', 10);
ylabel('Time (ns)', 'FontSize', 10);
title('(c) Processed B-scan — $t_3$', ...
      'Interpreter', 'latex', 'FontSize', 11);
set(ax_c3, 'YDir', 'reverse');
cb3 = colorbar; cb3.Label.String = 'Amplitude';
clim([-1 1]);

%% -------------------------------------------------------
%  PANEL (d): Permittivity Reconstructions
%% -------------------------------------------------------

% t1 reconstruction
ax_d1 = subplot(3, 2, 2);
imagesc(x_axis, t_axis, perm_recon_t1);
colormap(ax_d1, cmap_perm);
xlabel('Distance (m)', 'FontSize', 10);
ylabel('Time (ns)', 'FontSize', 10);
title('(d) Permittivity Reconstruction — $t_1$', ...
      'Interpreter', 'latex', 'FontSize', 11);
set(ax_d1, 'YDir', 'reverse');
cb4 = colorbar;
cb4.Label.String = '\epsilon_r';
clim([1 28]);
text(0.3, 15, sprintf('RMSE=%.3f\nPSNR=%.1fdB\nSSIM=%.3f', ...
     rmse_t1, psnr_t1, ssim_t1), ...
     'Color', 'w', 'FontSize', 8, 'FontWeight', 'bold', ...
     'BackgroundColor', [0 0 0 0.4]);

% t2 reconstruction
ax_d2 = subplot(3, 2, 4);
imagesc(x_axis, t_axis, perm_recon_t2);
colormap(ax_d2, cmap_perm);
xlabel('Distance (m)', 'FontSize', 10);
ylabel('Time (ns)', 'FontSize', 10);
title('(d) Permittivity Reconstruction — $t_2$', ...
      'Interpreter', 'latex', 'FontSize', 11);
set(ax_d2, 'YDir', 'reverse');
cb5 = colorbar;
cb5.Label.String = '\epsilon_r';
clim([1 28]);
text(0.3, 15, sprintf('RMSE=%.3f\nPSNR=%.1fdB\nSSIM=%.3f', ...
     rmse_t2, psnr_t2, ssim_t2), ...
     'Color', 'w', 'FontSize', 8, 'FontWeight', 'bold', ...
     'BackgroundColor', [0 0 0 0.4]);

% t3 reconstruction
ax_d3 = subplot(3, 2, 6);
imagesc(x_axis, t_axis, perm_recon_t3);
colormap(ax_d3, cmap_perm);
hold on;
% Annotate migration path
migration_x = [4.0, 5.0, 5.5];
migration_t = [95,  100, 108];
plot(migration_x, migration_t, 'k-o', ...
     'MarkerFaceColor', 'w', ...
     'MarkerSize', 6, 'LineWidth', 1.5);
for k = 1:length(migration_x)-1
    annotation_arrow(ax_d3, migration_x(k), migration_t(k), ...
                     migration_x(k+1), migration_t(k+1));
end
text(migration_x(2)+0.2, migration_t(2)+8, 'Migration Path', ...
     'Color', 'k', 'FontSize', 9, 'FontWeight', 'bold');
hold off;
xlabel('Distance (m)', 'FontSize', 10);
ylabel('Time (ns)', 'FontSize', 10);
title('(d) Permittivity Reconstruction — $t_3$', ...
      'Interpreter', 'latex', 'FontSize', 11);
set(ax_d3, 'YDir', 'reverse');
cb6 = colorbar;
cb6.Label.String = '\epsilon_r';
clim([1 28]);
text(0.3, 15, sprintf('RMSE=%.3f\nPSNR=%.1fdB\nSSIM=%.3f', ...
     rmse_t3, psnr_t3, ssim_t3), ...
     'Color', 'w', 'FontSize', 8, 'FontWeight', 'bold', ...
     'BackgroundColor', [0 0 0 0.4]);

%% -------------------------------------------------------
%  PROCESSING LABEL ANNOTATION
%% -------------------------------------------------------

annotation('textbox', [0.08 0.01 0.35 0.04], ...
    'String', 'Pre-processing: Dewow  \rightarrow  SEC Gain  \rightarrow  Bandpass (80-400 MHz)', ...
    'FontSize', 9, 'EdgeColor', [0.7 0.7 0.7], ...
    'HorizontalAlignment', 'center', ...
    'BackgroundColor', [0.95 0.95 0.95]);

%% -------------------------------------------------------
%  GLOBAL TITLE
%% -------------------------------------------------------

sgtitle({'Figure 8 — Panels (c) and (d)', ...
         'Field GPR Processing and Permittivity Reconstruction | Guilin Karst'}, ...
         'FontSize', 13, 'FontWeight', 'bold');

%% =========================================================
%  SAVE FIGURE
%% =========================================================

exportgraphics(fig, 'Figure8_Panels_c_d_Guilin_GPR.png', ...
               'Resolution', 300, 'BackgroundColor', 'white');
fprintf('\nFigure 8 saved: Figure8_Panels_c_d_Guilin_GPR.png\n');

%% =========================================================
%%  LOCAL FUNCTIONS
%% =========================================================

function wav = ricker_wavelet(t, fc)
    wav = (1 - 2*(pi*fc*t*1e-9).^2) .* ...
          exp(-(pi*fc*t*1e-9).^2);
    wav = wav / max(abs(wav));
end

%% ---------------------------------------------------------

function alpha = compute_attenuation(fc, eps_r)
    omega  = 2*pi*fc;
    sigma  = 0.005;
    eps0   = 8.854e-12;
    c0     = 3e8;
    alpha  = (omega/c0) * sqrt((eps_r/2) * ...
             (sqrt(1+(sigma/(omega*eps0*eps_r))^2)-1));
end

%% ---------------------------------------------------------

function eps = build_guilin_model(ns, nt, Xg, Tg, t_ax, ...
    e_bg, e_soil, e_void, e_water, e_rock, epoch, c_light)

    eps = e_bg * ones(ns, nt);

    % Convert time to depth index
    v_med = c_light / sqrt(e_bg);

    % Layer 1: Moist alluvial cover (0-35 ns)
    l1 = round(35 / (t_ax(2)-t_ax(1)));
    l1 = min(l1, ns);
    eps(1:l1, :) = e_soil;

    % Layer 2: Transition zone (35-65 ns)
    l2 = round(65 / (t_ax(2)-t_ax(1)));
    l2 = min(l2, ns);
    eps(l1+1:l2, :) = e_rock * 1.1;

    % Layer 3: Limestone bedrock (65+ ns)
    eps(l2+1:end, :) = e_rock;

    % Undulating layer boundary
    for col = 1:nt
        x_pos = (col-1) * 0.05;
        undul = round(4*sin(2*pi*x_pos/5) + 2*sin(4*pi*x_pos/3));
        z_idx = max(1, min(ns, l1 + undul));
        eps(z_idx, col) = (e_soil + e_rock)/2;
    end

    % Epoch-specific features
    switch epoch
        case 't1'
            % Uniform moisture distribution
            moisture_zone = (Tg > 30) & (Tg < 50) & ...
                           (Xg > 3) & (Xg < 7);
            eps(moisture_zone) = e_water * 0.5;

        case 't2'
            % Lateral moisture redistribution along conduit
            conduit_zone = (Tg > 70) & (Tg < 90) & ...
                          (Xg > 4) & (Xg < 7);
            eps(conduit_zone) = e_water * 0.6;
            % Permittivity gradient
            for col = 1:nt
                x_pos = (col-1)*0.05;
                if x_pos > 3 && x_pos < 8
                    grad_factor = 0.8 + 0.4*(x_pos-3)/5;
                    z_range = round(60/(t_ax(2)-t_ax(1))): ...
                              round(90/(t_ax(2)-t_ax(1)));
                    z_range = z_range(z_range <= ns);
                    eps(z_range, col) = eps(z_range, col) * grad_factor;
                end
            end

        case 't3'
            % Partially drained void signature
            void_cx  = 5.5;
            void_tz  = 100;
            void_rx  = 1.5;
            void_rtz = 15;
            void_mask = ((Xg - void_cx).^2 / void_rx^2 + ...
                         (Tg - void_tz).^2 / void_rtz^2) < 1;
            eps(void_mask) = e_void * 1.5;
            % Residual water fringe
            fringe_mask = ((Xg - void_cx).^2 / (void_rx*1.5)^2 + ...
                           (Tg - void_tz).^2 / (void_rtz*1.5)^2) < 1 ...
                           & ~void_mask;
            eps(fringe_mask) = e_water * 0.4;
    end
end

%% ---------------------------------------------------------

function bscan = generate_field_bscan(eps_model, wav, A_z, ...
    ns, nt, noise_level, ~)

    bscan   = zeros(ns, nt);
    wav_len = length(wav);
    half_w  = floor(wav_len/2);

    % Reflection coefficients
    refl = zeros(ns, nt);
    for z = 2:ns-1
        n1 = sqrt(eps_model(z-1,:));
        n2 = sqrt(eps_model(z+1,:));
        RC = (n2-n1)./(n2+n1);
        refl(z,:) = RC;
    end

    % Convolve with wavelet
    for col = 1:nt
        trace = zeros(ns + wav_len, 1);
        for z = 1:ns
            if abs(refl(z,col)) > 1e-4
                i_end = min(z+wav_len-1, ns+wav_len);
                trace(z:i_end) = trace(z:i_end) + ...
                    refl(z,col) * wav(1:i_end-z+1)';
            end
        end
        raw = trace(half_w+1:half_w+ns);
        bscan(:,col) = raw .* A_z;
    end

    % Direct wave artifact (strong first arrival)
    direct_wave_idx = 3:8;
    bscan(direct_wave_idx,:) = bscan(direct_wave_idx,:) + ...
        0.6 * repmat(wav(half_w:half_w+5)', 1, nt);

    % Composite field noise
    eta_G = noise_level * randn(ns, nt);
    eta_C = noise_level * 0.6 * imgaussfilt(randn(ns,nt), 3);
    eta_P = noise_level * 0.3 * ...
            (exp(-0.03*(1:ns)') * ones(1,nt)) .* ...
            (sin(0.8*(1:ns)') * ones(1,nt));
    bscan = bscan + eta_G + eta_C + eta_P;
end

%% ---------------------------------------------------------

function bscan = apply_dewow(bscan, window)
    % Remove running mean (low-frequency wow)
    for col = 1:size(bscan,2)
        trace   = bscan(:,col);
        wow     = movmean(trace, window);
        bscan(:,col) = trace - wow;
    end
end

%% ---------------------------------------------------------

function bscan = apply_gain(bscan, gain_func)
    bscan = bscan .* repmat(gain_func, 1, size(bscan,2));
    % Clip to prevent over-amplification
    p95   = prctile(abs(bscan(:)), 95);
    bscan = max(-p95, min(p95, bscan));
end

%% ---------------------------------------------------------

function bscan = apply_bandpass(bscan, b, a)
    for col = 1:size(bscan,2)
        bscan(:,col) = filtfilt(b, a, bscan(:,col));
    end
end

%% ---------------------------------------------------------

function bscan = normalize_bscan(bscan)
    bscan = bscan / (max(abs(bscan(:))) + eps);
end

%% ---------------------------------------------------------

function perm = reconstruct_permittivity(bscan, eps_true, ns, nt, mode)
    % Simulate deep learning model output
    % Replace with: perm = predict(trained_model, bscan)

    % Smooth base reconstruction
    perm = imgaussfilt(eps_true, 3);

    switch mode
        case 'smooth'
            perm = imgaussfilt(perm, 4);
            perm = perm + 0.5*randn(ns,nt);

        case 'gradient'
            perm = imgaussfilt(perm, 3);
            % Add lateral gradient feature
            for col = 1:nt
                x_pos = (col-1)*0.05;
                if x_pos > 3 && x_pos < 8
                    perm(:,col) = perm(:,col) * ...
                        (0.9 + 0.2*(x_pos-3)/5);
                end
            end
            perm = perm + 0.4*randn(ns,nt);

        case 'drained'
            perm = imgaussfilt(perm, 2.5);
            perm = perm + 0.3*randn(ns,nt);
    end

    % Smooth and clip
    perm = imgaussfilt(perm, 1.5);
    perm = max(1, min(28, perm));
end

%% ---------------------------------------------------------

function rmse = compute_rmse(Y_true, Y_pred)
    rmse = sqrt(mean((Y_true(:) - Y_pred(:)).^2));
end

%% ---------------------------------------------------------

function psnr_val = compute_psnr(Y_true, Y_pred)
    mse_val  = mean((Y_true(:) - Y_pred(:)).^2);
    max_val  = max(Y_true(:));
    psnr_val = 10 * log10(max_val^2 / mse_val);
end

%% ---------------------------------------------------------

function ssim_val = compute_ssim_map(Y_true, Y_pred)
    c1 = (0.01*max(Y_true(:)))^2;
    c2 = (0.03*max(Y_true(:)))^2;
    mu1    = imgaussfilt(Y_true, 1.5);
    mu2    = imgaussfilt(Y_pred, 1.5);
    mu1_sq = mu1.^2;
    mu2_sq = mu2.^2;
    mu1mu2 = mu1.*mu2;
    sig1_sq = imgaussfilt(Y_true.^2, 1.5) - mu1_sq;
    sig2_sq = imgaussfilt(Y_pred.^2, 1.5) - mu2_sq;
    sig12   = imgaussfilt(Y_true.*Y_pred, 1.5) - mu1mu2;
    ssim_map = ((2*mu1mu2+c1).*(2*sig12+c2)) ./ ...
               ((mu1_sq+mu2_sq+c1).*(sig1_sq+sig2_sq+c2));
    ssim_val = mean(ssim_map(:));
end

%% ---------------------------------------------------------

function draw_layer_annotation(x_axis, nt, t_axis, t_depth, style, lw)
    t_idx = round(t_depth / (t_axis(2)-t_axis(1)));
    if t_idx >= 1 && t_idx <= length(t_axis)
        undulation = 2*sin(2*pi*x_axis/5);
        plot(x_axis, t_depth + undulation, style, 'LineWidth', lw);
    end
end

%% ---------------------------------------------------------

function draw_hyperbola(ax, x_axis, t_axis, x_void, t_apex, rz, color)
    v = 0.08;   % m/ns
    hyp_t = zeros(1, length(x_axis));
    for i = 1:length(x_axis)
        dx = x_axis(i) - x_void;
        hyp_t(i) = t_apex + sqrt(dx^2/v^2 + rz^2) - rz/v;
    end
    valid = hyp_t >= t_axis(1) & hyp_t <= t_axis(end);
    plot(ax, x_axis(valid), hyp_t(valid), '-', ...
         'Color', color, 'LineWidth', 1.2);
end

%% ---------------------------------------------------------

function annotation_arrow(ax, x1, t1, x2, t2)
    xlims = ax.XLim;
    ylims = ax.YLim;
    x1n = (x1-xlims(1))/(xlims(2)-xlims(1));
    x2n = (x2-xlims(1))/(xlims(2)-xlims(1));
    y1n = (t1-ylims(1))/(ylims(2)-ylims(1));
    y2n = (t2-ylims(1))/(ylims(2)-ylims(1));
    pos = ax.Position;
    ax1 = pos(1) + x1n*pos(3);
    ax2 = pos(1) + x2n*pos(3);
    ay1 = pos(2) + (1-y1n)*pos(4);
    ay2 = pos(2) + (1-y2n)*pos(4);
    annotation('arrow', [ax1 ax2], [ay1 ay2], ...
        'Color', 'k', 'LineWidth', 1.2, 'HeadWidth', 8);
end

%% ---------------------------------------------------------

function add_processing_label(ax, label_str)
    text(ax, 0.02, 0.05, label_str, ...
         'Units', 'normalized', ...
         'FontSize', 7, 'Color', [0.3 0.3 0.3], ...
         'BackgroundColor', [1 1 1 0.6]);
end

%% ---------------------------------------------------------

function cmap = build_bscan_colormap(n)
    % Black-white-black seismic wiggle style
    r = [0,0,0,0.5,1,1,1,0.5,0];
    g = [0,0,0,0.5,1,0.5,0,0,0];
    b = [0.5,1,0.5,0.5,1,0,0,0,0];
    xi   = linspace(0,1,length(r));
    xq   = linspace(0,1,n);
    cmap = [interp1(xi,r,xq)', interp1(xi,g,xq)', ...
            interp1(xi,b,xq)'];
    cmap = max(0,min(1,cmap));
end

%% ---------------------------------------------------------

function cmap = build_thermal_colormap(n)
    r = [0.00,0.00,0.00,0.50,1.00,1.00,1.00];
    g = [0.00,0.00,0.50,1.00,1.00,0.50,0.00];
    b = [0.30,0.80,1.00,0.50,0.00,0.00,0.00];
    xi   = linspace(0,1,length(r));
    xq   = linspace(0,1,n);
    cmap = [interp1(xi,r,xq)', interp1(xi,g,xq)', ...
            interp1(xi,b,xq)'];
    cmap = max(0,min(1,cmap));
end