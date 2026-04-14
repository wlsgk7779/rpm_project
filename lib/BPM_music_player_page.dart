import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_manager.dart';
import 'models/song_class.dart';
import 'voulume _control_page.dart';
import 'song_class.dart'; // allSongs 리스트 정의된 파일

class BpmPlayerPage extends StatefulWidget {
  final int bpm;
  final List<Song> songs;
  final int initialIndex;

  const BpmPlayerPage({
    Key? key,
    required this.songs,
    required this.initialIndex,
    required this.bpm,
  }) : super(key: key);

  @override
  State<BpmPlayerPage> createState() => _BpmPlayerPageState();
}

class _BpmPlayerPageState extends State<BpmPlayerPage> {
  late AudioPlayer _audioPlayer;
  AudioPlayer? _clickPlayer;

  int currentIndex = 0;
  bool isPlaying = false;
  double musicVolume = 1.0;
  double metronomeVolume = 0.3;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Timer? _metronomeTimer;

  List<Song> get filteredSongs =>
      allSongs.where((song) => song.bpm == widget.bpm).toList();

  Song get currentSong => filteredSongs[currentIndex];

  @override
  void initState() {
    super.initState();
    AudioManager.replacePlayer();
    _audioPlayer = AudioManager.player;
    _clickPlayer = AudioPlayer();
    _clickPlayer!.setAsset('assets/audio/metronome.mp3');

    _audioPlayer.playingStream.listen((playing) => setState(() => isPlaying = playing));
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) _playNext();
    });
    _audioPlayer.positionStream.listen((pos) => setState(() => _position = pos));
    _audioPlayer.durationStream.listen((dur) => setState(() => _duration = dur ?? Duration.zero));

    _playAudio();
  }

  Future<void> _playAudio() async {
    try {
      await _audioPlayer.setAsset(currentSong.audioPath);
      await _audioPlayer.load();
      await _audioPlayer.setVolume(musicVolume);
      await _audioPlayer.play();

      Future.delayed(const Duration(milliseconds: 100), () {
        _startMetronome();
      });
      setState(() => isPlaying = true);
    } catch (e) {
      print("🔴 Audio load error: $e");
    }
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    _stopMetronome();
    setState(() => isPlaying = false);
  }

  Future<void> _playPrevious() async {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
      await _playAudio();
    }
  }

  Future<void> _playNext() async {
    if (currentIndex < filteredSongs.length - 1) {
      setState(() => currentIndex++);
      await _playAudio();
    }
  }

  void _startMetronome() {
    _stopMetronome();
    final bpm = AudioManager.currentBpm;
    if (bpm <= 0) return;
    final intervalMs = (60000 / bpm).round();
    _metronomeTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
          (_) => _playMetronomeClick(),
    );
  }

  Future<void> _playMetronomeClick() async {
    try {
      await _clickPlayer!.seek(Duration.zero);
      await _clickPlayer!.setVolume(metronomeVolume);
      await _clickPlayer!.play();
    } catch (e) {
      print("🔴 Metronome click error: $e");
    }
  }

  void _stopMetronome() {
    _metronomeTimer?.cancel();
    _metronomeTimer = null;
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _stopMetronome();
    _audioPlayer.dispose();
    _clickPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remainingSongs = filteredSongs.sublist(currentIndex + 1);

    return Scaffold(
      backgroundColor: const Color(0xFFFF670C),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF670C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            _audioPlayer.stop();
            _stopMetronome();
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: const [
            Icon(Icons.music_note, color: Colors.black),
            SizedBox(width: 4),
            Text("music", style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              "${currentSong.bpm} BPM",
              style: const TextStyle(fontSize: 37, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 20),
            const Divider(thickness: 1, color: Colors.black),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
              child: Row(
                children: const [
                  Icon(Icons.radio_button_unchecked, size: 20),
                  SizedBox(width: 6),
                  Text("재생 중인 곡", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            _buildSongTile(currentSong),
            const Divider(thickness: 1, color: Colors.black),
            Expanded(
              child: remainingSongs.isEmpty
                  ? const Center(child: Text("재생 대기 중인 곡이 없습니다.", style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                itemCount: remainingSongs.length,
                itemBuilder: (context, index) {
                  final song = remainingSongs[index];
                  final realIndex = currentIndex + 1 + index;
                  return GestureDetector(
                    onTap: () async {
                      setState(() => currentIndex = realIndex);
                      await _playAudio();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(song.imagePath, width: 40, height: 40, fit: BoxFit.cover),
                        ),
                        title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(song.artist),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
              child: Row(
                children: [
                  Text(_formatDuration(_position), style: const TextStyle(color: Colors.white)),
                  Expanded(
                    child: Slider(
                      value: _position.inMilliseconds.toDouble().clamp(0, _duration.inMilliseconds.toDouble()),
                      max: _duration.inMilliseconds.toDouble(),
                      onChanged: (value) => _audioPlayer.seek(Duration(milliseconds: value.toInt())),
                      activeColor: Colors.white,
                      inactiveColor: Colors.white54,
                    ),
                  ),
                  Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 20,
                  child: IconButton(
                    icon: const Icon(Icons.volume_up, size: 32, color: Colors.white),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VolumeControlPage(
                            musicVolume: musicVolume,
                            metronomeVolume: metronomeVolume,
                            onVolumeChanged: (newMusic, newMetronome) {
                              setState(() {
                                musicVolume = newMusic;
                                metronomeVolume = newMetronome;
                                _audioPlayer.setVolume(musicVolume);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(icon: const Icon(Icons.skip_previous, size: 40, color: Colors.white), onPressed: _playPrevious),
                    IconButton(
                      icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 60, color: Colors.white),
                      onPressed: () => isPlaying ? _pauseAudio() : _playAudio(),
                    ),
                    IconButton(icon: const Icon(Icons.skip_next, size: 40, color: Colors.white), onPressed: _playNext),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSongTile(Song song) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(song.imagePath, width: 40, height: 40, fit: BoxFit.cover),
        ),
        title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(song.artist),
      ),
    );
  }
}
