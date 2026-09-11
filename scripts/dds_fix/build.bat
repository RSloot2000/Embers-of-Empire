call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64
cd /d "C:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\scripts\dds_fix"
cl /O2 /Fe:encode_dxt5.exe encode_dxt5.c
