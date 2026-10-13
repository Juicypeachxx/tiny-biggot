#!/usr/bin/env python3
# lists a Godot 4 .pck (pack format 2 or 3); usage: pck.py file.pck [extract_path out_file]
import struct, sys
f = open(sys.argv[1], 'rb')
magic = f.read(4)
assert magic == b'GDPC', magic
ver, maj, mnr, pat = struct.unpack('<4I', f.read(16))
flags = struct.unpack('<I', f.read(4))[0]
base = struct.unpack('<Q', f.read(8))[0]
if ver >= 3:
    diroff = struct.unpack('<Q', f.read(8))[0]
    f.seek(diroff)
else:
    f.read(16 * 4)
n = struct.unpack('<I', f.read(4))[0]
ents = []
for i in range(n):
    l = struct.unpack('<I', f.read(4))[0]
    path = f.read(l).rstrip(b'\0').decode()
    off, size = struct.unpack('<QQ', f.read(16))
    md5 = f.read(16)
    fl = struct.unpack('<I', f.read(4))[0]
    ents.append((path, off, size, md5.hex(), fl))
if len(sys.argv) > 3:
    for p, off, size, m, fl in ents:
        if p == sys.argv[2] or 'res://' + p == sys.argv[2]:
            f.seek(base + off); open(sys.argv[3], 'wb').write(f.read(size)); print('extracted', p, size)
else:
    print('pack format %d, engine %d.%d.%d, flags %d, %d files' % (ver, maj, mnr, pat, flags, n))
    for p, off, size, m, fl in sorted(ents):
        print('%s\t%d\t%s\t%d' % (p, size, m, fl))
