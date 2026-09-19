# Synthetic Huawei responses

The `.tl1` files are synthetic fixtures following the structure described in §11.3,
pp. 91–92 of *iManager U2000 V200R016C50CP2012 TL1 NBI User Guide 01*,
Issue 01 (2017-05-27). They do not come from a device and do not confirm the behavior
of a target U2000 version. They contain a complete frame with CRLF line endings, CTAG `21`,
the fictional identifier `TEST` and sample data. The `binary` attribute in this directory's
`.gitattributes` disables automatic line ending conversion for these files.

The published `lib-tl1` parses the frame, and `Output` reads the metadata and table.
Columns are separated by tabs; spaces within values and `--` retain their meaning.
`one_of_many.tl1` is a single packet from a result containing three records in total,
even though the packet itself contains only one record.

The files `utf8.tl1`, `gbk.tl1` and `iso8859_1.tl1` contain actual UTF-8, GBK
and ISO-8859-1 bytes, respectively. These encodings are listed in §10, pp. 84–85;
using each one is a local test and does not establish the server's configuration.
The other fixtures contain only ASCII characters.

`manual_vlan_switch_pair.tl1` adapts the response example for
`LST-ONTETHVLANSWTICHPAIR` in §15.8.30, pp. 888–889. It preserves the order and names
of all 14 columns defined on pp. 887–888 and the three displayed records, including
raw `--` values in `CENCAP`, `SPRI` and `SPRIPOLICY`. The SID, DID, device name,
date and time have been replaced with test data, and the textual `CTAG` with `21`
because of the frame parser limitation in `lib-tl1 0.1.2`. Lines wrapped in the PDF
layout have been joined into a single line per header or record, and columns are
separated by tabs as specified in §11.3.

The printed example specifies `blkcount=7` and `blktotal=7` but shows three records.
The fixture preserves both printed counters and the three visible records. The test checks
that the parser reads counters from the protocol regardless of the table excerpt's length;
it neither derives counters from the number of parsed rows nor adds the four records
that are not shown in the manual.

Verification is limited to the cited manual revision: the frame, metadata and table structure
(§11.3), the specific column example (§15.8.30) and the three listed encodings (§10).
The tests do not constitute verification against a device.
