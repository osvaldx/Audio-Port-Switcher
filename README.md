# Audio-Port-Switcher

A lightweight, native DMS (Dank Material Shell) top-bar widget built entirely in QML and QuickShell. 

It provides an elegant and universal solution for laptop users on Linux who need to frequently toggle their audio input route between the internal built-in microphone and an external headset mic connected via a single 3.5mm combo Jack.

## Features
* **100% Dynamic:** Automatically detects your default active PipeWire source device without hardcoded IDs or PCI card names.
* **Reactive UI:** Listens to PipeWire hardware events in real-time (`pactl subscribe`). If you unplug your headset, the bar icon updates instantly.
* **One-Click Toggle:** Switch your input port natively with a simple click on the bar widget.
