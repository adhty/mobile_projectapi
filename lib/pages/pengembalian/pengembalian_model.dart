class Pengembalian {
  final int? id;
  final int? peminjamanId;
  final String? tanggalKembali;
  final String? kondisi;
  final String? catatan;
  final String? status;

  Pengembalian({
    this.id,
    this.peminjamanId,
    this.tanggalKembali,
    this.kondisi,
    this.catatan,
    this.status,
  });

  factory Pengembalian.fromJson(Map<String, dynamic> json) {
    return Pengembalian(
      id: int.tryParse(json['id'].toString()),
      peminjamanId: int.tryParse(json['peminjaman_id'].toString()),
      tanggalKembali: json['tanggal_kembali'],
      kondisi: json['kondisi'],
      catatan: json['catatan'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'peminjaman_id': peminjamanId,
      'tanggal_kembali': tanggalKembali,
      'kondisi': kondisi,
      'catatan': catatan,
      'status': status,
    };
  }
}