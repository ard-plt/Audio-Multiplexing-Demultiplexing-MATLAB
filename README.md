# Audio Multiplexing and Demodulation in MATLAB

This project implements a basic audio communication system by modulating two audio signals on different carrier frequencies and separating them via demodulation and FIR filtering.

## Features

- Two audio inputs: `Nature.wav`, `Ship.wav`
- Modulation via cosine carriers (8 kHz and 24 kHz)
- Multiplexed signal spectrum visualization
- Demodulation with FIR lowpass filters
- Signal normalization and playback

## Highlights

- Uses `designfilt` for sharp filtering
- Resampling and synchronization of different audio sources
- Full-frequency analysis of each stage
