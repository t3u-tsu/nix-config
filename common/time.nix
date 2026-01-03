{ pkgs, ... }:

{
  # タイムゾーンを日本標準時（JST）に設定
  time.timeZone = "Asia/Tokyo";

  # 国際的な慣習に従い、ハードウェアクロックは UTC とみなす
  # (Windows とのデュアルブートでない限りこれが標準)
  services.chrony.enable = true; # より精度の高い時刻同期
}
