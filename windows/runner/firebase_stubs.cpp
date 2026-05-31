extern "C" {
    // UCRT AVX2-optimized wide char memory functions flag.
    // Required by firebase_firestore.lib (compiled with VS 2022 17.4+).
    __declspec(dllexport) bool _Avx2WmemEnabled = false;
}

namespace std {
    // MSVC STL internal helper for std::find_first_of optimization.
    // Required by firebase_app.lib flatbuffers (compiled with VS 2022 17.6+).
    // Returns the first position in [_Haystack, _Haystack + _Haystack_size)
    // where any character from [_Needle, _Needle + _Needle_size) appears,
    // or -1 if none found.
    extern "C" __declspec(dllexport) unsigned long long __std_find_first_of_trivial_pos_1(
        const unsigned char* const _Haystack,
        const unsigned long long _Haystack_size,
        const unsigned char* const _Needle,
        const unsigned long long _Needle_size) noexcept {
        for (unsigned long long i = 0; i < _Haystack_size; ++i) {
            for (unsigned long long j = 0; j < _Needle_size; ++j) {
                if (_Haystack[i] == _Needle[j]) {
                    return i;
                }
            }
        }
        return static_cast<unsigned long long>(-1);
    }
}
