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
  String get configureConnection => _t(
    'Configure connection details',
    'Atur detail koneksi',
  );
  String get save => _t('Save', 'Simpan');
  String get oltNameLabel => _t('OLT Name (e.g. Main Office)', 'Nama OLT (cth. Kantor Pusat)');
  String get oltModelLabel => _t('OLT Model', 'Model OLT');
  String get oltAddressLabel => _t('OLT Address / HTTP URL', 'Alamat OLT / HTTP URL');
  String get usernameLabel => _t('Username', 'Nama Pengguna');
  String get passwordLabel => _t('Password', 'Kata Sandi');
  String get refreshTimeLabel => _t('Refresh Time (Minutes)', 'Waktu Muat Ulang (Menit)');
  String get onuIconLabel => _t('ONU Map Marker Icon', 'Ikon Penanda ONU');
  String get odpIconLabel => _t('ODP Map Marker Icon', 'Ikon Penanda ODP');
  String markerSizeLabel(int size) => _t('Map Marker Size: $size', 'Ukuran Penanda Peta: $size');

  // Validators
  String get validatorAddress => _t(
    'Please enter the OLT IP address or URL',
    'Harap masukkan alamat IP atau URL OLT',
  );
  String get validatorUsername => _t('Please enter username', 'Harap masukkan nama pengguna');
  String get validatorPassword => _t('Please enter password', 'Harap masukkan kata sandi');
  String get validatorRefreshEmpty => _t('Please enter refresh time', 'Harap masukkan waktu muat ulang');
  String get validatorRefreshMin => _t('Must be at least 1 minute', 'Minimal 1 menit');
  String get errorSavingConfig => _t('Error saving config', 'Gagal menyimpan konfigurasi');

  // ─── Main Layout ─────────────────────────────────────────────────────────
  String get dashboard => _t('Dashboard', 'Dasbor');
  String get onuList => _t('ONU List', 'Daftar ONU');
  String get map => _t('Map', 'Peta');
  String get refresh => _t('Refresh', 'Muat Ulang');
  String get logout => _t('Logout', 'Keluar');
  String get cachedOffline => _t('Cached Offline', 'Cache Offline');
  String get onuUpdated => _t('ONU list updated successfully', 'Daftar ONU berhasil diperbarui');
  String get refreshFailed => _t('Failed to refresh data', 'Gagal memuat ulang data');

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
  String get badRx => _t('Bad Rx (<= -24)', 'Rx Buruk (<= -24)');
  String get kmzImportExport => _t('KMZ Import & Export', 'Impor & Ekspor KMZ');
  String get kmzImportExportHint => _t(
    'Manage map placemarks using Google Earth files',
    'Kelola penanda peta menggunakan file Google Earth',
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
  String get exportCompleted => _t('Export completed successfully', 'Ekspor berhasil diselesaikan');
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
