# 버프 표시 애드온
버프 생성/해제시 어느 버프가 생성됐구 지워졌는지 표기해주는 애드온입니다

`/bn` 혹은 `/buffnotifier` 명령어로 ui 위치 이동 아이콘 숨김/표시 할수 있습니다.

`/bn hide 406` 등 버프 아이디를 입력하면 그 버프는 더이상 안뜨게끔 조정이 가능합니다.

https://handtos.mochisuke.jp/ktos/ko/database/buffs

위 주소에서 버프 ID 를 찾아볼수가 있는데, 예를들어 매직실드의 아이디는 67, 즉 `/bn hide 67` 을 하면 매직실드가 더이상 안뜨게끔 설정 가능합니다.

반대로, 숨김이 된 버프를 다시 보이게 할려면 `/bn unhide 67` 처럼 `unhide` 명령어를 사용하시면됩니다.

제가 개인적으로 사용하는 설정파일: https://github.com/meldavy/tos-addons/blob/main/buffnotifier/settings.json
* 다운 후 addons/buffnotifier/settings.json 덮어씌우기

# Buff Notifier
Addon to display added and removed buffs.

Use the `/bn` or `/buffnotifier` command to hide and show the addon position mover icon.

You can hide unwanted buffs from being displayed. Find the buff ID from

https://handtos.mochisuke.jp/ktos/ko/database/buffs

and use the `/bn hide id` command, where `id` is the numerical class ID. For instance, Magic Shield has an id of `67`, so to hide magic shield from BuffNotifier, use `/bn hide 67`

Similar, to unhide, use `/bn unhide id`

You can use my blacklist setting: https://github.com/meldavy/tos-addons/blob/main/buffnotifier/settings.json
* Download and replace addons/buffnotifier/settings.json

![image](https://user-images.githubusercontent.com/12102540/136193948-eaf2fc8a-a133-4bc7-889f-6ba1c3a2e833.png)

* v1.0.6 - Bugfixes
* v1.0.2 - Add blacklist feature
* v1.0.1 - Enable repositioning
