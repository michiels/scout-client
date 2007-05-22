require 'test/unit'

# tests to generate plugins - processing output

# we pull output from both mac/linux systems (and win32?) where we can, and generate
# regex-style matching on their output, in order to generate values for thresholds

class PluginTest < Test::Unit::TestCase

  # def setup
  # end
  # 
  # def teardown
  # end

  def test_disk_usage
    # $ df -h
    mac_du_output = <<-DISK_USAGE_OUTPUT
Filesystem                Size   Used  Avail Capacity  Mounted on
/dev/disk0s2               93G    88G   4.3G    95%    /
devfs                      97K    97K     0B   100%    /dev
fdesc                     1.0K   1.0K     0B   100%    /dev
<volfs>                   512K   512K     0B   100%    /.vol
automount -nsl [137]        0B     0B     0B   100%    /Network
automount -fstab [141]      0B     0B     0B   100%    /automount/Servers
automount -static [141]     0B     0B     0B   100%    /automount/static
DISK_USAGE_OUTPUT

  # match and pull data here
  
  end

  def test_top
    # $ top -l 1
    mac_top_output = <<-TOP_OUTPUT
Processes:  95 total, 2 running, 93 sleeping... 301 threads            20:29:07
Load Avg:  0.39, 0.30, 0.26     CPU usage:  0.0% user, 56.2% sys, 43.8% idle
SharedLibs: num =  170, resident = 43.8M code, 5.92M data, 8.32M LinkEdit
MemRegions: num = 10355, resident =  383M + 32.1M private,  293M shared
PhysMem:   181M wired,  331M active, 1.14G inactive, 1.65G used,  362M free
VM: 15.5G +  124M   53870(0) pageins, 0(0) pageouts

  PID COMMAND      %CPU   TIME   #TH #PRTS #MREGS RPRVT  RSHRD  RSIZE  VSIZE 
 6407 top          0.0%  0:00.08   1    17    19   316K   784K   768K  26.9M 
 6287 bash         0.0%  0:00.01   1    14    18   236K  1.17M   864K  27.1M 
 6286 login        0.0%  0:00.00   1    16    40   172K   880K   612K  26.9M 
 6118 bash         0.0%  0:00.02   1    14    17   220K  1.17M   840K  27.1M 
 6117 login        0.0%  0:00.00   1    16    40   172K   880K   612K  26.9M 
 6111 ruby         0.0%  0:08.57   2    16    54  3.15M  1.63M  4.22M  31.6M 
 6100 qtimageser   0.0%  0:00.23   2    57   109  1.01M  2.83M  3.21M   338M 
 5990 bash         0.0%  0:00.03   1    14    17   236K  1.17M   832K  27.1M 
 5989 login        0.0%  0:00.00   1    16    40   172K   880K   612K  26.9M 
 5955 slpd         0.0%  0:00.09   6    30    31   252K  1.25M  1008K  30.2M 
 5953 lookupd      0.0%  0:04.52   2    34    38   488K  1.41M  1.25M  28.5M 
 5952 mdimport     0.0%  0:00.29   4    61    55  1.18M  9.79M  3.63M  40.5M 
 5951 mdimport     0.0%  0:00.14   3    60    45   912K  4.60M  3.17M  42.3M 
 3874 Colloquy     0.0%  0:46.00   6   144   335  11.1M  24.1M  19.2M   380M 
 1932 ruby         0.0%  0:40.54   2    16   156  33.6M  4.00M  35.7M  69.2M 
 1916 bash         0.0%  0:00.02   1    14    17   220K  1.17M   828K  27.1M 
 1915 login        0.0%  0:00.01   1    16    41   216K   880K   612K  26.9M 
  798 iCal         0.0%  0:34.02   8   172   618  29.1M  29.0M  42.7M   419M 
  553 AppleSpell   0.0%  0:02.32   1    46    35   732K  2.63M  2.39M  37.8M 
  464 firefox-bi   0.0% 12:20.05   8   106   533  84.5M  64.7M   129M   537M 
  463 ruby         0.0%  3:07.47   2    16   180  19.9M  5.15M  23.9M  73.2M 
  462 lighttpd     0.0%  0:01.21   1    14    58   512K  1.52M  1.13M  28.8M 
  458 ruby         0.0%  1:01.90   2    15    43  3.16M  1.59M  4.17M  31.6M 
  442 bash         0.0%  0:00.02   1    14    17   224K  1.17M   840K  27.1M 
  441 login        0.0%  0:00.00   1    16    40   172K   880K   604K  26.9M 
  432 TextMate     0.0%  1:37.50  18   175   341  18.0M  57.0M  55.0M   417M 
  430 bash         0.0%  0:00.01   1    14    18   236K  1.17M   860K  27.1M 
  429 login        0.0%  0:00.00   1    16    40   172K   880K   604K  26.9M 
  376 Terminal     0.0%  0:23.62  15   117   182  3.29M  23.6M  15.8M   379M 
  338 DashboardC   0.0%  0:01.24   3    95   154  5.25M  11.5M  8.61M   354M 
  337 DashboardC   0.0%  0:00.44   3    77   153  3.51M  13.5M  6.50M   362M 
  336 DashboardC   0.0%  0:00.40   3    93   157  3.98M  12.4M  7.34M   356M 
  335 DashboardC   0.0%  0:00.61   3    80   148  3.95M  11.6M  6.82M   353M 
  334 DashboardC   0.0%  0:00.43   3   100   153  4.19M  14.8M  7.02M   356M 
  333 DashboardC   0.0%  0:01.44   4   127   199  6.54M  22.4M  11.4M   366M 
  332 DashboardC   0.0%  0:00.62   3    93   139  3.36M  12.0M  6.38M   355M 
  331 DashboardC   0.0%  0:00.38   3    77   134  3.25M  12.1M  6.68M   355M 
  330 DashboardC   0.0%  0:00.62   3    93   151  4.90M  17.8M  8.60M   365M 
  329 DashboardC   0.0%  0:00.35   3    93   142  3.59M  11.2M  6.15M   353M 
  301 httpd        0.0%  0:00.00   1    11    96   108K  2.38M   428K  27.7M 
  284 httpd        0.0%  0:00.72   1    13    96  44.0K  2.38M  1.36M  28.2M 
  279 prl_dhcpd    0.0%  0:01.78   1    13    22  2.34M  1.31M  2.96M  29.5M 
  259 mysqld       0.0%  0:11.06  11    48    59  15.8M  3.80M  18.7M  60.7M 
  248 SystemUISe   0.0%  0:09.43   5   223   231  4.11M  16.7M  9.90M   395M 
  241 mds          0.0%  0:13.76   8    90    84  3.82M  3.21M  5.04M  43.9M 
  237 AppleFileS   0.0%  0:00.87   2    55    39  3.04M  1.89M  3.31M  33.3M 
  228 cupsd        0.0%  0:03.83   2    26    30   964K  1.36M  1.95M  27.9M 
  220 sh           0.0%  0:00.02   1    14    17   192K  1.12M   648K  27.1M 
  202 MissingSyn   0.0%  0:00.22   1    32    39   504K  2.31M  2.52M  37.1M 
  193 crashrepor   0.0%  0:00.00   1    24    18   120K   768K   212K  26.6M 
  150 Missing Sy   0.0%  0:03.23   3    90   117  1.23M  3.48M  4.04M   344M 
  149 Palm Deskt   0.0%  1:37.34   2    70   146  7.71M  28.9M  12.9M   441M 
  148 witchdaemo   0.0%  0:02.43   1    63   105  1016K  3.93M  3.23M   347M 
  147 System Eve   0.0%  0:00.92   1    60   112  1.14M  2.99M  3.32M   342M 
  146 Snapz Pro    0.0%  1:39.50   2    75   163  11.1M  33.6M  18.4M   436M 
  141 automount    0.0%  0:00.01   3    39    31   316K  1.31M  1.07M  28.7M 
  137 automount    0.0%  0:00.06   3    41    35   320K  1.33M  1.11M  29.0M 
  134 rpc.lockd    0.0%  0:00.00   1    10    18   104K   844K   196K  26.7M 
  132 UniversalA   0.0%  0:14.63   1    63   113  1.37M  4.41M  3.85M   348M 
  130 Quicksilve   0.0%  0:42.12   5   124   478  46.9M  23.8M  25.7M   421M 
  129 nmbd         0.0%  0:11.11   1    14    24   388K  1.28M  1.54M  27.8M 
  128 VirtueDesk   0.0%  1:10.12   2   102   243  5.59M  66.2M  58.1M   411M 
  127 Microsoft    0.0%  0:24.05   3   113   166  9.84M  32.6M  16.3M   468M 
  126 iCalAlarmS   0.0%  0:00.38   1    61   100  1.05M  10.6M  3.99M   344M 
  122 Microsoft    0.0%  0:02.00   2   107   126  6.17M  27.1M  10.0M   417M 
  121 iTunesHelp   0.0%  0:00.08   1    51    81   648K  3.13M  1.85M   337M 
  117 nfsiod       0.0%  0:00.00   5    30    25   108K   744K   188K  28.6M 
  114 ntpd         0.0%  0:00.06   1     8    19  72.0K  1.05M   232K  27.1M 
  101 ntpd         0.0%  0:01.57   1    11    18  60.0K  1.05M   380K  27.1M 
   85 Finder       0.0%  0:00.94   3   101   148  2.62M  21.3M  7.70M   365M 
   81 Dock         0.0%  1:11.95   4   155   199  1.74M  21.2M  10.6M   342M 
   74 pbs          0.0%  0:00.48   2    37    45   816K  9.86M  2.05M  55.4M 
   65 loginwindo   0.0%  0:16.02   4   230   153  2.14M  12.6M  5.56M   351M 
   64 ATSServer    0.0%  0:01.90   2   129   138  1.13M  17.2M  6.65M   104M 
   61 coreservic   0.0%  0:01.60   3   141   158  1.54M  31.3M  9.86M  41.5M 
   59 blued        0.0%  0:00.26   1    67    32   624K  2.04M  2.08M  37.0M 
   55 WindowServ   0.0%  9:18.34   3   443   913  10.6M   139M   142M   479M 
   49 update       0.0%  0:25.25   1    12    17   120K   744K   224K  26.6M 
   48 DirectoryS   0.0%  0:01.44   4    70    44   788K  2.16M  2.69M  30.3M 
   47 distnoted    0.0%  0:01.07   1    66    19   356K  1.14M   908K  27.0M 
   42 notifyd      0.0%  0:00.73   2    99    21   220K   812K   480K  27.2M 
   41 securityd    0.0%  0:00.39   1   162    29   696K  1.95M  2.20M  28.6M 
   40 memberd      0.0%  0:00.13   3    22    23   276K   812K   672K  27.7M 
   39 diskarbitr   0.0%  0:00.23   1   149    23   560K  1.23M  1.20M  27.2M 
   38 coreaudiod   0.0%  0:00.17   1   125    55  1.08M  1.63M  2.05M  31.1M 
   36 configd      0.0%  0:12.22   3   237    74   740K  2.49M  2.08M  29.3M 
   35 cron         0.0%  0:00.24   1    15    20   140K   788K   480K  26.9M 
   34 syslogd      0.0%  0:00.49   1    14    19   164K   800K   420K  26.6M 
   33 netinfod     0.0%  0:01.33   1    14    22   208K   864K  1.12M  26.9M 
   32 mDNSRespon   0.0%  4:05.49   3    48    26   504K  1.37M  1.26M  28.0M 
   31 KernelEven   0.0%  0:00.02   2    21    21   244K   780K   620K  27.2M 
   27 kextd        0.0%  0:01.41   2    29    23   772K  1.20M  1.14M  27.6M 
   23 dynamic_pa   0.0%  0:00.00   1    12    18  80.0K   768K   172K  26.6M 
    1 launchd      0.0%  0:00.56   3   374    21   252K   800K   560K  27.7M 
    0 kernel_tas   0.0% 11:39.67  49     2   536  5.21M     0B   105M  1.22G 
TOP_OUTPUT

  # match and pull data here
  
  end
  
  def test_tail_output
    # $ top -l 1
    mac_top_output = <<-TAIL_OUTPUT
  # $ tail -n 100 ../../tci_diagnostic/log/development.log 
  
  SQL (0.000138)   BEGIN
  Globalize::ViewTranslation Load (0.001832)   SELECT * FROM globalize_translations WHERE (tr_key = 'My Profile' AND language_id = 1819 AND pluralization_index = 1) AND ( (globalize_translations.`type` = 'ViewTranslation' ) ) LIMIT 1
  SQL (0.000102)   COMMIT
  SQL (0.000096)   BEGIN
  Globalize::ViewTranslation Load (0.000456)   SELECT * FROM globalize_translations WHERE (tr_key = 'Logout' AND language_id = 1819 AND pluralization_index = 1) AND ( (globalize_translations.`type` = 'ViewTranslation' ) ) LIMIT 1
  SQL (0.000098)   COMMIT
  User Load (0.000551)   SELECT * FROM users WHERE (users.`id` = 1 ) LIMIT 1
  User Load (0.000436)   SELECT * FROM users WHERE (users.`id` = 1 ) LIMIT 1
  User Load (0.000442)   SELECT * FROM users WHERE (users.`id` = 1 ) LIMIT 1
  User Load (0.000375)   SELECT * FROM users WHERE (users.`id` = 1 ) LIMIT 1
  User Load (0.000404)   SELECT * FROM users WHERE (users.`id` = 1 ) LIMIT 1
  User Load (0.000407)   SELECT * FROM users WHERE (users.`id` = 1 ) LIMIT 1
Rendered admin/shared/_menu (0.06836)
Rendered shared/_header (0.33578)
Rendered shared/_notices (0.00013)
Rendered admin/shared/_admin_footer (0.02299)
Rendered shared/_footer (0.02338)
Completed in 1.74339 (0 reqs/sec) | Rendering: 0.36511 (20%) | DB: 0.38264 (21%) | 200 OK [http://localhost/admin/teams]
  Globalize::Language Columns (0.000347)   SHOW FIELDS FROM globalize_languages
  Globalize::Language Load (0.000454)   SELECT * FROM globalize_languages WHERE (globalize_languages.`iso_639_1` = 'en' ) LIMIT 1
TAIL_OUTPUT

  # match and pull data here

  end

end