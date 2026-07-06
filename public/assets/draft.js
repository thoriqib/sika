/**
 * Draft.js — fitur "Simpan Sementara"
 * Menyimpan isi formulir secara otomatis ke localStorage browser,
 * agar data yang sudah diketik tidak hilang jika koneksi terputus,
 * tab tertutup tidak sengaja, atau device restart sebelum sempat disimpan ke server.
 *
 * Data HANYA tersimpan di perangkat/browser yang dipakai mengisi form,
 * bukan di server, sehingga tidak bisa dilihat pengguna lain.
 */
const Draft = {
    _formatTanggal(date) {
        const pad = n => String(n).padStart(2, '0');
        return `${pad(date.getDate())}-${pad(date.getMonth() + 1)}-${date.getFullYear()} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
    },

    init(formId, storageKey, opts = {}) {
        const form = document.getElementById(formId);
        if (!form) return;
        const statusEl = opts.statusElId ? document.getElementById(opts.statusElId) : null;
        const bannerEl = opts.bannerElId ? document.getElementById(opts.bannerElId) : null;
        const excludeFields = opts.exclude || [];

        function save() {
            const data = {};
            new FormData(form).forEach((value, key) => {
                if (excludeFields.includes(key)) return;
                data[key] = value;
            });
            form.querySelectorAll('input[type=checkbox]').forEach(cb => {
                if (excludeFields.includes(cb.name)) return;
                data[cb.name] = cb.checked;
            });
            data.__saved_at = new Date().toISOString();
            try {
                localStorage.setItem(storageKey, JSON.stringify(data));
                if (statusEl) {
                    statusEl.innerHTML = '<i class="bi bi-cloud-check text-success"></i> Tersimpan sementara di perangkat ini, pukul ' +
                        Draft._formatTanggal(new Date()).split(' ')[1];
                }
            } catch (e) {
                // localStorage penuh atau tidak tersedia (mis. mode incognito ketat) — abaikan diam-diam
            }
        }

        let timer = null;
        const scheduleSave = () => { clearTimeout(timer); timer = setTimeout(save, 700); };
        form.addEventListener('input', scheduleSave);
        form.addEventListener('change', scheduleSave);

        // Tampilkan banner jika ada draft tersimpan sebelumnya
        const existing = localStorage.getItem(storageKey);
        if (existing && bannerEl) {
            try {
                const parsed = JSON.parse(existing);
                const t = parsed.__saved_at ? Draft._formatTanggal(new Date(parsed.__saved_at)) : '-';
                bannerEl.innerHTML =
                    '<div class="alert alert-warning d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">' +
                    '<div><i class="bi bi-clock-history"></i> Ditemukan draft tersimpan otomatis pada <strong>' + t + '</strong>. Muat draft ini?</div>' +
                    '<div class="flex-shrink-0">' +
                    '<button type="button" class="btn btn-sm btn-teal me-1" id="' + storageKey + '_restore">Muat Draft</button>' +
                    '<button type="button" class="btn btn-sm btn-outline-secondary" id="' + storageKey + '_discard">Buang</button>' +
                    '</div></div>';

                document.getElementById(storageKey + '_restore').addEventListener('click', () => {
                    Object.keys(parsed).forEach(k => {
                        if (k === '__saved_at') return;
                        const el = form.elements[k];
                        if (!el) return;
                        if (el.type === 'checkbox') {
                            el.checked = (parsed[k] === true || parsed[k] === 'true');
                        } else {
                            el.value = parsed[k];
                        }
                    });
                    bannerEl.innerHTML = '<div class="alert alert-success">Draft berhasil dimuat. Silakan periksa kembali sebelum menyimpan.</div>';
                    setTimeout(() => { bannerEl.innerHTML = ''; }, 3000);
                });
                document.getElementById(storageKey + '_discard').addEventListener('click', () => {
                    localStorage.removeItem(storageKey);
                    bannerEl.innerHTML = '';
                });
            } catch (e) { /* draft rusak, abaikan */ }
        }
    },

    // Hapus draft berdasarkan key — dipanggil di halaman tujuan setelah data berhasil disimpan ke server
    clearFromUrlParam(paramName = 'clear_draft') {
        const params = new URLSearchParams(window.location.search);
        const key = params.get(paramName);
        if (key) {
            localStorage.removeItem(key);
            // Bersihkan parameter dari address bar agar rapi & tidak terhapus ulang saat refresh
            params.delete(paramName);
            const newUrl = window.location.pathname + (params.toString() ? '?' + params.toString() : '');
            window.history.replaceState({}, '', newUrl);
        }
    }
};

// Otomatis bersihkan draft setiap kali halaman manapun dimuat dengan parameter ?clear_draft=KEY
document.addEventListener('DOMContentLoaded', () => Draft.clearFromUrlParam());
