import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class UnitFormatter extends TextInputFormatter {
  final String unit;

  UnitFormatter(this.unit);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    final lower = text.toLowerCase();

    if (lower.endsWith(unit)) {
      final core = text.substring(0, text.length - unit.length).trimRight();
      final formatted = '$core $unit';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    return newValue;
  }
}

class EditAccountinfo extends StatefulWidget {
  const EditAccountinfo({super.key});

  @override
  State<EditAccountinfo> createState() => _EditAccountinfoState();
}

class _EditAccountinfoState extends State<EditAccountinfo> {
  // Images: mobile uses File, web uses Uint8List (bytes). We keep both to support both platforms.
  File? _profileImage;
  File? _idImage;
  String? _profileImageUrl;
  String? _idImageUrl;
  Uint8List? _profileImageBytes;
  Uint8List? _idImageBytes;

  // flags for deletion
  bool _removeProfileImage = false;
  bool _removeIdImage = false;

  // upload progress indicators
  double? _profileUploadProgress;
  double? _idUploadProgress;

  final _formKey = GlobalKey<FormState>();
  bool _isFormDirty = false;
  bool _isSaving = false;
  final Map<TextEditingController, String?> _fieldErrors = {};
  AutovalidateMode _autoValidateMode = AutovalidateMode.onUserInteraction;

  // Basic Controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();

  final _addressController = TextEditingController();

  // Health / other
  final _bloodTypeController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  // Town options
  final List<String> _towns = [
    "Tondo",
    "Binondo",
    "Quiapo",
    "Intramuros",
    "Ermita",
    "Malate",
    "Paco",
    "Pandacan",
    "Port Area",
    "San Nicolas",
    "Santa Ana",
    "Santa Cruz",
    "Santa Mesa",
    "San Miguel",
    "San Andres Bukid",
    "Sampaloc",
  ];
  // ZIP code mapping
final Map<String, List<String>> _zipCodeMap = {
  "Tondo": ["1012", "1013"],
  "Binondo": ["1006"],
  "Quiapo": ["1001"],
  "Intramuros": ["1002"],
  "Ermita": ["1000"],
  "Malate": ["1004"],
  "Paco": ["1007"],
  "Pandacan": ["1011"],
  "Port Area": ["1018", "1019"],
  "San Nicolas": ["1010"],
  "Santa Ana": ["1009"],
  "Santa Cruz": ["1003"],
  "Santa Mesa": ["1016"],
  "San Miguel": ["1005"],
  "San Andres Bukid": ["1017"],
  "Sampaloc": ["1008"],
};

List<String> _getZipCodesForTown(String? town) {
  if (town == null) return [];
  return _zipCodeMap[town] ?? [];
}

String? _getFirstZipCodeForTown(String? town) {
  final zipCodes = _getZipCodesForTown(town);
  return zipCodes.isNotEmpty ? zipCodes.first : null;
}

  //barangay
  final String _barangayCsv = r'''
district,barangay
Tondo,Barangay 1
Tondo,Barangay 2
Tondo,Barangay 3
Tondo,Barangay 4
Tondo,Barangay 5
Tondo,Barangay 6
Tondo,Barangay 7
Tondo,Barangay 8
Tondo,Barangay 9
Tondo,Barangay 10
Tondo,Barangay 11
Tondo,Barangay 12
Tondo,Barangay 13
Tondo,Barangay 14
Tondo,Barangay 15
Tondo,Barangay 16
Tondo,Barangay 17
Tondo,Barangay 18
Tondo,Barangay 19
Tondo,Barangay 20
Tondo,Barangay 21
Tondo,Barangay 22
Tondo,Barangay 23
Tondo,Barangay 24
Tondo,Barangay 25
Tondo,Barangay 26
Tondo,Barangay 27
Tondo,Barangay 28
Tondo,Barangay 29
Tondo,Barangay 30
Tondo,Barangay 31
Tondo,Barangay 32
Tondo,Barangay 33
Tondo,Barangay 34
Tondo,Barangay 35
Tondo,Barangay 36
Tondo,Barangay 37
Tondo,Barangay 38
Tondo,Barangay 39
Tondo,Barangay 40
Tondo,Barangay 41
Tondo,Barangay 42
Tondo,Barangay 43
Tondo,Barangay 44
Tondo,Barangay 45
Tondo,Barangay 46
Tondo,Barangay 47
Tondo,Barangay 48
Tondo,Barangay 49
Tondo,Barangay 50
Tondo,Barangay 51
Tondo,Barangay 52
Tondo,Barangay 53
Tondo,Barangay 54
Tondo,Barangay 55
Tondo,Barangay 56
Tondo,Barangay 57
Tondo,Barangay 58
Tondo,Barangay 59
Tondo,Barangay 60
Tondo,Barangay 61
Tondo,Barangay 62
Tondo,Barangay 63
Tondo,Barangay 64
Tondo,Barangay 65
Tondo,Barangay 66
Tondo,Barangay 67
Tondo,Barangay 68
Tondo,Barangay 69
Tondo,Barangay 70
Tondo,Barangay 71
Tondo,Barangay 72
Tondo,Barangay 73
Tondo,Barangay 74
Tondo,Barangay 75
Tondo,Barangay 76
Tondo,Barangay 77
Tondo,Barangay 78
Tondo,Barangay 79
Tondo,Barangay 80
Tondo,Barangay 81
Tondo,Barangay 82
Tondo,Barangay 83
Tondo,Barangay 84
Tondo,Barangay 85
Tondo,Barangay 86
Tondo,Barangay 87
Tondo,Barangay 88
Tondo,Barangay 89
Tondo,Barangay 90
Tondo,Barangay 91
Tondo,Barangay 92
Tondo,Barangay 93
Tondo,Barangay 94
Tondo,Barangay 95
Tondo,Barangay 96
Tondo,Barangay 97
Tondo,Barangay 98
Tondo,Barangay 99
Tondo,Barangay 100
Tondo,Barangay 101
Tondo,Barangay 102
Tondo,Barangay 103
Tondo,Barangay 104
Tondo,Barangay 105
Tondo,Barangay 106
Tondo,Barangay 107
Tondo,Barangay 108
Tondo,Barangay 109
Tondo,Barangay 110
Tondo,Barangay 111
Tondo,Barangay 112
Tondo,Barangay 113
Tondo,Barangay 114
Tondo,Barangay 115
Tondo,Barangay 116
Tondo,Barangay 117
Tondo,Barangay 118
Tondo,Barangay 119
Tondo,Barangay 120
Tondo,Barangay 121
Tondo,Barangay 122
Tondo,Barangay 123
Tondo,Barangay 124
Tondo,Barangay 125
Tondo,Barangay 126
Tondo,Barangay 127
Tondo,Barangay 128
Tondo,Barangay 129
Tondo,Barangay 130
Tondo,Barangay 131
Tondo,Barangay 132
Tondo,Barangay 133
Tondo,Barangay 134
Tondo,Barangay 135
Tondo,Barangay 136
Tondo,Barangay 137
Tondo,Barangay 138
Tondo,Barangay 139
Tondo,Barangay 140
Tondo,Barangay 141
Tondo,Barangay 142
Tondo,Barangay 143
Tondo,Barangay 144
Tondo,Barangay 145
Tondo,Barangay 146
Tondo,Barangay 147
Tondo,Barangay 148
Tondo,Barangay 149
Tondo,Barangay 150
Tondo,Barangay 151
Tondo,Barangay 152
Tondo,Barangay 153
Tondo,Barangay 154
Tondo,Barangay 155
Tondo,Barangay 156
Tondo,Barangay 157
Tondo,Barangay 158
Tondo,Barangay 159
Tondo,Barangay 160
Tondo,Barangay 161
Tondo,Barangay 162
Tondo,Barangay 163
Tondo,Barangay 164
Tondo,Barangay 165
Tondo,Barangay 166
Tondo,Barangay 167
Tondo,Barangay 168
Tondo,Barangay 169
Tondo,Barangay 170
Tondo,Barangay 171
Tondo,Barangay 172
Tondo,Barangay 173
Tondo,Barangay 174
Tondo,Barangay 175
Tondo,Barangay 176
Tondo,Barangay 177
Tondo,Barangay 178
Tondo,Barangay 179
Tondo,Barangay 180
Tondo,Barangay 181
Tondo,Barangay 182
Tondo,Barangay 183
Tondo,Barangay 184
Tondo,Barangay 185
Tondo,Barangay 186
Tondo,Barangay 187
Tondo,Barangay 188
Tondo,Barangay 189
Tondo,Barangay 190
Tondo,Barangay 191
Tondo,Barangay 192
Tondo,Barangay 193
Tondo,Barangay 194
Tondo,Barangay 195
Tondo,Barangay 196
Tondo,Barangay 197
Tondo,Barangay 198
Tondo,Barangay 199
Tondo,Barangay 200
Tondo,Barangay 201
Tondo,Barangay 202
Tondo,Barangay 203
Tondo,Barangay 204
Tondo,Barangay 205
Tondo,Barangay 206
Tondo,Barangay 207
Tondo,Barangay 208
Tondo,Barangay 209
Tondo,Barangay 210
Tondo,Barangay 211
Tondo,Barangay 212
Tondo,Barangay 213
Tondo,Barangay 214
Tondo,Barangay 215
Tondo,Barangay 216
Tondo,Barangay 217
Tondo,Barangay 218
Tondo,Barangay 219
Tondo,Barangay 220
Tondo,Barangay 221
Tondo,Barangay 222
Tondo,Barangay 223
Tondo,Barangay 224
Tondo,Barangay 225
Tondo,Barangay 226
Tondo,Barangay 227
Tondo,Barangay 228
Tondo,Barangay 229
Tondo,Barangay 230
Tondo,Barangay 231
Tondo,Barangay 232
Tondo,Barangay 233
Tondo,Barangay 234
Tondo,Barangay 235
Tondo,Barangay 236
Tondo,Barangay 237
Tondo,Barangay 238
Tondo,Barangay 239
Tondo,Barangay 240
Tondo,Barangay 241
Tondo,Barangay 242
Tondo,Barangay 243
Tondo,Barangay 244
Tondo,Barangay 245
Tondo,Barangay 246
Tondo,Barangay 247
Tondo,Barangay 248
Tondo,Barangay 249
Tondo,Barangay 250
Tondo,Barangay 251
Tondo,Barangay 252
Tondo,Barangay 253
Tondo,Barangay 254
Tondo,Barangay 255
Tondo,Barangay 256
Tondo,Barangay 257
Tondo,Barangay 258
Tondo,Barangay 259
Tondo,Barangay 260
Tondo,Barangay 261
Tondo,Barangay 262
Tondo,Barangay 263
Tondo,Barangay 264
Tondo,Barangay 265
Tondo,Barangay 266
Tondo,Barangay 267
Binondo,Barangay 287
Binondo,Barangay 288
Binondo,Barangay 289
Binondo,Barangay 290
Binondo,Barangay 291
Binondo,Barangay 292
Binondo,Barangay 293
Binondo,Barangay 294
Binondo,Barangay 295
Binondo,Barangay 296
Quiapo,Barangay 306
Quiapo,Barangay 307
Quiapo,Barangay 308
Quiapo,Barangay 309
Quiapo,Barangay 383
Quiapo,Barangay 384
Quiapo,Barangay 385
Quiapo,Barangay 386
Quiapo,Barangay 387
Quiapo,Barangay 388
Quiapo,Barangay 389
Quiapo,Barangay 390
Quiapo,Barangay 391
Quiapo,Barangay 392
Quiapo,Barangay 393
Quiapo,Barangay 394
Intramuros,Barangay 654
Intramuros,Barangay 655
Intramuros,Barangay 656
Intramuros,Barangay 657
Intramuros,Barangay 658
Ermita,Barangay 659
Ermita,Barangay 659-A
Ermita,Barangay 660
Ermita,Barangay 660-A
Ermita,Barangay 661
Ermita,Barangay 663
Ermita,Barangay 663-A
Ermita,Barangay 664
Ermita,Barangay 666
Ermita,Barangay 667
Ermita,Barangay 668
Ermita,Barangay 669
Ermita,Barangay 670
Malate,Barangay 688
Malate,Barangay 689
Malate,Barangay 690
Malate,Barangay 691
Malate,Barangay 692
Malate,Barangay 693
Malate,Barangay 694
Malate,Barangay 695
Malate,Barangay 696
Malate,Barangay 697
Malate,Barangay 698
Malate,Barangay 699
Malate,Barangay 700
Malate,Barangay 701
Malate,Barangay 702
Malate,Barangay 703
Malate,Barangay 704
Malate,Barangay 705
Malate,Barangay 706
Malate,Barangay 707
Malate,Barangay 708
Malate,Barangay 709
Malate,Barangay 710
Malate,Barangay 711
Malate,Barangay 712
Malate,Barangay 713
Malate,Barangay 714
Malate,Barangay 715
Malate,Barangay 716
Malate,Barangay 717
Malate,Barangay 718
Malate,Barangay 719
Malate,Barangay 720
Malate,Barangay 722
Malate,Barangay 723
Malate,Barangay 724
Malate,Barangay 725
Malate,Barangay 726
Malate,Barangay 727
Malate,Barangay 728
Malate,Barangay 729
Malate,Barangay 730
Malate,Barangay 731
Malate,Barangay 732
Malate,Barangay 733
Malate,Barangay 734
Malate,Barangay 735
Malate,Barangay 736
Malate,Barangay 737
Malate,Barangay 738
Malate,Barangay 739
Malate,Barangay 740
Malate,Barangay 741
Malate,Barangay 742
Malate,Barangay 743
Malate,Barangay 744
Paco,Barangay 662
Paco,Barangay 664-A
Paco,Barangay 671
Paco,Barangay 672
Paco,Barangay 673
Paco,Barangay 674
Paco,Barangay 675
Paco,Barangay 676
Paco,Barangay 677
Paco,Barangay 678
Paco,Barangay 679
Paco,Barangay 680
Paco,Barangay 681
Paco,Barangay 682
Paco,Barangay 683
Paco,Barangay 684
Paco,Barangay 685
Paco,Barangay 686
Paco,Barangay 686
Paco,Barangay 687
Paco,Barangay 809
Paco,Barangay 810
Paco,Barangay 811
Paco,Barangay 812
Paco,Barangay 813
Paco,Barangay 814
Paco,Barangay 815
Paco,Barangay 816
Paco,Barangay 817
Paco,Barangay 818
Paco,Barangay 819
Paco,Barangay 820
Paco,Barangay 821
Paco,Barangay 822
Paco,Barangay 823
Paco,Barangay 824
Paco,Barangay 825
Paco,Barangay 826
Paco,Barangay 827
Paco,Barangay 828
Pandacan,Barangay 833
Pandacan,Barangay 834
Pandacan,Barangay 835
Pandacan,Barangay 836
Pandacan,Barangay 837
Pandacan,Barangay 838
Pandacan,Barangay 839
Pandacan,Barangay 840
Pandacan,Barangay 841
Pandacan,Barangay 842
Pandacan,Barangay 843
Pandacan,Barangay 844
Pandacan,Barangay 845
Pandacan,Barangay 846
Pandacan,Barangay 847
Pandacan,Barangay 848
Pandacan,Barangay 849
Pandacan,Barangay 850
Pandacan,Barangay 851
Pandacan,Barangay 852
Pandacan,Barangay 853
Pandacan,Barangay 854
Pandacan,Barangay 855
Pandacan,Barangay 856
Pandacan,Barangay 857
Pandacan,Barangay 858
Pandacan,Barangay 859
Pandacan,Barangay 860
Pandacan,Barangay 861
Pandacan,Barangay 862
Pandacan,Barangay 863
Pandacan,Barangay 864
Pandacan,Barangay 865
Pandacan,Barangay 867
Pandacan,Barangay 868
Pandacan,Barangay 869
Pandacan,Barangay 870
Pandacan,Barangay 871
Pandacan,Barangay 872
Port Area,Barangay 649
Port Area,Barangay 650
Port Area,Barangay 651
Port Area,Barangay 652
Port Area,Barangay 653
San Nicolas,Barangay 268
San Nicolas,Barangay 269
San Nicolas,Barangay 270
San Nicolas,Barangay 271
San Nicolas,Barangay 272
San Nicolas,Barangay 273
San Nicolas,Barangay 274
San Nicolas,Barangay 275
San Nicolas,Barangay 276
San Nicolas,Barangay 281
San Nicolas,Barangay 282
San Nicolas,Barangay 283
San Nicolas,Barangay 284
San Nicolas,Barangay 285
San Nicolas,Barangay 286
Santa Ana,Barangay 866
Santa Ana,Barangay 873
Santa Ana,Barangay 874
Santa Ana,Barangay 875
Santa Ana,Barangay 876
Santa Ana,Barangay 877
Santa Ana,Barangay 878
Santa Ana,Barangay 879
Santa Ana,Barangay 880
Santa Ana,Barangay 881
Santa Ana,Barangay 882
Santa Ana,Barangay 883
Santa Ana,Barangay 884
Santa Ana,Barangay 885
Santa Ana,Barangay 886
Santa Ana,Barangay 887
Santa Ana,Barangay 888
Santa Ana,Barangay 889
Santa Ana,Barangay 890
Santa Ana,Barangay 891
Santa Ana,Barangay 892
Santa Ana,Barangay 893
Santa Ana,Barangay 894
Santa Ana,Barangay 895
Santa Ana,Barangay 896
Santa Ana,Barangay 897
Santa Ana,Barangay 898
Santa Ana,Barangay 899
Santa Ana,Barangay 900
Santa Ana,Barangay 901
Santa Ana,Barangay 902
Santa Ana,Barangay 903
Santa Ana,Barangay 904
Santa Ana,Barangay 905
Santa Cruz,Barangay 297
Santa Cruz,Barangay 298
Santa Cruz,Barangay 299
Santa Cruz,Barangay 300
Santa Cruz,Barangay 301
Santa Cruz,Barangay 302
Santa Cruz,Barangay 303
Santa Cruz,Barangay 304
Santa Cruz,Barangay 305
Santa Cruz,Barangay 310
Santa Cruz,Barangay 311
Santa Cruz,Barangay 312
Santa Cruz,Barangay 313
Santa Cruz,Barangay 314
Santa Cruz,Barangay 315
Santa Cruz,Barangay 316
Santa Cruz,Barangay 317
Santa Cruz,Barangay 318
Santa Cruz,Barangay 319
Santa Cruz,Barangay 320
Santa Cruz,Barangay 321
Santa Cruz,Barangay 322
Santa Cruz,Barangay 323
Santa Cruz,Barangay 324
Santa Cruz,Barangay 325
Santa Cruz,Barangay 326
Santa Cruz,Barangay 327
Santa Cruz,Barangay 328
Santa Cruz,Barangay 329
Santa Cruz,Barangay 330
Santa Cruz,Barangay 331
Santa Cruz,Barangay 332
Santa Cruz,Barangay 333
Santa Cruz,Barangay 334
Santa Cruz,Barangay 335
Santa Cruz,Barangay 336
Santa Cruz,Barangay 337
Santa Cruz,Barangay 338
Santa Cruz,Barangay 339
Santa Cruz,Barangay 340
Santa Cruz,Barangay 341
Santa Cruz,Barangay 342
Santa Cruz,Barangay 343
Santa Cruz,Barangay 344
Santa Cruz,Barangay 345
Santa Cruz,Barangay 346
Santa Cruz,Barangay 347
Santa Cruz,Barangay 348
Santa Cruz,Barangay 349
Santa Cruz,Barangay 350
Santa Cruz,Barangay 351
Santa Cruz,Barangay 352
Santa Cruz,Barangay 353
Santa Cruz,Barangay 354
Santa Cruz,Barangay 355
Santa Cruz,Barangay 356
Santa Cruz,Barangay 357
Santa Cruz,Barangay 358
Santa Cruz,Barangay 359
Santa Cruz,Barangay 360
Santa Cruz,Barangay 361
Santa Cruz,Barangay 362
Santa Mesa,Barangay 587
Santa Mesa,Barangay 588
Santa Mesa,Barangay 589
Santa Mesa,Barangay 590
Santa Mesa,Barangay 591
Santa Mesa,Barangay 592
Santa Mesa,Barangay 593
Santa Mesa,Barangay 594
Santa Mesa,Barangay 595
Santa Mesa,Barangay 596
Santa Mesa,Barangay 597
Santa Mesa,Barangay 598
Santa Mesa,Barangay 599
Santa Mesa,Barangay 600
Santa Mesa,Barangay 601
Santa Mesa,Barangay 602
Santa Mesa,Barangay 603
Santa Mesa,Barangay 604
Santa Mesa,Barangay 605
Santa Mesa,Barangay 606
Santa Mesa,Barangay 607
Santa Mesa,Barangay 608
Santa Mesa,Barangay 609
Santa Mesa,Barangay 610
Santa Mesa,Barangay 611
Santa Mesa,Barangay 612
Santa Mesa,Barangay 613
Santa Mesa,Barangay 614
Santa Mesa,Barangay 615
Santa Mesa,Barangay 616
Santa Mesa,Barangay 617
Santa Mesa,Barangay 618
Santa Mesa,Barangay 619
Santa Mesa,Barangay 620
Santa Mesa,Barangay 621
Santa Mesa,Barangay 622
Santa Mesa,Barangay 623
Santa Mesa,Barangay 624
Santa Mesa,Barangay 625
Santa Mesa,Barangay 626
Santa Mesa,Barangay 627
Santa Mesa,Barangay 628
Santa Mesa,Barangay 629
Santa Mesa,Barangay 630
Santa Mesa,Barangay 631
Santa Mesa,Barangay 632
Santa Mesa,Barangay 633
Santa Mesa,Barangay 634
Santa Mesa,Barangay 635
Santa Mesa,Barangay 636
San Miguel,Barangay 637
San Miguel,Barangay 638
San Miguel,Barangay 639
San Miguel,Barangay 640
San Miguel,Barangay 641
San Miguel,Barangay 642
San Miguel,Barangay 643
San Miguel,Barangay 644
San Miguel,Barangay 645
San Miguel,Barangay 646
San Miguel,Barangay 647
San Miguel,Barangay 648
San Andres Bukid,Barangay 745
San Andres Bukid,Barangay 746
San Andres Bukid,Barangay 747
San Andres Bukid,Barangay 748
San Andres Bukid,Barangay 749
San Andres Bukid,Barangay 750
San Andres Bukid,Barangay 751
San Andres Bukid,Barangay 752
San Andres Bukid,Barangay 753
San Andres Bukid,Barangay 754
San Andres Bukid,Barangay 755
San Andres Bukid,Barangay 756
San Andres Bukid,Barangay 757
San Andres Bukid,Barangay 758
San Andres Bukid,Barangay 759
San Andres Bukid,Barangay 760
San Andres Bukid,Barangay 761
San Andres Bukid,Barangay 762
San Andres Bukid,Barangay 763
San Andres Bukid,Barangay 764
San Andres Bukid,Barangay 765
San Andres Bukid,Barangay 766
San Andres Bukid,Barangay 767
San Andres Bukid,Barangay 768
San Andres Bukid,Barangay 769
San Andres Bukid,Barangay 770
San Andres Bukid,Barangay 771
San Andres Bukid,Barangay 772
San Andres Bukid,Barangay 773
San Andres Bukid,Barangay 774
San Andres Bukid,Barangay 775
San Andres Bukid,Barangay 776
San Andres Bukid,Barangay 777
San Andres Bukid,Barangay 778
San Andres Bukid,Barangay 779
San Andres Bukid,Barangay 780
San Andres Bukid,Barangay 781
San Andres Bukid,Barangay 782
San Andres Bukid,Barangay 783
San Andres Bukid,Barangay 784
San Andres Bukid,Barangay 785
San Andres Bukid,Barangay 786
San Andres Bukid,Barangay 787
San Andres Bukid,Barangay 788
Sampaloc,Barangay 395
Sampaloc,Barangay 396
Sampaloc,Barangay 397
Sampaloc,Barangay 398
Sampaloc,Barangay 399
Sampaloc,Barangay 400
Sampaloc,Barangay 401
Sampaloc,Barangay 402
Sampaloc,Barangay 403
Sampaloc,Barangay 404
Sampaloc,Barangay 405
Sampaloc,Barangay 406
Sampaloc,Barangay 407
Sampaloc,Barangay 408
Sampaloc,Barangay 409
Sampaloc,Barangay 410
Sampaloc,Barangay 411
Sampaloc,Barangay 412
Sampaloc,Barangay 413
Sampaloc,Barangay 414
Sampaloc,Barangay 415
Sampaloc,Barangay 416
Sampaloc,Barangay 417
Sampaloc,Barangay 418
Sampaloc,Barangay 419
Sampaloc,Barangay 420
Sampaloc,Barangay 421
Sampaloc,Barangay 422
Sampaloc,Barangay 423
Sampaloc,Barangay 424
Sampaloc,Barangay 425
Sampaloc,Barangay 426
Sampaloc,Barangay 427
Sampaloc,Barangay 428
Sampaloc,Barangay 429
Sampaloc,Barangay 430
Sampaloc,Barangay 431
Sampaloc,Barangay 432
Sampaloc,Barangay 433
Sampaloc,Barangay 434
Sampaloc,Barangay 435
Sampaloc,Barangay 436
Sampaloc,Barangay 437
Sampaloc,Barangay 438
Sampaloc,Barangay 439
Sampaloc,Barangay 440
Sampaloc,Barangay 441
Sampaloc,Barangay 442
Sampaloc,Barangay 443
Sampaloc,Barangay 444
Sampaloc,Barangay 445
Sampaloc,Barangay 446
Sampaloc,Barangay 447
Sampaloc,Barangay 448
Sampaloc,Barangay 449
Sampaloc,Barangay 450
Sampaloc,Barangay 451
Sampaloc,Barangay 452
Sampaloc,Barangay 453
Sampaloc,Barangay 454
Sampaloc,Barangay 455
Sampaloc,Barangay 456
Sampaloc,Barangay 457
Sampaloc,Barangay 458
Sampaloc,Barangay 459
Sampaloc,Barangay 460
Sampaloc,Barangay 461
Sampaloc,Barangay 462
Sampaloc,Barangay 463
Sampaloc,Barangay 464
Sampaloc,Barangay 465
Sampaloc,Barangay 466
Sampaloc,Barangay 467
Sampaloc,Barangay 468
Sampaloc,Barangay 469
Sampaloc,Barangay 470
Sampaloc,Barangay 471
Sampaloc,Barangay 472
Sampaloc,Barangay 473
Sampaloc,Barangay 474
Sampaloc,Barangay 475
Sampaloc,Barangay 476
Sampaloc,Barangay 477
Sampaloc,Barangay 478
Sampaloc,Barangay 479
Sampaloc,Barangay 480
Sampaloc,Barangay 481
Sampaloc,Barangay 482
Sampaloc,Barangay 483
Sampaloc,Barangay 484
Sampaloc,Barangay 485
Sampaloc,Barangay 486
''';

  late Map<String, List<String>> _barangayMap;

  List<String> _getBarangaysForTown(String? town) {
    if (town == null) return [];
    return _barangayMap[town] ?? [];
  }

  // call this during initState to populate _barangayMap (see note below)
void _initializeBarangayMapFromCsv() {
  _barangayMap = {};
  final lines = _barangayCsv
    .split('\n')
    .map((l) => l.trim())
    .where((l) => l.isNotEmpty)
    .toList();
  if (lines.isNotEmpty && lines.first.toLowerCase().startsWith('district')) {
    lines.removeAt(0); // drop header if present
  }
  for (final line in lines) {
    final parts = line.split(',');
    if (parts.length >= 2) {
      final town = parts[0].trim();
      final barangay = parts.sublist(1).join(',').trim();
      if (town.isEmpty || barangay.isEmpty) continue;
      _barangayMap.putIfAbsent(town, () => <String>[]).add(barangay);
    }
  }
  // keep consistent ordering
  for (final k in _barangayMap.keys) {
    _barangayMap[k]!.sort((a, b) => a.compareTo(b));
  }
}
// --- END: copy from Registration ---

  // New: address controllers for Resident
  final _resHouseController = TextEditingController();
  final _resStreetController = TextEditingController();
  final _resBarangayController = TextEditingController();
  final _resTownController = TextEditingController();
  final _resTownManualController = TextEditingController();
  final _resZipController = TextEditingController();
  final _resCityController = TextEditingController(text: "Manila City");
  final _resCountryController = TextEditingController(text: "Philippines");

  // New: Work address controllers
  final _workStreetController = TextEditingController();
  final _workBarangayController = TextEditingController();
  final _workTownController = TextEditingController();
  final _workTownManualController = TextEditingController();
  final _workZipController = TextEditingController();
  final _workCityController = TextEditingController(text: "Manila City");
  final _workCountryController = TextEditingController(text: "Philippines");

  // New: Home address controllers (used by EMPLOYEE and STUDENT)
  final _homeHouseController = TextEditingController();
  final _homeStreetController = TextEditingController();
  final _homeBarangayController = TextEditingController();
  final _homeTownController = TextEditingController();
  final _homeTownManualController = TextEditingController();
  final _homeZipController = TextEditingController();
  final _homeCityController = TextEditingController();
  final _homeCountryController = TextEditingController(text: "Philippines");

  // New: School address controllers
  final _schoolNameController = TextEditingController();
  final _schoolStreetController = TextEditingController();
  final _schoolBarangayController = TextEditingController();
  final _schoolTownController = TextEditingController();
  final _schoolTownManualController = TextEditingController();
  final _schoolZipController = TextEditingController();
  final _schoolCityController = TextEditingController(text: "Manila City");
  final _schoolCountryController = TextEditingController(text: "Philippines");

  // track user category from supabase (RESIDENT / EMPLOYEE / STUDENT)
  String? _userCategory;
  // store initial category loaded from database to detect changes
  String? _initialUserCategory;

  // NEW: optional middle name checkbox state
  bool _hasMiddleName = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _initializeFormListeners();
    _addAddressCapitalizationListeners();
    _initializeBarangayMapFromCsv(); // << add this
    _loadUserData();
    _autoValidateMode = AutovalidateMode.onUserInteraction; //

    _bloodTypeController.addListener(() {
      final input = _bloodTypeController.text.toUpperCase();
      final validTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

      if (input.isEmpty || validTypes.any((type) => type.startsWith(input))) {
        if (_bloodTypeController.text != input) {
          _bloodTypeController.value = _bloodTypeController.value.copyWith(
            text: input,
            selection: TextSelection.fromPosition(
              TextPosition(offset: input.length),
            ),
          );
        }
      }
    });
  }

  Future<void> _loadUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    
    try {
      final response = await _supabase
          .from('app_users')
          .select()
          .eq('id', user.id)
          .single();
      
      final data = response;
      _userCategory = (data['user_category'] ?? '').toString().trim().toUpperCase();
      _initialUserCategory = _userCategory;
      String composedAddress = '';
      if ((data['address'] ?? '').toString().trim().isNotEmpty) {
        composedAddress = data['address'].toString();
      }

      Map<String, dynamic>? safeMap(dynamic v) {
        if (v is Map) return Map<String, dynamic>.from(v);
        return null;
      }

      final residentMap = safeMap(data['resident_address']);
      final homeMap = safeMap(data['home_address']);
      final workMap = safeMap(data['work_address']);
      final schoolMap = safeMap(data['school_address']);

      setState(() {
        _firstNameController.text = _capitalizeWords(data['first_name'] ?? '');
        _middleNameController.text = _capitalizeWords(data['middle_name'] ?? '');
        _hasMiddleName = (_middleNameController.text.trim().isNotEmpty);
        _lastNameController.text = _capitalizeWords(data['last_name'] ?? '');
        _emailController.text = data['email'] ?? '';
        _phoneController.text = _formatPhone(data['phone'] ?? '');
        _dobController.text = data['dob'] ?? '';
        _bloodTypeController.text = data['blood_type'] ?? '';
        _heightController.text = data['height'] ?? '';
        _weightController.text = data['weight'] ?? '';

        _profileImageUrl = (data['photo_url'] ?? '').toString().trim();
        _idImageUrl = (data['id_url'] ?? '').toString().trim();

        _addressController.text = composedAddress;

        // Resident
        if (residentMap != null && residentMap.isNotEmpty) {
          _resHouseController.text = residentMap['house']?.toString() ?? '';
          _resStreetController.text = residentMap['street']?.toString() ?? '';
          _resBarangayController.text = residentMap['barangay']?.toString() ?? '';
          _resTownController.text = residentMap['town']?.toString() ?? '';
          _resZipController.text = residentMap['zip']?.toString() ?? '';
          _resCityController.text = residentMap['city']?.toString() ?? (_resCityController.text);
          _resCountryController.text = residentMap['country']?.toString() ?? 'Philippines';
        }

        // Work
        if (workMap != null && workMap.isNotEmpty) {
          _workStreetController.text = workMap['street']?.toString() ?? '';
          _workBarangayController.text = workMap['barangay']?.toString() ?? '';
          _workTownController.text = workMap['town']?.toString() ?? '';
          _workZipController.text = workMap['zip']?.toString() ?? '';
          _workCityController.text = workMap['city']?.toString() ?? (_workCityController.text);
          _workCountryController.text = workMap['country']?.toString() ?? 'Philippines';
        }

        // Home
        if (homeMap != null && homeMap.isNotEmpty) {
          _homeHouseController.text = homeMap['house']?.toString() ?? '';
          _homeStreetController.text = homeMap['street']?.toString() ?? '';
          _homeBarangayController.text = homeMap['barangay']?.toString() ?? '';
          _homeTownController.text = homeMap['town']?.toString() ?? '';
          _homeZipController.text = homeMap['zip']?.toString() ?? '';
          _homeCityController.text = homeMap['city']?.toString() ?? _homeCityController.text;
          _homeCountryController.text = homeMap['country']?.toString() ?? 'Philippines';
        }

        // School
        if (schoolMap != null && schoolMap.isNotEmpty) {
          _schoolNameController.text = schoolMap['school_name']?.toString() ?? '';
          _schoolStreetController.text = schoolMap['street']?.toString() ?? '';
          _schoolBarangayController.text = schoolMap['barangay']?.toString() ?? '';
          _schoolTownController.text = schoolMap['town']?.toString() ?? '';
          _schoolZipController.text = schoolMap['zip']?.toString() ?? '';
          _schoolCityController.text = schoolMap['city']?.toString() ?? (_schoolCityController.text);
          _schoolCountryController.text = schoolMap['country']?.toString() ?? 'Philippines';
        }

        _normalizeLoadedTownValue(_workTownController, _workTownManualController);
        _normalizeLoadedTownValue(_schoolTownController, _schoolTownManualController);
        _normalizeLoadedTownValue(_homeTownController, _homeTownManualController);

        _isFormDirty = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void _normalizeLoadedTownValue(TextEditingController main, TextEditingController manual) {
  final val = main.text.trim();
  if (val.isNotEmpty && !_towns.contains(val)) {
    // keep the actual town value in main controller (so it can be shown)
    // clear manual controller — we no longer use 'Other' flow
    manual.text = '';
    // main.text left as the actual value (no 'Other' sentinel)
  }
}

  void _initializeFormListeners() {
    for (final ctrl in [
      _firstNameController,
      _middleNameController,
      _lastNameController,
      _emailController,
      _phoneController,
      _dobController,
      _addressController,
      _bloodTypeController,
      _heightController,
      _weightController,
      // resident
      _resHouseController,
      _resStreetController,
      _resBarangayController,
      _resTownController,
      _resTownManualController,
      _resZipController,
      _resCityController,
      _resCountryController,
      // work
      _workStreetController,
      _workBarangayController,
      _workTownController,
      _workTownManualController,
      _workZipController,
      _workCityController,
      _workCountryController,
      // home
      _homeHouseController,
      _homeStreetController,
      _homeBarangayController,
      _homeTownController,
      _homeTownManualController,
      _homeZipController,
      _homeCityController,
      _homeCountryController,
      // school
      _schoolNameController,
      _schoolStreetController,
      _schoolBarangayController,
      _schoolTownController,
      _schoolTownManualController,
      _schoolZipController,
      _schoolCityController,
      _schoolCountryController,
    ]) {
      ctrl.addListener(_markFormDirty);
    }
  }

  void _addAddressCapitalizationListeners() {
    final addressControllers = [
      _resHouseController,
      _resStreetController,
      _resBarangayController,
      _resTownController,
      _workStreetController,
      _workBarangayController,
      _workTownController,
      _homeHouseController,
      _homeStreetController,
      _homeBarangayController,
      _workCityController,
      _homeTownController,
      _homeCityController,
      _schoolNameController,
      _schoolStreetController,
      _schoolBarangayController,
      _schoolTownController,
      _schoolCityController,
      _resTownManualController,
      _workTownManualController,
      _homeTownManualController,
      _schoolTownManualController,
    ];

    for (final ctrl in addressControllers) {
      ctrl.addListener(() {
        final text = ctrl.text;
        final capitalized = _capitalizeWords(text);
        if (capitalized != text) {
          final sel = ctrl.selection;
          final int baseOffset = sel.baseOffset;
          final int offset = math.min(baseOffset, capitalized.length);
          ctrl.value = TextEditingValue(
            text: capitalized,
            selection: TextSelection.collapsed(offset: offset),
          );
        }
      });
    }
  }

  void _markFormDirty() {
    if (!_isFormDirty) setState(() => _isFormDirty = true);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _bloodTypeController.dispose();
    _heightController.dispose();
    _weightController.dispose();

    _resHouseController.dispose();
    _resStreetController.dispose();
    _resBarangayController.dispose();
    _resTownController.dispose();
    _resTownManualController.dispose();
    _resZipController.dispose();
    _resCityController.dispose();
    _resCountryController.dispose();

    _workStreetController.dispose();
    _workBarangayController.dispose();
    _workTownController.dispose();
    _workTownManualController.dispose();
    _workZipController.dispose();
    _workCityController.dispose();
    _workCountryController.dispose();

    _homeHouseController.dispose();
    _homeStreetController.dispose();
    _homeBarangayController.dispose();
    _homeTownController.dispose();
    _homeTownManualController.dispose();
    _homeZipController.dispose();
    _homeCityController.dispose();
    _homeCountryController.dispose();

    _schoolNameController.dispose();
    _schoolStreetController.dispose();
    _schoolBarangayController.dispose();
    _schoolTownController.dispose();
    _schoolTownManualController.dispose();
    _schoolZipController.dispose();
    _schoolCityController.dispose();
    _schoolCountryController.dispose();

    super.dispose();
  }

  bool _isFileSizeValid(File file, {int maxSizeMB = 5}) {
    final sizeInBytes = file.lengthSync();
    final sizeInMB = sizeInBytes / (1024 * 1024);
    return sizeInMB <= maxSizeMB;
  }

  Future<String?> _uploadImageToStorage(dynamic imageFileOrBytes, String folder) async {
  try {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final fileName = '${user.id}.jpg';
    final fullPath = '$folder/${user.id}/$fileName';

    // Step 1: Remove any existing file (ignore if missing)
    try {
      await _supabase.storage.from('profiles').remove([fullPath]);
    } catch (e) {
      debugPrint('No existing file to remove (that’s fine): $e');
    }

    // Step 2: Upload file
    final fileOptions = FileOptions(cacheControl: '3600', upsert: true);
    final bucket = _supabase.storage.from('profiles');

    if (kIsWeb && imageFileOrBytes is Uint8List) {
      // Web upload
      await bucket.uploadBinary(fullPath, imageFileOrBytes, fileOptions: fileOptions);
    } else if (imageFileOrBytes is File) {
      // Mobile upload
      await bucket.upload(fullPath, imageFileOrBytes, fileOptions: fileOptions);
    } else {
      throw Exception('Unsupported image format');
    }

    // Step 3: Get the public URL
    final publicUrl = bucket.getPublicUrl(fullPath);
    debugPrint('✅ Uploaded successfully: $publicUrl');
    return publicUrl;
  } catch (e) {
    debugPrint('uploadToProfilesBucket failed: $e');
    return null;
  }
}

  /// Returns true if remove succeeded (or file didn't exist), false on error.
  Future<bool> _deleteFileFromStorage(String folder, String userId) async {
    final path = '$folder/$userId.jpg';
    try {
      await _supabase.storage.from('profiles').remove([path]);
      debugPrint('Storage.remove succeeded: $path');
      return true;
    } catch (e, st) {
      debugPrint('Storage.remove failed for $path: $e\n$st');
      return false;
    }
  }

  /// Clear the URL/path fields in your app_users row.
  Future<bool> _clearUserImageField(String userId, {required bool isProfile}) async {
    try {
      final columnUrl = isProfile ? 'photo_url' : 'id_url';
      final columnPath = isProfile ? 'photo_path' : 'id_path';
      final updates = <String, dynamic>{columnUrl: null, columnPath: null, 'updated_at': DateTime.now().toIso8601String()};
      // Use select().single() to get response shape consistent with your save flow
      final resp = await _supabase.from('app_users').update(updates).eq('id', userId).select().single();
      debugPrint('DB cleared ${isProfile ? 'profile' : 'id'} fields for $userId -> $resp');
      return true;
    } catch (e, st) {
      debugPrint('DB update exception clearing image fields: $e\n$st');
      return false;
    }
  }

  /// Combined flow: delete from storage first, then clear DB, then update UI state.
  Future<void> deleteProfileOrId({required bool isProfile}) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final folder = isProfile ? 'profile_images' : 'id_uploads';
    final userId = user.id;

    final removed = await _deleteFileFromStorage(folder, userId);
    if (!removed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete image from storage. Check permissions or network.'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isSaving = false);
      return;
    }

    final cleared = await _clearUserImageField(userId, isProfile: isProfile);
    if (!cleared) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File removed but failed to update profile record.'), backgroundColor: Colors.orange),
        );
      }
      setState(() => _isSaving = false);
      return;
    }

    setState(() {
      if (isProfile) {
        _profileImage = null;
        _profileImageBytes = null;
        _profileImageUrl = null;
        _removeProfileImage = false;
        _profileUploadProgress = null;
      } else {
        _idImage = null;
        _idImageBytes = null;
        _idImageUrl = null;
        _removeIdImage = false;
        _idUploadProgress = null;
      }
      _isFormDirty = false;
      _isSaving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image deleted successfully.')),
      );
    }
  }

 Future<void> _pickImage(ImageSource source, bool isProfile) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(source: source);
  if (picked == null) return;

  Uint8List? bytes;
  File? file;
  try {
    if (kIsWeb) {
      bytes = await picked.readAsBytes();
      debugPrint('DEBUG: picked image (web) bytes=${bytes.lengthInBytes}');
    } else {
      file = File(picked.path);
      debugPrint('DEBUG: picked image (mobile) path=${picked.path}');
    }
  } catch (e) {
    debugPrint('Error reading picked image: $e');
    return;
  }

  // 🔹 Check file size
  if (bytes != null) {
    final sizeInMB = bytes.lengthInBytes / (1024 * 1024);
    if (sizeInMB > 5) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image size too large (max 5MB)'), backgroundColor: Colors.red),
      );
      return;
    }
  } else if (file != null && !_isFileSizeValid(file)) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image size too large (max 5MB)'), backgroundColor: Colors.red),
    );
    return;
  }

  final action = await _showImagePreviewBeforeSave(bytes ?? file!, isProfile);
  if (!mounted) return;

  if (action == 'use') {
    setState(() {
      if (isProfile) {
        _profileImage = file;
        _profileImageBytes = bytes;
        _removeProfileImage = false;
        _profileImageUrl = null;
      } else {
        _idImage = file;
        _idImageBytes = bytes;
        _removeIdImage = false;
        _idImageUrl = null;
      }
      _markFormDirty();
    });

    // 🔹 Upload immediately after user confirms
    final imageToUpload = file ?? bytes;
    final folder = isProfile ? 'profile_images' : 'id_uploads';

    final newUrl = await _uploadImageToStorage(imageToUpload, folder);

    if (newUrl != null && mounted) {
      setState(() {
        if (isProfile) {
          _profileImageUrl = newUrl;
        } else {
          _idImageUrl = newUrl;
        }
      });
      debugPrint('✅ Image updated: $newUrl');
    } else {
      debugPrint('⚠️ Upload failed or returned null URL');
    }
  } else if (action == 'retake') {
    await _pickImage(ImageSource.camera, isProfile);
  } else if (action == 'gallery') {
    await _pickImage(ImageSource.gallery, isProfile);
  }
}

  Future<String?> _showImagePreviewBeforeSave(dynamic image, bool isProfile) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Widget content;
        if (image is Uint8List) {
          content = Image.memory(image, fit: BoxFit.contain);
        } else if (image is File) {
          content = Image.file(image, fit: BoxFit.contain);
        } else {
          content = const SizedBox.shrink();
        }
        return AlertDialog(
          title: Text(isProfile ? 'Preview Profile Photo' : 'Preview ID Photo'),
          content: SizedBox(width: double.maxFinite, child: content),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop('cancel'), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(ctx).pop('gallery'), child: const Text('Choose from Gallery')),
            TextButton(onPressed: () => Navigator.of(ctx).pop('retake'), child: const Text('Retake')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop('use'), child: const Text('Use Photo')),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final ninetyfiveYearsAgo = DateTime(now.year - 95, now.month, now.day);
    final eightYearsAgo = DateTime(now.year - 8, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: eightYearsAgo,
      firstDate: ninetyfiveYearsAgo,
      lastDate: eightYearsAgo,
    );

    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.month}/${picked.day}/${picked.year}";
        _markFormDirty();
      });
    }
  }

  String _capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _formatPhone(String phone) {
    if (phone.startsWith('+63')) {
      return '0${phone.substring(3)}';
    }
    return phone;
  }

  Map<String, dynamic> _collectAddressMap({
    required TextEditingController house,
    required TextEditingController street,
    required TextEditingController barangay,
    required TextEditingController townMain,
    required TextEditingController townManual,
    required TextEditingController zip,
    required TextEditingController city,
    required TextEditingController country,
  }) {
    final String townValue = _getTownValue(townMain, townManual);
    return {
      'house': house.text.trim(),
      'street': street.text.trim(),
      'barangay': barangay.text.trim(),
      'town': townValue,
      'zip': zip.text.trim(),
      'city': city.text.trim(),
      'country': country.text.trim(),
    };
  }

  String _getTownValue(TextEditingController main, TextEditingController manual) {
    final mainVal = main.text.trim();
    if (mainVal.toLowerCase() == 'other') {
      return manual.text.trim();
    }
    return mainVal;
  }

  String _composeAddressStringFromMap(Map<String, dynamic> m) {
    final parts = <String>[];
    void addIf(String? s) {
      if (s != null && s.toString().trim().isNotEmpty) parts.add(s.toString().trim());
    }

    addIf(m['house']);
    addIf(m['street']);
    if (m['barangay'] != null && m['barangay'].toString().trim().isNotEmpty) {
      parts.add('Barangay ${m['barangay'].toString().trim()}');
    }
    addIf(m['town']);
    addIf(m['city']);
    if (m['zip'] != null && m['zip'].toString().trim().isNotEmpty) parts.add('ZIP ${m['zip'].toString().trim()}');
    return parts.join(', ');
  }

  ImageProvider? _getProfileImageProvider() {
    if (_profileImage != null) return FileImage(_profileImage!);
    if (_profileImageBytes != null) return MemoryImage(_profileImageBytes!);
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) return NetworkImage(_profileImageUrl!);
    return null;
  }

 Future<void> _deleteFileByPath(String? path) async {
  if (path == null || path.isEmpty) {
    debugPrint('Skip delete — no path provided');
    return;
  }

  try {
    // Normalize: handle full URLs or wrong prefixes
    String normalizedPath = path.trim();

    // Case 1: full URL (convert to internal path)
    if (normalizedPath.startsWith('http')) {
      final uri = Uri.parse(normalizedPath);
      final segments = uri.pathSegments;
      final idx = segments.indexOf('profiles');
      if (idx != -1 && idx + 1 < segments.length) {
        normalizedPath = segments.sublist(idx + 1).join('/');
      }
    }

    // Case 2: accidental leading slashes or "public/" prefix
    if (normalizedPath.startsWith('public/')) {
      normalizedPath = normalizedPath.replaceFirst('public/', '');
    }
    if (normalizedPath.startsWith('/')) {
      normalizedPath = normalizedPath.substring(1);
    }

    debugPrint('Attempting to delete storage object: $normalizedPath');

    final response = await _supabase.storage.from('profiles').remove([normalizedPath]);
    debugPrint('Storage.remove response: $response');

    // Double-check: list objects to confirm delete
    final listAfter = await _supabase.storage.from('profiles').list(
      path: normalizedPath.split('/').first,
    );
    debugPrint('Files still present in folder after delete: ${listAfter.map((e) => e.name).toList()}');
  } catch (e, st) {
    debugPrint('deleteFileByPath failed: $e\n$st');
  }
}

  Future<void> _saveProfile() async {
  // DEBUG INSTRUMENTATION START
debugPrint('=== _saveProfile() DEBUG RUN ===');
debugPrint('_isSaving before start = $_isSaving');
debugPrint('_autoValidateMode before start = $_autoValidateMode');
debugPrint('_hasMiddleName = $_hasMiddleName');
debugPrint('_userCategory = ${_userCategory ?? "<null>"}');

// snapshot of controllers
debugPrint('controllers snapshot:');
final controllers = {
  'First Name': _firstNameController.text,
  'Middle Name': _middleNameController.text,
  'Last Name': _lastNameController.text,
  'Phone Number': _phoneController.text,
  'Res House': _resHouseController.text,
  'Res Street': _resStreetController.text,
  'Res Barangay': _resBarangayController.text,
  'Res City': _resCityController.text,
  'Work Street': _workStreetController.text,
  'Home Street': _homeStreetController.text,
  'School Name': _schoolNameController.text,
};
controllers.forEach((k, v) => debugPrint('  $k => "${v}"'));

// snapshot of _fieldErrors map
debugPrint('_fieldErrors.keys: ${_fieldErrors.keys.toList()}');
// human-friendly print for controller-keyed _fieldErrors
debugPrint('_fieldErrors size: ${_fieldErrors.length}');
_fieldErrors.forEach((ctrl, msg) {
  // try to map controller -> label for readable logging
  String label;
  if (identical(ctrl, _firstNameController)) label = 'First Name';
  else if (identical(ctrl, _middleNameController)) label = 'Middle Name';
  else if (identical(ctrl, _lastNameController)) label = 'Last Name';
  else if (identical(ctrl, _phoneController)) label = 'Phone Number';
  else if (identical(ctrl, _resHouseController)) label = 'Res House';
  else if (identical(ctrl, _resStreetController)) label = 'Res Street';
  else if (identical(ctrl, _resBarangayController)) label = 'Res Barangay';
  else if (identical(ctrl, _resCityController)) label = 'Res City';
  else if (identical(ctrl, _workStreetController)) label = 'Work Street';
  else if (identical(ctrl, _homeStreetController)) label = 'Home Street';
  else if (identical(ctrl, _schoolNameController)) label = 'School Name';
  else label = ctrl.toString(); // fallback
  debugPrint('  _fieldErrors["$label"] = "$msg"');
});

// check form validator state quickly
bool formValid = _formKey.currentState?.validate() ?? true;
debugPrint('Form validate() returned: $formValid');
// DEBUG INSTRUMENTATION END


  // 2) Phone format guard (must start with 0 and be exactly 11 digits)
  final phoneVal = _phoneController.text.trim();
  if (!RegExp(r'^0\d{10}$').hasMatch(phoneVal)) {
    // trigger phone field validator display (no SnackBar)
    if (mounted) {
      setState(() {}); // forces validators / UI update
      _formKey.currentState!.validate();
    }
    return;
  }

  // 3) Address completeness guard based on category
  final category = (_userCategory ?? '').toString().toUpperCase();

  String? addressErrorMessage;

  if (category == 'RESIDENT') {
    if (_resHouseController.text.trim().isEmpty ||
        _resStreetController.text.trim().isEmpty ||
        _resBarangayController.text.trim().isEmpty ||
        _resCityController.text.trim().isEmpty) {
      addressErrorMessage = 'Please complete your resident address (House, Street, Barangay, City).';
    }
  } else if (category == 'EMPLOYEE') {
    if (_workStreetController.text.trim().isEmpty ||
        _workBarangayController.text.trim().isEmpty ||
        _workCityController.text.trim().isEmpty) {
      addressErrorMessage = 'Please complete your work address (Street, Barangay, City).';
    } else if (_homeHouseController.text.trim().isEmpty ||
        _homeStreetController.text.trim().isEmpty ||
        _homeBarangayController.text.trim().isEmpty ||
        _homeCityController.text.trim().isEmpty) {
      addressErrorMessage = 'Please complete your home address (House, Street, Barangay, City).';
    }
  } else if (category == 'STUDENT') {
    if (_schoolNameController.text.trim().isEmpty ||
        _schoolStreetController.text.trim().isEmpty ||
        _schoolBarangayController.text.trim().isEmpty ||
        _schoolCityController.text.trim().isEmpty) {
      addressErrorMessage = 'Please complete your school address (School name, Street, Barangay, City).';
    } else if (_homeHouseController.text.trim().isEmpty ||
        _homeStreetController.text.trim().isEmpty ||
        _homeBarangayController.text.trim().isEmpty ||
        _homeCityController.text.trim().isEmpty) {
      addressErrorMessage = 'Please complete your home address (House, Street, Barangay, City).';
    }
  } else {
    // fallback when category missing or other
    if (_resHouseController.text.trim().isEmpty ||
        _resStreetController.text.trim().isEmpty ||
        _resBarangayController.text.trim().isEmpty ||
        _resCityController.text.trim().isEmpty) {
      addressErrorMessage = 'Please complete your address (House, Street, Barangay, City).';
    }
  }

  if (addressErrorMessage != null) {
    // Instead of SnackBar, show field-level errors via validators
    if (mounted) {
      setState(() {}); // validators should report empty-field errors under each affected TextFormField
      _formKey.currentState!.validate();
    }
    return;
  }

  // All guards passed — start saving
  setState(() => _isSaving = true);

  try {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    

    String? profileUrl;
    if (_removeProfileImage) {
      try {
        await _supabase.storage
            .from('profiles')
            .remove(['profile_images/${user.id}.jpg']);
      } catch (_) {}
    } else if (_profileImage != null || _profileImageBytes != null) {
      final img = _profileImage ?? _profileImageBytes!;
      profileUrl = await _uploadImageToStorage(
    _profileImage ?? _profileImageBytes,
    'profile_images',
  );

      if (profileUrl == null && (img != null)) {
        debugPrint('Profile upload failed; aborting save.');
        if (mounted) {
          Flushbar(
            message: 'Failed to upload profile photo. Check storage permissions or network.',
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ).show(context);
        }
        setState(() => _isSaving = false);
        return;
      }
    }

    String? idUrl;
    if (_removeIdImage) {
      try {
        await _supabase.storage
            .from('profiles')
            .remove(['id_uploads/${user.id}.jpg']);
      } catch (_) {}
    } else if (_idImage != null || _idImageBytes != null) {
      final img = _idImage ?? _idImageBytes!;
      idUrl = await _uploadImageToStorage(_idImage ?? _idImageBytes,'id_uploads',);

      if (idUrl == null && (img != null)) {
        debugPrint('ID upload failed; aborting save.');
        if (mounted) {
          Flushbar(
            message: 'Failed to upload ID image. Check storage permissions or network.',
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ).show(context);
        }
        setState(() => _isSaving = false);
        return;
      }
    }

    final updates = <String, dynamic>{
      'first_name': _firstNameController.text.trim(),
      'middle_name': _hasMiddleName ? _middleNameController.text.trim() : '',
      'last_name': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'dob': _dobController.text.trim(),
      'blood_type': _bloodTypeController.text.trim(),
      'height': _heightController.text.trim(),
      'weight': _weightController.text.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (profileUrl != null) {
      updates['photo_url'] = profileUrl;
      updates['photo_path'] = 'profile_images/${user.id}.jpg';
    }
    if (idUrl != null) {
      updates['id_url'] = idUrl;
      updates['id_path'] = 'id_uploads/${user.id}.jpg';
    }

    if (_removeProfileImage) {
      updates['photo_url'] = null;
      updates['photo_path'] = null;
    }
    if (_removeIdImage) {
      updates['id_url'] = null;
      updates['id_path'] = null;
    }

    if ((_userCategory ?? '').isNotEmpty) {
      updates['user_category'] = (_userCategory ?? '').toString().toUpperCase();
    }

    final newCat = (_userCategory ?? '').toString().toUpperCase();
    final oldCat = (_initialUserCategory ?? '').toString().toUpperCase();

    if (newCat == 'RESIDENT') {
      final map = _collectAddressMap(
        house: _resHouseController,
        street: _resStreetController,
        barangay: _resBarangayController,
        townMain: _resTownController,
        townManual: _resTownManualController,
        zip: _resZipController,
        city: _resCityController,
        country: _resCountryController,
      );
      updates['resident_address'] = map;
      updates['address'] = _composeAddressStringFromMap(map);
    } else if (newCat == 'EMPLOYEE') {
      final workMap = _collectAddressMap(
        house: TextEditingController(),
        street: _workStreetController,
        barangay: _workBarangayController,
        townMain: _workTownController,
        townManual: _workTownManualController,
        zip: _workZipController,
        city: _workCityController,
        country: _workCountryController,
      );
      final homeMap = _collectAddressMap(
        house: _homeHouseController,
        street: _homeStreetController,
        barangay: _homeBarangayController,
        townMain: _homeTownController,
        townManual: _homeTownManualController,
        zip: _homeZipController,
        city: _homeCityController,
        country: _homeCountryController,
      );
      updates['work_address'] = workMap;
      updates['home_address'] = homeMap;
      updates['address'] = _composeAddressStringFromMap(homeMap);
    } else if (newCat == 'STUDENT') {
      final schoolMap = {
        'school_name': _schoolNameController.text.trim(),
        'street': _schoolStreetController.text.trim(),
        'barangay': _schoolBarangayController.text.trim(),
        'town': _getTownValue(_schoolTownController, _schoolTownManualController),
        'zip': _schoolZipController.text.trim(),
        'city': _schoolCityController.text.trim(),
        'country': _schoolCountryController.text.trim(),
      };
      final homeMap = _collectAddressMap(
        house: _homeHouseController,
        street: _homeStreetController,
        barangay: _homeBarangayController,
        townMain: _homeTownController,
        townManual: _homeTownManualController,
        zip: _homeZipController,
        city: _homeCityController,
        country: _homeCountryController,
      );
      updates['school_address'] = schoolMap;
      updates['home_address'] = homeMap;
      updates['address'] = _composeAddressStringFromMap(homeMap);
    }

    if (oldCat != newCat) {
      if (newCat == 'RESIDENT') {
        updates['work_address'] = null;
        updates['home_address'] = null;
        updates['school_address'] = null;
      } else if (newCat == 'EMPLOYEE') {
        updates['resident_address'] = null;
        updates['school_address'] = null;
      } else if (newCat == 'STUDENT') {
        updates['resident_address'] = null;
        updates['work_address'] = null;
      } else {
        updates['resident_address'] = null;
        updates['work_address'] = null;
        updates['school_address'] = null;
        updates['home_address'] = null;
      }
    }

    debugPrint('DEBUG: database updates prepared = $updates');

   // ---------- deterministic field-error population (controller-keyed) ----------
    _fieldErrors.clear(); // clear earlier programmatic errors

    // run the Form validators first
    final formOk = _formKey.currentState?.validate() ?? true;

    // personal fields
    if (_firstNameController.text.trim().isEmpty) {
      _fieldErrors[_firstNameController] = 'Please enter First Name';
    }
    if (_lastNameController.text.trim().isEmpty) {
      _fieldErrors[_lastNameController] = 'Please enter Last Name';
    }
    if (_hasMiddleName == true && _middleNameController.text.trim().isEmpty) {
      _fieldErrors[_middleNameController] = 'Please enter Middle Name';
    }
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _fieldErrors[_phoneController] = 'Please enter Phone Number';
    } else if (!RegExp(r'^0\d{10}$').hasMatch(phone)) {
      _fieldErrors[_phoneController] = 'Enter a valid 11-digit number starting with 0';
    }

    // Address checks by category — set per-controller keys
    final category = (_userCategory ?? '').toString().toUpperCase();
if (category == 'RESIDENT') {
if (_resHouseController.text.trim().isEmpty) _fieldErrors[_resHouseController] = 'Please enter House/Unit/Building No.';
if (_resStreetController.text.trim().isEmpty) _fieldErrors[_resStreetController] = 'Please enter Street Name';
if (_resBarangayController.text.trim().isEmpty) _fieldErrors[_resBarangayController] = 'Please enter Barangay/Subdivision';
if (_resCityController.text.trim().isEmpty) _fieldErrors[_resCityController] = 'Please enter City/Municipality';
} else if (category == 'EMPLOYEE') {
if (_workStreetController.text.trim().isEmpty) _fieldErrors[_workStreetController] = 'Please enter Street/Building No.';
if (_workBarangayController.text.trim().isEmpty) _fieldErrors[_workBarangayController] = 'Please enter Barangay/Subdivision';
if (_workCityController.text.trim().isEmpty) _fieldErrors[_workCityController] = 'Please enter City/Municipality';
if (_homeHouseController.text.trim().isEmpty) _fieldErrors[_homeHouseController] = 'Please enter House/Unit/Building No.';
if (_homeStreetController.text.trim().isEmpty) _fieldErrors[_homeStreetController] = 'Please enter Street Name';
if (_homeBarangayController.text.trim().isEmpty) _fieldErrors[_homeBarangayController] = 'Please enter Barangay/Subdivision';
if (_homeCityController.text.trim().isEmpty) _fieldErrors[_homeCityController] = 'Please enter City/Municipality';
} else if (category == 'STUDENT') {
if (_schoolNameController.text.trim().isEmpty) _fieldErrors[_schoolNameController] = 'Please enter Full School Name';
if (_schoolStreetController.text.trim().isEmpty) _fieldErrors[_schoolStreetController] = 'Please enter Street Name';
if (_schoolBarangayController.text.trim().isEmpty) _fieldErrors[_schoolBarangayController] = 'Please enter Barangay/Subdivision';
if (_schoolCityController.text.trim().isEmpty) _fieldErrors[_schoolCityController] = 'Please enter City/Municipality';
if (_homeHouseController.text.trim().isEmpty) _fieldErrors[_homeHouseController] = 'Please enter House/Unit/Building No.';
if (_homeStreetController.text.trim().isEmpty) _fieldErrors[_homeStreetController] = 'Please enter Street Name';
if (_homeBarangayController.text.trim().isEmpty) _fieldErrors[_homeBarangayController] = 'Please enter Barangay/Subdivision';
if (_homeCityController.text.trim().isEmpty) _fieldErrors[_homeCityController] = 'Please enter City/Municipality';
} else {
if (_resHouseController.text.trim().isEmpty) _fieldErrors[_resHouseController] = 'Please enter House/Unit/Building No.';
if (_resStreetController.text.trim().isEmpty) _fieldErrors[_resStreetController] = 'Please enter Street Name';
if (_resBarangayController.text.trim().isEmpty) _fieldErrors[_resBarangayController] = 'Please enter Barangay/Subdivision';
if (_resCityController.text.trim().isEmpty) _fieldErrors[_resCityController] = 'Please enter City/Municipality';
}


if (_fieldErrors.isNotEmpty) {
if (mounted) {
setState(() {
_autoValidateMode = AutovalidateMode.always;
});
}
return;
}


debugPrint('_fieldErrors size: ${_fieldErrors.length}');
_fieldErrors.forEach((ctrl, msg) {
debugPrint(' _fieldErrors[${ctrl.hashCode}] = "$msg"');
});

    // Show errors if any — force form to display them (existing pattern)
    if (_fieldErrors.isNotEmpty || !formOk) {
      if (mounted) {
        setState(() {
          _autoValidateMode = AutovalidateMode.always;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _formKey.currentState?.validate();
            setState(() {}); // ensure controller-keyed errorText is picked up
          }
        });
      }
      return;
    }
    // ---------- end controller-keyed population ----------

    // proceed with DB update
    Map<String, dynamic>? returnedRow;

    try {
      final resp = await _supabase
          .from('app_users')
          .update(updates)
          .eq('id', user.id)
          .select()
          .single();

      debugPrint('DB update returned: $resp');

      if (resp is Map<String, dynamic>) {
        returnedRow = resp;
      } else {
        try {
          returnedRow = (resp as dynamic)?['data'] as Map<String, dynamic>?;
        } catch (_) {
          returnedRow = null;
        }
      }

      debugPrint('Returned row: $returnedRow');
      debugPrint('DEBUG: Database update completed for user ${user.id}');

      _initialUserCategory = _userCategory;
    } catch (e, st) {
      debugPrint('======== UPDATE ERROR ========');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');
      debugPrint('Stack: $st');
      if (kIsWeb) {
        debugPrint('Check browser DevTools Network/Console for CORS errors.');
      }

      if (mounted) {
        Flushbar(
          message: 'Failed to update profile: $e',
          duration: const Duration(seconds: 3),
        ).show(context);
      }

      rethrow;
    }
    if (mounted) {
      setState(() {
        _profileImage = null;
        _profileImageBytes = null;
        _profileImageUrl = null;
        _profileUploadProgress = null;
        _removeProfileImage = false;
        _idImage = null;
        _idImageBytes = null;
        _idImageUrl = null;
        _idUploadProgress = null;
        _removeIdImage = false;
      });
    }

    if (!mounted) return;
    await Flushbar(
      message: 'Profile saved successfully!',
      backgroundColor: const Color.fromARGB(255, 14, 151, 7),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderRadius: BorderRadius.circular(12),
      flushbarPosition: FlushbarPosition.TOP,
      icon: const Icon(
        Icons.check_circle,
        color: Colors.white,
      ),
      messageColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      animationDuration: const Duration(milliseconds: 300),
      duration: const Duration(seconds: 3),
    ).show(context);

    if (!mounted) return;
    setState(() => _isFormDirty = false);

    Navigator.pop(context, true);
  } catch (e) {
    debugPrint('Error saving profile: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}

  Future<bool> _confirmUnsavedChanges() async {
    if (!_isFormDirty) return true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Discard them and go back?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Discard',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Widget _buildProfileImageSection() {
    const primaryColor = Color(0xFF28588B);
    
    Widget _grayPlaceholder(double size) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.account_circle,
            size: size * 0.6,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor.withOpacity(0.2), width: 3),
                ),
                child: ClipOval(
                  child: _getProfileImageProvider() != null
                      ? Image(image: _getProfileImageProvider()!, fit: BoxFit.cover)
                      : _grayPlaceholder(94),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showProfileImageOptions,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ),
              ),
              if (_profileUploadProgress != null)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 36,
                            width: 36,
                            child: CircularProgressIndicator(
                              value: _profileUploadProgress,
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${((_profileUploadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_profileImage != null || _profileImageBytes != null || (_profileImageUrl != null && !_removeProfileImage))
            TextButton.icon(
              onPressed: () async {
                await deleteProfileOrId(isProfile: true);
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
              label: const Text(
                'Remove Photo',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  void _showProfileImageOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final hasAny = _profileImage != null || _profileImageBytes != null || _profileImageUrl != null;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            child: Wrap(
              children: [
                if (hasAny)
                  ListTile(
                    leading: const Icon(Icons.remove_red_eye, color: Color(0xFF28588B)),
                    title: const Text('View Photo', style: TextStyle(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      if (_profileImage != null) {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_profileImage!),
                            ),
                          ),
                        );
                      } else if (_profileImageBytes != null) {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(_profileImageBytes!),
                            ),
                          ),
                        );
                      } else if (_profileImageUrl != null) {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(_profileImageUrl!),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Color(0xFF28588B)),
                  title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera, true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Color(0xFF28588B)),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery, true);
                  },
                ),
                if (hasAny)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Remove Photo', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                    onTap: () async {
                      Navigator.pop(context);
                      await deleteProfileOrId(isProfile: true);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.grey),
                  title: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Personal Information'),
          const SizedBox(height: 16),
          _buildEditableField('First Name', _firstNameController, hint: 'First Name'),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _hasMiddleName,
                  onChanged: (val) {
                    final bool newVal = val ?? false;
                    setState(() {
                      _hasMiddleName = newVal;
                      if (!newVal) {
                        _middleNameController.clear();
                        _fieldErrors.remove('Middle Name'); // <-- remove any programmatic error
                      }
                      _markFormDirty();
                    });

                    FocusScope.of(context).unfocus();

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _formKey.currentState?.validate();
                    });
                  },
                ),
                const Text("I have a middle name", style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
          if (_hasMiddleName)
            _buildEditableField(
              'Middle Name',
              _middleNameController,
              hint: 'Middle Name',
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter Middle Name';
                final pattern = RegExp(r"^[A-Za-z\s\.'-]+$");
                if (!pattern.hasMatch(val.trim())) return 'Enter a valid middle name';
                return null;
              },
            ),
          _buildEditableField('Last Name', _lastNameController, hint: 'Last Name'),
          _buildEditableField(
            'Email',
            _emailController,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            isReadOnly: true,
          ),
          _buildEditableField(
  'Phone Number',
  _phoneController,
  hint: '09123456789',
  keyboardType: TextInputType.number,
  validator: (val) {
    if (val == null || val.trim().isEmpty) return 'Please enter Phone Number';
    final s = val.trim();
    if (!RegExp(r'^0\d{10}$').hasMatch(s)) {
      return 'Enter a valid 11-digit number starting with 0';
    }
    return null;
  },
),
          _buildEditableField(
            'Date of Birth',
            _dobController,
            hint: 'MM/DD/YYYY',
            isDateField: true,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              value: (_userCategory != null && _userCategory!.isNotEmpty)
                  ? _userCategory!.toUpperCase()
                  : null,
              autovalidateMode: _autoValidateMode, // ✅ add this line
              decoration: InputDecoration(
                labelText: 'Category',
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'RESIDENT', child: Text('Resident')),
                DropdownMenuItem(value: 'EMPLOYEE', child: Text('Employee')),
                DropdownMenuItem(value: 'STUDENT', child: Text('Student')),
              ],
              onChanged: (val) {
                setState(() {
                  _userCategory = (val ?? '').toString().toUpperCase();
                  _markFormDirty();

                  // ✅ clear red indicator instantly when a valid option is picked
                  if (_autoValidateMode == AutovalidateMode.always) {
                    _autoValidateMode = AutovalidateMode.onUserInteraction;
                  }
                });
              },
            validator: (v) {
              if ((_userCategory ?? '').isNotEmpty) return null; // already set from DB
              if (v == null || v.isEmpty) return 'Please select a category';
              return null;
            },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    final cat = (_userCategory ?? 'RESIDENT').toUpperCase();
    
    Widget _buildAddressCard(String title, List<Widget> children) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      );
    }

    if (cat == 'EMPLOYEE') {
      return Column(
        children: [
          _buildAddressCard('Work Address', [
            // Work Address children — Town -> Barangay -> ZIP dropdowns
              _buildEditableField('Street/Building No.', _workStreetController, hint: 'Street / Building'),

              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: (_workTownController.text.isNotEmpty && _towns.contains(_workTownController.text))
                      ? _workTownController.text
                      : (_workTownController.text.isNotEmpty ? _workTownController.text : null),
                  items: [
                    ..._towns.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                    if (_workTownController.text.isNotEmpty && !_towns.contains(_workTownController.text))
                      DropdownMenuItem(value: _workTownController.text, child: Text(_workTownController.text)),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _workTownController.text = val ?? '';
                      _workBarangayController.text = '';
                      final zip = _getFirstZipCodeForTown(_workTownController.text);
                      if (zip != null) _workZipController.text = zip;
                      _markFormDirty();
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Town',
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  validator: (val) {
                    if ((_workTownController.text ?? '').trim().isEmpty && (val == null || val.trim().isEmpty)) return 'Select town';
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _getBarangaysForTown(_workTownController.text).contains(_workBarangayController.text) ? _workBarangayController.text : null,
                  items: _getBarangaysForTown(_workTownController.text).map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: _getBarangaysForTown(_workTownController.text).isEmpty
                      ? null
                      : (val) {
                          setState(() {
                            _workBarangayController.text = val ?? '';
                            _markFormDirty();
                          });
                        },
                  decoration: InputDecoration(
                    labelText: "Barangay/Subdivision",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _getZipCodesForTown(_workTownController.text).contains(_workZipController.text) ? _workZipController.text : _getFirstZipCodeForTown(_workTownController.text),
                  items: _getZipCodesForTown(_workTownController.text).map((zip) => DropdownMenuItem(value: zip, child: Text(zip))).toList(),
                  onChanged: _getZipCodesForTown(_workTownController.text).isEmpty
                      ? null
                      : (val) {
                          setState(() {
                            _workZipController.text = val ?? '';
                            _markFormDirty();
                          });
                        },
                  decoration: InputDecoration(
                    labelText: "ZIP Code",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'ZIP code is required';
                    return null;
                  },
                ),
              ),

              _buildEditableField('City/Municipality', _workCityController, hint: 'City', isReadOnly: false),
              _buildEditableField('Country', _workCountryController, hint: 'Philippines', isReadOnly: true),
            ]),
          const SizedBox(height: 16),
          
          _buildAddressCard('Home Address', [
            _buildEditableField('House/Unit/Building No.', _homeHouseController, hint: 'House/Unit'),
            _buildEditableField('Street Name', _homeStreetController, hint: 'Street Name'),
            _buildEditableField('Barangay/Subdivision', _homeBarangayController, hint: 'Barangay Name'),
            _buildEditableField('Town (Optional)', _homeTownController, hint: 'Town Name', validator: (val) { return null; }),
            _buildEditableField('ZIP Code', _homeZipController, hint: '1000', keyboardType: TextInputType.number, validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
              if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
              return null;
            }),
            _buildEditableField('City/Municipality', _homeCityController, hint: 'City'),
            _buildEditableField('Country', _homeCountryController, hint: 'Philippines', isReadOnly: true),
          ]),
        ],
      );
    } else if (cat == 'STUDENT') {
      return Column(
        children: [
          _buildAddressCard('School Address', [
            // School Address children replacement
            // School Address
_buildEditableField('Full School Name', _schoolNameController, hint: 'Full School Name'),
_buildEditableField('Street Name', _schoolStreetController, hint: 'Street Name'),

Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: DropdownButtonFormField<String>(
    value: (_schoolTownController.text.isNotEmpty && _towns.contains(_schoolTownController.text))
        ? _schoolTownController.text
        : (_schoolTownController.text.isNotEmpty ? _schoolTownController.text : null),
    items: [
      ..._towns.map((t) => DropdownMenuItem(value: t, child: Text(t))),
      if (_schoolTownController.text.isNotEmpty && !_towns.contains(_schoolTownController.text))
        DropdownMenuItem(value: _schoolTownController.text, child: Text(_schoolTownController.text)),
    ],
    onChanged: (val) {
      setState(() {
        _schoolTownController.text = val ?? '';
        _schoolBarangayController.text = '';
        final zip = _getFirstZipCodeForTown(_schoolTownController.text);
        if (zip != null) _schoolZipController.text = zip;
        _markFormDirty();
      });
    },
    decoration: InputDecoration(
      labelText: 'Town',
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    ),
    validator: (val) {
      if ((_schoolTownController.text ?? '').trim().isEmpty && (val == null || val.trim().isEmpty)) return 'Select town';
      return null;
    },
  ),
),

const SizedBox(height: 12),

Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: DropdownButtonFormField<String>(
    value: _getBarangaysForTown(_schoolTownController.text).contains(_schoolBarangayController.text) ? _schoolBarangayController.text : null,
    items: _getBarangaysForTown(_schoolTownController.text).map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
    onChanged: _getBarangaysForTown(_schoolTownController.text).isEmpty
        ? null
        : (val) {
            setState(() {
              _schoolBarangayController.text = val ?? '';
              _markFormDirty();
            });
          },
    decoration: InputDecoration(
      labelText: "Barangay/Subdivision",
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    validator: (val) {
      if (_getBarangaysForTown(_schoolTownController.text).isNotEmpty) {
        if (val == null || val.trim().isEmpty) return 'Enter school barangay/subdivision';
      } else {
        if (_schoolBarangayController.text.trim().isEmpty) return 'Enter school barangay/subdivision';
      }
      return null;
    },
  ),
),

const SizedBox(height: 12),

Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: DropdownButtonFormField<String>(
    value: _getZipCodesForTown(_schoolTownController.text).contains(_schoolZipController.text) ? _schoolZipController.text : _getFirstZipCodeForTown(_schoolTownController.text),
    items: _getZipCodesForTown(_schoolTownController.text).map((zip) => DropdownMenuItem(value: zip, child: Text(zip))).toList(),
    onChanged: _getZipCodesForTown(_schoolTownController.text).isEmpty
        ? null
        : (val) {
            setState(() {
              _schoolZipController.text = val ?? '';
              _markFormDirty();
            });
          },
    decoration: InputDecoration(
      labelText: "ZIP Code",
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    validator: (val) {
      if (val == null || val.trim().isEmpty) return 'ZIP code is required';
      return null;
    },
  ),
),

_buildEditableField('City/Municipality', _schoolCityController, hint: 'City', isReadOnly: false),
_buildEditableField('Country', _schoolCountryController, hint: 'Philippines', isReadOnly: true),

          ]),
          const SizedBox(height: 16),
          _buildAddressCard('Home Address', [
            _buildEditableField('House/Unit/Building No.', _homeHouseController, hint: 'House/Unit'),
            _buildEditableField('Street Name', _homeStreetController, hint: 'Street Name'),
            _buildEditableField('Barangay/Subdivision', _homeBarangayController, hint: 'Barangay Name'),
            _buildEditableField('Town (Optional)', _homeTownController, hint: 'Town Name', validator: (val) {return null;}),
            _buildEditableField('ZIP Code', _homeZipController, hint: '1000', keyboardType: TextInputType.number, validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
              if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
              return null;
            }),
            _buildEditableField('City/Municipality', _homeCityController, hint: 'City'),
            _buildEditableField('Country', _homeCountryController, hint: 'Philippines', isReadOnly: true),
          ]),
        ],
      );
    } else {

      // ===== Replace resident branch with this chunk =====
final List<DropdownMenuItem<String>> residentTownItems = _towns
    .map((town) => DropdownMenuItem(value: town, child: Text(town)))
    .toList();

final currentResTown = _resTownController.text.trim();
if (currentResTown.isNotEmpty && !_towns.contains(currentResTown)) {
  residentTownItems.add(DropdownMenuItem(value: currentResTown, child: Text(currentResTown)));
}

return _buildAddressCard('Address', [
  _buildEditableField('House/Unit/Building No.', _resHouseController, hint: 'House/Unit'),
  _buildEditableField('Street Name', _resStreetController, hint: 'Street Name'),

Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: DropdownButtonFormField<String>(
    // effective current town (keep DB-only towns visible)
    value: _resTownController.text.isNotEmpty ? _resTownController.text : null,
    items: [
      ..._towns.map((t) => DropdownMenuItem(value: t, child: Text(t))),
      if (_resTownController.text.isNotEmpty && !_towns.contains(_resTownController.text))
        DropdownMenuItem(value: _resTownController.text, child: Text(_resTownController.text)),
    ],
    onChanged: (val) {
      setState(() {
        _resTownController.text = val ?? '';
        // when town changes: clear barangay & auto-set ZIP
        _resBarangayController.text = '';
        final zip = _getFirstZipCodeForTown(_resTownController.text);
        if (zip != null) _resZipController.text = zip;
        _markFormDirty();
      });
    },
    decoration: InputDecoration(
      labelText: 'Town',
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    ),
    validator: (val) {
      if (_resTownController.text.trim().isEmpty && (val == null || val.trim().isEmpty)) return 'Select town';
      return null;
    },
  ),
),

  const SizedBox(height: 12),

  // Barangay (dependent on effective town)
  Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      value: _getBarangaysForTown(_resTownController.text)
          .contains(_resBarangayController.text) ? _resBarangayController.text : null,
      items: _getBarangaysForTown(_resTownController.text)
          .map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
      onChanged: _getBarangaysForTown(_resTownController.text).isEmpty
          ? null
          : (val) {
              setState(() {
                _resBarangayController.text = val ?? '';
                _markFormDirty();
              });
            },
      decoration: InputDecoration(
        labelText: "Barangay/Subdivision",
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  ),

  const SizedBox(height: 12),

  Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      value: _getZipCodesForTown((_resTownController.text != 'Other') ? _resTownController.text : (_resTownManualController.text.isNotEmpty ? _resTownManualController.text : null))
          .contains(_resZipController.text) ? _resZipController.text : (_getFirstZipCodeForTown((_resTownController.text != 'Other') ? _resTownController.text : (_resTownManualController.text.isNotEmpty ? _resTownManualController.text : null))),
      items: _getZipCodesForTown((_resTownController.text != 'Other') ? _resTownController.text : (_resTownManualController.text.isNotEmpty ? _resTownManualController.text : null))
          .map((zip) => DropdownMenuItem(value: zip, child: Text(zip))).toList(),
      onChanged: _getZipCodesForTown((_resTownController.text != 'Other') ? _resTownController.text : (_resTownManualController.text.isNotEmpty ? _resTownManualController.text : null)).isEmpty
          ? null
          : (val) {
              setState(() {
                _resZipController.text = val ?? '';
              });
            },
      decoration: InputDecoration(
        labelText: "ZIP Code",
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'ZIP code is required';
        return null;
      },
    ),
  ),

  _buildEditableField('City/Municipality', _resCityController, hint: 'Manila', isReadOnly: true),
  _buildEditableField('Country', _resCountryController, hint: 'Philippines', isReadOnly: true),
  ]);
  }
  }

    Widget _buildTownDropdown(TextEditingController mainController, TextEditingController manualController, String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      value: mainController.text.isNotEmpty ? mainController.text : null,
      items: _towns.map((town) => DropdownMenuItem(value: town, child: Text(town))).toList(),
      onChanged: (val) {
        setState(() {
          mainController.text = val ?? '';
          _markFormDirty();
        });
      },
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    ),
  );
}

  Widget _buildIdUploadSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('ID Upload (optional)'),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _pickImage(ImageSource.gallery, false),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
              child: Stack(
                children: [
                  if (_idImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _idImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => _buildInvalidImagePlaceholder(),
                      ),
                    )
                  else if (_idImageBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _idImageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => _buildInvalidImagePlaceholder(),
                      ),
                    )
                  else if (_idImageUrl != null && _idImageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _idImageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) =>
                            loadingProgress == null ? child : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (context, error, stackTrace) => _buildInvalidImagePlaceholder(),
                      ),
                    )
                  else
                    // Default placeholder when user has not uploaded anything yet
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Tap to upload ID', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),

                  // Remove button
                  if (_idImage != null || _idImageBytes != null || (_idImageUrl != null && _idImageUrl!.isNotEmpty && !_removeIdImage))
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red, size: 18),
                          onPressed: () async {
                            await deleteProfileOrId(isProfile: false);
                          },
                        ),
                      ),
                    ),

                  // Upload progress
                  if (_idUploadProgress != null)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 36,
                                width: 36,
                                child: CircularProgressIndicator(
                                  value: _idUploadProgress,
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${((_idUploadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Upload a valid government-issued ID.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildInvalidImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image, size: 36, color: Colors.grey.shade500),
          const SizedBox(height: 6),
          Text('Invalid image', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
  

  Widget _buildHealthInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Health Information (optional)'),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: _bloodTypeController,
              decoration: InputDecoration(
                labelText: 'Blood Type',
                hintText: 'O+',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final validTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
                  if (!validTypes.contains(value.toUpperCase())) {
                    return 'Invalid blood type';
                  }
                }
                return null;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: _heightController,
              decoration: InputDecoration(
                labelText: 'Height',
                hintText: '170 cm',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              inputFormatters: [UnitFormatter("cm")],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!value.toLowerCase().endsWith('cm')) {
                    return 'Height must end with cm';
                  }
                }
                return null;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: 'Weight',
                hintText: '65 kg',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              inputFormatters: [UnitFormatter("kg")],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!value.toLowerCase().endsWith('kg')) {
                    return 'Weight must end with kg';
                  }
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(Color backgroundColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }

 Widget _buildEditableField(
  String label,
  TextEditingController controller, {
  String? hint,
  TextInputType keyboardType = TextInputType.text,
  bool isDateField = false,
  bool isReadOnly = false,
  String? Function(String?)? validator,
}) {
  // fields we want to require and show red error text when empty
  const Set<String> _requiredLabels = {
    'First Name',
    'Last Name',
    'Phone Number',
    'Date of Birth',
    // address-related required labels
    'House/Unit/Building No.',
    'Street Name',
    'Barangay/Subdivision',
    'Street/Building No.',
    'City/Municipality',
    'Full School Name',
  };

 return Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextFormField(
    controller: controller,
    autovalidateMode: _autoValidateMode, // ✅ add this line
    keyboardType: keyboardType,
    readOnly: isDateField || isReadOnly,

    onChanged: (val) {
      // ✅ clear field-specific errors when user types
      if (_fieldErrors.containsKey(controller)) {
        setState(() {
          _fieldErrors.remove(controller);
        });
      }

      // ✅ switch autovalidation mode back to user interaction
      if (_autoValidateMode == AutovalidateMode.always) {
        setState(() {
          _autoValidateMode = AutovalidateMode.onUserInteraction;
        });
      }

      _markFormDirty(); // keep your existing logic
    },

    inputFormatters: label == 'Phone Number'
        ? [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ]
        : (keyboardType == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : []),

    onTap: isDateField
        ? () async {
            FocusScope.of(context).requestFocus(FocusNode());
            await _selectDate(context);
          }
        : null,

    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      suffixIcon:
          isDateField ? const Icon(Icons.calendar_today, size: 20) : null,

      // ✅ show controller-based error under the correct field
      errorText: _fieldErrors[controller],
    ),

    validator: (value) {
      final text = value?.trim() ?? '';

      // (1) Custom validator first
      if (validator != null) {
        final result = validator(value);
        if (result != null) return result;
      }

      // (2) Required fields
      if (_requiredLabels.contains(label) && text.isEmpty) {
        return 'Please enter $label';
      }

      // (3) Phone field validation
      if (label == 'Phone Number' && text.isNotEmpty) {
        final normalized = text.replaceAll(RegExp(r'[^0-9]'), '');
        final phoneRegex = RegExp(r'^0\d{10}$');
        if (!phoneRegex.hasMatch(normalized)) {
          return 'Enter a valid 11-digit number starting with 0';
        }
      }

      // (4) DOB validation
      if (isDateField && text.isNotEmpty) {
        try {
          final parts = text.split('/');
          if (parts.length != 3) throw FormatException();
          final month = int.parse(parts[0]);
          final day = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          final dob = DateTime(year, month, day);
          final now = DateTime.now();
          int age = now.year - dob.year;
          if (now.month < dob.month ||
              (now.month == dob.month && now.day < dob.day)) {
            age--;
          }
          if (age < 8) return 'Age must be at least 8 years';
          if (age > 95) return 'Age must be less than 95 years';
        } catch (_) {
          return 'Invalid date format (MM/DD/YYYY)';
        }
      }

      return null;
    },
  ),
);
}

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF28588B);
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        if (await _confirmUnsavedChanges()) {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Edit Profile',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (await _confirmUnsavedChanges()) Navigator.pop(context, true);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidateMode, // <-- add this
            child: ListView(
              children: [
                _buildProfileImageSection(),
                const SizedBox(height: 20),
                _buildPersonalInfoSection(),
                const SizedBox(height: 20),
                _buildAddressSection(),
                const SizedBox(height: 20),
                _buildIdUploadSection(),
                const SizedBox(height: 20),
                _buildHealthInfoSection(),
                const SizedBox(height: 24),
                _buildSaveButton(primaryColor),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
