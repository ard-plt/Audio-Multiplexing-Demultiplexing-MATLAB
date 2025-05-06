clc;
clear;
close all;

% Read audio files
[natureAudio, F1] = audioread('Nature.wav');
[shipAudio, F2] = audioread('Ship.wav');

% Convert to mono if stereo
if size(natureAudio, 2) == 2
    natureAudio = mean(natureAudio, 2);
end
if size(shipAudio, 2) == 2
    shipAudio = mean(shipAudio, 2);
end

% Equalize lengths
len1 = length(natureAudio);
len2 = length(shipAudio);

if len1 < len2
    natureAudio = [natureAudio; zeros(len2 - len1, 1)];
elseif len2 < len1
    shipAudio = [shipAudio; zeros(len1 - len2, 1)];
end

fprintf('Nature audio length: %d samples\n', length(natureAudio));
fprintf('Ship audio length:   %d samples\n', length(shipAudio));

% Resample to common Fs
Fs = min(F1, F2);
natureAudio = resample(natureAudio, Fs, F1);
shipAudio = resample(shipAudio, Fs, F2);

% Normalize
natureAudio = natureAudio - mean(natureAudio);
shipAudio = shipAudio - mean(shipAudio);
natureAudio = natureAudio / max(abs(natureAudio));
shipAudio = shipAudio / max(abs(shipAudio));

n = length(natureAudio);
t = (0:n-1)' / Fs;

% Modulation (carrier frequencies)
fc1 = 8000;
fc2 = 24000;

modNature = natureAudio .* cos(2 * pi * fc1 * t);
modShip = shipAudio .* cos(2 * pi * fc2 * t);

% Time separation
gap = zeros(Fs, 1);
multiplexed = [modNature; gap; modShip];

% Frequency domain analysis of inputs
f = linspace(0, Fs/2, floor(n/2));
natureFFT = abs(fft(natureAudio));
natureFFT = natureFFT(1:floor(n/2));
shipFFT = abs(fft(shipAudio));
shipFFT = shipFFT(1:floor(n/2));

figure;
subplot(2,1,1);
plot(f, natureFFT); title('Nature Audio Spectrum');
xlabel('Frequency (Hz)'); ylabel('Amplitude');

subplot(2,1,2);
plot(f, shipFFT); title('Ship Audio Spectrum');
xlabel('Frequency (Hz)'); ylabel('Amplitude');

% Time-domain plots of modulated signals
figure;
subplot(2,1,1);
plot(t(1:1000), modNature(1:1000));
title('Modulated Nature Signal');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(2,1,2);
plot(t(1:1000), modShip(1:1000));
title('Modulated Ship Signal');
xlabel('Time (s)'); ylabel('Amplitude');

% Frequency domain of multiplexed signal
nTotal = length(multiplexed);
fTotal = linspace(0, Fs/2, floor(nTotal/2));
muxFFT = abs(fft(multiplexed));
muxFFT = muxFFT(1:floor(nTotal/2));

figure;
plot(fTotal, muxFFT);
title('Multiplexed Signal Spectrum');
xlabel('Frequency (Hz)'); ylabel('Amplitude');

% Playback original and multiplexed
disp('Playing Nature Audio:');
sound(natureAudio, Fs); pause(n/Fs + 0.5);
disp('Playing Ship Audio:');
sound(shipAudio, Fs); pause(n/Fs + 0.5);
disp('Playing Multiplexed Signal:');
sound(multiplexed, Fs); pause(length(multiplexed)/Fs + 1);

% Demodulation and filtering (Nature)
demodNature = multiplexed(1:n) .* cos(2*pi*fc1*t);
filter1 = designfilt('lowpassfir', ...
    'PassbandFrequency', 5000, ...
    'StopbandFrequency', 5500, ...
    'SampleRate', Fs);
recoveredNature = filter(filter1, demodNature);
recoveredNature = recoveredNature - mean(recoveredNature);
recoveredNature = recoveredNature / max(abs(recoveredNature));

% Demodulation and filtering (Ship)
start2 = n + Fs + 1;
stop2 = start2 + n - 1;
demodShip = multiplexed(start2:stop2) .* cos(2*pi*fc2*t);
filter2 = designfilt('lowpassfir', ...
    'PassbandFrequency', 5000, ...
    'StopbandFrequency', 5500, ...
    'SampleRate', Fs);
recoveredShip = filter(filter2, demodShip);
recoveredShip = recoveredShip - mean(recoveredShip);
recoveredShip = recoveredShip / max(abs(recoveredShip));

% Frequency domain of recovered signals
recoveredNatureFFT = abs(fft(recoveredNature));
recoveredNatureFFT = recoveredNatureFFT(1:floor(n/2));
recoveredShipFFT = abs(fft(recoveredShip));
recoveredShipFFT = recoveredShipFFT(1:floor(n/2));

figure;
subplot(2,1,1);
plot(f, recoveredNatureFFT);
title('Recovered Nature Audio Spectrum');
xlabel('Frequency (Hz)'); ylabel('Amplitude');

subplot(2,1,2);
plot(f, recoveredShipFFT);
title('Recovered Ship Audio Spectrum');
xlabel('Frequency (Hz)'); ylabel('Amplitude');

% Playback demodulated signals
disp('Recovered Nature Audio:');
sound(recoveredNature, Fs); pause(n/Fs + 0.5);
disp('Recovered Ship Audio:');
sound(recoveredShip, Fs); pause(n/Fs + 0.5);

% Save output
audiowrite('NatureRecovered.wav', recoveredNature, Fs);
audiowrite('ShipRecovered.wav', recoveredShip, Fs);
