import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'verify_info_screen.dart';
import 'dart:math';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  
  final SupabaseClient supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;

  // Resident address
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _barangayController = TextEditingController();
  final TextEditingController _residentTownController = TextEditingController();
  String? _selectedTown;
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _cityController =
      TextEditingController(text: "Manila City");
  final TextEditingController _countryController =
      TextEditingController(text: "Philippines");

  // Work address (Employee)
  final TextEditingController _workStreetController =
      TextEditingController();
  final TextEditingController _workBarangayController =
      TextEditingController();
  final TextEditingController _workTownController =
      TextEditingController();
  String? _selectedWorkTown;
  final TextEditingController _workZipController = TextEditingController();
  final TextEditingController _workCityController =
      TextEditingController(text: "Manila City");
  final TextEditingController _workCountryController =
      TextEditingController(text: "Philippines");

  // Home address (for Employee and Student)
  final TextEditingController _homeHouseController = TextEditingController();
  final TextEditingController _homeStreetController = TextEditingController();
  final TextEditingController _homeBarangayController =
      TextEditingController();
  final TextEditingController _homeTownController =
      TextEditingController();
  String? _selectedHomeTown;
  final TextEditingController _homeZipController = TextEditingController();
  final TextEditingController _homeCityController =
      TextEditingController();
  final TextEditingController _homeCountryController =
      TextEditingController(text: "Philippines");

  // Student school address
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _schoolStreetController =
      TextEditingController();
  final TextEditingController _schoolBarangayController =
      TextEditingController();
  final TextEditingController _schoolTownController =
      TextEditingController();
  String? _selectedSchoolTown;
  final TextEditingController _schoolZipController = TextEditingController();
  final TextEditingController _schoolCityController =
      TextEditingController(text: "Manila City");
  final TextEditingController _schoolCountryController =
      TextEditingController(text: "Philippines");

  bool _hasMiddleName = false;
  String _selectedCategory = "RESIDENT";

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
  "Tondo": ["1012", "1013"],  // Tondo now has 2 ZIP codes
  "Binondo": ["1006"],
  "Quiapo": ["1001"],
  "Intramuros": ["1002"],
  "Ermita": ["1000"],
  "Malate": ["1004"],
  "Paco": ["1007"],
  "Pandacan": ["1011"],
  "Port Area": ["1018", "1019"],  // Port Area also has 2 ZIP codes
  "San Nicolas": ["1010"],
  "Santa Ana": ["1009"],
  "Santa Cruz": ["1003"],
  "Santa Mesa": ["1016"],
  "San Miguel": ["1005"],
  "San Andres Bukid": ["1017"],
  "Sampaloc": ["1008"],
};

  bool _showWorkTownManual = false;
  bool _showSchoolTownManual = false;

  // Update the method to get ZIP codes for a town
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: const Color(0xFF336699),
      end: const Color(0xFF5588CC),
    ).animate(_controller);

    // Initialize title case listeners
    void addTitleListener(TextEditingController c) {
      c.addListener(() {
        final text = c.text;
        final transformed = _toTitleCase(text);
        if (text != transformed) {
          final sel = c.selection;
          c.value = TextEditingValue(
            text: transformed,
            selection: TextSelection(
              baseOffset: min(max(sel.baseOffset, 0), transformed.length),
              extentOffset: min(max(sel.extentOffset, 0), transformed.length),
            ),
          );
        }
      });
    }

    addTitleListener(_lastNameController);
    addTitleListener(_firstNameController);
    addTitleListener(_middleNameController);
    addTitleListener(_houseController);
    addTitleListener(_streetController);
    addTitleListener(_barangayController);
    addTitleListener(_residentTownController);
    addTitleListener(_cityController);
    addTitleListener(_workStreetController);
    addTitleListener(_workBarangayController);
    addTitleListener(_workTownController);
    addTitleListener(_workCityController);
    addTitleListener(_homeHouseController);
    addTitleListener(_homeStreetController);
    addTitleListener(_homeBarangayController);
    addTitleListener(_homeTownController);
    addTitleListener(_homeCityController);
    addTitleListener(_schoolNameController);
    addTitleListener(_schoolStreetController);
    addTitleListener(_schoolBarangayController);
    addTitleListener(_schoolTownController);
    addTitleListener(_schoolCityController);

    // parse CSV into map
    _barangayMap = {};
    final lines = _barangayCsv
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isNotEmpty && lines.first.toLowerCase().startsWith('district')) {
      lines.removeAt(0); // drop header
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
    // sort barangays for consistent order
    for (final k in _barangayMap.keys) {
      _barangayMap[k]!.sort((a, b) => a.compareTo(b));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _barangayController.dispose();
    _zipController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _residentTownController.dispose();
    _workStreetController.dispose();
    _workBarangayController.dispose();
    _workTownController.dispose();
    _workZipController.dispose();
    _workCityController.dispose();
    _workCountryController.dispose();
    _homeHouseController.dispose();
    _homeStreetController.dispose();
    _homeBarangayController.dispose();
    _homeTownController.dispose();
    _homeZipController.dispose();
    _homeCityController.dispose();
    _homeCountryController.dispose();
    _schoolNameController.dispose();
    _schoolStreetController.dispose();
    _schoolBarangayController.dispose();
    _schoolTownController.dispose();
    _schoolZipController.dispose();
    _schoolCityController.dispose();
    _schoolCountryController.dispose();
    super.dispose();
  }

  String _toTitleCase(String input) {
    if (input.trim().isEmpty) return input;

    // Split on whitespace to preserve words
    final parts = input.split(RegExp(r'\s+'));

    final transformed = parts.map((word) {
      if (word.isEmpty) return '';

      // Handle hyphenated subwords
      final hyphenParts = word.split('-');
      final hyphenTransformed = hyphenParts.map((sub) {
        if (sub.isEmpty) return '';
        final first = sub.substring(0, 1).toUpperCase();
        final rest = sub.length > 1 ? sub.substring(1).toLowerCase() : '';
        return first + rest;
      }).join('-');

      return hyphenTransformed;
    }).join(' ');

    return transformed;
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(
      r'^[\w\.-]+@[A-Za-z0-9.-]+\.(edu\.ph|org\.ph|edu|com|net|org|gov|ph)$',
      caseSensitive: false,
    );
    return regex.hasMatch(email);
  }

  void _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    final phoneInput = _phoneController.text.trim();

    // Normalize phone number to match Supabase RPC logic
    String normalizePhone(String input) {
      String digits = input.replaceAll(RegExp(r'\D'), '');

      if (digits.startsWith('09')) {
        digits = '63${digits.substring(1)}';
      } else if (digits.startsWith('9')) {
        digits = '63$digits';
      } else if (digits.startsWith('0')) {
        digits = '63${digits.substring(1)}';
      } else if (digits.startsWith('63')) {
        // already normalized
      }

      return digits; // returns "639XXXXXXXXX"
    }

    final normalizedPhone = normalizePhone(phoneInput);

    bool duplicateEmail = false;
    bool duplicatePhone = false;

    try {
      // Check duplicates via Supabase RPC
      final rpcResult = await supabase.rpc(
        'check_user_exists',
        params: {'p_email': email, 'p_phone': normalizedPhone},
      );

      if (rpcResult != null && rpcResult is Map<String, dynamic>) {
        duplicateEmail =
            (rpcResult['auth_email'] == true) || (rpcResult['app_email'] == true);
        duplicatePhone = (rpcResult['app_phone'] == true);
      }
    } catch (e) {
      debugPrint('RPC duplicate check failed: $e');
    }

    // Stop registration if duplicate found
    if (duplicateEmail || duplicatePhone) {
      String message = '';
      if (duplicateEmail && duplicatePhone) {
        message =
            'This email and phone number are already registered. Please use different credentials.';
      } else if (duplicateEmail) {
        message = 'This email is already registered. Please use a different one.';
      } else if (duplicatePhone) {
        message =
            'This phone number is already registered. Please use a different one.';
      }

      _showErrorDialog(message);
      return; // Prevent navigation
    }

    // Continue only if no duplicates
    final residentAddress = _buildResidentAddress();
    final workAddress = _buildWorkAddress();
    final homeAddress = _buildHomeAddress();
    final schoolAddress = _buildSchoolAddress();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerifyInfoScreen(
          lastName: _lastNameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          middleName: _hasMiddleName ? _middleNameController.text.trim() : "",
          email: email,
          phone: phoneInput,
          password: _passwordController.text,
          userCategory: _selectedCategory,
          residentAddress:
              _selectedCategory == "RESIDENT" ? residentAddress : null,
          workAddress: _selectedCategory == "EMPLOYEE" ? workAddress : null,
          homeAddress:
              (_selectedCategory == "EMPLOYEE" || _selectedCategory == "STUDENT")
                  ? homeAddress
                  : null,
          schoolAddress:
              _selectedCategory == "STUDENT" ? schoolAddress : null,
          onConfirm: () {
            _createAccount(
              residentAddress: residentAddress,
              workAddress: workAddress,
              homeAddress: homeAddress,
              schoolAddress: schoolAddress,
            );
          },
          onEdit: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _createAccount({
    required Map<String, dynamic>? residentAddress,
    required Map<String, dynamic>? workAddress,
    required Map<String, dynamic>? homeAddress,
    required Map<String, dynamic>? schoolAddress,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();
      final phoneInput = _phoneController.text.trim();

      // Normalize phone number for duplicate checking
      String normalizePhone(String input) {
        String digits = input.replaceAll(RegExp(r'\D'), '');

        if (digits.startsWith('09')) {
          digits = '63${digits.substring(1)}';
        } else if (digits.startsWith('9')) {
          digits = '63$digits';
        } else if (digits.startsWith('0')) {
          digits = '63${digits.substring(1)}';
        } else if (digits.startsWith('63')) {
          // already normalized
        }

        return digits;
      }

      final normalizedPhone = normalizePhone(phoneInput);
      bool duplicateEmail = false;
      bool duplicatePhone = false;

      try {
        // Use the same RPC
        final rpcResult = await supabase.rpc(
          'check_user_exists',
          params: {'p_email': email, 'p_phone': normalizedPhone},
        );

        if (rpcResult != null && rpcResult is Map<String, dynamic>) {
          duplicateEmail =
              (rpcResult['auth_email'] == true) || (rpcResult['app_email'] == true);
          duplicatePhone = (rpcResult['app_phone'] == true);
        }
      } catch (rpcError) {
        debugPrint('check_user_exists RPC failed: $rpcError');
      }

      // Stop if duplicates exist
      if (duplicateEmail || duplicatePhone) {
        String message = '';
        if (duplicateEmail && duplicatePhone) {
          message =
              'This email and phone number are already registered. Please use different credentials.';
        } else if (duplicateEmail) {
          message = 'This email is already registered. Please use a different one.';
        } else if (duplicatePhone) {
          message =
              'This phone number is already registered. Please use a different one.';
        }

        setState(() => _errorMessage = message);
        _showErrorDialog(message);
        return;
      }

      // Proceed with account creation
      final AuthResponse authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'type': 'app',
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'middle_name': _hasMiddleName ? _middleNameController.text.trim() : null,
          'phone': '+$normalizedPhone',
          'user_category': _selectedCategory,
          'resident_address': _selectedCategory == "RESIDENT" ? residentAddress : null,
          'work_address': _selectedCategory == "EMPLOYEE" ? workAddress : null,
          'home_address': (_selectedCategory == "EMPLOYEE" || _selectedCategory == "STUDENT")
              ? homeAddress
              : null,
          'school_address': _selectedCategory == "STUDENT" ? schoolAddress : null,
        },
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user account in Auth');
      }

      debugPrint('Auth user created: ${authResponse.user!.id}');
      _showSuccessDialog();
    } on AuthException catch (e) {
      final errorMsg = _getAuthErrorMessage(e);
      setState(() => _errorMessage = errorMsg);
      _showErrorDialog(errorMsg);
    } catch (e, stack) {
      debugPrint('Unexpected error: $e');
      debugPrint('Stack trace: $stack');
      _showErrorDialog('Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Check Your Email',
          style: TextStyle(
            color: Color(0xFF336699),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registration successful!',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We\'ve sent a verification email to:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _emailController.text.trim(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please check your inbox and click the verification link to activate your account.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF336699),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _removeNullValues(Map<String, dynamic> map) {
    return Map.from(map)..removeWhere((key, value) => value == null);
  }

  String _getAuthErrorMessage(AuthException e) {
    final message = e.message.toLowerCase();
    
    if (message.contains('already registered') || message.contains('user exists')) {
      return 'This email is already registered. Please try logging in or use a different email.';
    } else if (message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    } else if (message.contains('password') && message.contains('weak')) {
      return 'Password is too weak. Use at least 6 characters with letters, numbers, and special characters.';
    } else if (message.contains('rate limit') || message.contains('too many requests')) {
      return 'Too many attempts. Please try again in a few minutes.';
    } else {
      return 'Registration failed: ${e.message}';
    }
  }

  Map<String, dynamic> _buildResidentAddress() {
    return {
      'house': _houseController.text.trim(),
      'street': _streetController.text.trim(),
      'barangay': _barangayController.text.trim(),
      'town': _residentTownController.text.trim(),
      'zip': _zipController.text.trim(),
      'city': _cityController.text.trim(),
      'country': _countryController.text.trim(),
    };
  }

  Map<String, dynamic> _buildWorkAddress() {
    return {
      'street': _workStreetController.text.trim(),
      'barangay': _workBarangayController.text.trim(),
      'town': (_selectedWorkTown != null && _selectedWorkTown != 'Other')
          ? _selectedWorkTown
          : _workTownController.text.trim(),
      'zip': _workZipController.text.trim(),
      'city': _workCityController.text.trim(),
      'country': _workCountryController.text.trim(),
    };
  }

  Map<String, dynamic> _buildHomeAddress() {
    return {
      'house': _homeHouseController.text.trim(),
      'street': _homeStreetController.text.trim(),
      'barangay': _homeBarangayController.text.trim(),
      'town': _selectedHomeTown ?? _homeTownController.text.trim(),
      'zip': _homeZipController.text.trim(),
      'city': _homeCityController.text.trim(),
      'country': _homeCountryController.text.trim(),
    };
  }

  Map<String, dynamic> _buildSchoolAddress() {
    return {
      'school_name': _schoolNameController.text.trim(),
      'street': _schoolStreetController.text.trim(),
      'barangay': _schoolBarangayController.text.trim(),
      'town': (_selectedSchoolTown != null && _selectedSchoolTown != 'Other')
          ? _selectedSchoolTown
          : _schoolTownController.text.trim(),
      'zip': _schoolZipController.text.trim(),
      'city': _schoolCityController.text.trim(),
      'country': _schoolCountryController.text.trim(),
    };
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade600,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Registration Error',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF336699),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //Text Field
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            icon,
            color: const Color(0xFF336699),
            size: 20,
          ),
        ),
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF336699),
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF336699), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  //Phone Field
  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Please enter your contact number';
        }
        final digitsOnly = val.trim();
        if (!RegExp(r'^[9]\d{9}$').hasMatch(digitsOnly)) {
          return 'Enter a valid 10-digit number starting with 9';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Phone Number',
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF336699),
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF336699), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/ph_flag.png',
                width: 20,
                height: 20,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.flag,
                    color: Color(0xFF336699),
                    size: 20,
                  );
                },
              ),
              const SizedBox(width: 8),
              const Text(
                '+63',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF336699),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Password Field
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.lock,
            color: const Color(0xFF336699),
            size: 20,
          ),
        ),
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF336699),
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF336699), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey.shade600,
            size: 20,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }

  //Dropdown Field
  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String label,
    required String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF336699),
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF336699), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: const Icon(
            Icons.category,
            color: Color(0xFF336699),
            size: 20,
          ),
        ),
      ),
      validator: validator,
      dropdownColor: Colors.white,
      icon: const Icon(
        Icons.arrow_drop_down,
        color: Color(0xFF336699),
      ),
    );
  }

  //Town Dropdown Field
  Widget _buildTownDropdownField({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String label,
    required String? Function(String?)? validator,
    bool showOtherOption = false,
  }) {
    final dropdownItems = showOtherOption 
        ? [...items, 'Other']
        : items;

    return DropdownButtonFormField<String>(
      value: value,
      items: dropdownItems.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF336699),
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF336699), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: const Icon(
            Icons.location_city,
            color: Color(0xFF336699),
            size: 20,
          ),
        ),
      ),
      validator: validator,
      dropdownColor: Colors.white,
      icon: const Icon(
        Icons.arrow_drop_down,
        color: Color(0xFF336699),
      ),
    );
  }

  // ZIP Code Dropdown Field
Widget _buildZipCodeDropdownField({
  required String? selectedTown,
  required TextEditingController zipController,
  required String label,
  required String? Function(String?)? validator,
}) {
  final List<String> zipOptions = _getZipCodesForTown(selectedTown);

  return DropdownButtonFormField<String>(
    value: zipOptions.isNotEmpty && zipOptions.contains(zipController.text) 
        ? zipController.text 
        : (zipOptions.isNotEmpty ? zipOptions.first : null),
    items: zipOptions.map((zip) {
      return DropdownMenuItem(
        value: zip,
        child: Text(
          zip,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }).toList(),
    onChanged: zipOptions.isNotEmpty ? (val) {
      setState(() {
        zipController.text = val ?? '';
      });
    } : null,
    style: const TextStyle(
      color: Colors.black87,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF336699),
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF336699), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      errorStyle: const TextStyle(
        color: Colors.red,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: const Icon(
          Icons.local_post_office,
          color: Color(0xFF336699),
          size: 20,
        ),
      ),
    ),
    validator: validator,
    dropdownColor: Colors.white,
    icon: const Icon(
      Icons.arrow_drop_down,
      color: Color(0xFF336699),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return Container(
            color: _colorAnimation.value,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const Text(
                              "Create an Account",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(30),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      offset: Offset(0, -3),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (_errorMessage != null)
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.red.shade200),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                color: Colors.red.shade600,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  _errorMessage!,
                                                  style: TextStyle(
                                                    color: Colors.red.shade700,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      const SizedBox(height: 16),

                                      // CATEGORY dropdown
                                      _buildDropdownField(
                                        value: _selectedCategory,
                                        items: const ["RESIDENT", "EMPLOYEE", "STUDENT"],
                                        onChanged: (val) => setState(() { _selectedCategory = val ?? "RESIDENT"; }),
                                        label: "Category",
                                        validator: (val) => val == null ? 'Please select a category' : null,
                                      ),

                                      const SizedBox(height: 16),

                                      _buildTextField(
                                        _lastNameController,
                                        'Last Name',
                                        Icons.person,
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) {
                                            return 'Enter last name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      _buildTextField(
                                        _firstNameController,
                                        'First Name',
                                        Icons.person_outline,
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) {
                                            return 'Enter first name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),

                                      // Optional middle name checkbox
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: _hasMiddleName,
                                              onChanged: (val) =>
                                                  setState(() => _hasMiddleName = val!),
                                              activeColor: const Color(0xFF336699),
                                            ),
                                            const Text(
                                              "I have a middle name",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_hasMiddleName)
                                        _buildTextField(
                                          _middleNameController,
                                          'Middle Name',
                                          Icons.person_outline,
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) {
                                              return 'Enter middle name';
                                            }
                                            final pattern = RegExp(r"^[A-Za-z\s\.'-]+$");
                                            if (!pattern.hasMatch(val.trim())) {
                                              return 'Enter a valid middle name';
                                            }
                                            return null;
                                          },
                                        ),
                                      if (_hasMiddleName) const SizedBox(height: 12),

                                      _buildTextField(
                                        _emailController,
                                        'Email',
                                        Icons.email,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: (val) {
                                          if (val == null || val.isEmpty || !_isValidEmail(val)) {
                                            return 'Enter valid email';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),

                                      _buildPhoneField(),
                                      const SizedBox(height: 12),

                                      _buildPasswordField(
                                        controller: _passwordController,
                                        label: 'Password',
                                        isVisible: _isPasswordVisible,
                                        onToggleVisibility: () => setState(() {
                                          _isPasswordVisible = !_isPasswordVisible;
                                        }),
                                        validator: (val) {
                                          if (val == null || val.isEmpty) {
                                            return 'Password is required';
                                          }
                                          if (val.length < 6) {
                                            return 'At least 6 characters';
                                          }
                                          final regex = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).+$');
                                          if (!regex.hasMatch(val)) {
                                            return 'Must Contains 1 Uppercase letters, numbers, and special characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      _buildPasswordField(
                                        controller: _confirmPasswordController,
                                        label: 'Confirm Password',
                                        isVisible: _isConfirmPasswordVisible,
                                        onToggleVisibility: () => setState(() {
                                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                        }),
                                        validator: (val) {
                                          if (val == null || val.isEmpty) {
                                            return 'Confirm Password is required';
                                          }
                                          if (val != _passwordController.text) {
                                            return 'Passwords don\'t match';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 24),

                                      // RESIDENT Address
                                      if (_selectedCategory == "RESIDENT") ...[
                                        const Text(
                                          "Address", 
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          )
                                        ),
                                        const SizedBox(height: 12),

                                        _buildTextField(_houseController, "House/Unit/Building No.", Icons.home,
                                            validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter house/unit/building no.';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_streetController, "Street Name", Icons.location_on,
                                            validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter street name';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),

                                        // Town first (Resident)
                                        _buildTownDropdownField(
                                          value: _selectedTown ?? (_residentTownController.text.isNotEmpty ? _residentTownController.text : null),
                                          items: _towns,
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedTown = val;
                                              if (val != null) _residentTownController.text = val;
                                              // clear barangay when town changes
                                              _barangayController.text = '';
                                              // auto-set ZIP code based on town
                                              final zip = _getFirstZipCodeForTown(val);
                                              if (zip != null) {
                                                _zipController.text = zip;
                                              }
                                            });
                                          },
                                          label: "Town",
                                          validator: (val) {
                                            final townVal = _selectedTown ?? _residentTownController.text;
                                            if (townVal == null || townVal.trim().isEmpty) return 'Select town';
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),

                                        // Barangay (dependent on selected town)
                                        DropdownButtonFormField<String>(
                                          value: _getBarangaysForTown(_selectedTown).contains(_barangayController.text) ? _barangayController.text : null,
                                          items: _getBarangaysForTown(_selectedTown).map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                                          onChanged: _getBarangaysForTown(_selectedTown).isEmpty
                                              ? null
                                              : (val) {
                                                  setState(() {
                                                    _barangayController.text = val ?? '';
                                                  });
                                                },
                                          decoration: InputDecoration(
                                            labelText: "Barangay/Subdivision",
                                            labelStyle: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            floatingLabelStyle: const TextStyle(
                                              color: Color(0xFF336699),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(8),
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: const Icon(
                                                Icons.location_city,
                                                color: Color(0xFF336699),
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          validator: (val) {
                                            if (_getBarangaysForTown(_selectedTown).isNotEmpty) {
                                              if (val == null || val.trim().isEmpty) return 'Enter barangay/subdivision';
                                            } else {
                                              if (_barangayController.text.trim().isEmpty) return 'Enter barangay/subdivision';
                                            }
                                            return null;
                                          },
                                          dropdownColor: Colors.white,
                                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF336699)),
                                        ),

                                        const SizedBox(height: 12),

                                        // ZIP Code Dropdown for Resident
                                        _buildZipCodeDropdownField(
                                          selectedTown: _selectedTown,
                                          zipController: _zipController,
                                          label: "ZIP Code",
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) return 'ZIP code is required';
                                            return null;
                                          },
                                        ),

                                        const SizedBox(height: 12),
                                        _buildTextField(_cityController, "City/Municipality", Icons.location_city, readOnly: true, validator: (_) => null),
                                        const SizedBox(height: 12),
                                        _buildTextField(_countryController, "Country", Icons.flag, readOnly: true, validator: (_) => null),
                                        const SizedBox(height: 12),
                                      ],

                                      // EMPLOYEE Address
                                      if (_selectedCategory == "EMPLOYEE") ...[
                                        const Text(
                                          "Work Address", 
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          )
                                        ),
                                        const SizedBox(height: 12),
                                        _buildTextField(_workStreetController, "Street/Building No.", Icons.business, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter work street/building';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),

                                        // Work Town first (keeps Other)
                                        _buildTownDropdownField(
                                          value: _selectedWorkTown ?? (_workTownController.text.isNotEmpty ? _workTownController.text : null),
                                          items: _towns,
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedWorkTown = val;
                                              _showWorkTownManual = false;
                                              if (val != null) _workTownController.text = val;
                                              
                                              _workBarangayController.text = '';
                                              
                                              final zip = _getFirstZipCodeForTown(val);
                                              if (zip != null) {
                                                _workZipController.text = zip;
                                              }
                                            });
                                          },
                                          label: "Town",
                                          validator: null,
                                          showOtherOption: false,
                                        ),
                                        const SizedBox(height: 12),

                                        // Work barangay (dependent on effective work town)
                                        DropdownButtonFormField<String>(
                                          value: _getBarangaysForTown((_selectedWorkTown != null && _selectedWorkTown != 'Other') ? _selectedWorkTown : (_workTownController.text.isNotEmpty ? _workTownController.text : null))
                                                  .contains(_workBarangayController.text) ? _workBarangayController.text : null,
                                          items: _getBarangaysForTown((_selectedWorkTown != null && _selectedWorkTown != 'Other') ? _selectedWorkTown : (_workTownController.text.isNotEmpty ? _workTownController.text : null))
                                              .map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                                          onChanged: _getBarangaysForTown((_selectedWorkTown != null && _selectedWorkTown != 'Other') ? _selectedWorkTown : (_workTownController.text.isNotEmpty ? _workTownController.text : null)).isEmpty
                                              ? null
                                              : (val) {
                                                  setState(() {
                                                    _workBarangayController.text = val ?? '';
                                                  });
                                                },
                                          decoration: InputDecoration(
                                            labelText: "Barangay/Subdivision",
                                            labelStyle: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            floatingLabelStyle: const TextStyle(
                                              color: Color(0xFF336699),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(8),
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: const Icon(
                                                Icons.map,
                                                color: Color(0xFF336699),
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          validator: (val) {
                                            final workTownEffective = (_selectedWorkTown != null && _selectedWorkTown != 'Other') ? _selectedWorkTown : (_workTownController.text.isNotEmpty ? _workTownController.text : null);
                                            if (_getBarangaysForTown(workTownEffective).isNotEmpty) {
                                              if (val == null || val.trim().isEmpty) return 'Enter work barangay/subdivision';
                                            } else {
                                              if (_workBarangayController.text.trim().isEmpty) return 'Enter work barangay/subdivision';
                                            }
                                            return null;
                                          },
                                          dropdownColor: Colors.white,
                                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF336699)),
                                        ),

                                        const SizedBox(height: 12),

                                        // ZIP Code Dropdown for Work
                                        _buildZipCodeDropdownField(
                                          selectedTown: (_selectedWorkTown != null && _selectedWorkTown != 'Other') ? _selectedWorkTown : (_workTownController.text.isNotEmpty ? _workTownController.text : null),
                                          zipController: _workZipController,
                                          label: "ZIP Code",
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) return 'ZIP code is required';
                                            return null;
                                          },
                                        ),

                                        const SizedBox(height: 12),
                                        _buildTextField(_workCityController, "City/Municipality", Icons.location_city,  readOnly: true, validator: (_) => null),
                                        const SizedBox(height: 12),
                                        _buildTextField(_workCountryController, "Country", Icons.flag, readOnly: true, validator: (_) => null),
                                        const SizedBox(height: 20),

                                        const Text(
                                          "Home Address", 
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          )
                                        ),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeHouseController, "House/Unit/Building No.", Icons.home, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter house/unit/building no.';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeStreetController, "Street Name", Icons.location_on, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter street name';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeBarangayController, "Barangay/Subdivision", Icons.location_city, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter barangay/subdivision';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(
                                          _homeTownController,
                                          "Town (Optional)",
                                          Icons.location_city,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeZipController, "ZIP Code", Icons.local_post_office, keyboardType: TextInputType.number, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
                                          if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeCityController, "City/Municipality", Icons.location_city, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter city/municipality';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeCountryController, "Country", Icons.flag, readOnly: true, validator: (_) => null),
                                      ],

                                      // STUDENT Address
                                      if (_selectedCategory == "STUDENT") ...[
                                        const Text(
                                          "School Address", 
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          )
                                        ),
                                        const SizedBox(height: 12),
                                        _buildTextField(_schoolNameController, "Full School Name", Icons.school, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter full school name';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_schoolStreetController, "Street Name", Icons.location_city, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter school street/building';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),

                                        // School Town first (keeps Other)
                                        _buildTownDropdownField(
                                          value: _selectedSchoolTown ?? (_schoolTownController.text.isNotEmpty ? _schoolTownController.text : null),
                                          items: _towns,
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedSchoolTown = val;
                                              _showSchoolTownManual = false;
                                              if (val != null) _schoolTownController.text = val;
                                              
                                              _schoolBarangayController.text = '';
                                              
                                              final zip = _getFirstZipCodeForTown(val);
                                              if (zip != null) {
                                                _schoolZipController.text = zip;
                                              }
                                            });
                                          },
                                          label: "Town",
                                          validator: null,
                                          showOtherOption: false,
                                        ),
                                        const SizedBox(height: 12),

                                        // School barangay (dependent on effective school town)
                                        DropdownButtonFormField<String>(
                                          value: _getBarangaysForTown((_selectedSchoolTown != null && _selectedSchoolTown != 'Other') ? _selectedSchoolTown : (_schoolTownController.text.isNotEmpty ? _schoolTownController.text : null)).contains(_schoolBarangayController.text) ? _schoolBarangayController.text : null,
                                          items: _getBarangaysForTown((_selectedSchoolTown != null && _selectedSchoolTown != 'Other') ? _selectedSchoolTown : (_schoolTownController.text.isNotEmpty ? _schoolTownController.text : null)).map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                                          onChanged: _getBarangaysForTown((_selectedSchoolTown != null && _selectedSchoolTown != 'Other') ? _selectedSchoolTown : (_schoolTownController.text.isNotEmpty ? _schoolTownController.text : null)).isEmpty
                                              ? null
                                              : (val) {
                                                  setState(() {
                                                    _schoolBarangayController.text = val ?? '';
                                                  });
                                                },
                                          decoration: InputDecoration(
                                            labelText: "Barangay/Subdivision",
                                            labelStyle: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            floatingLabelStyle: const TextStyle(
                                              color: Color(0xFF336699),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(8),
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: const Icon(
                                                Icons.school,
                                                color: Color(0xFF336699),
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          validator: (val) {
                                            final schoolTownEffective = (_selectedSchoolTown != null && _selectedSchoolTown != 'Other') ? _selectedSchoolTown : (_schoolTownController.text.isNotEmpty ? _schoolTownController.text : null);
                                            if (_getBarangaysForTown(schoolTownEffective).isNotEmpty) {
                                              if (val == null || val.trim().isEmpty) return 'Enter school barangay/subdivision';
                                            } else {
                                              if (_schoolBarangayController.text.trim().isEmpty) return 'Enter school barangay/subdivision';
                                            }
                                            return null;
                                          },
                                          dropdownColor: Colors.white,
                                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF336699)),
                                        ),

                                        const SizedBox(height: 12),

                                        // ZIP Code Dropdown for School
                                        _buildZipCodeDropdownField(
                                          selectedTown: (_selectedSchoolTown != null && _selectedSchoolTown != 'Other') ? _selectedSchoolTown : (_schoolTownController.text.isNotEmpty ? _schoolTownController.text : null),
                                          zipController: _schoolZipController,
                                          label: "ZIP Code",
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) return 'ZIP code is required';
                                            return null;
                                          },
                                        ),

                                        const SizedBox(height: 12),
                                        _buildTextField(_schoolCityController, "City/Municipality", Icons.location_city, readOnly: true, validator: (_) => null),
                                        const SizedBox(height: 12),
                                        _buildTextField(_schoolCountryController, "Country", Icons.flag, readOnly: true, validator: (_) => null),
                                        const SizedBox(height: 20),

                                        const Text(
                                          "Home Address", 
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          )
                                        ),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeHouseController, "House/Unit/Building No.", Icons.home, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter house/unit/building no.';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeStreetController, "Street Name", Icons.location_on, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter street name';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeBarangayController, "Barangay/Subdivision", Icons.location_city, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter barangay/subdivision';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(
                                          _homeTownController,
                                          "Town (Optional)",
                                          Icons.location_city,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeZipController, "ZIP Code", Icons.local_post_office, keyboardType: TextInputType.number, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
                                          if (!RegExp(r'^\d{4}$').hasMatch(val.trim())) return 'ZIP must be 4 digits';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeCityController, "City/Municipality", Icons.location_city, validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Enter city/municipality';
                                          return null;
                                        }),
                                        const SizedBox(height: 12),
                                        _buildTextField(_homeCountryController, "Country", Icons.flag, readOnly: true, validator: (_) => null),
                                      ],

                                      const SizedBox(height: 24),
                                      ElevatedButton(
                                        onPressed:
                                            _isLoading ? null : _submitRegistration,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _colorAnimation.value,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          elevation: 2,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 24, 
                                                height: 24, 
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2, 
                                                  color: Colors.white
                                                )
                                              )
                                            : const Text(
                                                'Register', 
                                                style: TextStyle(
                                                  fontSize: 16, 
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                )
                                              ),
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
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}