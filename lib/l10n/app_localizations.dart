import 'package:flutter/material.dart';

/// Simple hand-crafted AppLocalizations supporting 'id' and 'en'.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // ─── OLT List ────────────────────────────────────────────────────────────
  String get savedOlts => _t('Saved OLTs', 'OLT Tersimpan');
  String get noOltSaved => _t('No OLTs Saved Yet', 'Belum Ada OLT Tersimpan');
  String get noOltHint => _t(
    'Click the + button to add a new connection.',
    'Tekan tombol + untuk menambah koneksi baru.',
  );
  String get unnamedOlt => _t('Unnamed OLT', 'OLT Tanpa Nama');
  String get connectingOlt => _t('Connecting...', 'Menghubungkan...');
  String get connectionError => _t('Connection Error', 'Gagal Terhubung');

  // ─── Delete Dialog ───────────────────────────────────────────────────────
  String get deleteOltTitle => _t('Delete OLT?', 'Hapus OLT?');
  String deleteOltConfirm(String name) => _t(
    'Are you sure you want to delete $name?',
    'Yakin ingin menghapus $name?',
  );
  String get cancel => _t('Cancel', 'Batal');
  String get delete => _t('Delete', 'Hapus');

  // ─── Edit / Add OLT ──────────────────────────────────────────────────────
  String get addOlt => _t('Add New OLT', 'Tambah OLT Baru');
  String get editOlt => _t('Edit OLT', 'Edit OLT');
  String get configureConnection =>
      _t('Configure connection details', 'Atur detail koneksi');
  String get save => _t('Save', 'Simpan');
  String get oltNameLabel =>
      _t('OLT Name (e.g. Main Office)', 'Nama OLT (cth. Kantor Pusat)');
  String get oltModelLabel => _t('OLT Model', 'Model OLT');
  String get oltAddressLabel =>
      _t('OLT Address / HTTP URL', 'Alamat OLT / HTTP URL');
  String get usernameLabel => _t('Username', 'Nama Pengguna');
  String get passwordLabel => _t('Password', 'Kata Sandi');
  String get refreshTimeLabel =>
      _t('Refresh Time (Minutes)', 'Waktu Muat Ulang (Menit)');
  String get onuIconLabel => _t('ONU Map Marker Icon', 'Ikon Penanda ONU');
  String get odpIconLabel => _t('ODP Map Marker Icon', 'Ikon Penanda ODP');
  String markerSizeLabel(int size) =>
      _t('Map Marker Size: $size', 'Ukuran Penanda Peta: $size');

  // Validators
  String get validatorAddress => _t(
    'Please enter the OLT IP address or URL',
    'Harap masukkan alamat IP atau URL OLT',
  );
  String get validatorUsername =>
      _t('Please enter username', 'Harap masukkan nama pengguna');
  String get validatorPassword =>
      _t('Please enter password', 'Harap masukkan kata sandi');
  String get validatorRefreshEmpty =>
      _t('Please enter refresh time', 'Harap masukkan waktu muat ulang');
  String get validatorRefreshMin =>
      _t('Must be at least 1 minute', 'Minimal 1 menit');
  String get errorSavingConfig =>
      _t('Error saving config', 'Gagal menyimpan konfigurasi');

  // ─── Main Layout ─────────────────────────────────────────────────────────
  String get dashboard => _t('Dashboard', 'Dasbor');
  String get onuList => _t('ONU List', 'Daftar ONU');
  String get map => _t('Map', 'Peta');
  String get refresh => _t('Refresh', 'Muat Ulang');
  String get logout => _t('Logout', 'Keluar');
  String get cachedOffline => _t('Cached Offline', 'Cache Offline');
  String get onuUpdated =>
      _t('ONU list updated successfully', 'Daftar ONU berhasil diperbarui');
  String get refreshFailed =>
      _t('Failed to refresh data', 'Gagal memuat ulang data');

  // ─── Dashboard ───────────────────────────────────────────────────────────
  String get oltUnreachable => _t(
    'OLT Unreachable - Offline Mode',
    'OLT Tidak Terjangkau - Mode Offline',
  );
  String get cachedDataHint => _t(
    'Showing cached data from the last successful connection. Please check your network.',
    'Menampilkan data cache dari koneksi terakhir yang berhasil. Periksa jaringan Anda.',
  );
  String get totalOnus => _t('Total ONUs', 'Total ONU');
  String get onlineOnus => _t('Online (Up)', 'Online');
  String get offlineOnus => _t('Offline (Down)', 'Offline');
  String get onlineRatio => _t('Online Ratio', 'Rasio Online');
  String get badRx => _t('Bad Rx (<= -24)', 'Redaman Buruk');
  String get kmzImportExport => _t('KMZ Import & Export', 'Impor & Ekspor KMZ');
  String get kmzImportExportHint => _t(
    'Manage map placemarks using Google Earth files',
    'Kelola penanda peta menggunakan file Google Earth',
  );
  // Activate
  String get activateOnu => _t('Activate ONU', 'Aktifkan ONU');
  String get activateOnuDescription => _t(
    'Register and provision a new ONU device on this OLT.',
    'Daftarkan dan instalasi perangkat ONU baru di OLT ini.',
  );

  // ─── KMZ Import/Export ───────────────────────────────────────────────────
  String get importKmzTitle => _t('Import KMZ/KML', 'Impor KMZ/KML');
  String get importKmzHint => _t(
    'Import placemarks from Google Earth files. They will appear as Unknown Markers on the map, which you can assign to ONUs or ODPs.',
    'Impor penanda dari file Google Earth. Penanda akan muncul sebagai Penanda Tidak Dikenal di peta, yang dapat Anda tetapkan sebagai ONU atau ODP.',
  );
  String get selectFile => _t('Select File', 'Pilih File');
  String get exportKmzTitle => _t('Export to KMZ', 'Ekspor ke KMZ');
  String get exportKmzHint => _t(
    'Export your mapped ONUs, ODPs, and cables to a KMZ file for use in Google Earth.',
    'Ekspor ONU, ODP, dan kabel yang telah dipetakan ke file KMZ untuk digunakan di Google Earth.',
  );
  String get exportNow => _t('Export Now', 'Ekspor Sekarang');
  String importedMarkers(int count) => _t(
    'Successfully imported $count markers!',
    'Berhasil mengimpor $count penanda!',
  );
  String get importFailed => _t('Import failed', 'Impor gagal');
  String get exportCompleted =>
      _t('Export completed successfully', 'Ekspor berhasil diselesaikan');
  String get exportFailed => _t('Export failed', 'Ekspor gagal');

  // ─── Map ─────────────────────────────────────────────────────────────────
  String get addOnuMarker => _t('Add Onu Marker', 'Tambah Penanda ONU');
  String get addOdpMarker => _t('Add Odp Marker', 'Tambah Penanda ODP');
  String get assignAsOnu => _t('Assign as ONU', 'Tetapkan sebagai ONU');
  String get assignAsOdp => _t('Assign as ODP', 'Tetapkan sebagai ODP');
  String get deleteMarker => _t('Delete Marker', 'Hapus Penanda');
  String get reloadMap => _t('Reload', 'Muat Ulang');
  String get satelliteMap => _t('Satellite', 'Satelit');
  String get normalMap => _t('Normal', 'Normal');

  // ─── ONU List ────────────────────────────────────────────────────────────
  String get searchOnu => _t('Search ONU...', 'Cari ONU...');
  String get filterAll => _t('All', 'Semua');
  String get filterOnline => _t('Online', 'Online');
  String get filterOffline => _t('Offline', 'Offline');
  String get filterBadRx => _t('Bad Rx', 'Rx Buruk');

  // ─── Dialogs & Markers ───────────────────────────────────────────────────
  // ODP Form Dialog
  String get newOdp => _t('New ODP', 'ODP Baru');
  String get editOdp => _t('Edit ODP', 'Edit ODP');
  String get odpName => _t('ODP Name', 'Nama ODP');
  String get portCountHint => _t('Port Count (e.g. 8)', 'Jumlah Port (cth. 8)');
  String get cableNameTagOptional =>
      _t('Cable Name / Tag (Optional)', 'Nama / Tag Kabel (Opsional)');
  String get tubeColorOptional =>
      _t('Tube Color (Optional)', 'Warna Tube (Opsional)');
  String get coreColorOptional =>
      _t('Core Color (Optional)', 'Warna Core (Opsional)');
  String get assignOnusNearest => _t(
    'Assign ONUs (Sorted by nearest)',
    'Tetapkan ONU (Diurutkan dari terdekat)',
  );
  String distanceAway(String dist) => _t('$dist away', 'Jarak $dist');

  // ONU Details Dialog
  String get rebootOnuTitle => _t('Reboot ONU?', 'Mulai Ulang ONU?');
  String get locate => _t('Locate', 'Lacak');
  String confirmReboot(String name, String id) => _t(
    'Are you sure you want to reboot $name ($id)?',
    'Yakin ingin memulai ulang $name ($id)?',
  );
  String get reboot => _t('Reboot', 'Mulai Ulang');
  String get rebooting => _t('Rebooting...', 'Memulai Ulang...');
  String get rebootSuccess => _t(
    'ONU Reboot command sent successfully',
    'Perintah mulai ulang ONU berhasil dikirim',
  );
  String rebootFailed(String err) =>
      _t('Failed to reboot: $err', 'Gagal memulai ulang: $err');
  String get fetchingOnuStats =>
      _t('Fetching detailed ONU stats...', 'Mengambil detail statistik ONU...');
  String loadDetailsFailed(String err) =>
      _t('Failed to load details:\n$err', 'Gagal memuat detail:\n$err');
  String get close => _t('Close', 'Tutup');
  String get closeDetails => _t('Close Details', 'Tutup Detail');

  String get connectionHealth => _t('Connection Health', 'Kesehatan Koneksi');
  String get status => _t('Status', 'Status');
  String get rxPower => _t('Rx Power', 'Redaman Terima');
  String get txPower => _t('Tx Power', 'Redaman Pancar');
  String get temperature => _t('Temperature', 'Suhu');
  String get voltage => _t('Voltage', 'Tegangan');
  String get biasCurrent => _t('Bias Current', 'Arus Bias');
  String get distance => _t('Distance', 'Jarak');
  String get rtt => _t('RTT', 'RTT (Waktu Tempuh)');

  String get timeAndActivity => _t('Time & Activity', 'Waktu & Aktivitas');
  String get uptime => _t('Uptime', 'Waktu Aktif');
  String get deregisters => _t('Deregisters', 'Gagal Daftar');
  String get firstUpTime => _t('First UpTime', 'Waktu Aktif Pertama');
  String get onlineTime => _t('Online Time', 'Waktu Online');
  String get offlineTime => _t('Offline Time', 'Waktu Offline');
  String get offlineReason => _t('Offline Reason', 'Alasan Offline');

  String get hardwareCtcConfig =>
      _t('Hardware & CTC Configuration', 'Perangkat Keras & Konfigurasi CTC');
  String get fwVersion => _t('FW Version', 'Versi FW');
  String get chipId => _t('Chip ID', 'ID Chip');
  String get ports => _t('Ports', 'Port');
  String get ctcStatus => _t('CTC Status', 'Status CTC');
  String get ctcVersion => _t('CTC Version', 'Versi CTC');
  String get activation => _t('Activation', 'Aktivasi');

  // Cable Edit Overlay
  String get editingCableRoute =>
      _t('Editing Cable Route...', 'Mengedit Rute Kabel...');

  // ODP Marker Options
  String get connectedOnus => _t('Connected ONUs', 'ONU Terhubung');
  String get portsAvailable => _t('Ports Available', 'Port Tersedia');
  String yesPorts(int count) => _t('Yes ($count)', 'Ya ($count)');
  String get noFull => _t('No (Full)', 'Tidak (Penuh)');
  String get cableTag => _t('Cable Tag', 'Tag Kabel');
  String get tube => _t('Tube', 'Tube');
  String get core => _t('Core', 'Core');
  String get avgRx => _t('Avg Rx', 'Rata-rata Rx');
  String get bestRx => _t('Best Rx', 'Rx Terbaik');
  String get worstRx => _t('Worst Rx', 'Rx Terburuk');
  String get edit => _t('Edit', 'Edit');

  // ONU Marker Options
  String get length => _t('Length', 'Panjang');
  String get editMarker => _t('Edit Marker', 'Edit Penanda');
  String get editCableRoute => _t('Edit Cable Route', 'Edit Rute Kabel');
  String detailsFor(String name) =>
      _t('Details for $name', 'Detail untuk $name');
  String get cableNameOptional =>
      _t('Cable Name (Optional)', 'Nama Kabel (Opsional)');
  String get cableLengthOptional => _t(
    'Cable Length in meters (Optional)',
    'Panjang Kabel dalam meter (Opsional)',
  );
  String get back => _t('Back', 'Kembali');
  String get assignLocationToOnu =>
      _t('Assign Location to ONU', 'Tetapkan Lokasi untuk ONU');

  // ─── Language ────────────────────────────────────────────────────────────
  String get languageLabel => _t('Language', 'Bahasa');
  String get langEnglish => _t('English', 'Inggris');
  String get langIndonesian => _t('Indonesian', 'Indonesia');

  // ─── Helper ──────────────────────────────────────────────────────────────
  String _t(String en, String id) => locale.languageCode == 'id' ? id : en;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'id'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
