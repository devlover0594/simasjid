import 'dart:async';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

class SshTunnelManager {
  final String vpsHost;
  final int vpsSshPort;
  final String username;
  final String? password; // Bisa null jika pakai private key
  final String? privateKey; // Path ke file private key
  final int remotePort; // Port di VPS yang akan di-forward (e.g., 8089)
  final String localHost;
  final int localPort; // Port web server lokal di TV (e.g., 8088)

  SSHClient? _client;
  bool _isConnected = false;
  Timer? _reconnectTimer;

  // Callback untuk memberitahu UI tentang status
  Function(bool isConnected, String? publicUrl)? onStatusChanged;

  SshTunnelManager({
    required this.vpsHost,
    this.vpsSshPort = 22,
    required this.username,
    this.password,
    this.privateKey,
    required this.remotePort,
    this.localHost = '127.0.0.1',
    this.localPort = 8088,
    this.onStatusChanged,
  });

  Future<void> connect() async {
    if (_isConnected) return;
    debugPrint('SSH: Mencoba terhubung ke $vpsHost...');

    try {
      final socket = await SSHSocket.connect(vpsHost, vpsSshPort);

      _client = SSHClient(
        socket,
        username: username,
        // Prioritaskan private key jika ada, jika tidak, gunakan password.
        identities: privateKey != null && privateKey!.isNotEmpty
            ? SSHKeyPair.fromPem(privateKey!)
            : null,
        onPasswordRequest: () => password ?? '',
      );

      await _client!.authenticated;
      _isConnected = true;
      debugPrint('SSH: Berhasil terhubung dan terautentikasi.');

      // Membuat Reverse Tunnel
      final forward = await _client!.forwardRemote(port: remotePort);

      if (forward == null) {
        debugPrint(
          'SSH: Gagal memulai remote forwarding. Pastikan GatewayPorts=yes di server.',
        );
        disconnect();
        return;
      }

      final publicUrl = 'http://$vpsHost:$remotePort';
      debugPrint('SSH: Tunnel aktif! Akses publik di $publicUrl');
      onStatusChanged?.call(true, publicUrl);

      // Loop untuk menerima koneksi masuk dari VPS
      await for (final connection in forward.connections) {
        debugPrint('SSH: Menerima koneksi masuk dari tunnel...');
        // Tidak menggunakan await di sini agar loop bisa menerima koneksi lain
        // tanpa menunggu koneksi sebelumnya selesai.
        _pipeConnection(connection, localHost, localPort).catchError((e) {
          debugPrint('SSH: Error pada _pipeConnection: $e');
        });
      }
    } catch (e) {
      debugPrint('SSH: Koneksi gagal: $e');
      _isConnected = false;
      onStatusChanged?.call(false, null);
      _scheduleReconnect();
    }
  }

  // Helper function to handle piping for each connection
  Future<void> _pipeConnection(
    SSHForwardChannel connection,
    String localHost,
    int localPort,
  ) async {
    try {
      final localSocket = await Socket.connect(localHost, localPort);
      debugPrint(
        'SSH: Terhubung ke server lokal. Memulai piping data antara remote dan lokal.',
      );

      // Menyalurkan data dua arah.
      // `pipe` akan secara otomatis menutup sink (tujuan) ketika stream (sumber) selesai.
      // Jika salah satu koneksi ditutup, stream-nya akan selesai,
      // dan pipe akan menutup sisi tujuan secara otomatis.
      unawaited(
        connection.stream.cast<List<int>>().pipe(localSocket).catchError((e) {
          debugPrint('SSH: Error pipe remote->lokal: $e');
        }),
      );
      unawaited(
        localSocket.cast<List<int>>().pipe(connection.sink).catchError((e) {
          debugPrint('SSH: Error pipe lokal->remote: $e');
        }),
      );
    } catch (e) {
      debugPrint('SSH: Gagal meneruskan koneksi ke server lokal: $e');
      await connection.close();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 30), connect);
    debugPrint('SSH: Mencoba koneksi ulang dalam 30 detik...');
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _client?.close();
    _isConnected = false;
    onStatusChanged?.call(false, null);
    debugPrint('SSH: Koneksi diputus.');
  }
}
